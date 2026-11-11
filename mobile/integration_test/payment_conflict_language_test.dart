import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma_api/qesma_api.dart';

import 'support/ui.dart';

/// FL9 (c), (d) and (g) on the phone, real UI against the real backend. The data is created through the generated client
/// (the second client of the conflict test), the behaviour under test goes through the screens:
///  (c) record the suggested payment: the transfer disappears and everyone is settled up (V1/V2 behaviour);
///  (d) an expense edited elsewhere: saving a stale edit shows the conflict dialog; the expense history shows both versions;
///  (g) switching the language to Arabic flips the layout direction and the text.
///
///   adb reverse tcp:18080 tcp:18080
///   flutter test integration_test/payment_conflict_language_test.dart -d DEVICE_ID --dart-define=API_BASE_URL=http://localhost:18080
Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('record a payment, hit an edit conflict, switch the language', (tester) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final session = await startSignedIn(tester, 'fl9-ui-pay-$stamp');
    final api = session.container.read(qesmaApiProvider);

    // Data: a group with Asem; Tester pays 100.00 split equally: Tester +50.00, Asem -50.00.
    final group = (await api.getGroupControllerApi().createGroup(
          createGroupRequest: CreateGroupRequest((b) => b
            ..name = 'FL9 payment'
            ..type = 'TRIP'
            ..currencyCode = 'EGP'),
        ))
        .data!;
    final gid = group.id;
    await api.getMemberControllerApi().addMember(gid: gid, createMemberRequest: CreateMemberRequest((b) => b.displayName = 'Asem'));
    ExpenseCommand command(int total) => ExpenseCommand((b) => b
      ..title = 'Lunch'
      ..expenseDate = Date(2026, 10, 20)
      ..splitType = 'EQUAL'
      ..totalMinor = total
      ..payers.add(PayerInput((x) => x
        ..memberId = group.yourMemberId
        ..amountMinor = total)));
    final eid = (await api.getExpenseControllerApi().createExpense(gid: gid, idempotencyKey: '5a6b0c1d-0000-4000-8000-${stamp.toString().padLeft(12, '0').substring(0, 12)}', expenseCommand: command(10000))).data!.id;

    // (c) Balances -> record the suggested payment -> settled.
    session.container.read(routerProvider).go('${Routes.group(gid)}?tab=balances');
    await pumpUntil(tester, find.text('Suggested transfers'));
    expect(find.textContaining('50.00'), findsWidgets, reason: 'Asem owes Tester 50.00 (the server computed it)');
    await tapText(tester, 'Record payment');
    await pumpUntil(tester, find.textContaining('Confirm payment'));
    await tapContaining(tester, 'Confirm payment');
    await pumpUntil(tester, find.text('Everyone is settled up'));
    expect(find.text('Suggested transfers'), findsNothing);

    // (d) Edit conflict: open the expense, start an edit, let "another device" change it, then save.
    session.container.read(routerProvider).go(Routes.expense(gid, eid));
    await pumpUntil(tester, find.text('Expense details'));
    await tapText(tester, 'Edit expense');
    await pumpUntil(tester, find.text('Expense name'));
    await typeInto(tester, 1, '120');
    await hideKeyboard(tester);
    await api.getExpenseControllerApi().updateExpense(gid: gid, eid: eid, ifMatch: '"1"', expenseCommand: command(11000)); // the other device: 110.00
    await tapText(tester, 'Save changes');
    await pumpUntil(tester, find.text('This expense was edited'));

    // Leave the screen (the conflict dialog and the stale form go away) and open the expense again: the server's version shows.
    session.container.read(routerProvider).go(Routes.account);
    await pumpUntil(tester, find.text('App language'));
    session.container.read(routerProvider).go(Routes.expense(gid, eid));
    await pumpUntil(tester, find.text('Expense details'));
    expect(find.textContaining('110.00'), findsWidgets, reason: 'the other device change is what the server holds');
    expect(find.textContaining('Edited (version 2)'), findsWidgets);

    // (g) Language: Account -> App language -> العربية.
    session.container.read(routerProvider).go(Routes.account);
    await pumpUntil(tester, find.text('App language'));
    await tapText(tester, 'App language');
    await pumpUntil(tester, find.text('Choose a language'));
    await tapText(tester, 'العربية');
    await pumpUntil(tester, find.text('لغة التطبيق'));
    final direction = Directionality.of(tester.element(find.byType(Scaffold).first));
    expect(direction, TextDirection.rtl, reason: 'Arabic is right-to-left');
    expect(find.text('App language'), findsNothing);
  });
}
