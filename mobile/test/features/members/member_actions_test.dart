import 'package:flutter_test/flutter_test.dart';
import 'package:qesma_api/qesma_api.dart';
import 'package:qesma/core/permissions/group_role.dart';
import 'package:qesma/core/permissions/permissions.dart';
import 'package:qesma/features/members/application/member_actions.dart';

typedef _Case = ({String name, GroupRole viewer, String role, bool linked, bool left, bool self, Set<MemberAction> expected});

MemberDto _member({required String role, required bool linked, required bool left, required bool self}) => MemberDto((b) => b
  ..id = 'm'
  ..displayName = 'x'
  ..role = role
  ..status = left ? 'LEFT' : 'ACTIVE'
  ..hasAccount = linked
  ..isYou = self
  ..sortOrder = 0
  ..createdAt = DateTime.utc(2026));

const _rename = MemberAction.rename;
const _delete = MemberAction.delete;
const _promote = MemberAction.promote;
const _demote = MemberAction.demote;
const _unlink = MemberAction.unlink;
const _markLeft = MemberAction.markLeft;
const _reactivate = MemberAction.reactivate;
const _transfer = MemberAction.transferOwnership;

_Case _c(String name, GroupRole viewer, String role, {bool linked = true, bool left = false, bool self = false, required Set<MemberAction> expected}) =>
    (name: name, viewer: viewer, role: role, linked: linked, left: left, self: self, expected: expected);

void main() {
  const owner = GroupRole.owner;
  const admin = GroupRole.admin;
  const member = GroupRole.member;

  // The whole matrix of the FL12 plan.
  final table = <_Case>[
    _c('owner -> self', owner, 'OWNER', self: true, expected: {_rename}),
    _c('owner -> admin', owner, 'ADMIN', expected: {_rename, _demote, _unlink, _markLeft, _transfer}),
    _c('owner -> member', owner, 'MEMBER', expected: {_rename, _promote, _unlink, _markLeft, _transfer}),
    _c('owner -> ghost', owner, 'MEMBER', linked: false, expected: {_rename, _delete, _markLeft}),
    _c('owner -> LEFT member', owner, 'MEMBER', left: true, expected: {_rename, _reactivate}),
    _c('owner -> LEFT admin', owner, 'ADMIN', left: true, expected: {_rename, _reactivate}),
    _c('owner -> LEFT ghost', owner, 'MEMBER', linked: false, left: true, expected: {_rename, _delete, _reactivate}),
    _c('admin -> self', admin, 'ADMIN', self: true, expected: {_rename}),
    _c('admin -> owner', admin, 'OWNER', expected: {_rename}),
    _c('admin -> other admin', admin, 'ADMIN', expected: {_rename}),
    _c('admin -> member', admin, 'MEMBER', expected: {_rename, _unlink, _markLeft}),
    _c('admin -> ghost', admin, 'MEMBER', linked: false, expected: {_rename, _delete, _markLeft}),
    _c('admin -> LEFT member', admin, 'MEMBER', left: true, expected: {_rename, _reactivate}),
    _c('admin -> LEFT ghost', admin, 'MEMBER', linked: false, left: true, expected: {_rename, _delete, _reactivate}),
    for (final role in ['OWNER', 'ADMIN', 'MEMBER']) _c('member -> $role', member, role, expected: {}),
    _c('member -> ghost', member, 'MEMBER', linked: false, expected: {}),
    _c('member -> self', member, 'MEMBER', self: true, expected: {}),
  ];

  group('options-sheet action matrix', () {
    for (final c in table) {
      test(c.name, () {
        final actions = memberActionsFor(
          viewer: Permissions(c.viewer),
          target: _member(role: c.role, linked: c.linked, left: c.left, self: c.self),
        );
        expect(actions, c.expected);
      });
    }
  });

  test('an unknown viewer role is a Member: nothing is offered', () {
    expect(
      memberActionsFor(viewer: Permissions(GroupRole.parse('SUPERUSER')), target: _member(role: 'MEMBER', linked: true, left: false, self: false)),
      isEmpty,
    );
  });

  test('transfer candidates: active, linked, not me', () {
    final list = [
      _member(role: 'OWNER', linked: true, left: false, self: true),
      _member(role: 'ADMIN', linked: true, left: false, self: false),
      _member(role: 'MEMBER', linked: false, left: false, self: false),
      _member(role: 'MEMBER', linked: true, left: true, self: false),
    ];
    expect(transferCandidates(list), [list[1]]);
  });
}
