import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/widgets/widgets.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma/features/invites/presentation/invite_sheet.dart';
import 'package:qesma/features/invites/application/pending_invite.dart';

import '../../support/auth_ui.dart';
import '../../support/fake_invites_server.dart';
import '../../support/invites_rig.dart';

const _code = 'ABCD2345';

AppLocalizations _l10n(Locale l) => lookupAppLocalizations(l);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first, warnIfMissed: false);
  await tester.pumpAndSettle();
}

AppButton _button(WidgetTester tester, String label) => tester.widget<AppButton>(find.widgetWithText(AppButton, label).first);

String _location(ProviderContainer c) => c.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

const _configs = <(Locale, double)>[(Locale('ar'), 1.0), (Locale('ar'), 2.0), (Locale('en'), 1.0), (Locale('en'), 2.0)];

void main() {
  group('join screen (P12-02)', () {
    for (final (locale, scale) in _configs) {
      testWidgets('${locale.languageCode} ${scale}x: preview, unclaimed names only, no money, no overflow', (tester) async {
        final l10n = _l10n(locale);
        await pumpInvitesApp(tester, inviteServer(), route: Routes.joinCode(_code), locale: locale, textScale: scale);

        expect(find.text('رحلة دهب'), findsOneWidget);
        expect(find.text(l10n.inviteInvitedBy('محمد')), findsOneWidget);
        expect(find.text(l10n.groupMemberCount('5')), findsOneWidget);
        for (final name in ['محسن', 'يوسف', 'كريم']) {
          expect(find.text(name), findsOneWidget);
        }
        expect(find.text(l10n.inviteWhoAreYou), findsOneWidget);
        expect(find.text(l10n.inviteNewMember), findsOneWidget);
        // a person who has not joined sees no money of the group: no balance chip, no amount, no currency
        expect(find.byType(BalanceStatusChip), findsNothing);
        expect(find.byType(MoneyText), findsNothing);
        expect(find.textContaining(l10n.moneyCurrency), findsNothing);
        expect(find.textContaining(RegExp(r'\d+[.,]\d{2}')), findsNothing);
        expect(_button(tester, l10n.inviteJoinButton).onPressed, isNull, reason: 'disabled until a choice is made');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('picking a name enables Join, sends claimMemberId, refetches the groups and opens the group', (tester) async {
      final server = inviteServer();
      final h = await pumpInvitesApp(tester, server, route: Routes.joinCode(_code));
      final l10n = _l10n(const Locale('ar'));
      await _tap(tester, find.text('يوسف'));
      expect(_button(tester, l10n.inviteJoinButton).onPressed, isNotNull);
      await _tap(tester, find.widgetWithText(AppButton, l10n.inviteJoinButton));

      expect(server.joinBodies.single, {'claimMemberId': 'u2'});
      expect(_location(h.container), Routes.group('g1'));
      expect(server.requests.where((r) => r == 'GET /api/v1/groups?page=0&size=20'), isNotEmpty, reason: 'groups refetched');
    });

    testWidgets('"I am a new member": the name field is prefilled, limited to 40, and DUPLICATE_MEMBER_NAME shows inline', (tester) async {
      final server = inviteServer()..joinFaults.add((409, 'DUPLICATE_MEMBER_NAME'));
      await pumpInvitesApp(tester, server, route: Routes.joinCode(_code));
      final l10n = _l10n(const Locale('ar'));
      await _tap(tester, find.text(l10n.inviteNewMember));
      final field = find.byType(TextField);
      expect(tester.widget<TextField>(field).controller!.text, 'Test User', reason: 'prefilled with the display name');

      await tester.enterText(field, 'ن' * 50);
      await tester.pump();
      expect(tester.widget<TextField>(field).controller!.text.runes.length, 40);

      await tester.enterText(field, 'محسن');
      await tester.pump();
      await _tap(tester, find.widgetWithText(AppButton, l10n.inviteJoinButton));
      expect(find.text(l10n.errorDuplicateMemberName('محسن')), findsOneWidget);
      expect(server.joinBodies.single, {'newMemberName': 'محسن'});
    });

    testWidgets('a 202 shows "waiting for admin approval" with a way to refresh and to go home', (tester) async {
      final server = inviteServer(preview: FakePreview(requiresApproval: true))..joinNeedsApproval = true;
      final h = await pumpInvitesApp(tester, server, route: Routes.joinCode(_code));
      final l10n = _l10n(const Locale('ar'));
      await _tap(tester, find.text('كريم'));
      await _tap(tester, find.widgetWithText(AppButton, l10n.inviteJoinButton));
      expect(find.text(l10n.inviteWaitingTitle), findsOneWidget);
      expect(find.text(l10n.inviteWaitingBody('رحلة دهب')), findsOneWidget);

      // still waiting
      server.previews[_code]!.callerState = 'PENDING_APPROVAL';
      await _tap(tester, find.text(l10n.inviteRefreshStatus));
      expect(find.text(l10n.inviteStillWaiting), findsOneWidget);
      expect(find.text(l10n.inviteWaitingTitle), findsOneWidget);

      await _tap(tester, find.text(l10n.inviteBackHome));
      expect(_location(h.container), Routes.home);
    });

    final states = <String, (int, String, String Function(AppLocalizations))>{
      'expired': (410, 'INVITE_EXPIRED', (l) => l.inviteExpiredTitle),
      'revoked': (410, 'INVITE_REVOKED', (l) => l.inviteRevokedTitle),
      'unknown': (404, 'NOT_FOUND', (l) => l.inviteNotFoundTitle),
      'already a member': (409, 'ALREADY_MEMBER', (l) => l.inviteAlreadyMemberTitle),
    };
    for (final entry in states.entries) {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        testWidgets('${entry.key} (${locale.languageCode}, 2.0x): its own state, no form', (tester) async {
          final server = inviteServer()..previewFaults.add((entry.value.$1, entry.value.$2));
          await pumpInvitesApp(tester, server, route: Routes.joinCode(_code), locale: locale, textScale: 2.0);
          final l10n = _l10n(locale);
          expect(find.text(entry.value.$3(l10n)), findsOneWidget);
          expect(find.text(l10n.inviteJoinButton), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('expired: tells the person to ask an admin for a new invite', (tester) async {
      final server = inviteServer()..previewFaults.add((410, 'INVITE_EXPIRED'));
      await pumpInvitesApp(tester, server, route: Routes.joinCode(_code));
      expect(find.text(_l10n(const Locale('ar')).inviteExpiredBody), findsOneWidget);
    });

    testWidgets('rate limited and offline show the shared retry states', (tester) async {
      final server = inviteServer()..previewFaults.add((429, 'RATE_LIMITED'));
      await pumpInvitesApp(tester, server, route: Routes.joinCode(_code));
      final l10n = _l10n(const Locale('ar'));
      expect(find.text(l10n.errorRateLimited), findsOneWidget);
      await _tap(tester, find.text(l10n.commonRetry));
      expect(find.text('محسن'), findsOneWidget, reason: 'the retry reads the preview again');
    });

    testWidgets('MEMBER_ALREADY_CLAIMED: the list is refreshed, the notice shows, the typed name stays', (tester) async {
      final server = inviteServer()..joinFaults.add((409, 'MEMBER_ALREADY_CLAIMED'));
      await pumpInvitesApp(tester, server, route: Routes.joinCode(_code));
      final l10n = _l10n(const Locale('ar'));
      await _tap(tester, find.text('محسن'));
      server.previews[_code]!.unclaimed = [(id: 'u2', name: 'يوسف'), (id: 'u3', name: 'كريم')];
      await _tap(tester, find.widgetWithText(AppButton, l10n.inviteJoinButton));
      expect(find.text(l10n.inviteClaimedNotice), findsOneWidget);
      expect(find.text('محسن'), findsNothing);
      expect(find.text('يوسف'), findsOneWidget);
      expect(_button(tester, l10n.inviteJoinButton).onPressed, isNull, reason: 'nothing is selected any more');
    });
  });

  group('deep link', () {
    testWidgets('warm start: the app is open on the groups list and the link arrives', (tester) async {
      final h = await pumpInvitesApp(tester, inviteServer());
      expect(_location(h.container), Routes.home);
      h.container.read(routerProvider).go('/join/abcd-2345');
      await tester.pumpAndSettle();
      expect(find.text('رحلة دهب'), findsWidgets);
      expect(find.text(_l10n(const Locale('ar')).inviteWhoAreYou), findsOneWidget);
    });

    testWidgets('cold start signed out: the link goes to sign-in, the code waits, and sign-in leads back to the join screen', (tester) async {
      final lines = <String>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');

      final server = inviteServer();
      final h = await pumpInvitesApp(tester, server, auth: const AuthSignedOut());
      h.container.read(routerProvider).go(Routes.joinCode(_code));
      await tester.pumpAndSettle();

      expect(_location(h.container), startsWith(Routes.welcome), reason: 'a signed-out person is sent to sign-in');
      expect(h.container.read(pendingInviteProvider).code, _code, reason: 'kept in memory');
      expect(h.pending.value, _code, reason: 'and in secure storage');
      expect(server.previewCalls, 0, reason: 'nothing is asked of the server before sign-in');

      // sign-in succeeds
      (h.container.read(authControllerProvider.notifier) as StubAuth).set(AuthSignedIn(testUser));
      await tester.pumpAndSettle();
      expect(_location(h.container), Routes.joinCode(_code));
      expect(find.text(_l10n(const Locale('ar')).inviteWhoAreYou), findsOneWidget);

      // joining uses the code up: it is forgotten everywhere
      await _tap(tester, find.text('محسن'));
      await _tap(tester, find.widgetWithText(AppButton, _l10n(const Locale('ar')).inviteJoinButton));
      expect(h.container.read(pendingInviteProvider).code, isNull);
      expect(h.pending.value, isNull);

      debugPrint = original;
      expect(lines.where((l) => l.contains(_code) || l.contains('2345')), isEmpty, reason: 'the code never reaches a log');
      expect(lines.any((l) => l.contains('/invites/***')), isTrue, reason: 'the calls are logged, without the secret');
    });

    testWidgets('a code left in secure storage by a killed process opens the join screen once the person is signed in', (tester) async {
      final h = await pumpInvitesApp(tester, inviteServer(), storedPending: _code);
      await tester.pumpAndSettle();
      expect(_location(h.container), Routes.joinCode(_code));
      // backing out is not trapped by a redirect loop
      h.container.read(routerProvider).go(Routes.home);
      await tester.pumpAndSettle();
      expect(_location(h.container), Routes.home);
    });

    testWidgets('a dead invite clears the pending code', (tester) async {
      final server = inviteServer()..previewFaults.add((410, 'INVITE_EXPIRED'));
      final h = await pumpInvitesApp(tester, server, storedPending: _code);
      await tester.pumpAndSettle();
      expect(h.container.read(pendingInviteProvider).code, isNull);
      expect(h.pending.value, isNull);
    });

    testWidgets('a link whose code cannot be right opens code entry with the error and stores nothing', (tester) async {
      final h = await pumpInvitesApp(tester, inviteServer(), route: '/join/not-a-code');
      final l10n = _l10n(const Locale('ar'));
      expect(find.text(l10n.inviteCodeInvalid), findsOneWidget);
      expect(h.container.read(pendingInviteProvider).code, isNull);
      expect(h.pending.value, isNull);
    });

    testWidgets('signed out with a bad link: nothing is remembered', (tester) async {
      final h = await pumpInvitesApp(tester, inviteServer(), auth: const AuthSignedOut(), route: '/join/nope');
      expect(h.pending.value, isNull);
    });
  });

  group('code entry', () {
    for (final input in ['abcd-٢٣٤٥', ' ABCD 2345 ', 'https://qesma.app/join/ABCD-2345']) {
      testWidgets('type or paste "$input": case, dashes, Arabic-Indic digits and a whole link are accepted', (tester) async {
        final l10n = _l10n(const Locale('ar'));
        final h = await pumpInvitesApp(tester, inviteServer(), route: Routes.join);
        await tester.enterText(find.byType(TextField), input);
        await _tap(tester, find.text(l10n.inviteContinue));
        expect(_location(h.container), Routes.joinCode(_code));
        expect(find.text(l10n.inviteWhoAreYou), findsOneWidget);
      });
    }

    testWidgets('a wrong code shows the hint and goes nowhere', (tester) async {
      final server = inviteServer();
      final h = await pumpInvitesApp(tester, server, route: Routes.join);
      final l10n = _l10n(const Locale('ar'));
      await tester.enterText(find.byType(TextField), 'AB12');
      await _tap(tester, find.text(l10n.inviteContinue));
      expect(find.text(l10n.inviteCodeInvalid), findsOneWidget);
      expect(_location(h.container), Routes.join);
      expect(server.previewCalls, 0);
    });

    testWidgets('the groups list offers it (header icon)', (tester) async {
      await pumpInvitesApp(tester, inviteServer());
      final l10n = _l10n(const Locale('ar'));
      await _tap(tester, find.byTooltip(l10n.inviteEnterCodeButton));
      expect(find.text(l10n.inviteEnterCodeTitle), findsOneWidget);
    });
  });

  group('invite sheet (P12-01)', () {
    FakeInvitesServer server0({String role = 'OWNER'}) {
      final server = inviteServer();
      server.groups['g1']!.yourRole = role;
      server.addInvite('g1', code: _code, requiresApproval: true);
      return server;
    }

    Future<InvitesHarness> open(WidgetTester tester, FakeInvitesServer server, {Locale locale = const Locale('ar'), double scale = 1.0}) async {
      final h = await pumpInvitesApp(tester, server, route: Routes.group('g1'), locale: locale, textScale: scale);
      await _tap(tester, find.byTooltip(_l10n(locale).inviteAction));
      return h;
    }

    for (final (locale, scale) in _configs) {
      testWidgets('${locale.languageCode} ${scale}x: code in a big box, link, expiry from expiresAt, approval, no overflow', (tester) async {
        final l10n = _l10n(locale);
        await open(tester, server0(), locale: locale, scale: scale);
        expect(find.text('ABCD-2345'), findsOneWidget);
        expect(find.text('https://qesma.app/join/$_code'), findsOneWidget);
        expect(find.text(l10n.inviteExpiresIn(l10n.inviteDaysFew('7'))), findsOneWidget);
        expect(find.text(l10n.inviteApprovalTag), findsOneWidget);
        expect(find.text(l10n.inviteShareLink), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('copy puts the exact code on the clipboard and confirms with a snackbar', (tester) async {
      final h = await open(tester, server0());
      final l10n = _l10n(const Locale('ar'));
      await _tap(tester, find.widgetWithText(AppButton, l10n.inviteCopyCode));
      expect(h.copied, [_code], reason: 'the wire code, without the display dash');
      expect(find.text(l10n.inviteCodeCopied), findsOneWidget);
    });

    testWidgets('copy link copies the link', (tester) async {
      final h = await open(tester, server0());
      final l10n = _l10n(const Locale('ar'));
      await _tap(tester, find.byTooltip(l10n.inviteCopyLink));
      expect(h.copied, ['https://qesma.app/join/$_code']);
      expect(find.text(l10n.inviteLinkCopied), findsOneWidget);
    });

    testWidgets('share hands the system share sheet the group name, the link and the code', (tester) async {
      final h = await open(tester, server0());
      final l10n = _l10n(const Locale('ar'));
      await _tap(tester, find.widgetWithText(AppButton, l10n.inviteShareLink));
      expect(h.sharer.shared.single, l10n.inviteShareText('رحلة دهب', 'https://qesma.app/join/$_code', 'ABCD-2345'));
    });

    testWidgets('revoke asks first: "keep" does nothing, confirming revokes and re-reads the list', (tester) async {
      final server = server0();
      await open(tester, server);
      final l10n = _l10n(const Locale('ar'));
      await _tap(tester, find.widgetWithText(AppButton, l10n.inviteRevoke));
      expect(find.text(l10n.inviteRevokeConfirmTitle), findsOneWidget);
      await _tap(tester, find.text(l10n.inviteKeep));
      expect(server.revoked, isEmpty);
      expect(find.text('ABCD-2345'), findsOneWidget);

      await _tap(tester, find.widgetWithText(AppButton, l10n.inviteRevoke));
      await _tap(tester, find.descendant(of: find.byType(AlertDialog), matching: find.text(l10n.inviteRevoke)));
      expect(server.revoked, ['i1']);
      expect(find.text('ABCD-2345'), findsNothing);
      expect(find.text(l10n.inviteNoActive), findsOneWidget);
      expect(find.text(l10n.inviteRevoked), findsOneWidget);
    });

    testWidgets('create sends the chosen expiry and approval with one Idempotency-Key and shows the new invite', (tester) async {
      final server = inviteServer();
      await open(tester, server);
      final l10n = _l10n(const Locale('ar'));
      expect(find.text(l10n.inviteNoActive), findsOneWidget);
      await _tap(tester, find.text(l10n.inviteDaysMany('30')));
      await _tap(tester, find.byType(Switch));
      await _tap(tester, find.widgetWithText(AppButton, l10n.inviteCreate));
      expect(server.createBodies.single, {'expiresInDays': 30, 'requiresApproval': true});
      expect(server.createKeys.single, isNotEmpty);
      expect(find.text(l10n.inviteNoActive), findsNothing);
      expect(find.text(l10n.inviteExpiresIn(l10n.inviteDaysMany('30'))), findsOneWidget);
    });

    for (final (role, offered) in [('OWNER', true), ('ADMIN', true), ('MEMBER', false)]) {
      testWidgets('$role ${offered ? 'is' : 'is not'} offered the sheet (group menu and members tab)', (tester) async {
        final l10n = _l10n(const Locale('ar'));
        await pumpInvitesApp(tester, server0(role: role), route: Routes.group('g1'));
        expect(find.byTooltip(l10n.inviteAction), offered ? findsOneWidget : findsNothing);
        await _tap(tester, find.text(l10n.groupTabMembers));
        expect(find.widgetWithText(AppButton, l10n.inviteAction), offered ? findsOneWidget : findsNothing);
      });
    }

    testWidgets('expiry text follows the server time: hours, then "less than an hour"', (tester) async {
      final l10n = _l10n(const Locale('ar'));
      final now = FakeInvitesServer.serverNow;
      expect(inviteExpiryText(l10n, now.add(const Duration(hours: 5)), now), l10n.inviteExpiresIn(l10n.inviteHoursFew('5')));
      expect(inviteExpiryText(l10n, now.add(const Duration(minutes: 10)), now), l10n.inviteExpiresSoon);
      expect(inviteExpiryText(l10n, now.add(const Duration(days: 1, hours: 3)), now), l10n.inviteExpiresIn(l10n.inviteDayOne));
      expect(inviteExpiryText(l10n, now.add(const Duration(days: 2)), now), l10n.inviteExpiresIn(l10n.inviteDayTwo));
    });
  });
}
