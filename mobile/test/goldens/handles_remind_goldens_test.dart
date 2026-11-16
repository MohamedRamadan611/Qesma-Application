import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/widgets/widgets.dart';

import '../support/expenses_ui.dart';
import '../support/fake_balances_server.dart';
import '../support/settlement_ui.dart';
import '../support/test_app.dart';

/// Goldens of the payment details screen and the Remind states (FL14). Arabic, RTL, 360 wide. Only made-up values appear
/// (`demo@bank`, `01000000000`): never a real handle. Update with
/// `flutter test --update-goldens test/goldens/handles_remind_goldens_test.dart` and review the PNGs.
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
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('handles_remind_goldens_test.dart'));
  });

  Future<FakeBalancesServer> openHandles(WidgetTester tester, {Map<String, String?>? handles, bool fail = false}) async {
    final server = FakeBalancesServer();
    if (handles != null) server.myHandles = handles;
    server.failNextHandlesGet = fail;
    await pumpExpensesApp(tester, server, height: 900, route: Routes.paymentHandles);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();
    return server;
  }

  testWidgets('payment details: empty', (tester) async {
    await openHandles(tester);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('handles_empty_ar.png'));
  });

  testWidgets('payment details: filled', (tester) async {
    await openHandles(tester, handles: {'instapay': 'demo@bank', 'wallet': '01000000000'});
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('handles_filled_ar.png'));
  });

  testWidgets('payment details: inline errors', (tester) async {
    await openHandles(tester);
    await tester.enterText(find.byType(TextField).at(0), 'no at sign');
    await tester.enterText(find.byType(TextField).at(1), '01312345678');
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, l10nFor(ar).handlesSave));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('handles_errors_ar.png'));
  });

  testWidgets('payment details: could not load', (tester) async {
    await openHandles(tester, fail: true);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('handles_load_error_ar.png'));
  });

  testWidgets('Remind: enabled on the first transfer, "sent today" with the server time on the second', (tester) async {
    final server = FakeBalancesServer()..linkAll();
    final t = (server.balances['transfers'] as List).cast<Map<String, dynamic>>();
    t.last['canRemindAt'] = '2099-03-04T05:06:00Z';
    await openGroupTab(tester, server, height: 1700);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('remind_states_ar.png'));
  });

  testWidgets('Remind: the debtor has no account, so a caption and no button', (tester) async {
    final server = FakeBalancesServer();
    await openGroupTab(tester, server, height: 1500);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('remind_no_account_ar.png'));
  });
}
