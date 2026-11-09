import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/router/app_router.dart';

import '../support/expenses_ui.dart';
import '../support/fake_expenses_server.dart';
import '../support/test_app.dart';

/// Goldens of the add-expense form (the design's Exact case) and of the paid-by sheet with two
/// payers, Arabic, RTL, 360 wide, on server numbers. Update with
/// `flutter test --update-goldens test/goldens` and review the PNGs.
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
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('expense_form_goldens_test.dart'));
  });

  Future<void> openForm(WidgetTester tester, FakeExpensesServer server) async {
    await pumpExpensesApp(tester, server, height: 1500, route: Routes.addExpense(server.gid));
    await settleForm(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Petrol');
    await tester.enterText(find.byType(TextField).at(1), '520');
    await settleForm(tester);
  }

  testWidgets('add expense: Exact tab with the server\'s equal split (P5-01)', (tester) async {
    final server = FakeExpensesServer();
    await openForm(tester, server);
    await tapText(tester, 'مبالغ محددة');
    await settleForm(tester);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('expense_form_exact_ar.png'));
  });

  testWidgets('paid by: two payers whose amounts match the bill (P6-01)', (tester) async {
    final server = FakeExpensesServer();
    await openForm(tester, server);
    await tapText(tester, 'تعديل الدافعين');
    await settleForm(tester);
    await tester.tap(find.byType(Checkbox).at(1));
    await settleForm(tester);
    final boxes = find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField));
    await tester.enterText(boxes.at(0), '300');
    await tester.enterText(boxes.at(1), '220');
    await settleForm(tester);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('expense_payers_sheet_ar.png'));
  });
}
