import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:qesma/core/format/clock.dart';
import 'package:qesma/features/expenses/application/expense_form_controller.dart';
import 'package:qesma/features/expenses/application/expense_preview_controller.dart';
import 'package:qesma/features/groups/application/group_detail_controller.dart';

import 'expenses_rig.dart';
import 'fake_expenses_server.dart';

/// Ids of the captured group's members (the "you" member first).
const String kYou = '77e31a5d-f072-4568-9115-0259fb131e9a';
const String kAsem = '98138ea2-62ee-4b5d-92d0-0ecccb012cfa';
const String kMohsen = '014bf05a-7ba1-432e-9c17-35881f72d003';

/// The "today" of the form tests.
final DateTime formNow = DateTime(2026, 10, 18, 12);

void keepAlive(ProviderContainer container, ProviderListenable<Object?> provider) {
  container.listen(provider, (_, _) {});
}

/// The real form stack (controller, preview, repository, generated client) on the fake server, with
/// the group already loaded (the form reads its members from it) and a short debounce.
Future<ProviderContainer> formContainer(FakeExpensesServer server, {Duration debounce = const Duration(milliseconds: 10)}) async {
  final container = expensesContainer(
    server,
    extra: [
      clockProvider.overrideWithValue(() => formNow),
      previewDebounceProvider.overrideWithValue(debounce),
    ],
  );
  keepAlive(container, groupDetailControllerProvider(server.gid));
  await container.read(groupDetailControllerProvider(server.gid).notifier).load();
  return container;
}

/// The controller for adding ([eid] null) or editing an expense, kept alive.
ExpenseFormController formController(ProviderContainer container, FakeExpensesServer server, {String? eid}) {
  final key = (gid: server.gid, eid: eid);
  keepAlive(container, expenseFormControllerProvider(key));
  return container.read(expenseFormControllerProvider(key).notifier);
}

ExpenseFormView formView(ProviderContainer container, FakeExpensesServer server, {String? eid}) =>
    container.read(expenseFormControllerProvider((gid: server.gid, eid: eid)));

Future<void> waitUntil(bool Function() done, {int tries = 400}) async {
  for (var i = 0; i < tries && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
