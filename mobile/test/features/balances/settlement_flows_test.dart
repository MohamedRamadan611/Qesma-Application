import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/widgets/widgets.dart';
import 'package:qesma/features/balances/application/settlement_rules.dart';
import 'package:qesma/features/balances/presentation/settlement_status_chip.dart';

import '../../support/expenses_ui.dart';
import '../../support/fake_balances_server.dart';
import '../../support/settlement_ui.dart';

Finder inSheet(Finder f) => find.descendant(of: find.byType(AppBottomSheet), matching: f);

void main() {
  late FakeBalancesServer server;

  setUp(() => server = FakeBalancesServer());

  for (final locale in [ar, en]) {
    final l10n = l10nFor(locale);
    final name = locale.languageCode;

    group('Payer transfer card, P13-01 ($name)', () {
      // Asem is signed in and owes Mohamed 80.00; Mohamed has added both handles.
      void asPayer({String? instapay = 'mohamed@instapay', String? wallet = '01012345678'}) {
        server.actAs('Asem');
        server.linkAll();
        server.balances = withHandles(balancesMap('balances_v1'), instapay: instapay, wallet: wallet);
      }

      testWidgets('shows the receiver, the server amount, the handles, the fixed note and the two buttons', (tester) async {
        asPayer();
        await openGroupTab(tester, server, locale: locale);
        expect(find.text(l10n.payHandlesTitle(fsIsolate('Mohamed'))), findsOneWidget);
        expect(find.text(l10n.payInstapayLabel), findsOneWidget);
        expect(find.text(l10n.payWalletLabel), findsOneWidget);
        expect(find.textContaining('mohamed@instapay'), findsOneWidget);
        expect(find.textContaining('01012345678'), findsOneWidget);
        expect(find.text(l10n.payNoMoveNote), findsOneWidget);
        expect(find.text(money(locale, 8000)), findsOneWidget);
        expect(find.text(l10n.payButton), findsOneWidget);
        expect(find.text(l10n.payCopyAll), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the fixed note is exactly the one of the brief (Arabic)', (tester) async {
        expect(l10nFor(ar).payNoMoveNote, 'التطبيق مبيحوّلش فلوس — حوّل من تطبيق البنك أو المحفظة وبعدين اضغط دفعت');
      });

      testWidgets('the copy buttons put exactly the handle on the clipboard; "copy details" puts both, one per line', (tester) async {
        final copied = spyClipboard(tester);
        asPayer();
        await openGroupTab(tester, server, locale: locale);
        await tester.tap(find.text(l10n.payCopyOne).first);
        await tester.pump();
        await tester.tap(find.text(l10n.payCopyOne).last);
        await tester.pump();
        await tester.tap(find.text(l10n.payCopyAll));
        await tester.pump();
        expect(copied, ['mohamed@instapay', '01012345678', 'mohamed@instapay\n01012345678']);
        expect(find.text(l10n.payCopied), findsOneWidget);
      });

      testWidgets('only one handle: one row, and "copy details" copies just that', (tester) async {
        final copied = spyClipboard(tester);
        asPayer(instapay: null);
        await openGroupTab(tester, server, locale: locale);
        expect(find.text(l10n.payInstapayLabel), findsNothing);
        expect(find.text(l10n.payWalletLabel), findsOneWidget);
        await tester.tap(find.text(l10n.payCopyAll));
        await tester.pump();
        expect(copied, ['01012345678']);
      });

      testWidgets('no handles: explains it, no copy buttons, and "I paid" is still there', (tester) async {
        asPayer(instapay: null, wallet: null);
        await openGroupTab(tester, server, locale: locale);
        expect(find.text(l10n.payNoHandles(fsIsolate('Mohamed'))), findsOneWidget);
        expect(find.text(l10n.payCopyOne), findsNothing);
        expect(find.text(l10n.payCopyAll), findsNothing);
        expect(find.text(l10n.payButton), findsOneWidget);
        expect(find.text(l10n.payNoMoveNote), findsOneWidget, reason: 'the app says it moves no money, with or without handles');
      });

      testWidgets('I paid: the sheet is prefilled, the payer is me and cannot be changed, and the server\'s PENDING is what is said afterwards', (tester) async {
        asPayer();
        server.balancesAfterCreate = balancesMap('balances_v4_pending');
        await openGroupTab(tester, server, locale: locale);
        await tester.tap(find.text(l10n.payButton));
        await tester.pumpAndSettle();
        expect(inSheet(find.text(l10n.paymentTitleDeclare)), findsOneWidget);
        expect(tester.widget<TextField>(inSheet(find.byType(TextField)).first).controller!.text, '80');
        expect(find.text(l10n.paymentHintPending(fsIsolate('Mohamed'))), findsOneWidget, reason: 'it goes to the receiver to confirm');
        // The payer field does not open a picker (a member declares their own payment).
        await tester.tap(inSheet(find.text('Asem')).first);
        await tester.pumpAndSettle();
        expect(find.text(l10n.paymentPickMember), findsNothing);

        await tester.tap(find.text(l10n.paymentConfirm(money(locale, 8000))));
        await tester.pumpAndSettle();
        expect(server.settlementCreates.single.body, {
          'fromMemberId': server.member('Asem'),
          'toMemberId': server.member('Mohamed'),
          'amountMinor': 8000,
          'settledOn': '2026-10-18',
        });
        expect(server.settlements.single['status'], 'PENDING');
        expect(find.text(l10n.paymentSentPending(fsIsolate('Mohamed'))), findsOneWidget);
        expect(find.byType(AppBottomSheet), findsNothing);
        // Balances were read again: still 80.00 due (confirmed only), and the pending amount is shown beside it.
        expect(server.count('GET', '/balances'), greaterThanOrEqualTo(2));
        expect(find.text(l10n.pendingBadge), findsOneWidget);
        expect(find.text(l10n.pendingExplain(money(locale, 8000), money(locale, 8000))), findsOneWidget);
      });

      testWidgets('a partial amount is allowed: the typed amount is what is sent', (tester) async {
        asPayer();
        await openGroupTab(tester, server, locale: locale);
        await tester.tap(find.text(l10n.payButton));
        await tester.pumpAndSettle();
        await tester.enterText(inSheet(find.byType(TextField)).first, '30');
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.paymentConfirm(money(locale, 3000))));
        await tester.pumpAndSettle();
        expect(server.settlementCreates.single.body['amountMinor'], 3000);
      });

      testWidgets('key lifecycle: a lost reply is retried with the SAME key (no second payment); a changed amount gets a NEW key', (tester) async {
        asPayer();
        await openGroupTab(tester, server, locale: locale);
        await tester.tap(find.text(l10n.payButton));
        await tester.pumpAndSettle();
        server.loseNextSettlementResponse = true;
        await tester.tap(find.text(l10n.paymentConfirm(money(locale, 8000))));
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomSheet), findsOneWidget, reason: 'the reply was lost: the sheet stays');
        // Same body, retry: the server replays the stored payment.
        await tester.tap(find.text(l10n.paymentConfirm(money(locale, 8000))));
        await tester.pumpAndSettle();
        expect(server.settlementAttemptKeys, hasLength(2));
        expect(server.settlementAttemptKeys[1], server.settlementAttemptKeys[0]);
        expect(server.settlements, hasLength(1), reason: 'one payment, not two');
        expect(find.byType(AppBottomSheet), findsNothing);

        // A new action (another payment, amount changed in a fresh sheet) uses a different key.
        await tester.tap(find.text(l10n.payButton));
        await tester.pumpAndSettle();
        await tester.enterText(inSheet(find.byType(TextField)).first, '10');
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.paymentConfirm(money(locale, 1000))));
        await tester.pumpAndSettle();
        expect(server.settlementAttemptKeys, hasLength(3));
        expect(server.settlementAttemptKeys[2], isNot(server.settlementAttemptKeys[0]));
      });

      testWidgets('a member paying someone without an account is told an admin records it, and cannot send', (tester) async {
        asPayer();
        server.group.members.firstWhere((m) => m.name == 'Mohsen').linked = false;
        await openGroupTab(tester, server, locale: locale);
        await tester.tap(find.text(l10n.balancesRecordAnother));
        await tester.pumpAndSettle();
        await tester.tap(inSheet(find.text(l10n.paymentTo)).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mohsen').last);
        await tester.pumpAndSettle();
        expect(find.text(l10n.paymentHintNoAccount(fsIsolate('Mohsen'))), findsOneWidget);
        await tester.enterText(inSheet(find.byType(TextField)).first, '5');
        await tester.pumpAndSettle();
        final confirm = find.widgetWithText(AppButton, l10n.paymentConfirm(money(locale, 500)));
        expect(tester.widget<AppButton>(confirm).onPressed, isNull);
        expect(server.settlementCreates, isEmpty);
      });
    });

    group('Receiver card, P13-02 ($name)', () {
      // Mohamed (owner) is signed in; Asem says he paid 80.00.
      late Map<String, dynamic> pending;
      setUp(() {
        server.linkAll();
        pending = server.seedSettlement('pending');
        server.balances = balancesMap('balances_v4_pending');
      });

      testWidgets('shows "X says they paid you N" with both buttons, in the balances tab', (tester) async {
        await openGroupTab(tester, server, locale: locale);
        expect(find.text(l10n.incomingTitle), findsOneWidget);
        expect(find.text(l10n.receiverCardTitle(fsIsolate('Asem'), money(locale, 8000))), findsOneWidget);
        expect(find.text(l10n.receiverConfirm), findsOneWidget);
        expect(find.text(l10n.receiverDispute), findsOneWidget);
        expect(find.byType(SettlementStatusChip), findsWidgets);
      });

      testWidgets('reachable from the group home: the banner on the Expenses tab opens the same cards', (tester) async {
        await openGroupTab(tester, server, locale: locale, tab: 'expenses');
        expect(find.text(l10n.incomingBannerOne), findsOneWidget);
        await tester.tap(find.text(l10n.incomingBannerOne));
        await tester.pumpAndSettle();
        expect(inSheet(find.text(l10n.receiverCardTitle(fsIsolate('Asem'), money(locale, 8000)))), findsOneWidget);
        await tester.tap(inSheet(find.text(l10n.receiverConfirm)));
        await tester.pumpAndSettle();
        expect(server.transitions, ['confirm ${pending['id']}']);
        expect(find.byType(AppBottomSheet), findsNothing, reason: 'nothing left to answer: the sheet closes');
        expect(find.text(l10n.incomingBannerOne), findsNothing);
      });

      testWidgets('several payments: the banner says how many', (tester) async {
        server.settlements.add({...pending, 'id': 'second', 'amountMinor': 500});
        await openGroupTab(tester, server, locale: locale, tab: 'expenses');
        expect(find.text(l10n.incomingBannerMany('2')), findsOneWidget);
      });

      testWidgets('no banner and no card when nothing is waiting, or when the payment is addressed to somebody else', (tester) async {
        server.settlements.clear();
        server.settlements.add({...pending, 'toMemberId': server.member('Mohsen')});
        await openGroupTab(tester, server, locale: locale, tab: 'expenses');
        expect(find.text(l10n.incomingBannerOne), findsNothing);
      });

      testWidgets('"Received": confirms, everything is read again, the card is gone and the server\'s balances are shown', (tester) async {
        server.balancesAfterAction = balancesMap('balances_v2');
        await openGroupTab(tester, server, locale: locale);
        final balancesBefore = server.count('GET', '/balances');
        await tester.tap(find.text(l10n.receiverConfirm));
        await tester.pumpAndSettle();
        expect(server.transitions, ['confirm ${pending['id']}']);
        expect(find.text(l10n.settlementConfirmedSnack), findsOneWidget);
        expect(find.text(l10n.incomingTitle), findsNothing);
        expect(server.count('GET', '/balances'), greaterThan(balancesBefore), reason: 'balances re-read');
        expect(server.count('GET', '/api/v1/groups/${server.gid}'), greaterThanOrEqualTo(2), reason: 'group re-read');
        expect(find.text(l10n.balancesNeedOne), findsOneWidget, reason: 'the server\'s V2');
      });

      testWidgets('"Not received yet" asks first; confirming sends the dispute and the transfer shows the dispute flag', (tester) async {
        server.balancesAfterAction = balancesMap('balances_v5_disputed');
        await openGroupTab(tester, server, locale: locale);
        await tester.tap(find.text(l10n.receiverDispute));
        await tester.pumpAndSettle();
        expect(find.text(l10n.disputeDialogTitle), findsOneWidget);
        expect(find.text(l10n.disputeDialogBody(fsIsolate('Asem'))), findsOneWidget);
        expect(server.transitions, isEmpty, reason: 'nothing is sent before the question is answered');
        await tester.tap(find.text(l10n.disputeDialogConfirm));
        await tester.pumpAndSettle();
        expect(server.transitions, ['dispute ${pending['id']}']);
        expect(find.text(l10n.settlementDisputedSnack), findsOneWidget);
        expect(find.text(l10n.disputeFlag), findsOneWidget);
        expect(find.text(l10n.incomingTitle), findsNothing);
      });

      testWidgets('backing out of the dispute question sends nothing', (tester) async {
        await openGroupTab(tester, server, locale: locale);
        await tester.tap(find.text(l10n.receiverDispute));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.cancelDialogKeep));
        await tester.pumpAndSettle();
        expect(server.transitions, isEmpty);
        expect(find.text(l10n.receiverConfirm), findsOneWidget);
      });

      testWidgets('409 INVALID_STATE_TRANSITION: somebody moved it first, everything is re-read and the current state is shown', (tester) async {
        await openGroupTab(tester, server, locale: locale);
        // Another phone cancelled it meanwhile.
        pending['status'] = 'CANCELLED';
        pending['cancelledAt'] = '2026-11-10T12:00:00Z';
        server.balances = balancesMap('balances_v1');
        server.forceNextTransition = (status: 409, code: 'INVALID_STATE_TRANSITION');
        final listsBefore = server.count('GET', '/settlements');
        await tester.tap(find.text(l10n.receiverConfirm));
        await tester.pumpAndSettle();
        expect(find.text(l10n.settlementStateChanged), findsOneWidget);
        expect(server.count('GET', '/settlements'), greaterThan(listsBefore));
        expect(find.text(l10n.incomingTitle), findsNothing, reason: 'no longer pending');
        expect(find.text(settlementStatusLabel(l10n, SettlementStatus.cancelled)), findsWidgets, reason: 'the history now shows it as cancelled');
        expect(find.text(l10n.pendingBadge), findsNothing);
      });

      testWidgets('404: the payment is gone, said so, and the lists are re-read', (tester) async {
        await openGroupTab(tester, server, locale: locale);
        server.settlements.clear();
        await tester.tap(find.text(l10n.receiverConfirm));
        await tester.pumpAndSettle();
        expect(find.text(l10n.settlementGone), findsOneWidget);
        expect(find.text(l10n.incomingTitle), findsNothing);
      });

      testWidgets('403: refused, the group is re-read so the role catches up, and nothing changed', (tester) async {
        await openGroupTab(tester, server, locale: locale);
        final groupReads = server.count('GET', '/api/v1/groups/${server.gid}');
        server.forceNextTransition = (status: 403, code: 'FORBIDDEN');
        await tester.tap(find.text(l10n.receiverConfirm));
        await tester.pumpAndSettle();
        expect(find.text(l10n.errorForbidden), findsOneWidget);
        expect(server.count('GET', '/api/v1/groups/${server.gid}'), greaterThan(groupReads));
        expect(find.text(l10n.receiverConfirm), findsOneWidget, reason: 'still pending');
      });

      testWidgets('offline: a failure message, the card stays and can be tried again', (tester) async {
        await openGroupTab(tester, server, locale: locale);
        server.balancesOffline = true;
        await tester.tap(find.text(l10n.receiverConfirm));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text(l10n.receiverConfirm), findsOneWidget);
        server.balancesOffline = false;
        await tester.tap(find.text(l10n.receiverConfirm));
        await tester.pumpAndSettle();
        expect(server.transitions, ['confirm ${pending['id']}'], reason: 'the offline attempt never reached the server');
      });

      testWidgets('one action at a time: while one is in flight the other button is disabled', (tester) async {
        final gate = Completer<void>();
        server.holdNextSettlementAction = gate;
        await openGroupTab(tester, server, locale: locale);
        await tester.tap(find.text(l10n.receiverConfirm));
        await tester.pump(const Duration(milliseconds: 50));
        final dispute = find.widgetWithText(AppButton, l10n.receiverDispute);
        expect(tester.widget<AppButton>(dispute).onPressed, isNull);
        gate.complete();
        await tester.pumpAndSettle();
      });

      testWidgets('no overflow at text scale 2.0', (tester) async {
        await openGroupTab(tester, server, locale: locale, textScale: 2.0, height: 5000);
        expect(tester.takeException(), isNull);
        expect(find.text(l10n.receiverConfirm), findsOneWidget);
      });

      testWidgets('semantics: both buttons are announced with who and how much', (tester) async {
        final handle = tester.ensureSemantics();
        await openGroupTab(tester, server, locale: locale);
        expect(find.bySemanticsLabel(l10n.receiverConfirmSpoken(moneySpoken(l10n, 8000), 'Asem')), findsOneWidget);
        expect(find.bySemanticsLabel(l10n.receiverDisputeSpoken(moneySpoken(l10n, 8000), 'Asem')), findsOneWidget);
        handle.dispose();
      });
    });

    group('Balances tab with pending and disputed payments ($name)', () {
      testWidgets('pending: the nets are V1\'s, the transfer still says 80.00, and the badge and the explanation show both server numbers', (tester) async {
        server.linkAll();
        server.seedSettlement('pending');
        server.balances = balancesMap('balances_v4_pending');
        await openGroupTab(tester, server, locale: locale);
        expect(find.text('${l10n.balanceOwed} ${money(locale, 10000, signed: true)}'), findsOneWidget);
        expect(find.text('${l10n.balanceOwes} ${money(locale, -8000, signed: true)}'), findsOneWidget);
        expect(find.text('${l10n.balanceOwes} ${money(locale, -2000, signed: true)}'), findsOneWidget);
        expect(find.text(money(locale, 8000)), findsWidgets);
        expect(find.text(l10n.balancesNeedTwo), findsOneWidget, reason: 'still two transfers: pending does not settle anything');
        expect(find.text(l10n.pendingBadge), findsOneWidget);
        expect(find.text(l10n.pendingExplain(money(locale, 8000), money(locale, 8000))), findsOneWidget);
        expect(find.text(l10n.disputeFlag), findsNothing);
      });

      testWidgets('disputed: the flag shows, the nets are unchanged, no pending badge', (tester) async {
        server.linkAll();
        server.seedSettlement('disputed');
        server.balances = balancesMap('balances_v5_disputed');
        await openGroupTab(tester, server, locale: locale);
        expect(find.text(l10n.disputeFlag), findsOneWidget);
        expect(find.text(l10n.pendingBadge), findsNothing);
        expect(find.text('${l10n.balanceOwes} ${money(locale, -8000, signed: true)}'), findsOneWidget);
        expect(find.text(l10n.incomingTitle), findsNothing, reason: 'a disputed payment is no longer waiting for the receiver');
      });

      testWidgets('plain V1 and V2 (no pending, no dispute): no badge, no flag', (tester) async {
        await openGroupTab(tester, server, locale: locale);
        expect(find.text(l10n.pendingBadge), findsNothing);
        expect(find.text(l10n.disputeFlag), findsNothing);
      });

      testWidgets('the history lists every status with its chip, cancelled included, and has no delete control', (tester) async {
        for (final k in ['pending', 'disputed', 'confirmed', 'cancelled']) {
          server.seedSettlement(k);
        }
        server.balances = balancesMap('balances_v4_pending');
        await openGroupTab(tester, server, locale: locale, height: 4200);
        for (final s in [SettlementStatus.pending, SettlementStatus.disputed, SettlementStatus.confirmed, SettlementStatus.cancelled]) {
          expect(find.text(settlementStatusLabel(l10n, s)), findsWidgets, reason: s.name);
        }
        expect(find.byIcon(Icons.delete_outline), findsNothing);
        expect(find.byIcon(Icons.delete), findsNothing);
        expect(server.requests.where((r) => r.startsWith('DELETE')), isEmpty);
      });

      testWidgets('a history row opens the payment\'s detail', (tester) async {
        server.seedSettlement('confirmed');
        await openGroupTab(tester, server, locale: locale, height: 3000);
        await tester.tap(find.text(l10n.balancesPaymentTitle(fsIsolate('Asem'), fsIsolate('Mohamed'))));
        await tester.pumpAndSettle();
        expect(find.text(l10n.settlementDetailTitle), findsOneWidget);
        expect(find.text(l10n.detailBannerConfirmed), findsOneWidget);
      });
    });

    group('Role x action on the transfer cards ($name)', () {
      testWidgets('the receiver of a transfer can record cash received; nobody else\'s transfer gets a button for a plain member', (tester) async {
        server.actAs('Asem'); // Asem pays Mohamed (his own: "I paid") and is not part of Mohsen -> Mohamed
        await openGroupTab(tester, server, locale: locale);
        expect(find.text(l10n.payButton), findsOneWidget);
        expect(find.text(l10n.payOnBehalf), findsNothing, reason: 'a plain member cannot record for others');
        expect(find.text(l10n.payReceived), findsNothing);
      });

      testWidgets('an admin gets "record on behalf" on the transfers that are not theirs; confirmed at once', (tester) async {
        server.actAs('Asem', role: 'ADMIN');
        await openGroupTab(tester, server, locale: locale);
        expect(find.text(l10n.payOnBehalf), findsOneWidget, reason: 'Mohsen -> Mohamed is not Asem\'s');
        await tester.tap(find.text(l10n.payOnBehalf));
        await tester.pumpAndSettle();
        expect(inSheet(find.text(l10n.paymentTitleOnBehalf)), findsOneWidget);
        expect(find.text(l10n.paymentHintConfirmed), findsOneWidget);
        await tester.tap(find.text(l10n.paymentConfirm(money(locale, 2000))));
        await tester.pumpAndSettle();
        expect(server.settlements.single['status'], 'CONFIRMED');
        expect(server.settlements.single['recordedByAdmin'], true);
        expect(find.text(l10n.paymentRecorded), findsOneWidget);
      });

      testWidgets('the receiver records cash from a member without an account: confirmed at once', (tester) async {
        await openGroupTab(tester, server, locale: locale); // Mohamed (owner) is owed by Asem, who has no account
        await tester.tap(find.text(l10n.payReceived).first);
        await tester.pumpAndSettle();
        expect(inSheet(find.text(l10n.paymentTitleReceived)), findsOneWidget);
        await tester.tap(find.text(l10n.paymentConfirm(money(locale, 8000))));
        await tester.pumpAndSettle();
        expect(server.settlements.single['status'], 'CONFIRMED');
        expect(find.text(l10n.paymentRecorded), findsOneWidget);
      });
    });
  }

  group('Settlement detail, P13-03 (ar)', () {
    final l10n = l10nFor(ar);

    // role x status x what is on screen, written out (the buttons of the detail screen).
    final cases = <({String viewer, String role, String status, Set<SettlementAction> shown})>[
      (viewer: 'Asem', role: 'MEMBER', status: 'pending', shown: {SettlementAction.cancel}),
      (viewer: 'Mohamed', role: 'MEMBER', status: 'pending', shown: {SettlementAction.confirm, SettlementAction.dispute}),
      (viewer: 'Mohsen', role: 'MEMBER', status: 'pending', shown: {}),
      (viewer: 'Mohsen', role: 'ADMIN', status: 'pending', shown: {SettlementAction.confirm, SettlementAction.cancel}),
      (viewer: 'Asem', role: 'OWNER', status: 'pending', shown: {SettlementAction.cancel}),
      (viewer: 'Mohamed', role: 'OWNER', status: 'pending', shown: {SettlementAction.confirm, SettlementAction.dispute, SettlementAction.cancel}),
      (viewer: 'Asem', role: 'MEMBER', status: 'disputed', shown: {SettlementAction.cancel}),
      (viewer: 'Mohamed', role: 'MEMBER', status: 'disputed', shown: {SettlementAction.confirm}),
      (viewer: 'Mohsen', role: 'MEMBER', status: 'disputed', shown: {}),
      (viewer: 'Mohsen', role: 'OWNER', status: 'disputed', shown: {SettlementAction.confirm, SettlementAction.cancel}),
      for (final v in [('Asem', 'MEMBER'), ('Mohamed', 'MEMBER'), ('Mohsen', 'ADMIN'), ('Mohamed', 'OWNER')]) ...[
        (viewer: v.$1, role: v.$2, status: 'confirmed', shown: <SettlementAction>{}),
        (viewer: v.$1, role: v.$2, status: 'cancelled', shown: <SettlementAction>{}),
      ],
    ];

    for (final c in cases) {
      testWidgets('${c.status} as ${c.viewer} (${c.role}): ${c.shown.map((a) => a.name).toList()}', (tester) async {
        final server = FakeBalancesServer();
        server.linkAll();
        server.actAs(c.viewer, role: c.role);
        final s = server.seedSettlement(c.status);
        await openSettlementDetail(tester, server, s['id'] as String);
        expect(find.text(l10n.detailConfirm).evaluate().isNotEmpty, c.shown.contains(SettlementAction.confirm));
        expect(find.text(l10n.receiverDispute).evaluate().isNotEmpty, c.shown.contains(SettlementAction.dispute));
        expect(find.text(l10n.cancelDialogConfirm).evaluate().isNotEmpty, c.shown.contains(SettlementAction.cancel));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('disputed: the amount, both statements from the status, the dates, the guidance, and the two actions for the receiver', (tester) async {
      final server = FakeBalancesServer()..linkAll();
      final s = server.seedSettlement('disputed');
      await openSettlementDetail(tester, server, s['id'] as String);
      expect(find.text(money(ar, 8000)), findsOneWidget);
      expect(find.text(l10n.detailBannerDisputed), findsOneWidget);
      expect(find.text(l10n.stmtPayerPaid), findsOneWidget);
      expect(find.text(l10n.stmtReceiverNotReceived), findsOneWidget);
      expect(find.textContaining('2026-10-24'), findsOneWidget, reason: 'settledOn from the server');
      expect(find.textContaining('2026-11-10'), findsWidgets, reason: 'declared / disputed dates from the server');
      expect(find.text(l10n.guidanceTitle), findsOneWidget);
      expect(find.text(l10n.guidanceBody), findsOneWidget);
      expect(find.text(l10n.detailNotCounted), findsOneWidget);
      expect(find.text(l10n.detailConfirm), findsOneWidget);
      expect(find.text(l10n.cancelDialogConfirm), findsOneWidget);
      expect(find.text(l10n.receiverDispute), findsNothing, reason: 'it is already disputed');
    });

    testWidgets('confirm from the detail: the status chip becomes confirmed and the buttons go', (tester) async {
      final server = FakeBalancesServer()..linkAll();
      final s = server.seedSettlement('disputed');
      server.balancesAfterAction = balancesMap('balances_v2');
      await openSettlementDetail(tester, server, s['id'] as String);
      await tester.tap(find.text(l10n.detailConfirm));
      await tester.pumpAndSettle();
      expect(server.transitions, ['confirm ${s['id']}']);
      expect(find.text(l10n.detailBannerConfirmed), findsOneWidget);
      expect(find.text(l10n.detailConfirm), findsNothing);
      expect(find.text(l10n.settlementConfirmedSnack), findsOneWidget);
    });

    testWidgets('cancel from the detail asks first, then shows the cancelled state', (tester) async {
      final server = FakeBalancesServer()..linkAll();
      final s = server.seedSettlement('disputed');
      await openSettlementDetail(tester, server, s['id'] as String);
      await tester.tap(find.text(l10n.cancelDialogConfirm));
      await tester.pumpAndSettle();
      expect(find.text(l10n.cancelDialogTitle), findsOneWidget);
      expect(server.transitions, isEmpty);
      await tester.tap(find.text(l10n.cancelDialogConfirm).last);
      await tester.pumpAndSettle();
      expect(server.transitions, ['cancel ${s['id']}']);
      expect(find.text(l10n.detailBannerCancelled), findsOneWidget);
      expect(find.text(l10n.settlementCancelledSnack), findsOneWidget);
    });

    testWidgets('409 on the detail: refetched, the current state is shown', (tester) async {
      final server = FakeBalancesServer()..linkAll();
      final s = server.seedSettlement('disputed');
      await openSettlementDetail(tester, server, s['id'] as String);
      s['status'] = 'CONFIRMED';
      s['confirmedAt'] = '2026-11-10T12:30:00Z';
      server.forceNextTransition = (status: 409, code: 'INVALID_STATE_TRANSITION');
      await tester.tap(find.text(l10n.detailConfirm));
      await tester.pumpAndSettle();
      expect(find.text(l10n.settlementStateChanged), findsOneWidget);
      expect(find.text(l10n.detailBannerConfirmed), findsOneWidget);
    });

    testWidgets('an unknown payment: says it is not there', (tester) async {
      final server = FakeBalancesServer()..linkAll();
      await openSettlementDetail(tester, server, 'does-not-exist');
      expect(find.text(l10n.settlementGone), findsOneWidget);
    });

    testWidgets('recorded by an admin is said so', (tester) async {
      final server = FakeBalancesServer()..linkAll();
      final s = server.seedSettlement('adminRecorded');
      await openSettlementDetail(tester, server, s['id'] as String);
      expect(find.text(l10n.stmtRecordedByAdmin), findsOneWidget);
    });

    for (final locale in [ar, en]) {
      testWidgets('no overflow at text scale 2.0 (${locale.languageCode})', (tester) async {
        final server = FakeBalancesServer()..linkAll();
        final s = server.seedSettlement('disputed');
        await openSettlementDetail(tester, server, s['id'] as String, locale: locale, textScale: 2.0, height: 5000);
        expect(tester.takeException(), isNull);
        expect(find.text(l10nFor(locale).detailConfirm), findsOneWidget);
      });
    }
  });

  group('Status chips: word + icon + colour, labelled', () {
    for (final locale in [ar, en]) {
      final l10n = l10nFor(locale);
      testWidgets('each state has its own word, icon and colour, and one semantic label (${locale.languageCode})', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(children: [for (final s in [SettlementStatus.pending, SettlementStatus.confirmed, SettlementStatus.disputed, SettlementStatus.cancelled]) SettlementStatusChip(s)]),
          ),
        ));
        final colours = <int>{};
        final icons = <IconData>{};
        for (final s in [SettlementStatus.pending, SettlementStatus.confirmed, SettlementStatus.disputed, SettlementStatus.cancelled]) {
          final word = settlementStatusLabel(l10n, s);
          expect(find.text(word), findsOneWidget, reason: 'word of ${s.name}');
          expect(find.bySemanticsLabel(l10n.settlementChipSpoken(word)), findsOneWidget, reason: 'label of ${s.name}');
          final icon = find.descendant(of: find.ancestor(of: find.text(word), matching: find.byType(SettlementStatusChip)), matching: find.byType(Icon));
          final widget = tester.widget<Icon>(icon);
          expect(widget.icon, SettlementStatusChip.iconFor(s));
          icons.add(widget.icon!);
          colours.add(widget.color!.toARGB32());
        }
        expect(icons, hasLength(4), reason: 'four different icons');
        expect(colours, hasLength(4), reason: 'amber, green, red and a neutral grey');
        handle.dispose();
      });
    }

    testWidgets('an unknown status gets the neutral chip, no actions, and does not crash', (tester) async {
      final server = FakeBalancesServer()..linkAll();
      final s = server.seedSettlement('cancelled');
      s['status'] = 'SOMETHING_NEW';
      await openSettlementDetail(tester, server, s['id'] as String);
      expect(find.text(l10nFor(ar).settlementChipUnknown), findsWidgets);
      expect(find.text(l10nFor(ar).detailConfirm), findsNothing);
    });
  });

  group('Omitted elements (no backend data)', () {
    final banned = [
      'TX-', 'رقم العملية', 'Transaction', 'transaction', 'لقطة', 'Screenshot', 'screenshot', 'إشعار التحويل المرفق', 'تم إرفاق',
      'verified', 'Verified', 'موثّق', 'receipt', 'Receipt', 'إيصال',
    ];
    for (final locale in [ar, en]) {
      for (final screen in ['balances tab', 'detail']) {
        testWidgets('no screenshot, transaction number, photo, verified label or receipt on the $screen (${locale.languageCode})', (tester) async {
          server.linkAll();
          final pending = server.seedSettlement('pending');
          final disputed = server.seedSettlement('disputed');
          server.balances = withHandles(balancesMap('balances_v4_pending'), instapay: 'mohamed@instapay', wallet: '01012345678');
          if (screen == 'detail') {
            await openSettlementDetail(tester, server, disputed['id'] as String, locale: locale, height: 4000);
          } else {
            await openGroupTab(tester, server, locale: locale, height: 5000);
          }
          final all = allText(tester);
          for (final b in banned) {
            expect(all.contains(b), isFalse, reason: '$screen ($b)');
          }
          expect(find.byType(Image), findsNothing);
          expect(find.byIcon(Icons.camera_alt), findsNothing);
          expect(find.byIcon(Icons.photo), findsNothing);
          expect(pending['id'], isNotNull);
        });
      }
    }

    test('the sources of the feature do not mention them either', () {
      final files = Directory('lib/features/balances').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
      for (final f in files) {
        final text = f.readAsStringSync();
        for (final b in ['Image.network', 'Image.file', 'ImagePicker', 'image_picker', 'file_picker', 'transactionRef', 'txNumber']) {
          expect(text.contains(b), isFalse, reason: '${f.path} mentions $b');
        }
      }
    });
  });
}
