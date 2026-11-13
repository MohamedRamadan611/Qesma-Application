import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/router/app_router.dart';

import '../support/expenses_ui.dart';
import '../support/fake_balances_server.dart';
import '../support/test_app.dart';

/// Goldens of the Balances tab with the REAL backend's V1 numbers (nets 100.00 / -80.00 / -20.00 and
/// the two suggested transfers) and V2's payment history, plus the Record payment sheet; Arabic, RTL,
/// 360 wide. Update with `flutter test --update-goldens test/goldens` and review the PNGs.
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
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('balances_goldens_test.dart'));
  });

  testWidgets('balances tab: V1 with the server\'s numbers and the payment history', (tester) async {
    final server = FakeBalancesServer()..seedV2();
    // The V1 numbers and the history in one picture: the server answers V1 while a payment is listed.
    server.balances = balancesMap('balances_v1');
    await pumpExpensesApp(tester, server, height: 1700, route: '${Routes.group(server.gid)}?tab=balances');
    await tester.pumpAndSettle();
    expect(find.text(lookupAppLocalizations(const Locale('ar')).balancesNeedTwo), findsOneWidget);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('balances_tab_v1_ar.png'));
  });

  testWidgets('record payment sheet opened from the 80.00 transfer', (tester) async {
    final server = FakeBalancesServer();
    await pumpExpensesApp(tester, server, height: 1300, route: '${Routes.group(server.gid)}?tab=balances');
    await tester.pumpAndSettle();
    await tester.tap(find.text(lookupAppLocalizations(const Locale('ar')).payReceived).first);
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('record_payment_sheet_ar.png'));
  });
}
