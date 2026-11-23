import 'package:built_collection/built_collection.dart';
import 'package:drift/drift.dart';
import 'package:qesma_api/qesma_api.dart';
import 'package:qesma_engine/qesma_engine.dart' show Limits;

import '../db/local_database.dart';
import '../errors.dart';
import 'expense_validator.dart';
import 'field_rules.dart';
import 'ledger.dart';
import 'local_context.dart';
import 'views.dart';

/// Groups (spec 3.1, 8.2), a port of Java `GroupService` + the GroupDto assembly of `GroupController`.
final class GroupService {
  GroupService(this._ctx) : _ledger = Ledger(_ctx.db);

  final LocalContext _ctx;
  final Ledger _ledger;

  LocalDatabase get _db => _ctx.db;

  /// Creates the group and its member #1, the caller ("you", OWNER, linked; B9, A53) in one transaction.
  Future<GroupDto> create({String? name, String? type, String? currencyCode}) => _db.transaction(() async {
        final me = await _ctx.profile();
        final validName = FieldRules.name(name, FieldRules.groupNameMax, 'name');
        final validType = FieldRules.groupType(type);
        final currency = FieldRules.currency(currencyCode);
        final now = _ctx.clock();
        final id = _ctx.newId();
        await _db.groupsDao.insertGroup(ExpenseGroupsCompanion.insert(
          id: id,
          ownerUserId: me.id,
          name: validName,
          type: validType,
          currencyCode: Value(currency),
          createdAt: now,
          updatedAt: now,
          memberSeq: const Value(1), // the owner is member #1
        ));
        await _db.membersDao.insertMember(
          id: _ctx.newId(),
          groupId: id,
          displayName: _ownerMemberName(me.displayName),
          sortOrder: 1,
          createdAt: now,
          userId: me.id,
          role: 'OWNER',
          joinedAt: now,
        );
        return detail(await _ctx.requireGroup(id));
      });

  /// The caller's groups, newest first (A19), with member counts, totals and their own net.
  Future<PageResponseGroupSummaryDto> list(int page, int size) => _db.transaction(() async {
        FieldRules.page(page, size);
        final me = await _ctx.profile();
        const membership = 'JOIN members me ON me.group_id = g.id AND me.user_id = ? AND me.status = \'ACTIVE\' AND g.archived_at IS NULL';
        final total = await _db
            .customSelect('SELECT COUNT(*) AS n FROM expense_groups g $membership',
                variables: [Variable.withString(me.id)], readsFrom: {_db.expenseGroups, _db.members})
            .getSingle();
        final rows = await _db.customSelect(
          'SELECT g.id AS id, me.id AS me_id, me.role AS role FROM expense_groups g $membership '
          'ORDER BY g.created_at DESC, g.id DESC LIMIT ? OFFSET ?',
          variables: [Variable.withString(me.id), Variable.withInt(size), Variable.withInt(page * size)],
          readsFrom: {_db.expenseGroups, _db.members},
        ).get();
        final items = <GroupSummaryDto>[];
        for (final r in rows) {
          final id = r.read<String>('id');
          final group = (await _db.groupsDao.findById(id))!;
          final members = await _db.membersDao.listByGroup(id);
          final totals = await _ledger.groupTotals(id);
          final net = await _ledger.netOf(id, r.read<String>('me_id'));
          items.add(GroupSummaryDto((b) => b
            ..id = group.id
            ..name = group.name
            ..type = group.type
            ..currencyCode = group.currencyCode
            ..memberCount = members.where((m) => m.status == 'ACTIVE').length
            ..totalSpentMinor = totals.totalSpentMinor
            ..lastExpenseAt = totals.lastExpenseAt == null ? null : utc(totals.lastExpenseAt!)
            ..yourNetMinor = net
            ..yourRole = r.read<String>('role')));
        }
        final count = total.read<int>('n');
        return PageResponseGroupSummaryDto((b) => b
          ..items = ListBuilder(items)
          ..page = page
          ..size = size
          ..totalElements = count
          ..totalPages = (count + size - 1) ~/ size);
      });

  Future<GroupDto> get(String groupId) => _db.transaction(() async => detail(await _ctx.requireGroup(groupId)));

