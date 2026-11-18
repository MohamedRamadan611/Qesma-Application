import 'package:built_collection/built_collection.dart';
import 'package:drift/drift.dart';
import 'package:qesma_api/qesma_api.dart';
import 'package:qesma_engine/qesma_engine.dart';

import '../db/local_database.dart';
import '../errors.dart';
import 'commands.dart';
import 'field_rules.dart';
import 'idempotency_service.dart';
import 'local_context.dart';
import 'views.dart';

/// Payments between members (spec 7.8, 8.2) for the local app (STANDALONE_SPEC 3.5, A125): a settlement is recorded
/// by the Owner and every other member is a ghost, so it is CONFIRMED at once (A85). Cancel is the only undo and is
/// allowed from any open or confirmed state; confirm and dispute are server-only.
final class SettlementService {
  SettlementService(this._ctx) : _idempotency = IdempotencyService(_ctx);

  final LocalContext _ctx;
  final IdempotencyService _idempotency;

  static const String createEndpoint = 'POST /api/v1/groups/{gid}/settlements';
  static const Set<String> statuses = {'PENDING', 'CONFIRMED', 'DISPUTED', 'CANCELLED'};
  static const int maxNote = 200;
  static const String minDate = '2000-01-01';
  static const String maxDate = '2100-12-31';
  static const String payment = 'PAYMENT';
  static const String poolDeposit = 'POOL_DEPOSIT';

  LocalDatabase get _db => _ctx.db;

  Future<Outcome> create(String groupId, String key, SettlementIn command) => _db.transaction(() async {
        final access = await _ctx.requireGroup(groupId);
        final v = _validate(command);
        final fingerprint = IdempotencyService.fingerprint({
          'endpoint': createEndpoint,
          'groupId': groupId,
          'fromMemberId': v.from,
          'toMemberId': v.to,
          'amountMinor': v.amount,
          'settledOn': v.settledOn,
          'note': v.note,
          // Only the non-default kind is hashed (Java SettlementService.canonical), so older keys keep their hash.
          if (v.kind != payment) 'kind': v.kind,
        });
        final replay = await _idempotency.findReplay(key, createEndpoint, fingerprint);
        if (replay != null) return replay;
        _requireActiveMember(access, v.from);
        _requireActiveMember(access, v.to);
        // A135: a deposit goes to the treasurer only (this also refuses a deposit in a group without a treasurer).
        if (v.kind == poolDeposit && v.to != access.group.treasurerMemberId) {
          throw LocalApiException.validation('A pool deposit must go to the group treasurer');
        }
        final now = _ctx.clock();
        final row = SettlementRow(
          id: _ctx.newId(),
          groupId: groupId,
          fromMemberId: v.from,
          toMemberId: v.to,
          amountMinor: v.amount,
          settledOn: v.settledOn,
          note: v.note,
          createdByUserId: access.profile.id,
          createdByMemberId: access.me.id,
          createdAt: now,
          status: 'CONFIRMED',
          declaredAt: now,
          confirmedAt: now,
          // A85 with the caller as Owner: recorded on someone's behalf unless the caller is the receiver.
          recordedByAdmin: v.to == access.me.id ? 0 : 1,
          kind: v.kind,
        );
        await _db.settlementsDao.insertSettlement(row);
        final outcome = Outcome(201, toJsonText(SettlementView.serializer, settlementView(row)));
        await _idempotency.store(key, createEndpoint, fingerprint, outcome);
        return outcome;
      });

  /// Every status, newest `settledOn` first; [statusFilter] empty = all. An unknown status is 422.
  Future<PageResponseSettlementView> list(String groupId, List<String> statusFilter, int page, int size) =>
      _db.transaction(() async {
        FieldRules.page(page, size);
        for (final s in statusFilter) {
          if (!statuses.contains(s)) throw LocalApiException.validation('status must be one of ${statuses.join(', ')}');
        }
        await _ctx.requireGroup(groupId);
        final count = await _db.settlementsDao.countByGroup(groupId, statuses: statusFilter);
        final rows = await _db.settlementsDao
            .listByGroup(groupId, limit: size, offset: page * size, statuses: statusFilter);
        return PageResponseSettlementView((b) => b
          ..items = ListBuilder([for (final r in rows) settlementView(r)])
          ..page = page
          ..size = size
          ..totalElements = count
          ..totalPages = (count + size - 1) ~/ size);
      });

  /// CANCELLED from any other state; already CANCELLED is an idempotent no-op that returns the current view.
  /// The schema ties `confirmed_at` to the CONFIRMED status, so a cancelled payment keeps `cancelledAt` only.
  Future<SettlementView> cancel(String groupId, String settlementId) => _db.transaction(() async {
        await _ctx.requireGroup(groupId);
        final row = await _db.settlementsDao.findById(settlementId);
        if (row == null || row.groupId != groupId) throw LocalApiException.notFound();
        if (row.status == 'CANCELLED') return settlementView(row);
        final changed = await _db.settlementsDao.updateStatus(
          settlementId,
          row.status,
          SettlementsCompanion(
            status: const Value('CANCELLED'),
            cancelledAt: Value(_ctx.clock()),
            confirmedAt: const Value(null),
          ),
        );
        if (changed == 0) {
          throw LocalApiException.conflict('INVALID_STATE_TRANSITION', 'The payment changed meanwhile');
        }
        return settlementView((await _db.settlementsDao.findById(settlementId))!);
      });

  /// Java `SettlementValidator`, same order.
  static ({String from, String to, int amount, String settledOn, String? note, String kind}) _validate(SettlementIn c) {
    final from = c.fromMemberId;
    final to = c.toMemberId;
    if (from == null || to == null) throw LocalApiException.validation('fromMemberId and toMemberId are required');
    if (from == to) throw LocalApiException.validation('fromMemberId and toMemberId must differ');
    final amount = c.amountMinor;
    if (amount == null || amount <= 0) throw LocalApiException.validation('amountMinor must be greater than zero');
    if (!Limits.withinAmountLimit(amount)) {
      throw LocalApiException.validation('amountMinor must be at most ${Limits.maxAmountMinor}');
    }
    final settledOn = c.settledOn;
    if (settledOn == null) throw LocalApiException.validation('settledOn is required');
    if (settledOn.compareTo(minDate) < 0 || settledOn.compareTo(maxDate) > 0) {
      throw LocalApiException.validation('settledOn must be between $minDate and $maxDate');
    }
    String? note;
    if (c.note != null && javaStrip(c.note!).isNotEmpty) {
      note = javaStrip(c.note!);
      if (codePoints(note) > maxNote) throw LocalApiException.validation('note must be at most $maxNote characters');
    }
    final rawKind = c.kind;
    final kind = rawKind == null || javaStrip(rawKind).isEmpty ? payment : javaStrip(rawKind).toUpperCase();
    if (kind != payment && kind != poolDeposit) {
      throw LocalApiException.validation('kind must be $payment or $poolDeposit');
    }
    return (from: from, to: to, amount: amount, settledOn: settledOn, note: note, kind: kind);
  }

  static void _requireActiveMember(GroupAccess access, String memberId) {
    final m = access.member(memberId);
    if (m == null) {
      throw LocalApiException.unprocessable('MEMBER_NOT_IN_GROUP', 'A referenced member is not part of this group');
    }
    if (m.status == 'LEFT') throw LocalApiException.unprocessable('MEMBER_INACTIVE', 'This member has left the group');
  }
}
