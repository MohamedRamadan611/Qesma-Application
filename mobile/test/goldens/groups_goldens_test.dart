import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/groups/presentation/group_card.dart';
import 'package:qesma_api/qesma_api.dart';

import '../support/test_app.dart';

/// Golden of the group card in its three balance states (Arabic, RTL, 360 wide).
/// Update with `flutter test --update-goldens test/goldens` and review the PNG diff.
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

GroupSummaryDto _group(String id, String name, String type, int total, int net, {DateTime? last}) => GroupSummaryDto((b) => b
  ..id = id
  ..name = name
  ..type = type
  ..yourRole = 'OWNER'
  ..currencyCode = 'EGP'
  ..memberCount = id == 'c' ? 1 : 5
  ..totalSpentMinor = total
  ..yourNetMinor = net
  ..lastExpenseAt = last);

void main() {
  setUpAll(() async {
    await loadAppFonts();
    final current = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('groups_goldens_test.dart'));
  });

  testWidgets('group cards: owed, owes and settled (P2-01)', (tester) async {
    await pumpApp(
      tester,
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GroupCard(group: _group('a', 'رحلة دهب الشباب', 'TRIP', 425000, 65000, last: DateTime.utc(2026, 10, 18, 12)), onTap: () {}),
          const SizedBox(height: 12),
          GroupCard(group: _group('b', 'شقة المهندسين', 'HOUSING', 890000, -32000, last: DateTime.utc(2026, 10, 15, 12)), onTap: () {}),
          const SizedBox(height: 12),
          GroupCard(group: _group('c', 'عشا الخميس', 'OUTING', 56179, 0), onTap: () {}),
        ],
      ),
    );
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('group_cards_ar.png'));
  });
}
