import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_groups_server.dart';
import '../../support/test_app.dart';
import 'members_v2_test.dart' show inSheet, openMembers, openOptions, seedGroup;

/// SA19: the "Default share" action of the member options sheet: shown with rename, set and clear send the right PATCH
/// body, the current value is shown in the row hint, and the stepper stays in 1..100.
const _ar = Locale('ar');
const _en = Locale('en');

void main() {
  setUpAll(loadAppFonts);

  late FakeGroupsServer server;
  setUp(() => server = FakeGroupsServer());

  for (final (locale, scale) in [(_ar, 1.0), (_en, 2.0)]) {
    final tag = '${locale.languageCode} ${scale}x';

    testWidgets('options ($tag): offered for the Owner and Admin wherever rename is, not for a plain member', (tester) async {
      seedGroup(server, 'OWNER');
      final l10n = await openMembers(tester, server, locale: locale, scale: scale);
      await openOptions(tester, l10n, 'Sara');
      expect(inSheet(find.text(l10n.membersActionDefaultShare, skipOffstage: false)), findsOneWidget);
      expect(inSheet(find.text(l10n.membersActionDefaultShareHint, skipOffstage: false)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('set ($tag): the stepper starts at 1, saves with defaultShareUnits only and the hint shows the saved value', (tester) async {
      final g = seedGroup(server, 'OWNER');
      final l10n = await openMembers(tester, server, locale: locale, scale: scale);
      await openOptions(tester, l10n, 'Sara');
      await tester.tap(inSheet(find.text(l10n.membersActionDefaultShare)));
      await tester.pumpAndSettle();
      expect(find.text(l10n.memberDefaultShareTitle('Sara')), findsOneWidget);
      expect(find.text(l10n.memberDefaultShareClear), findsNothing, reason: 'nothing to clear yet');
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove)).onPressed, isNull, reason: 'minimum is 1');
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, l10n.commonSave));
      await tester.pumpAndSettle();
      expect(server.memberPatches.last, {'defaultShareUnits': 3});
      expect(g.members.firstWhere((m) => m.name == 'Sara').defaultShareUnits, 3);

      await openOptions(tester, l10n, 'Sara');
      expect(inSheet(find.text(l10n.membersDefaultShareCurrent(l10n.sharesUnitsFew(isolated('3'))), skipOffstage: false)), findsOneWidget);
    });

    testWidgets('clear ($tag): starts at the current value and Clear sends clearDefaultShareUnits', (tester) async {
      final g = seedGroup(server, 'OWNER');
      g.members.firstWhere((m) => m.name == 'Sara').defaultShareUnits = 4;
      final l10n = await openMembers(tester, server, locale: locale, scale: scale);
      await openOptions(tester, l10n, 'Sara');
      await tester.tap(inSheet(find.text(l10n.membersActionDefaultShare)));
      await tester.pumpAndSettle();
      expect(find.text(isolated('4')), findsOneWidget, reason: 'opens at the current value');
      await tester.tap(find.text(l10n.memberDefaultShareClear));
      await tester.pumpAndSettle();
      expect(server.memberPatches.last, {'clearDefaultShareUnits': true});
      expect(g.members.firstWhere((m) => m.name == 'Sara').defaultShareUnits, isNull);
    });
  }

  testWidgets('the stepper stops at 100', (tester) async {
    final g = seedGroup(server, 'OWNER');
    g.members.firstWhere((m) => m.name == 'Sara').defaultShareUnits = 99;
    final l10n = await openMembers(tester, server);
    await openOptions(tester, l10n, 'Sara');
    await tester.tap(inSheet(find.text(l10n.membersActionDefaultShare)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pump();
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add)).onPressed, isNull);
    await tester.tap(find.widgetWithText(FilledButton, l10n.commonSave));
    await tester.pumpAndSettle();
    expect(server.memberPatches.last, {'defaultShareUnits': 100});
  });
}
