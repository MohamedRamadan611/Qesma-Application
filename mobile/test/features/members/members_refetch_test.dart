import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/features/balances/application/balances_controller.dart';

import '../../support/expenses_ui.dart';
import '../../support/fake_balances_server.dart';
import '../../support/test_app.dart';

/// FL12 item 5: after every member change the members, the group and the balances are read again, and a member who
/// left still shows in the balances exactly as the server sends it (nothing is hidden or recomputed on the phone).
void main() {
  setUpAll(loadAppFonts);

  testWidgets('mark as left: group and balances are re-read; the person stays in the balances', (tester) async {
    final server = FakeBalancesServer();
    final l10n = l10nFor(const Locale('en'));
    final container = await pumpExpensesApp(tester, server, locale: const Locale('en'), height: 2400, route: '${Routes.group(server.gid)}?tab=balances');
    await tester.pumpAndSettle();
    // The balances controller is auto-dispose and the tab is swapped out; keep it alive like a second screen would.
    final keepAlive = container.listen(balancesControllerProvider(server.gid), (_, _) {});
    addTearDown(keepAlive.close);

    final ghost = server.group.members.firstWhere((m) => !m.isYou);
    final balancesBefore = server.count('GET', '/balances');
    final groupReadsBefore = server.groupReads;
    expect(balancesBefore, greaterThan(0));

    await tapText(tester, l10n.groupTabMembers);
    final options = find.byTooltip(l10n.membersOptions(ghost.name));
    await tester.ensureVisible(options);
    await tester.tap(options);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text(l10n.membersActionMarkLeft)));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(l10n.memberMarkLeftConfirmAction)));
    await tester.pumpAndSettle();

    expect(ghost.status, 'LEFT');
    expect(server.groupReads, greaterThan(groupReadsBefore), reason: 'group (and so the members) re-read');
    expect(server.count('GET', '/balances'), greaterThan(balancesBefore), reason: 'balances re-read');

    await tapText(tester, l10n.groupTabBalances);
    expect(find.textContaining(ghost.name), findsWidgets, reason: 'a member who left is still in the balances');
  });
}
