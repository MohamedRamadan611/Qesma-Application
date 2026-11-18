import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/balances/application/record_payment_state.dart';
import 'package:qesma/features/expenses/application/expense_command_builder.dart';
import 'package:qesma/features/expenses/application/expense_form_state.dart';
import 'package:qesma_api/qesma_api.dart';

/// SA10 request building: the deposit and the pool expense are built in the one place each body is built, and the
/// kind / flag are part of the idempotent body (same body, same key; a different kind is a different request).
void main() {
  const a = 'aaaaaaaa-0000-4000-8000-000000000001';
  const t = 'aaaaaaaa-0000-4000-8000-000000000002';
  final date = Date(2026, 11, 12);

  test('a deposit is POOL_DEPOSIT; a plain payment leaves the kind out (server default PAYMENT)', () {
    final deposit = buildSettlementCommand(PaymentForm(fromId: a, toId: t, amountText: '300', date: date, poolDeposit: true))!;
    final payment = buildSettlementCommand(PaymentForm(fromId: a, toId: t, amountText: '300', date: date))!;
    expect((deposit.kind, payment.kind), (kPoolDepositKind, null));
    expect(settlementBodyJson(deposit)['kind'], kPoolDepositKind);
    expect(settlementBodyJson(payment).containsKey('kind'), isFalse);
    expect(settlementBodyJson(deposit), isNot(settlementBodyJson(payment)), reason: 'another kind is another request');
  });

  test('the deposit flag survives every edit of the form', () {
    final form = PaymentForm(fromId: a, toId: t, date: date, poolDeposit: true).copyWith(amountText: '5', note: 'x');
    expect(form.poolDeposit, isTrue);
  });

  test('"Paid from the pool" is sent only when on, and it makes the form differ', () {
    final off = ExpenseFormState(title: 'Fuel', amountText: '450', date: date, singlePayerId: t);
    final on = off.copyWith(paidFromPool: true);
    expect(buildExpenseCommand(on, edit: false, memberIds: [t, a])!.paidFromPool, isTrue);
    expect(buildExpenseCommand(off, edit: false, memberIds: [t, a])!.paidFromPool, isNull);
    expect(on.differsFrom(off), isTrue);
  });
}
