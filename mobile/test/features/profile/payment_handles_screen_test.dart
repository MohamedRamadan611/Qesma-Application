import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/widgets/widgets.dart';

import '../../support/expenses_ui.dart';
import '../../support/fake_balances_server.dart';
import '../../support/settlement_ui.dart';

/// The payment details screen (FL14, B14). Fixtures are made-up values; the server fake normalises like the real one (A90).
void main() {
  late FakeBalancesServer server;
  setUp(() => server = FakeBalancesServer());

  Future<void> open(WidgetTester tester, Locale locale, {double textScale = 1.0}) async {
    await pumpExpensesApp(tester, server, locale: locale, textScale: textScale, height: 1800, route: Routes.paymentHandles);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();
  }

  Finder field(int i) => find.byType(TextField).at(i);
  Future<void> type(WidgetTester tester, int i, String text) async {
    await tester.enterText(field(i), text);
    await tester.pump();
  }

  for (final locale in [ar, en]) {
    final l10n = l10nFor(locale);
    final name = locale.languageCode;

    group('Payment details ($name)', () {
      testWidgets('shows what the server holds and the privacy note', (tester) async {
        server.myHandles = {'instapay': 'demo@bank', 'wallet': '01000000000'};
        await open(tester, locale);
        expect(find.text(l10n.handlesPrivacy), findsOneWidget);
        expect(find.text('demo@bank'), findsOneWidget);
        expect(find.text('01000000000'), findsOneWidget);
        expect(find.text(l10n.handlesEmpty), findsNothing);
        expect(tester.widget<AppButton>(find.widgetWithText(AppButton, l10n.handlesSave)).onPressed, isNull, reason: 'nothing changed');
      });

      testWidgets('empty: the note and the empty hint, nothing to save yet', (tester) async {
        await open(tester, locale);
        expect(find.text(l10n.handlesPrivacy), findsOneWidget);
        expect(find.text(l10n.handlesEmpty), findsOneWidget);
      });

      testWidgets('Arabic digits, spaces and dashes are normalised and the server answer is shown; success snackbar', (tester) async {
        await open(tester, locale);
        await type(tester, 0, '  Demo.User@Bank ');
        await type(tester, 1, '٠١٠ ١٢٣٤-٥٦٧٨');
        await tester.tap(find.widgetWithText(AppButton, l10n.handlesSave));
        await tester.pumpAndSettle();
        expect(server.handlePuts, [
          {'instapay': 'demo.user@bank', 'wallet': '01012345678'},
        ]);
        expect(find.text(l10n.handlesSaved), findsOneWidget);
        expect(find.text('demo.user@bank'), findsOneWidget);
        expect(find.text('01012345678'), findsOneWidget);
        expect(server.myHandles, {'instapay': 'demo.user@bank', 'wallet': '01012345678'});
      });

      testWidgets('replace one value: the other is sent unchanged (PUT is a full replace)', (tester) async {
        server.myHandles = {'instapay': 'demo@bank', 'wallet': '01000000000'};
        await open(tester, locale);
        await type(tester, 1, '+20 11 1234 5678');
        await tester.tap(find.widgetWithText(AppButton, l10n.handlesSave));
        await tester.pumpAndSettle();
        expect(server.handlePuts.single, {'instapay': 'demo@bank', 'wallet': '01112345678'});
      });

      testWidgets('wrong prefix: an inline error and nothing is sent', (tester) async {
        await open(tester, locale);
        await type(tester, 1, '01312345678');
        await tester.tap(find.widgetWithText(AppButton, l10n.handlesSave));
        await tester.pumpAndSettle();
        expect(find.text(l10n.handlesWalletInvalid), findsOneWidget);
        expect(server.handlePuts, isEmpty);
      });

      testWidgets('a bad InstaPay address: an inline error under that field only', (tester) async {
        await open(tester, locale);
        await type(tester, 0, 'no at sign');
        await tester.tap(find.widgetWithText(AppButton, l10n.handlesSave));
        await tester.pumpAndSettle();
        expect(find.text(l10n.handlesInstapayInvalid), findsOneWidget);
        expect(find.text(l10n.handlesWalletInvalid), findsNothing);
        expect(server.handlePuts, isEmpty);
      });

      testWidgets('removing: asks first; confirming sends the field as absent and the server clears it', (tester) async {
        server.myHandles = {'instapay': 'demo@bank', 'wallet': '01000000000'};
        await open(tester, locale);
        await type(tester, 1, '');
        await tester.tap(find.widgetWithText(AppButton, l10n.handlesSave));
        await tester.pumpAndSettle();
        expect(find.text(l10n.handlesRemoveTitle(l10n.payWalletLabel)), findsOneWidget);
        expect(server.handlePuts, isEmpty);
        await tester.tap(find.text(l10n.handlesRemoveConfirm));
        await tester.pumpAndSettle();
        expect(server.handlePuts.single, {'instapay': 'demo@bank'});
        expect(server.myHandles, {'instapay': 'demo@bank', 'wallet': null});
      });

      testWidgets('removing: cancelling the question sends nothing', (tester) async {
        server.myHandles = {'instapay': 'demo@bank', 'wallet': '01000000000'};
        await open(tester, locale);
        await type(tester, 0, '');
        await tester.tap(find.widgetWithText(AppButton, l10n.handlesSave));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.commonCancel));
        await tester.pumpAndSettle();
        expect(server.handlePuts, isEmpty);
        expect(server.myHandles['instapay'], 'demo@bank');
      });

      testWidgets('the server says 422 although the checks passed: a clear banner, the form is kept', (tester) async {
        await open(tester, locale);
        server.rejectNextHandlesPut = true;
        await type(tester, 1, '01012345678');
        await tester.tap(find.widgetWithText(AppButton, l10n.handlesSave));
        await tester.pumpAndSettle();
        expect(find.text(l10n.handlesRejected), findsOneWidget);
        expect(find.text('01012345678'), findsOneWidget);
      });

      testWidgets('a server error on save: a banner; saving again works', (tester) async {
        await open(tester, locale);
        server.failNextHandlesPut = true;
        await type(tester, 1, '01012345678');
        await tester.tap(find.widgetWithText(AppButton, l10n.handlesSave));
        await tester.pumpAndSettle();
        expect(find.text(l10n.handlesSaveFailed), findsOneWidget);
        await tester.tap(find.widgetWithText(AppButton, l10n.handlesSave));
        await tester.pumpAndSettle();
        expect(find.text(l10n.handlesSaved), findsOneWidget);
        expect(server.myHandles['wallet'], '01012345678');
      });

      testWidgets('loading fails: an error with retry, then the values', (tester) async {
        server.myHandles = {'instapay': 'demo@bank', 'wallet': null};
        server.failNextHandlesGet = true;
        await open(tester, locale);
        expect(find.text('demo@bank'), findsNothing);
        await tester.tap(find.text(l10n.commonRetry));
        await tester.pumpAndSettle();
        expect(find.text('demo@bank'), findsOneWidget);
      });

      testWidgets('offline: the offline state with retry', (tester) async {
        server.offline = true;
        await open(tester, locale);
        expect(find.text(l10n.stateNoInternetTitle), findsOneWidget);
        server.offline = false;
        await tester.tap(find.text(l10n.commonRetry));
        await tester.pumpAndSettle();
        expect(find.text(l10n.handlesPrivacy), findsOneWidget);
      });

      testWidgets('text scale 2.0: no overflow', (tester) async {
        server.myHandles = {'instapay': 'demo@bank', 'wallet': '01000000000'};
        await open(tester, locale, textScale: 2.0);
        await type(tester, 1, '01312345678');
        await tester.tap(find.widgetWithText(AppButton, l10n.handlesSave));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('the handles never reach a log line (whole save, replace and remove flow)', (tester) async {
    final lines = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');

    server.myHandles = {'instapay': 'old.one@bank', 'wallet': '01100000000'};
    await pumpExpensesApp(tester, server, height: 1800, route: Routes.paymentHandles);
    await tester.pumpAndSettle();
    final l10n = l10nFor(ar);
    await tester.enterText(find.byType(TextField).at(0), 'secret.name@bank');
    await tester.enterText(find.byType(TextField).at(1), '٠١٢٣٤٥٦٧٨٩٠');
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, l10n.handlesSave));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), '');
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, l10n.handlesSave));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.handlesRemoveConfirm));
    await tester.pumpAndSettle();

    debugPrint = original;
    expect(server.handlePuts, hasLength(2));
    final joined = lines.join('\n');
    for (final secret in ['secret.name', 'old.one', '01100000000', '01234567890', '@bank']) {
      expect(joined, isNot(contains(secret)), reason: 'a handle appeared in a log line');
    }
    expect(lines.any((l) => l.contains('/me/payment-handles')), isTrue, reason: 'the calls are logged (method, path, status), never the body');
  });

  testWidgets('the Account tab has the row and it opens the screen', (tester) async {
    await pumpExpensesApp(tester, server, height: 2000, route: Routes.account);
    await tester.pumpAndSettle();
    final l10n = l10nFor(ar);
    await tester.tap(find.text(l10n.profilePaymentDetails));
    await tester.pumpAndSettle();
    expect(find.text(l10n.handlesPrivacy), findsOneWidget);
  });
}
