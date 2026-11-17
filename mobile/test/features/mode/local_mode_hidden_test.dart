import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/app.dart';
import 'package:qesma/core/app_mode.dart';
import 'package:qesma/core/features_for_mode.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/l10n/locale_controller.dart';
import 'package:qesma/core/permissions/group_role.dart';
import 'package:qesma/core/permissions/permissions.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/local/backend/local_backend_overrides.dart';

import '../../local/backend/support/local_http.dart';
import '../../support/test_app.dart' show allConfigs;

/// SA4: every server-only control is absent from the widget tree in local mode (ar/en, text scale 1.0 and 2.0),
/// on every screen that could carry one; and the server-mode table keeps them.
void main() {
  late LocalHttp http;
  late String gid;

  setUp(() async {
    http = await LocalHttp.open(profileName: 'Mona');
    final g = await http.group(name: 'Siwa');
    gid = g['id'] as String;
    final you = g['yourMemberId'] as String;
    await http.member(gid, 'Omar');
    final r = await http.expense(gid, {
      'title': 'Dinner',
      'expenseDate': '2026-11-10',
      'splitType': 'EQUAL',
      'totalMinor': 10000,
      'payers': [
        {'memberId': you, 'amountMinor': 10000}
      ],
    });
    expect(r.statusCode, 201, reason: '${r.data}');
  });
  tearDown(() => http.close());

  List<String> serverOnly(AppLocalizations l) => [
        l.homeSignOut,
        l.profileAccountSettings,
        l.profileChangePassword,
        l.accountGoogleTitle,
        l.profileEmailLabel,
        l.inviteAction,
        l.inviteEnterCodeButton,
        l.membersRoleOwner,
        l.membersRoleAdmin,
        l.membersBadgeConnected,
        l.membersBadgeNameOnly,
        l.membersTransfer,
        l.membersLeave,
        l.remindButton,
        l.incomingTitle,
        l.settlementChipPending,
        l.settlementChipDisputed,
        l.pendingBadge,
        l.disputeFlag,
        l.welcomeStart,
      ];

  for (final config in allConfigs) {
    testWidgets('no server-only control on any screen (${config.name})', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 900);
      tester.platformDispatcher.textScaleFactorTestValue = config.textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final container = ProviderContainer(overrides: localModeOverrides(http.db));
      addTearDown(container.dispose);
      container.read(localeProvider.notifier).set(config.locale);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const QesmaApp()));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold).first));
      final router = container.read(routerProvider);

      Future<void> visit(String location) async {
        router.go(location);
        await tester.pumpAndSettle();
        for (final text in serverOnly(l10n)) {
          expect(find.text(text), findsNothing, reason: '"$text" on $location (${config.name})');
        }
        // The only icons that mark a server concept.
        for (final icon in [Icons.person_add, Icons.group_add, Icons.logout, Icons.swap_horiz_outlined]) {
          expect(find.byIcon(icon), findsNothing, reason: '$icon on $location');
        }
      }

      await visit(Routes.home);
      await visit(Routes.group(gid));
      await visit('${Routes.group(gid)}?tab=balances');
      await visit('${Routes.group(gid)}?tab=members');
      await visit(Routes.account);
      await visit(Routes.editProfile);

      // Links and routes of the server app are ignored: the person stays on their own groups.
      for (final stray in ['/join/ABCD2345', Routes.join, Routes.signIn, Routes.accountSettings, Routes.changePassword, Routes.joinRequests(gid), Routes.splash, Routes.welcome]) {
        router.go(stray);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, Routes.home, reason: stray);
      }
    });
  }

  test('the mode tables: local has no server-only feature, server keeps every one', () {
    expect(ModeFeatures.of(AppMode.server).signIn && ModeFeatures.of(AppMode.server).invites && ModeFeatures.of(AppMode.server).settlementReview, isTrue);
    final local = ModeFeatures.local;
    expect(
      [local.signIn, local.signOut, local.accountDeletion, local.invites, local.joinByCode, local.joinRequests, local.roleChips, local.roleManagement, local.leaveGroup, local.transferOwnership, local.settlementReview, local.serverRemind, local.notifications, local.sessionExpiredDialog, local.changePassword, local.accountSettings],
      everyElement(isFalse),
    );
    // An owner in server mode keeps every ability; the same owner in local mode loses the multi-user ones only.
    const server = Permissions(GroupRole.owner);
    const onDevice = Permissions(GroupRole.owner, features: ModeFeatures.local);
    expect([server.canManageInvites, server.canApproveJoins, server.canTransferOwnership, server.canRemindAny, server.canChangeRoles], everyElement(isTrue));
    expect([onDevice.canManageInvites, onDevice.canApproveJoins, onDevice.canTransferOwnership, onDevice.canRemindAny, onDevice.canChangeRoles, onDevice.canLeave], everyElement(isFalse));
    expect([onDevice.canManageMembers, onDevice.canEditGroup, onDevice.canDeleteGroup, onDevice.canAddExpense], everyElement(isTrue));
  });
}
