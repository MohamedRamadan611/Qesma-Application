import 'package:built_collection/built_collection.dart';
import 'package:drift/drift.dart';
import 'package:qesma_api/qesma_api.dart';

import '../db/local_database.dart';
import '../errors.dart';
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
        const membership = 'JOIN members me ON me.group_id = g.id AND me.user_id = ? AND me.status = \'ACTIVE\'';
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

  /// Edits name and/or type under If-Match. A stale version is 409 VERSION_CONFLICT with the current GroupDto
  /// (A113), checked before the input; the version moves only when something really changed.
  Future<GroupDto> update(String groupId, int expectedVersion, {String? name, String? type}) =>
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
        if (newName != group.name || newType != group.type) {
          final changed = await _db.groupsDao.updateIfVersion(
            groupId,
            expectedVersion,
            ExpenseGroupsCompanion(
              name: Value(newName),
              type: Value(newType),
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

  /// Deletes a group with no ledger data at all (expenses incl. soft-deleted, settlements of any status) and no
  /// other linked member; otherwise 409 GROUP_NOT_EMPTY (A23, B12).
  Future<void> delete(String groupId) => _db.transaction(() async {
        final access = await _ctx.requireGroup(groupId);
        final ledger = await _db.customSelect(
          'SELECT EXISTS(SELECT 1 FROM expenses WHERE group_id = ?1) '
          'OR EXISTS(SELECT 1 FROM settlements WHERE group_id = ?1) AS used',
          variables: [Variable.withString(groupId)],
          readsFrom: {_db.expenses, _db.settlements},
        ).getSingle();
        if (ledger.read<bool>('used')) {
          throw LocalApiException.conflict('GROUP_NOT_EMPTY', 'The group has expenses or settlements');
        }
        if (access.members.any((m) => m.userId != null && m.role != 'OWNER')) {
          throw LocalApiException.conflict('GROUP_NOT_EMPTY', 'The group has other members with an account');
        }
        await _db.groupsDao.deleteGroupWithMembers(groupId);
      });

  /// GroupDto exactly as GET shows it to the caller.
  Future<GroupDto> detail(GroupAccess access) async {
    final g = access.group;
    final totals = await _ledger.groupTotals(g.id);
    final net = await _ledger.netOf(g.id, access.me.id);
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
      ..members = ListBuilder([for (final m in access.members) memberDto(m, access.profile.id)]));
  }

  /// The owner's member name: the profile name cut to the member limit (40 code points), "Me" if blank.
  static String _ownerMemberName(String displayName) {
    final name = javaStrip(displayName);
    if (name.isEmpty) return 'Me';
    return FieldRules.cutCodePoints(name, FieldRules.memberNameMax);
  }
}
