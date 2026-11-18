import 'package:flutter_test/flutter_test.dart';

import '../../integration/flows/balances_flow.dart';
import '../../integration/flows/expense_form_flow.dart';
import '../../integration/flows/expense_itemized_flow.dart';
import '../../integration/flows/expenses_flow.dart';
import '../../integration/flows/groups_flow.dart';
import '../../integration/flows/pool_flow.dart';
import '../../integration/flows/profile_flow.dart';
import 'support/local_container.dart';

/// SA3 conformance: the same repository flows that run against the real Java backend (`test/integration/*_flow_test`
/// with `API_BASE_URL`) run here against `LocalBackend` over an in-memory database. They always run.
void main() {
  test('groups and members (FL3 flow) in local mode', () async => runGroupsFlow(await localContainer()));

  test('expenses list, filters, details, history, delete (FL4 flow) in local mode',
      () async => runExpensesFlow(await localContainer()));

  test('the add/edit form requests (FL5 flow) in local mode', () async => runExpenseFormFlow(await localContainer()));

  test('the restaurant-bill requests (FL6 flow) in local mode',
      () async => runExpenseItemizedFlow(await localContainer()));

  test('balances, transfers and payments (FL7 flow) in local mode', () async => runBalancesFlow(await localContainer()));

  test('pool & treasurer: deposits, a pool expense, the meter and the lock (SA10 flow) in local mode',
      () async => runPoolFlow(await localContainer()));

  test('profile name and own payment handles (FL8/FL14 flow) in local mode',
      () async => runProfileFlow(await localContainer()));
}
