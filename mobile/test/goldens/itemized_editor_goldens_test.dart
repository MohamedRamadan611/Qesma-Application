import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/router/app_router.dart';

import '../support/expenses_rig.dart';
import '../support/expenses_ui.dart';
import '../support/fake_expenses_server.dart';
import '../support/test_app.dart';

/// Golden of the restaurant-bill editor with the spec's V5 bill (service 12% + tax 14%), Arabic,
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
}
