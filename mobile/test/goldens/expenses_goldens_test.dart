import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/features/expenses/presentation/expense_card.dart';

import '../support/expenses_rig.dart';
import '../support/expenses_ui.dart';
import '../support/fake_expenses_server.dart';
import '../support/test_app.dart';

/// Goldens of the expense row (three split types) and of the expense details page (the
/// richest case: V5, itemized with service and tax), Arabic, RTL, 360 wide, from REAL
/// backend responses. Update with `flutter test --update-goldens test/goldens` and review the PNGs.
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
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('expenses_goldens_test.dart'));
  });

  testWidgets('expense rows: equal, exact and itemized (P3-01)', (tester) async {
    final server = FakeExpensesServer();
    final names = {for (final m in server.group.members) m.id: m.name};
    String nameOf(String id) => names[id] ?? '?';
    final you = server.group.members.firstWhere((m) => m.isYou).id;

    await pumpApp(
      tester,
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final name in ['expense_equal_v2', 'expense_exact', 'expense_itemized_v5']) ...[
            ExpenseCard(expense: expenseFixture(name), nameOf: nameOf, yourMemberId: you, onTap: () {}),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('expense_rows_ar.png'));
  });

  testWidgets('expense details: itemized with service 12% and tax 14% (P7-01)', (tester) async {
    final server = FakeExpensesServer();
    seedAllFixtures(server);
    await pumpExpensesApp(
      tester,
      server,
      height: 1700,
      route: Routes.expense(server.gid, '7e3b3a23-d844-4889-99ae-5cba254d1173'),
    );
    expect(find.text('تفاصيل المصروف'), findsOneWidget);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('expense_details_v5_ar.png'));
  });
}
