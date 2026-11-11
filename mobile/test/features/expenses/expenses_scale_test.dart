import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/expenses/presentation/expense_card.dart';

import '../../support/expenses_ui.dart';
import '../../support/fake_expenses_server.dart';
import '../../support/test_app.dart';

/// FL9 performance check that needs no phone: a group with 500 expenses (the planned maximum, spec B7) on the real expenses
/// stack. The list must stay lazy (only the cards on screen are built, never all 500) and must fetch each page exactly once
/// (25 pages of 20), however hard the user flings. Frame times themselves are in docs/mobile-perf.md.
void main() {
  setUpAll(loadAppFonts);

  testWidgets('500 expenses: the list builds only what is on screen and loads each page exactly once', (tester) async {
    final server = FakeExpensesServer();
    for (var i = 0; i < 500; i++) {
      server.expenses.add(cloneExpense(fixtureMap('expense_exact'), id: 'e$i', title: 'Expense $i', date: '2026-10-${(1 + i % 28).toString().padLeft(2, '0')}'));
    }
    await pumpExpensesApp(tester, server, height: 800);

    int built() => find.byType(ExpenseCard).evaluate().length;
    List<String> pageRequests() => server.requests.where((r) => r.contains('/expenses?')).toList();

    expect(pageRequests(), hasLength(1), reason: 'only page 0 is fetched on open');
    expect(built(), lessThan(15), reason: 'a lazy list builds the visible cards, not 20');

    // Fling to the end until the server has nothing more (25 pages x 20 = 500).
    for (var i = 0; i < 80 && pageRequests().length < 25; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -20000));
      await tester.pumpAndSettle();
    }
    expect(pageRequests(), hasLength(25), reason: 'every page was requested once: ${pageRequests().length}');
    expect(pageRequests().toSet(), hasLength(25), reason: 'and no page twice');

    // One more fling at the very end must not call the server again (no hammering).
    await tester.drag(find.byType(ListView).first, const Offset(0, -20000));
    await tester.pumpAndSettle();
    expect(pageRequests(), hasLength(25));

    expect(built(), lessThan(15), reason: 'with all 500 loaded, still only the visible cards exist');
    expect(find.byType(ListView), findsOneWidget);
  });
}
