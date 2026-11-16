import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/format/date_format.dart';
import 'package:qesma/core/widgets/widgets.dart';

import '../../support/expenses_ui.dart';
import '../../support/fake_balances_server.dart';
import '../../support/settlement_ui.dart';

/// Remind on the transfer card (FL14, B16). V1 balances: Mohamed (the signed-in owner) is owed 80.00 by Asem and 20.00 by
/// the third member. Every fact shown here is the server's (`canRemindAt`, `nextAllowedAt`).
void main() {
  late FakeBalancesServer server;
  setUp(() => server = FakeBalancesServer());

  const asem = '025f85ad-3a0a-4aea-bcba-2a9a120fe678';
  const mohamed = '650a2534-75c8-426e-a607-0924ab985bdc';
  const third = 'f1184040-b439-4f1a-bb7b-46ee1d5cb610';

  void setCanRemindAt(String memberId, String iso) {
    final t = (server.balances['transfers'] as List).cast<Map<String, dynamic>>().firstWhere((t) => t['fromMemberId'] == memberId);
    t['canRemindAt'] = iso;
  }

  for (final locale in [ar, en]) {
    final l10n = l10nFor(locale);
    final name = locale.languageCode;

    group('Remind ($name)', () {
      testWidgets('the creditor sees one enabled button per transfer', (tester) async {
        server.linkAll();
        await openGroupTab(tester, server, locale: locale);
        expect(find.text(l10n.remindButton), findsNWidgets(2));
        expect(find.text(l10n.remindSentToday), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a debtor without an account: no button, a caption says why', (tester) async {
        // Not linked: Asem and the third member are name-only members.
        await openGroupTab(tester, server, locale: locale);
        expect(find.text(l10n.remindButton), findsNothing);
        expect(find.text(l10n.remindNoAccount(fsIsolate('Asem'))), findsOneWidget);
      });

      testWidgets('one tap, one request with the pair and a key; the button turns into "sent today" with the server time', (tester) async {
        server.linkAll();
        await openGroupTab(tester, server, locale: locale);
        final balancesBefore = server.count('GET', '/balances');
        await tester.tap(find.text(l10n.remindButton).first);
        await tester.pumpAndSettle();
        expect(server.remindRequests, hasLength(1));
        expect(server.remindRequests.single.body, {'fromMemberId': asem, 'toMemberId': mohamed});
        expect(server.remindRequests.single.key, isNotEmpty);
        expect(find.text(l10n.remindSent), findsOneWidget);
        expect(find.text(l10n.remindSentToday), findsOneWidget);
        expect(find.text(l10n.remindButton), findsOneWidget, reason: 'the other transfer is untouched');
        expect(find.text(l10n.remindNextAt(ltrIsolate(isoDateTime(FakeBalancesServer.remindWindowEnd)))), findsOneWidget);
        expect(server.count('GET', '/balances'), greaterThan(balancesBefore), reason: 'balances are read again');
      });

      testWidgets('the disabled button cannot be tapped again', (tester) async {
        server.linkAll();
        await openGroupTab(tester, server, locale: locale);
        await tester.tap(find.text(l10n.remindButton).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.remindSentToday), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(server.remindRequests, hasLength(1));
      });

      testWidgets('a future canRemindAt from the server: disabled on load, with that time', (tester) async {
        server.linkAll();
        setCanRemindAt(asem, '2099-03-04T05:06:00Z');
        await openGroupTab(tester, server, locale: locale);
        expect(find.text(l10n.remindSentToday), findsOneWidget);
        expect(find.text(l10n.remindNextAt(ltrIsolate(isoDateTime(DateTime.utc(2099, 3, 4, 5, 6))))), findsOneWidget);
        expect(find.text(l10n.remindButton), findsOneWidget);
      });

      testWidgets('a canRemindAt in the past: enabled (compared with the clock, not a rule of ours)', (tester) async {
        server.linkAll();
        setCanRemindAt(asem, '2020-01-01T00:00:00Z');
        await openGroupTab(tester, server, locale: locale);
        expect(find.text(l10n.remindButton), findsNWidgets(2));
      });

      testWidgets("429: the same disabled state with the server's nextAllowedAt", (tester) async {
        server.linkAll();
        server.forceNextRemind = (status: 429, code: 'REMIND_RATE_LIMITED', nextAllowedAt: '2099-05-06T07:08:00Z');
        await openGroupTab(tester, server, locale: locale);
        await tester.tap(find.text(l10n.remindButton).first);
        await tester.pumpAndSettle();
        expect(find.text(l10n.remindSentToday), findsWidgets);
        expect(find.text(l10n.remindNextAt(ltrIsolate(isoDateTime(DateTime.utc(2099, 5, 6, 7, 8))))), findsOneWidget);
        expect(server.remindRequests, hasLength(1));
      });

      testWidgets('422 (the transfer is gone): says so and reads the balances again', (tester) async {
        server.linkAll();
        await openGroupTab(tester, server, locale: locale);
        server.forceNextRemind = (status: 422, code: 'VALIDATION_ERROR', nextAllowedAt: null);
        server.balances = {'nets': <Object>[], 'transfers': <Object>[]};
        await tester.tap(find.text(l10n.remindButton).first);
        await tester.pumpAndSettle();
        expect(find.text(l10n.remindGone), findsOneWidget);
        expect(find.text(l10n.remindButton), findsNothing);
      });

      testWidgets('offline: a retry message; "try again" sends the SAME key and only one reminder is stored', (tester) async {
        server.linkAll();
        await openGroupTab(tester, server, locale: locale);
        server.balancesOffline = true;
        await tester.tap(find.text(l10n.remindButton).first);
        await tester.pumpAndSettle();
        expect(find.text(l10n.remindRetry), findsOneWidget);
        expect(find.text(l10n.remindButton), findsNWidgets(2), reason: 'nothing was sent, nothing is disabled');

        server.balancesOffline = false;
        await tester.tap(find.text(l10n.commonRetry));
        await tester.pumpAndSettle();
        expect(server.remindAttemptKeys, hasLength(2));
        expect(server.remindAttemptKeys[0], server.remindAttemptKeys[1], reason: 'the retry of the same tap reuses the key');
        expect(find.text(l10n.remindSentToday), findsOneWidget);
      });

      testWidgets('a lost response is retried with the same key and the server replays instead of reminding twice', (tester) async {
        server.linkAll();
        server.loseNextRemindResponse = true;
        await openGroupTab(tester, server, locale: locale);
        await tester.tap(find.text(l10n.remindButton).first);
        await tester.pumpAndSettle();
        expect(find.text(l10n.remindRetry), findsOneWidget);
        await tester.tap(find.text(l10n.commonRetry));
        await tester.pumpAndSettle();
        expect(server.remindRequests.map((r) => r.key).toSet(), hasLength(1));
        expect(find.text(l10n.remindSentToday), findsOneWidget);
      });

      testWidgets('another debtor is another tap: a new key', (tester) async {
        server.linkAll();
        await openGroupTab(tester, server, locale: locale);
        await tester.tap(find.text(l10n.remindButton).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.remindButton));
        await tester.pumpAndSettle();
        expect(server.remindRequests, hasLength(2));
        expect(server.remindRequests[0].key, isNot(server.remindRequests[1].key));
        expect(server.remindRequests[1].body['fromMemberId'], third);
      });

      testWidgets('an admin who is not the creditor can remind; on their own debt there is no button', (tester) async {
        server.actAs('Asem', role: 'ADMIN');
        server.linkAll();
        await openGroupTab(tester, server, locale: locale);
        // Asem owes Mohamed (own debt: hidden); the third member owes Mohamed (somebody else's: allowed for an admin).
        expect(find.text(l10n.remindButton), findsOneWidget);
      });

      testWidgets('a plain member who is neither creditor nor admin: nothing, not even a caption', (tester) async {
        server.actAs('Asem');
        server.linkAll();
        await openGroupTab(tester, server, locale: locale);
        expect(find.text(l10n.remindButton), findsNothing);
        expect(find.text(l10n.remindSentToday), findsNothing);
      });

      testWidgets('text scale 2.0: no overflow in the enabled and the disabled state', (tester) async {
        server.linkAll();
        setCanRemindAt(third, '2099-03-04T05:06:00Z');
        await openGroupTab(tester, server, locale: locale, textScale: 2.0, height: 4000);
        expect(find.text(l10n.remindButton), findsOneWidget);
        expect(find.text(l10n.remindSentToday), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
