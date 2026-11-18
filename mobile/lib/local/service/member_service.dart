import 'package:drift/drift.dart';
import 'package:qesma_api/qesma_api.dart';

import '../db/local_database.dart';
import '../errors.dart';
import 'field_rules.dart';
import 'local_context.dart';
import 'views.dart';

/// Members (spec 3.1, 8.2): add, rename and delete ghost members, a port of Java `MemberService` for one local user.
/// Role and status changes are server-only (STANDALONE_SPEC 4): a PATCH carrying them is 422.
final class MemberService {
  MemberService(this._ctx);

  final LocalContext _ctx;

  LocalDatabase get _db => _ctx.db;

  Future<MemberDto> add(String groupId, String? displayName) => _db.transaction(() async {
        final access = await _ctx.requireGroup(groupId);
        final name = FieldRules.name(displayName, FieldRules.memberNameMax, 'displayName');
        await _requireUniqueName(groupId, name, exceptMemberId: null);
        final sortOrder = await _db.groupsDao.nextMemberSeq(groupId); // never reused (A20)
        final id = _ctx.newId();
        await _db.membersDao.insertMember(
          id: id,
          groupId: groupId,
          displayName: name,
          sortOrder: sortOrder,
          createdAt: _ctx.clock(),
        );
        return memberDto((await _db.membersDao.findById(id))!, access.profile.id);
      });

  Future<MemberDto> update(String groupId, String memberId, {String? displayName, String? role, String? status}) =>
      _db.transaction(() async {
        final access = await _ctx.requireGroup(groupId);
        if (access.member(memberId) == null) throw LocalApiException.notFound();
        if (displayName == null && role == null && status == null) {
          throw LocalApiException.validation('Nothing to update');
        }
        if (role != null || status != null) {
          throw LocalApiException.validation('Roles and member status cannot be changed in this app');
        }
        final name = FieldRules.name(displayName, FieldRules.memberNameMax, 'displayName');
        await _requireUniqueName(groupId, name, exceptMemberId: memberId);
        await _db.membersDao.rename(memberId, name);
        return memberDto((await _db.membersDao.findById(memberId))!, access.profile.id);
      });

  /// A member with an account (the owner, "you") is protected; a member used anywhere in the ledger (payer, share,
  /// item assignee even when owing 0, soft-deleted expenses included, or a settlement of any status) stays.
  Future<void> delete(String groupId, String memberId) => _db.transaction(() async {
        final access = await _ctx.requireGroup(groupId);
        final member = access.member(memberId);
        if (member == null) throw LocalApiException.notFound();
        if (member.userId != null) {
          throw LocalApiException.conflict('OWNER_MEMBER_PROTECTED', 'A member with an account cannot be removed');
        }
        final used = await _db.customSelect(
          'SELECT EXISTS(SELECT 1 FROM expense_payers WHERE member_id = ?1) '
          'OR EXISTS(SELECT 1 FROM expense_splits WHERE member_id = ?1) '
          'OR EXISTS(SELECT 1 FROM expense_item_assignees WHERE member_id = ?1) '
          'OR EXISTS(SELECT 1 FROM settlements WHERE from_member_id = ?1 OR to_member_id = ?1) AS used',
          variables: [Variable.withString(memberId)],
          readsFrom: {_db.expensePayers, _db.expenseSplits, _db.expenseItemAssignees, _db.settlements},
        ).getSingle();
        if (used.read<bool>('used')) {
          throw LocalApiException.conflict('MEMBER_HAS_TRANSACTIONS', 'This member is used by expenses or payments');
        }
        // SA10: the treasurer stays (Java's V20 foreign key refuses this delete; there is no dedicated code).
        if (access.group.treasurerMemberId == memberId) {
          throw LocalApiException.conflict('MEMBER_HAS_TRANSACTIONS', 'This member is the pool treasurer');
        }
        await _db.membersDao.deleteMember(memberId);
      });

  /// Names are unique per group on the normalized key (A152); the member being renamed may keep its own name.
  Future<void> _requireUniqueName(String groupId, String name, {required String? exceptMemberId}) async {
    final existing = await _db.membersDao.findByName(groupId, name);
    if (existing != null && existing.id != exceptMemberId) {
      throw LocalApiException.conflict('DUPLICATE_MEMBER_NAME', 'A member with this name already exists');
    }
  }
}