  /// Edits name and/or type under If-Match (and, A190/A193, the trip budget settings in [budget]). A stale version is 409 VERSION_CONFLICT with the current GroupDto
  /// (A113), checked before the input; the version moves only when something really changed.
  /// [treasurerMemberId] null = unchanged (the treasurer cannot be cleared, as in Java); see [_requireTreasurerChange].
  Future<GroupDto> update(String groupId, int expectedVersion,
          {String? name, String? type, String? treasurerMemberId, BudgetPatch budget = BudgetPatch.none}) =>
      _db.transaction(() async {
        final access = await _ctx.requireGroup(groupId);
        final group = access.group;
        if (group.version != expectedVersion) {
          throw LocalApiException.versionConflict(
            'The group was modified by someone else',
            group.version,
            toJsonValue(GroupDto.serializer, await detail(access))!,
          );
        }
        final newName = name == null ? group.name : FieldRules.name(name, FieldRules.groupNameMax, 'name');
        final newType = type == null ? group.type : FieldRules.groupType(type);
        final treasurerChanges = treasurerMemberId != null && treasurerMemberId != group.treasurerMemberId;
        if (treasurerChanges) await _requireTreasurerChange(access, treasurerMemberId);
        final b = budget;
        final newBudget = _resulting(b.budgetMinor, b.clearBudget, group.budgetMinor, 'budgetMinor');
        final newStart = _resulting(b.tripStartDate, b.clearTripStartDate, group.tripStartDate, 'tripStartDate');
        final newEnd = _resulting(b.tripEndDate, b.clearTripEndDate, group.tripEndDate, 'tripEndDate');
        if (newBudget != null && (newBudget < 1 || newBudget > Limits.maxAmountMinor)) {
          throw LocalApiException.validation('budgetMinor must be between 1 and ${Limits.maxAmountMinor}');
        }
        _requireTripDate(newStart, 'tripStartDate');
        _requireTripDate(newEnd, 'tripEndDate');
        // Checked on the resulting state, so sending only one date cannot leave the stored pair reversed.
        if (newStart != null && newEnd != null && newEnd.compareTo(newStart) < 0) {
          throw LocalApiException.validation('tripEndDate must not be before tripStartDate');
        }
        // A199: a group has a pool treasurer or a trip budget, never both (checked on the resulting state).
        final newTreasurer = treasurerChanges ? treasurerMemberId : group.treasurerMemberId;
        if (newBudget != null && newTreasurer != null) {
          throw LocalApiException.validation('A group cannot have both a pool treasurer and a trip budget');
        }
        final budgetChanges =
            newBudget != group.budgetMinor || newStart != group.tripStartDate || newEnd != group.tripEndDate;
        if (newName != group.name || newType != group.type || treasurerChanges || budgetChanges) {
          final changed = await _db.groupsDao.updateIfVersion(
            groupId,
            expectedVersion,
            ExpenseGroupsCompanion(
              name: Value(newName),
              type: Value(newType),
              treasurerMemberId: treasurerChanges ? Value(treasurerMemberId) : const Value.absent(),
              budgetMinor: Value(newBudget),
              tripStartDate: Value(newStart),
              tripEndDate: Value(newEnd),
              updatedAt: Value(_ctx.clock()),
              version: Value(group.version + 1),
            ),
          );
          if (changed == 0) {
            throw LocalApiException.conflict('VERSION_CONFLICT', 'The group was modified by someone else');
          }
        }
        return detail(await _ctx.requireGroup(groupId));
      });

  /// A193: the value after the patch; a value together with its clear flag is a 422.
  static T? _resulting<T extends Object>(T? sent, bool clear, T? stored, String field) {
    if (clear && sent != null) throw LocalApiException.validation('$field and its clear flag cannot both be sent');
    if (clear) return null;
    return sent ?? stored;
  }

  static void _requireTripDate(String? d, String field) {
    if (d != null && (d.compareTo(ExpenseValidator.minDate) < 0 || d.compareTo(ExpenseValidator.maxDate) > 0)) {
      throw LocalApiException.validation('$field must be between ${ExpenseValidator.minDate} and ${ExpenseValidator.maxDate}');
    }
  }

  /// A137 (Java `GroupService.requireTreasurerChange`): the treasurer is an ACTIVE member of this group (422), and it
  /// changes only while the pool has no deposit and no pool expense, cancelled and soft-deleted rows included (409).
  Future<void> _requireTreasurerChange(GroupAccess access, String memberId) async {
    final m = access.member(memberId);
    if (m == null) throw LocalApiException.validation('treasurerMemberId must be a member of this group');
    if (m.status != 'ACTIVE') throw LocalApiException.validation('The treasurer must be an active member');
    if (await _ledger.poolUsed(access.group.id)) {
      throw LocalApiException.conflict(
        'INVALID_STATE_TRANSITION',
        'The treasurer cannot change once the pool has deposits or expenses',
      );
    }
  }

