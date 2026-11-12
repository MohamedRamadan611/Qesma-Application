import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/permissions/group_role.dart';
import 'package:qesma/core/permissions/permissions.dart';

/// The role x permission table of PHASE2_SPEC section 2, as far as the UI uses it. One row per permission:
/// `[owner, admin, member]`. The server decides for real; this only decides what is shown.
void main() {
  group('GroupRole.parse', () {
    test('reads the three wire values', () {
      expect(GroupRole.parse('OWNER'), GroupRole.owner);
      expect(GroupRole.parse('ADMIN'), GroupRole.admin);
      expect(GroupRole.parse('MEMBER'), GroupRole.member);
    });

    test('anything else is the least privilege (a newer server never unlocks a control by accident)', () {
      for (final unknown in [null, '', 'owner', 'SUPERADMIN', 'LEFT', ' ADMIN']) {
        expect(GroupRole.parse(unknown), GroupRole.member, reason: 'for $unknown');
      }
    });
  });

  group('Permissions', () {
    final table = <String, ({bool Function(Permissions) get, List<bool> expected})>{
      'canEditGroup': (get: (p) => p.canEditGroup, expected: [true, true, false]),
      'canDeleteGroup': (get: (p) => p.canDeleteGroup, expected: [true, false, false]),
      'canManageMembers': (get: (p) => p.canManageMembers, expected: [true, true, false]),
      'canManageInvites': (get: (p) => p.canManageInvites, expected: [true, true, false]),
      'canApproveJoins': (get: (p) => p.canApproveJoins, expected: [true, true, false]),
      'canUnlinkMember': (get: (p) => p.canUnlinkMember, expected: [true, true, false]),
      'canChangeRoles': (get: (p) => p.canChangeRoles, expected: [true, false, false]),
      'canTransferOwnership': (get: (p) => p.canTransferOwnership, expected: [true, false, false]),
      'canLeave': (get: (p) => p.canLeave, expected: [false, true, true]),
      'canAddExpense': (get: (p) => p.canAddExpense, expected: [true, true, true]),
    };

    table.forEach((name, row) {
      test(name, () {
        const roles = [GroupRole.owner, GroupRole.admin, GroupRole.member];
        for (var i = 0; i < roles.length; i++) {
          expect(row.get(Permissions(roles[i])), row.expected[i], reason: '$name for ${roles[i].name}');
        }
      });
    });

    test('an unknown role (the group is not loaded yet) has no privilege at all', () {
      const unknown = Permissions.unknown();
      expect(unknown.role, GroupRole.member);
      expect(unknown.canEditGroup || unknown.canDeleteGroup || unknown.canManageMembers || unknown.canManageInvites, isFalse);
    });

    test('equal roles give equal permissions (so a provider does not rebuild for nothing)', () {
      expect(const Permissions(GroupRole.admin), const Permissions(GroupRole.admin));
      expect(const Permissions(GroupRole.admin), isNot(const Permissions(GroupRole.owner)));
      expect(const Permissions(GroupRole.admin).hashCode, const Permissions(GroupRole.admin).hashCode);
    });
  });
}
