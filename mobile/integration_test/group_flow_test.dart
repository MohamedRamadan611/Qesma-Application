import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/ui.dart';

/// FL9 (b)+(c) on the phone, real UI against the real backend (profiles local,fake-auth):
/// create a group, add members, add an EQUAL expense (spec V3: 100.00 among three = 33.34 / 33.33 / 33.33) and read the
/// balances the SERVER computed (owner +66.66, the others -33.33).
///
///   adb reverse tcp:18080 tcp:18080
///   flutter test integration_test/group_flow_test.dart -d DEVICE_ID --dart-define=API_BASE_URL=http://localhost:18080
Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create a group, add members and an equal expense, then read the balances', (tester) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await startSignedIn(tester, 'fl9-ui-group-$stamp');

    // Create the group.
    await tapText(tester, 'New group');
    await pumpUntil(tester, find.text('Create a new group'));
    await typeInto(tester, 0, 'FL9 trip');
    await hideKeyboard(tester);
    await tapText(tester, 'Create group');
    await pumpUntil(tester, find.text('Members'));

    // Add two members.
    await tapText(tester, 'Members');
    for (final name in ['Asem', 'Mohsen']) {
      await tapText(tester, 'Add member');
      await pumpUntil(tester, find.text('Add a new member'));
      await typeInto(tester, 0, name);
      await hideKeyboard(tester);
      await tapText(tester, 'Save member');
      await pumpUntil(tester, find.text(name));
    }

    // Add an equal expense: 100.00, paid by the owner, split between everyone.
    await tapText(tester, 'Expenses');
    await tapText(tester, 'Add expense');
    await pumpUntil(tester, find.text('Expense name'));
    await typeInto(tester, 0, 'Dinner');
    await typeInto(tester, 1, '100');
    await hideKeyboard(tester);
    await pumpUntil(tester, find.textContaining('33.34'));
    expect(find.textContaining('33.33'), findsWidgets, reason: 'the preview shows V3: 33.34 / 33.33 / 33.33');
    await tapText(tester, 'Save expense');
    // Saving opens the expense details: the shares are the server's V3 numbers.
    await pumpUntil(tester, find.text('Expense details'));
    for (final share in ['100.00', '33.34', '33.33']) {
      expect(find.textContaining(share), findsWidgets, reason: 'details show $share');
    }
    await tester.pageBack();
    await pumpUntil(tester, find.text('Balances'));

    // The balances the server computed.
    await tapText(tester, 'Balances');
    await pumpUntil(tester, find.text('Suggested transfers'));
    expect(find.textContaining('33.33'), findsWidgets);
    await tester.scrollUntilVisible(find.textContaining('66.66'), 300, scrollable: find.byType(Scrollable).first, maxScrolls: 20);
    expect(find.textContaining('66.66'), findsWidgets, reason: 'owner net +66.66 (100.00 paid minus the 33.34 share)');
  });
}