  /// Deletes a group with no ledger data, or one with history that is fully settled (all nets and the pool zero), and no
  /// other linked member; otherwise 409 GROUP_NOT_EMPTY (A23, B12).
  Future<void> delete(String groupId) => _db.transaction(() async {
        final access = await _ctx.requireGroup(groupId);
        final ledger = await _db.customSelect(
          'SELECT EXISTS(SELECT 1 FROM expenses WHERE group_id = ?1) '
          'OR EXISTS(SELECT 1 FROM settlements WHERE group_id = ?1) AS used',
          variables: [Variable.withString(groupId)],
          readsFrom: {_db.expenses, _db.settlements},
        ).getSingle();
        if (access.members.any((m) => m.userId != null && m.role != 'OWNER')) {
          throw LocalApiException.conflict('GROUP_NOT_EMPTY', 'The group has other members with an account');
        }
        if (ledger.read<bool>('used')) {
          // Standalone decision (A23 amended): a group with history can be deleted once it is fully settled, i.e.
          // every member's net is zero and the pool (if any) is empty. Anything still open is blocked as before.
          if (!await _isSettled(access)) {
            throw LocalApiException.conflict('GROUP_NOT_EMPTY', 'The group has unsettled balances');
          }
          await _db.groupsDao.deleteGroupWithLedger(groupId);
          return;
        }
        await _db.groupsDao.deleteGroupWithMembers(groupId);
      });

  /// A183/A184: every member's net is zero and the pool (if the group has one) is empty.
  Future<bool> _isSettled(GroupAccess access) async {
    final nets = await _ledger.nets(access.group.id, access.members);
    final poolOpen = access.group.treasurerMemberId != null && await _ledger.poolBalance(access.group.id) != 0;
    return !nets.values.any((n) => n != 0) && !poolOpen;
  }

  Future<bool> isSettled(String groupId) => _db.transaction(() async => _isSettled(await _ctx.requireGroup(groupId)));

  /// A184: hides a settled group from the groups list; it is deleted for good after the retention period. A group
  /// with an open balance or a non-empty pool cannot be archived (409 GROUP_NOT_EMPTY, same rule as the delete).
  /// Archiving an archived group changes nothing.
  Future<void> archive(String groupId) => _db.transaction(() async {
        final access = await _ctx.requireGroup(groupId);
        if (access.group.archivedAt != null) return;
        if (!await _isSettled(access)) {
          throw LocalApiException.conflict('GROUP_NOT_EMPTY', 'The group has unsettled balances');
        }
        await _db.groupsDao.setArchivedAt(groupId, _ctx.clock());
      });

  /// A184: brings an archived group back to the list. Restoring an active group changes nothing.
  Future<void> restore(String groupId) => _db.transaction(() async {
        await _ctx.requireGroup(groupId);
        await _db.groupsDao.setArchivedAt(groupId, null);
      });

  /// GroupDto exactly as GET shows it to the caller.
  Future<GroupDto> detail(GroupAccess access) async {
    final g = access.group;
    final totals = await _ledger.groupTotals(g.id);
    final net = await _ledger.netOf(g.id, access.me.id);
    // A136: null without a treasurer; never stored.
    final meter = g.treasurerMemberId == null ? null : await _ledger.poolBalance(g.id);
    return GroupDto((b) => b
      ..id = g.id
      ..name = g.name
      ..type = g.type
      ..currencyCode = g.currencyCode
      ..createdAt = utc(g.createdAt)
      ..updatedAt = utc(g.updatedAt)
      ..version = g.version
      ..totalSpentMinor = totals.totalSpentMinor
      ..lastExpenseAt = totals.lastExpenseAt == null ? null : utc(totals.lastExpenseAt!)
      ..yourMemberId = access.me.id
      ..yourNetMinor = net
      ..yourRole = access.me.role
      ..muted = false
      ..treasurerMemberId = g.treasurerMemberId
      ..poolBalanceMinor = meter
      // A190: the trip budget settings (figures are computed elsewhere, never stored: A191).
      ..budgetMinor = g.budgetMinor
      ..tripStartDate = g.tripStartDate == null ? null : dateOf(g.tripStartDate!)
      ..tripEndDate = g.tripEndDate == null ? null : dateOf(g.tripEndDate!)
      ..members = ListBuilder([for (final m in access.members) memberDto(m, access.profile.id)]));
  }

  /// The owner's member name: the profile name cut to the member limit (40 code points), "Me" if blank.
  static String _ownerMemberName(String displayName) {
    final name = javaStrip(displayName);
    if (name.isEmpty) return 'Me';
    return FieldRules.cutCodePoints(name, FieldRules.memberNameMax);
  }
}

/// The trip budget part of a group PATCH (A190, A193; Java `GroupService.BudgetPatch`): absent or null = no change,
/// a `clear*` flag = set to null.
final class BudgetPatch {
  const BudgetPatch({
    this.budgetMinor,
    this.clearBudget = false,
    this.tripStartDate,
    this.clearTripStartDate = false,
    this.tripEndDate,
    this.clearTripEndDate = false,
  });

  static const BudgetPatch none = BudgetPatch();

  final int? budgetMinor;
  final bool clearBudget;
  final String? tripStartDate;
  final bool clearTripStartDate;
  final String? tripEndDate;
  final bool clearTripEndDate;
}
