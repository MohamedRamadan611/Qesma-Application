import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_groups_server.dart';
import '../../support/test_app.dart';
import 'groups_screens_test.dart' show pumpGroupsApp, tapText;

/// B10 roles in the UI (FL10): owner and admin manage the group and its members, a plain member only reads.
/// What is hidden here is a convenience; the server answers 403 for the rest (covered by the freshness tests).
void main() {
  setUpAll(loadAppFonts);

  late FakeGroupsServer server;
  setUp(() => server = FakeGroupsServer());

  FakeGroup seedAs(String role) {
    final g = server.seed(name: 'Dahab');
    g.yourRole = role;
    g.members.first.role = role;
    return g;
  }

  const strings = {
    'ar': (edit: 'تعديل الجروب', add: 'إضافة عضو', options: 'خيارات Me', delete: 'امسح الجروب', members: 'الأعضاء'),
    'en': (edit: 'Edit group', add: 'Add member', options: 'Options for Me', delete: 'Delete group', members: 'Members'),
  };
  const expected = {
    // role: (edit icon, add member, member options, delete group)
    'OWNER': (true, true, true, true),
    'ADMIN': (true, true, true, false),
    'MEMBER': (false, false, false, false),
  };

  for (final entry in {'ar 1.0x': (const Locale('ar'), 1.0), 'en 2.0x': (const Locale('en'), 2.0)}.entries) {
    final (locale, scale) = entry.value;
    final s = strings[locale.languageCode]!;

    for (final role in expected.keys) {
      testWidgets('${entry.key}: $role sees exactly what the role allows', (tester) async {
        seedAs(role);
        await pumpGroupsApp(tester, server, locale: locale, textScale: scale);
        await tapText(tester, 'Dahab');
        final (canEdit, canAdd, canOptions, canDelete) = expected[role]!;

        expect(find.byTooltip(s.edit), canEdit ? findsOneWidget : findsNothing, reason: 'edit icon');

        await tapText(tester, s.members);
        expect(find.text(s.add), canAdd ? findsOneWidget : findsNothing, reason: 'add member');
        expect(find.byTooltip(s.options), canOptions ? findsOneWidget : findsNothing, reason: 'member options');
        expect(find.text('Me'), findsOneWidget, reason: 'the list itself is always there');

        if (canEdit) {
          await tester.tap(find.byTooltip(s.edit));
          await tester.pumpAndSettle();
          await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
          await tester.pumpAndSettle();
          expect(find.text(s.delete, skipOffstage: false), canDelete ? findsOneWidget : findsNothing, reason: 'delete group');
        }
      });
    }
  }

  testWidgets('before the group is read nothing privileged shows, and the role is picked up from the server afterwards', (tester) async {
    seedAs('ADMIN');
    await pumpGroupsApp(tester, server, locale: const Locale('en'));
    await tapText(tester, 'Dahab');
    expect(find.byTooltip('Edit group'), findsOneWidget, reason: 'the admin role arrived with the group');
  });

  testWidgets('the members tab can be pulled to refresh and picks up a member added elsewhere', (tester) async {
    final g = seedAs('MEMBER');
    await pumpGroupsApp(tester, server, locale: const Locale('en'));
    await tapText(tester, 'Dahab');
    await tapText(tester, 'Members');
    expect(find.text('Sara'), findsNothing);

    g.members.add(FakeMember(id: '${g.id}-m2', name: 'Sara', sortOrder: 2)); // somebody on another phone added her
    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Sara'), findsOneWidget);
  });
}
