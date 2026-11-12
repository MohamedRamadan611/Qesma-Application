import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/router/app_router.dart';

import '../support/fake_invites_server.dart';
import '../support/invites_rig.dart';
import '../support/test_app.dart';

/// Goldens of the invite sheet (P12-01) and the join screen (P12-02): Arabic, RTL, 360 wide, on the real screens with
/// backend-shaped fixtures. Update with `flutter test --update-goldens test/goldens/invites_goldens_test.dart`.
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
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('invites_goldens_test.dart'));
  });

  testWidgets('join screen: who are you? (P12-02), unclaimed names only, no money', (tester) async {
    await pumpInvitesApp(tester, inviteServer(), route: Routes.joinCode('ABCD2345'), height: 900);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('join_screen_ar.png'));
  });

  testWidgets('join screen: waiting for admin approval', (tester) async {
    final server = inviteServer(preview: FakePreview(callerState: 'PENDING_APPROVAL', requiresApproval: true));
    await pumpInvitesApp(tester, server, route: Routes.joinCode('ABCD2345'), height: 700);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('join_waiting_ar.png'));
  });

  testWidgets('invite sheet: code, link, share, expiry, approval, revoke (P12-01)', (tester) async {
    final server = inviteServer();
    server.addInvite('g1', code: 'ABCD2345', requiresApproval: true);
    await pumpInvitesApp(tester, server, route: Routes.group('g1'), height: 1400);
    await tester.tap(find.byTooltip(lookupAppLocalizations(const Locale('ar')).inviteAction));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('invite_sheet_ar.png'));
  });
}
