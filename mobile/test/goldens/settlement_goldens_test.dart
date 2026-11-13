import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_balances_server.dart';
import '../support/settlement_ui.dart';
import '../support/test_app.dart';

/// Goldens of the two-sided settlement UI (FL13): the payer's transfer card with the receiver's handles (P13-01), the
/// receiver's card (P13-02), the disputed detail (P13-03) and the balances tab with a pending and a disputed payment.
/// Arabic, RTL, 360 wide. Update with `flutter test --update-goldens test/goldens/settlement_goldens_test.dart` and
/// review the PNGs.
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
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('settlement_goldens_test.dart'));
  });

  testWidgets('payer transfer card with the receiver\'s handles (P13-01)', (tester) async {
    final server = FakeBalancesServer()
      ..actAs('Asem')
      ..linkAll();
    server.balances = withHandles(balancesMap('balances_v1'), instapay: 'mohamed@instapay', wallet: '01012345678');
    await openGroupTab(tester, server, height: 1900);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('settlement_payer_card_ar.png'));
  });

  testWidgets('receiver card: "Asem says he paid you 80.00" (P13-02)', (tester) async {
    final server = FakeBalancesServer()..linkAll();
    server.seedSettlement('pending');
    server.balances = balancesMap('balances_v4_pending');
    await openGroupTab(tester, server, height: 1500);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('settlement_receiver_card_ar.png'));
  });

  testWidgets('disputed settlement detail (P13-03)', (tester) async {
    final server = FakeBalancesServer()..linkAll();
    final disputed = server.seedSettlement('disputed');
    await openSettlementDetail(tester, server, disputed['id'] as String, height: 1500);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('settlement_disputed_detail_ar.png'));
  });

  testWidgets('balances tab: a pending payment waiting, the history with every status', (tester) async {
    final server = FakeBalancesServer()..linkAll();
    for (final k in ['pending', 'disputed', 'confirmed', 'cancelled']) {
      server.seedSettlement(k);
    }
    server.balances = balancesMap('balances_v4_pending');
    await openGroupTab(tester, server, height: 3300);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('settlement_balances_tab_ar.png'));
  });
}
