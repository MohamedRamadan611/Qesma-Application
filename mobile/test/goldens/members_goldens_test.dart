import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';

import '../features/groups/groups_screens_test.dart' show pumpGroupsApp, tapText;
import '../support/fake_groups_server.dart';
import '../support/test_app.dart';

/// Golden of the members tab v2 (P12-03): Arabic, RTL, 360 wide, owner view with mixed roles and statuses.
/// Update with `flutter test --update-goldens test/goldens/members_goldens_test.dart`.
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
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('members_goldens_test.dart'));
  });

  testWidgets('members tab: owner (you), admin, linked member, name only, left, and the join banner', (tester) async {
    final server = FakeGroupsServer();
    final g = server.seed(name: 'رحلة دهب');
    g.members.first.name = 'محمد';
    g.members.addAll([
      FakeMember(id: 'g1-asem', name: 'عاصم', sortOrder: 2, role: 'ADMIN', linked: true),
      FakeMember(id: 'g1-sara', name: 'سارة', sortOrder: 3, linked: true),
      FakeMember(id: 'g1-omar', name: 'عمر', sortOrder: 4),
      FakeMember(id: 'g1-hana', name: 'هناء', sortOrder: 5, status: 'LEFT', linked: true),
    ]);
    server.joinRequests[g.id] = [FakeJoinRequest(id: 'r1', requester: 'منى', newName: 'منى')];
    await pumpGroupsApp(tester, server, height: 900);
    await tapText(tester, 'رحلة دهب');
    await tapText(tester, lookupAppLocalizations(const Locale('ar')).groupTabMembers);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('members_tab_v2_ar.png'));
  });
}
