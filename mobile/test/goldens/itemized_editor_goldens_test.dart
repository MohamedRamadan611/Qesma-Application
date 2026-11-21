import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/features/expenses/application/expense_form_controller.dart';
import 'package:qesma/features/expenses/application/expense_form_state.dart';

import '../support/expense_form_rig.dart';
import '../support/expenses_rig.dart';
import '../support/expenses_ui.dart';
import '../support/fake_expenses_server.dart';
import '../support/fake_groups_server.dart';
import '../support/test_app.dart';

/// Goldens of the restaurant-bill editor (SA16): the spec's V5 bill, and a bill with a quantity and a discount in a
/// group of 5 members and of 15 (summary chip). The V5 bill (service 12% + tax 14%), Arabic,
/// RTL, 360 wide, with the REAL backend's preview numbers (561.79; 165.99 / 165.98 / 229.82).
/// Update with `flutter test --update-goldens test/goldens` and review the PNG.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  static const double tolerance = 0.005;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= tolerance) return true;
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    final current = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('itemized_editor_goldens_test.dart'));
  });

  testWidgets('restaurant bill editor: V5 with the server\'s numbers (P8-01)', (tester) async {
    final server = FakeExpensesServer();
    seedAllFixtures(server);
    final v5 = fixtureMap('expense_itemized_v5');
    server.cannedPreviews[server.itemizedKey({
      'items': v5['items'],
      'service': {'bps': 1200},
      'tax': {'bps': 1400, 'base': 'SUBTOTAL_PLUS_SERVICE'},
    })] = fixtureMap('preview_v5');
    await pumpExpensesApp(tester, server, height: 3500, route: Routes.editExpense(server.gid, v5['id'] as String));
    await settleForm(tester);
    expect(find.text('أصناف الفاتورة'), findsOneWidget);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('itemized_editor_v5_ar.png'));
  });

  /// A bill with a quantity, a discount and service, typed through the controller; the numbers are the fake engine's
  /// (it follows STANDALONE_SPEC 18.2).
  Future<void> pumpV2Bill(WidgetTester tester, int members) async {
    final server = FakeExpensesServer();
    seedAllFixtures(server);
    for (var i = server.group.members.length; i < members; i++) {
      server.group.members.add(FakeMember(id: 'member-$i', name: 'Member ${i + 1}', sortOrder: 10 + i));
    }
    final container = await pumpExpensesApp(tester, server, height: 2600, route: Routes.addExpense(server.gid));
    await settleForm(tester);
    final key = (gid: server.gid, eid: null);
    final form = container.read(expenseFormControllerProvider(key).notifier);
    form
      ..setTitle('Lunch')
      ..setSplitMode(SplitMode.itemized);
    final first = container.read(expenseFormControllerProvider(key)).form!.itemized.items.single.id;
    form
      ..setItemName(first, 'Pizza')
      ..setItemAmount(first, '200')
      ..addItem();
    final second = container.read(expenseFormControllerProvider(key)).form!.itemized.items.last.id;
    form
      ..setItemName(second, 'Pepsi')
      ..setItemAmount(second, '15.25')
      ..setItemQuantity(second, 3)
      ..setAssignees(second, {kYou, kAsem})
      ..setDiscountOn(true)
      ..setChargeText(ChargeKind.discount, '10')
      ..setServiceOn(true);
    await settleForm(tester);
  }

  testWidgets('restaurant bill editor: a quantity and a discount, 5 members', (tester) async {
    await pumpV2Bill(tester, 5);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('itemized_editor_5_members_ar.png'));
  });

  testWidgets('restaurant bill editor: a quantity and a discount, 15 members', (tester) async {
    await pumpV2Bill(tester, 15);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('itemized_editor_15_members_ar.png'));
  });
}
