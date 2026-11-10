import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/widgets/widgets.dart';
import 'package:qesma/features/balances/presentation/balances_tab.dart';
import 'package:qesma/features/balances/presentation/transfer_card.dart';
import 'package:qesma/features/expenses/presentation/expense_ui.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../support/expenses_ui.dart';
import '../../support/fake_balances_server.dart';

const _ar = Locale('ar');
const _en = Locale('en');

Future<void> openBalances(WidgetTester tester, FakeBalancesServer server, {Locale locale = _ar, double textScale = 1.0, double height = 2400}) async {
  await pumpExpensesApp(tester, server, locale: locale, textScale: textScale, height: height, route: '${Routes.group(server.gid)}?tab=balances');
  await tester.pump(const Duration(milliseconds: 10));
  await tester.pumpAndSettle();
}

Finder inSheet(Finder f) => find.descendant(of: find.byType(AppBottomSheet), matching: f);

void main() {
  late FakeBalancesServer server;

  setUp(() => server = FakeBalancesServer());

  for (final locale in [_ar, _en]) {
    final l10n = l10nFor(locale);
    final name = locale.languageCode;

    group('Balances tab ($name)', () {
      testWidgets('V1: the real server numbers, two transfers, and the nets with word + sign', (tester) async {
        await openBalances(tester, server, locale: locale);
        expect(find.byType(BalancesTab), findsOneWidget);
        expect(find.text(money(locale, 13000)), findsWidgets, reason: 'total spent from the group');
        expect(find.text(l10n.balancesNeedTwo), findsOneWidget);
        expect(find.text(l10n.balancesSuggestedTitle), findsOneWidget);
        expect(find.text(money(locale, 8000)), findsOneWidget, reason: 'the 80.00 transfer');
        expect(find.text(money(locale, 2000)), findsOneWidget, reason: 'the 20.00 transfer');
        // Nets 100.00 / -80.00 / -20.00 with the word, the sign and the amount together.
        expect(find.text('${l10n.balanceOwed} ${money(locale, 10000, signed: true)}'), findsOneWidget);
        expect(find.text('${l10n.balanceOwes} ${money(locale, -8000, signed: true)}'), findsOneWidget);
        expect(find.text('${l10n.balanceOwes} ${money(locale, -2000, signed: true)}'), findsOneWidget);
        expect(find.text('Mohamed ${l10n.membersYouTag}'), findsOneWidget, reason: 'the "(you)" badge');
        expect(find.text(l10n.balancesHistoryEmpty), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('V2 after the payment: 20.00 / 0 / -20.00, ONE transfer, and the payment in the history', (tester) async {
        server.seedV2();
        await openBalances(tester, server, locale: locale);
        expect(find.text(l10n.balancesNeedOne), findsOneWidget);
        expect(find.text('${l10n.balanceOwed} ${money(locale, 2000, signed: true)}'), findsOneWidget);
        expect(find.text('${l10n.balanceSettled} ${money(locale, 0, signed: true)}'), findsOneWidget);
        expect(find.text('${l10n.balanceOwes} ${money(locale, -2000, signed: true)}'), findsOneWidget);
        expect(find.text(money(locale, 8000)), findsOneWidget, reason: 'the recorded payment');
        expect(find.textContaining('cash on the road'), findsOneWidget);
        expect(find.byTooltip(l10n.balancesDeletePayment), findsOneWidget);
      });

      testWidgets('nothing to settle: the all-settled state, no suggested transfers, the nets are all settled', (tester) async {
        server.balances = balancesMap('balances_v3_settled');
        await openBalances(tester, server, locale: locale);
        expect(find.text(l10n.balancesAllSettledBody), findsOneWidget);
        expect(find.text(l10n.balancesSuggestedTitle), findsNothing);
        expect(find.text('${l10n.balanceSettled} ${money(locale, 0, signed: true)}'), findsNWidgets(3));
        expect(find.text(l10n.balancesRecordAnother), findsOneWidget, reason: 'a payment can still be recorded');
      });

      testWidgets('the screen only shows what the server said: inconsistent numbers are shown unchanged (no recomputing)', (tester) async {
        final odd = balancesMap('balances_v1');
        (odd['nets'] as List)[0]['netMinor'] = 777; // does not add up with the others, on purpose
        (odd['transfers'] as List).add({'fromMemberId': server.you, 'toMemberId': server.member('Asem'), 'amountMinor': 12345});
        server.balances = odd;
        await openBalances(tester, server, locale: locale);
        expect(find.text(countPhraseFor(l10n, 3)), findsOneWidget, reason: 'the count is the number of transfers sent: 3');
        expect(find.text('${l10n.balanceOwed} ${money(locale, 777, signed: true)}'), findsOneWidget);
        expect(find.text(money(locale, 12345)), findsOneWidget);
      });

      testWidgets('N transfers needed is the count of transfers: 7 gets the plural form', (tester) async {
        final many = balancesMap('balances_v1');
        final transfers = <Map<String, dynamic>>[
          for (var i = 0; i < 7; i++) {'fromMemberId': server.member('Asem'), 'toMemberId': server.you, 'amountMinor': 100 + i},
        ];
        many['transfers'] = transfers;
        server.balances = many;
        await openBalances(tester, server, locale: locale, height: 5000);
        expect(find.text(countPhraseFor(l10n, 7)), findsOneWidget);
        expect(find.byType(TransferCard), findsNWidgets(7));
      });

      testWidgets('semantics: each net row and transfer says the word and the amount in words; the button has a tap action', (tester) async {
        final handle = tester.ensureSemantics();
        await openBalances(tester, server, locale: locale);
        final owes80 = l10n.balancesMemberSpoken('Asem', l10n.balanceOwesSpoken(moneySpoken(l10n, 8000)));
        expect(find.bySemanticsLabel(owes80), findsOneWidget);
        final owed100 = l10n.balancesMemberSpoken('Mohamed ${l10n.membersYouTag}', l10n.balanceOwedSpoken(moneySpoken(l10n, 10000)));
        expect(find.bySemanticsLabel(owed100), findsOneWidget);
        final button = l10n.balancesRecordPaymentSpoken('Asem', 'Mohamed', moneySpoken(l10n, 8000));
        final node = tester.getSemantics(find.bySemanticsLabel(button));
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        expect(find.bySemanticsLabel(l10n.balancesTransferSpoken('Asem', moneySpoken(l10n, 8000), 'Mohamed')), findsOneWidget);
        handle.dispose();
      });

      testWidgets('no overflow at text scale 2.0, with the history', (tester) async {
        server.seedV2();
        await openBalances(tester, server, locale: locale, textScale: 2.0, height: 6000);
        expect(tester.takeException(), isNull);
        expect(find.text(l10n.balancesNeedOne), findsOneWidget);
      });

      testWidgets('leaving the tab and coming back asks the server again (balances are never cached)', (tester) async {
        await openBalances(tester, server, locale: locale);
        expect(server.count('GET', '/balances'), 1);
        await tapText(tester, l10n.groupTabExpenses);
        await tapText(tester, l10n.groupTabBalances);
        expect(server.count('GET', '/balances'), 2);
      });

      testWidgets('a failed first read shows the error state with retry; the retry works', (tester) async {
        server.failNextBalances = true;
        await openBalances(tester, server, locale: locale);
        expect(find.text(l10n.commonRetry), findsOneWidget);
        await tapText(tester, l10n.commonRetry);
        expect(find.text(l10n.balancesNeedTwo), findsOneWidget);
      });

      testWidgets('omitted from the design: no method chips, half amount, immediate-effect panel, undo, captions, algorithm chip', (tester) async {
        server.seedV2();
        await openBalances(tester, server, locale: locale);
        await tapText(tester, l10n.balancesRecordAnother);
        await tester.pumpAndSettle();
        final all = find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? '').join('\n');
        for (final banned in ['نقدًا', 'نقدا', 'فودافون', 'إنستاباي', 'Vodafone', 'Instapay', 'النصف', 'Half', 'half', 'تأثير', 'Immediate', 'immediate', 'تراجع', 'Undo', 'undo', 'خوارزمية', 'algorithm', 'Algorithm']) {
          expect(all.contains(banned), isFalse, reason: 'found "$banned"');
        }
        expect(find.byType(SnackBar), findsNothing);
      });
    });

    group('Record payment ($name)', () {
      testWidgets('from a transfer: prefilled with its members and amount; confirming sends the right body and refreshes', (tester) async {
        server.balancesAfterCreate = balancesMap('balances_v2');
        await openBalances(tester, server, locale: locale);
        await tester.tap(find.text(l10n.balancesRecordPayment).first);
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomSheet), findsOneWidget);
        expect(inSheet(find.text('Asem')), findsOneWidget);
        expect(inSheet(find.text('Mohamed')), findsOneWidget);
        expect(tester.widget<TextField>(inSheet(find.byType(TextField)).first).controller!.text, '80');
        expect(find.text(l10n.paymentConfirm(money(locale, 8000))), findsOneWidget);
        expect(find.text(dateText(Date(2026, 10, 18))), findsWidgets, reason: 'the date defaults to today');

        await tester.tap(find.text(l10n.paymentConfirm(money(locale, 8000))));
        await tester.pumpAndSettle();
        expect(server.settlementCreates, hasLength(1));
        expect(server.settlementCreates.single.body, {
          'fromMemberId': server.member('Asem'),
          'toMemberId': server.you,
          'amountMinor': 8000,
          'settledOn': '2026-10-18',
        });
        expect(find.byType(AppBottomSheet), findsNothing, reason: 'the sheet closed');
        expect(find.text(l10n.paymentRecorded), findsOneWidget);
        // Balances and history were read again and now show the server's V2 numbers.
        expect(server.count('GET', '/balances'), greaterThanOrEqualTo(2));
        expect(find.text(l10n.balancesNeedOne), findsOneWidget);
        expect(find.text('${l10n.balanceOwed} ${money(locale, 2000, signed: true)}'), findsOneWidget);
        expect(find.textContaining('Asem'), findsWidgets);
      });

      testWidgets('amount and note are validated before anything is sent', (tester) async {
        await openBalances(tester, server, locale: locale);
        await tapText(tester, l10n.balancesRecordAnother);
        final confirm = find.text(l10n.paymentConfirmNoAmount);
        expect(confirm, findsOneWidget);
        expect(tester.widget<AppButton>(find.widgetWithText(AppButton, l10n.paymentConfirmNoAmount)).onPressed, isNull, reason: 'no amount yet');

        final amount = inSheet(find.byType(TextField)).first;
        await tester.enterText(amount, '0');
        await tester.pumpAndSettle();
        expect(find.text(l10n.paymentAmountError), findsOneWidget);
        expect(tester.widget<AppButton>(find.widgetWithText(AppButton, l10n.paymentConfirmNoAmount)).onPressed, isNull);

        await tester.enterText(amount, '12.5');
        await tester.pumpAndSettle();
        expect(find.text(l10n.paymentAmountError), findsNothing);
        expect(find.text(l10n.paymentConfirm(money(locale, 1250))), findsOneWidget);
        expect(server.settlementCreates, isEmpty);
      });

      testWidgets('the note is limited to 200 characters', (tester) async {
        await openBalances(tester, server, locale: locale);
        await tapText(tester, l10n.balancesRecordAnother);
        final note = inSheet(find.byType(TextField)).last;
        await tester.enterText(note, 'x' * 250);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(note).controller!.text.runes.length, 200);
      });

      testWidgets('an offline send keeps the sheet and the amount, shows the failure, and a retry with the same body reuses the key', (tester) async {
        server.balancesOffline = true;
        // The tab itself is read first, then the network drops for the payment.
        server.balancesOffline = false;
        await openBalances(tester, server, locale: locale);
        await tester.tap(find.text(l10n.balancesRecordPayment).first);
        await tester.pumpAndSettle();
        server.balancesOffline = true;
        await tester.tap(find.text(l10n.paymentConfirm(money(locale, 8000))));
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomSheet), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(tester.widget<TextField>(inSheet(find.byType(TextField)).first).controller!.text, '80');
        server.balancesOffline = false;
        await tester.tap(find.text(l10n.paymentConfirm(money(locale, 8000))));
        await tester.pumpAndSettle();
        expect(server.settlementAttemptKeys, hasLength(2));
        expect(server.settlementAttemptKeys[1], server.settlementAttemptKeys[0]);
        expect(find.byType(AppBottomSheet), findsNothing);
      });

      testWidgets('a server refusal (VALIDATION_ERROR) is shown in the sheet and keeps what was typed', (tester) async {
        await openBalances(tester, server, locale: locale);
        await tester.tap(find.text(l10n.balancesRecordPayment).first);
        await tester.pumpAndSettle();
        server.forceNextSettlementCode = 'VALIDATION_ERROR';
        await tester.tap(find.text(l10n.paymentConfirm(money(locale, 8000))));
        await tester.pumpAndSettle();
        expect(find.text(l10n.errorValidation), findsOneWidget);
        expect(find.byType(AppBottomSheet), findsOneWidget);
      });

      testWidgets('the "full amount" chip puts the transfer\'s own amount back', (tester) async {
        await openBalances(tester, server, locale: locale);
        await tester.tap(find.text(l10n.balancesRecordPayment).first);
        await tester.pumpAndSettle();
        await tester.enterText(inSheet(find.byType(TextField)).first, '5');
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.paymentFullAmount(money(locale, 8000))));
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(inSheet(find.byType(TextField)).first).controller!.text, '80');
      });

      testWidgets('the from picker never offers the member already chosen as the receiver', (tester) async {
        await openBalances(tester, server, locale: locale);
        await tester.tap(find.text(l10n.balancesRecordPayment).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.paymentFrom));
        await tester.pumpAndSettle();
        expect(find.text(l10n.paymentPickMember), findsOneWidget);
        final picker = find.byType(AppBottomSheet).last;
        expect(find.descendant(of: picker, matching: find.text('Mohsen')), findsOneWidget);
        expect(find.descendant(of: picker, matching: find.text('Asem')), findsOneWidget);
        expect(find.descendant(of: picker, matching: find.text('Mohamed ${l10n.membersYouTag}')), findsNothing, reason: 'the receiver');
      });

      testWidgets('closing after a change asks first; closing untouched does not', (tester) async {
        await openBalances(tester, server, locale: locale);
        await tester.tap(find.text(l10n.balancesRecordPayment).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(l10n.commonClose));
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomSheet), findsNothing, reason: 'nothing changed');

        await tester.tap(find.text(l10n.balancesRecordPayment).first);
        await tester.pumpAndSettle();
        await tester.enterText(inSheet(find.byType(TextField)).first, '5');
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(l10n.commonClose));
        await tester.pumpAndSettle();
        expect(find.text(l10n.paymentDiscardTitle), findsOneWidget);
        await tester.tap(find.text(l10n.paymentDiscardConfirm));
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomSheet), findsNothing);
        expect(server.settlementCreates, isEmpty);
      });

      testWidgets('no overflow at text scale 2.0 and the confirm button stays reachable', (tester) async {
        await openBalances(tester, server, locale: locale, textScale: 2.0, height: 1400);
        await reveal(tester, find.text(l10n.balancesRecordPayment).first);
        await tester.tap(find.text(l10n.balancesRecordPayment).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(l10n.paymentConfirm(money(locale, 8000))), findsOneWidget);
      });
    });

    group('Payment history ($name)', () {
      testWidgets('deleting asks first, says it is final, then refreshes both lists', (tester) async {
        server.seedV2();
        server.balancesAfterDelete = balancesMap('balances_v1');
        await openBalances(tester, server, locale: locale, height: 3000);
        await tester.tap(find.byTooltip(l10n.balancesDeletePayment));
        await tester.pumpAndSettle();
        expect(find.text(l10n.balancesDeleteTitle), findsOneWidget);
        expect(find.text(l10n.balancesDeleteBody), findsOneWidget);
        await tester.tap(find.text(l10n.commonDelete));
        await tester.pumpAndSettle();
        expect(server.settlements, isEmpty);
        expect(find.text(l10n.balancesDeleted), findsOneWidget);
        expect(find.text(l10n.balancesHistoryEmpty), findsOneWidget);
        expect(find.text(l10n.balancesNeedTwo), findsOneWidget, reason: 'the balances are the server\'s V1 again');
        expect(find.byType(SnackBarAction), findsNothing, reason: 'no undo: the backend cannot restore a payment');
      });

      testWidgets('cancelling the question deletes nothing', (tester) async {
        server.seedV2();
        await openBalances(tester, server, locale: locale, height: 3000);
        await tester.tap(find.byTooltip(l10n.balancesDeletePayment));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.commonCancel));
        await tester.pumpAndSettle();
        expect(server.settlements, hasLength(1));
        expect(server.requests.where((r) => r.startsWith('DELETE')), isEmpty);
      });

      testWidgets('a payment somebody else already removed: the 404 is absorbed and the lists show what is true now', (tester) async {
        server.seedV2();
        await openBalances(tester, server, locale: locale, height: 3000);
        server.settlements.clear();
        server.balances = balancesMap('balances_v1');
        await tester.tap(find.byTooltip(l10n.balancesDeletePayment));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.commonDelete));
        await tester.pumpAndSettle();
        expect(find.text(l10n.balancesDeleteGone), findsOneWidget);
        expect(find.text(l10n.balancesHistoryEmpty), findsOneWidget);
        expect(find.text(l10n.balancesNeedTwo), findsOneWidget);
      });

      testWidgets('a long history loads the next page on request', (tester) async {
        for (var i = 0; i < 25; i++) {
          server.settlements.add({
            'id': 'p$i',
            'groupId': server.gid,
            'fromMemberId': server.you,
            'toMemberId': server.member('Asem'),
            'amountMinor': 100 + i,
            'settledOn': '2026-09-${(1 + i % 28).toString().padLeft(2, '0')}',
            'createdAt': '2026-11-10T10:00:00Z',
          });
        }
        await openBalances(tester, server, locale: locale, height: 9000);
        expect(find.text(l10n.balancesLoadMore), findsOneWidget);
        expect(find.byTooltip(l10n.balancesDeletePayment), findsNWidgets(20));
        await tapText(tester, l10n.balancesLoadMore);
        expect(find.byTooltip(l10n.balancesDeletePayment), findsNWidgets(25));
        expect(find.text(l10n.balancesLoadMore), findsNothing);
      });
    });
  }
}

/// The number of transfers as the status line writes it (the same wording choice the screen makes).
String countPhraseFor(AppLocalizations l10n, int count) {
  if (count == 1) return l10n.balancesNeedOne;
  if (count == 2) return l10n.balancesNeedTwo;
  return count <= 10 ? l10n.balancesNeed('$count') : l10n.balancesNeedMany('$count');
}
