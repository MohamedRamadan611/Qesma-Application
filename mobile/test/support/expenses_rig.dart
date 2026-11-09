import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:qesma/features/expenses/application/expense_detail_controller.dart';
import 'package:qesma/features/expenses/application/expenses_list_controller.dart';

import 'fake_expenses_server.dart';
import 'groups_rig.dart';

/// The real expenses stack (repository, controllers, generated client, Dio) on a fake server.
/// Controllers do not auto-load, so a test drives them step by step.
ProviderContainer expensesContainer(FakeExpensesServer server, {bool autoLoad = false, List<Override> extra = const []}) {
  return groupsContainer(
    server,
    autoLoad: autoLoad,
    extra: [
      expensesAutoLoadProvider.overrideWithValue(autoLoad),
      expenseDetailAutoLoadProvider.overrideWithValue(autoLoad),
      ...extra,
    ],
  );
}

/// The seven captured expenses, loaded into [server]: EQUAL (edited, version 2), EXACT and the
/// four itemized variants (service + tax, service only, tax only, neither).
void seedAllFixtures(FakeExpensesServer server) {
  for (final name in [
    'expense_equal_v2',
    'expense_exact',
    'expense_itemized_v5',
    'expense_itemized_v6_service_only',
    'expense_itemized_v7_tax_only',
    'expense_itemized_v8_neither',
  ]) {
    server.expenses.add(copyJson(fixtureMap(name)));
  }
  final equalId = fixtureMap('expense_equal_v2')['id'] as String;
  server.revisions[equalId] = [for (final r in (fixtureJson('revisions_equal') as List)) (r as Map).cast<String, dynamic>()];
}
