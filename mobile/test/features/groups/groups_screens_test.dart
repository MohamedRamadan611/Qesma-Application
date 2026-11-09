import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/app.dart';
import 'package:qesma/core/l10n/locale_controller.dart';
import 'package:qesma/core/theme/tokens.dart';
import 'package:qesma/core/widgets/widgets.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../support/auth_ui.dart';
import '../../support/fake_groups_server.dart';
import '../../support/groups_rig.dart';
import '../../support/test_app.dart';

final UserDto _user = UserDto((b) => b
  ..id = 'u1'
  ..displayName = 'Test User');

/// The whole real app (router, guard, controllers, repository, generated client) on the
/// fake groups server, signed in. Returns the container for inspection.
Future<ProviderContainer> pumpGroupsApp(
  WidgetTester tester,
  FakeGroupsServer server, {
  Locale locale = const Locale('ar'),
  double textScale = 1.0,
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(360, 800);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final container = groupsContainer(
    server,
    autoLoad: true,
    extra: [authControllerProvider.overrideWith(() => StubAuth(AuthSignedIn(_user)))],
  );
  addTearDown(container.dispose);
  container.read(localeProvider.notifier).set(locale);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const QesmaApp()));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return container;
}

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).first;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String _t(Config c, String ar, String en) => c.locale.languageCode == 'ar' ? ar : en;

void main() {
  setUpAll(loadAppFonts);

  late FakeGroupsServer server;
  setUp(() => server = FakeGroupsServer());

  group('groups list', () {
    testWidgets('cards show name, type, member count, total and the owed / owes / settled words', (tester) async {
      server
        ..seed(name: 'رحلة دهب', type: 'TRIP', total: 425000, net: 65000, lastExpenseAt: DateTime.utc(2026, 10, 18, 12))
        ..seed(name: 'شقة المهندسين', type: 'HOUSING', total: 890000, net: -32000)
        ..seed(name: 'عشا الخميس', type: 'OUTING', total: 56179, net: 0);
      await pumpGroupsApp(tester, server);

      expect(find.text('المجموعات'), findsOneWidget);
      for (final name in ['رحلة دهب', 'شقة المهندسين', 'عشا الخميس']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.textContaining('له '), findsWidgets);
      expect(find.textContaining('عليه '), findsWidgets);
      expect(find.textContaining('خالص'), findsWidgets);
      expect(find.text('آخر نشاط: ${isolated('2026-10-18')}'), findsOneWidget);
      expect(find.text('لسه مفيش مصاريف'), findsNWidgets(2));
      expect(find.text('جروب جديد'), findsOneWidget);
    });

    testWidgets('the net header appears when every group is loaded and shares a currency', (tester) async {
      server
        ..seed(net: 6500)
        ..seed(net: -3200);
      await pumpGroupsApp(tester, server);
      expect(find.text('صافي رصيدك في كل الجروبات'), findsOneWidget);
    });

    testWidgets('empty list: friendly empty state whose button opens create', (tester) async {
      await pumpGroupsApp(tester, server);
      expect(find.text('مفيش جروبات لسه'), findsOneWidget);
      await tapText(tester, 'جروب جديد');
      expect(find.text('إنشاء جروب جديد'), findsOneWidget);
    });

    testWidgets('while loading the skeleton shows; offline shows the no-internet state and retry recovers', (tester) async {
      server.seed(name: 'Dahab');
      server.offline = true;
      await pumpGroupsApp(tester, server, settle: false);
      expect(find.byType(SkeletonList), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('مفيش اتصال بالإنترنت'), findsOneWidget);

      server.offline = false;
      await tapText(tester, 'حاول تاني');
      expect(find.text('Dahab'), findsOneWidget);
    });

    testWidgets('scrolling to the end loads the next page once', (tester) async {
      for (var i = 0; i < 25; i++) {
        server.seed(name: 'Group $i');
      }
      await pumpGroupsApp(tester, server);
      expect(server.requests.where((r) => r.contains('page=1')), isEmpty);
      await tester.drag(find.byType(ListView).first, const Offset(0, -6000));
      await tester.pumpAndSettle();
      expect(server.requests.where((r) => r.contains('page=1')), hasLength(1));
      await tester.drag(find.byType(ListView).first, const Offset(0, -6000));
      await tester.pumpAndSettle();
      expect(find.text('Group 24'), findsOneWidget);
    });

    testWidgets('the temporary overflow menu offers sign out', (tester) async {
      server.seed();
      await pumpGroupsApp(tester, server);
      await tester.tap(find.byTooltip('المزيد'));
      await tester.pumpAndSettle();
      expect(find.text('تسجيل الخروج'), findsOneWidget);
    });

    for (final c in allConfigs) {
      testWidgets('fits at ${c.name}: list with long names, 48 px targets', (tester) async {
        server
          ..seed(name: _t(c, 'رحلة الأصدقاء الطويلة جدًا إلى شرم الشيخ ودهب ونويبع', 'A very long group name for the trip to Sharm, Dahab and Nuweiba'), total: 123456789, net: -123456)
          ..seed(name: 'B', net: 5);
        await pumpGroupsApp(tester, server, locale: c.locale, textScale: c.textScale);
        expect(tester.takeException(), isNull);
        final fab = find.byType(FloatingActionButton);
        expect(tester.getSize(fab).height, greaterThanOrEqualTo(kMinTouch));
      });
    }

    testWidgets('a card is one spoken sentence for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      server.seed(name: 'Dahab', type: 'TRIP', total: 8000, net: -2000);
      await pumpGroupsApp(tester, server);
      expect(find.bySemanticsLabel(RegExp(r'Dahab، رحلة، عضو واحد، إجمالي المصاريف 80 جنيه، عليه 20 جنيه')), findsOneWidget);
      handle.dispose();
    });
  });

  group('create group', () {
    Future<void> openCreate(WidgetTester tester, {Locale locale = const Locale('ar'), double scale = 1.0}) async {
      await pumpGroupsApp(tester, server, locale: locale, textScale: scale);
      await tapText(tester, locale.languageCode == 'ar' ? 'جروب جديد' : 'New group');
    }

    testWidgets('name counter counts to 60, EGP is fixed, the button needs a name, there is no contacts or photo option', (tester) async {
      await openCreate(tester);
      expect(find.text('0/60'), findsOneWidget);
      expect(find.text('جنيه مصري (ج.م)'), findsOneWidget);
      expect(find.textContaining('جهات الاتصال'), findsNothing);
      final button = find.widgetWithText(FilledButton, 'إنشاء الجروب');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, 'رحلة سيوة');
      await tester.pump();
      expect(find.text('9/60'), findsOneWidget);
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    });

    testWidgets('submitting creates the group and opens it with the chosen type', (tester) async {
      await openCreate(tester);
      await tester.enterText(find.byType(TextField).first, 'رحلة سيوة');
      await tapText(tester, 'سكن');
      await tapText(tester, 'إنشاء الجروب');
      expect(server.groups.values.single.name, 'رحلة سيوة');
      expect(server.groups.values.single.type, 'HOUSING');
      expect(find.text('رحلة سيوة'), findsWidgets);
      expect(find.text('الأعضاء'), findsOneWidget, reason: 'now on the group home shell');
    });

    testWidgets('a lost response still ends on the new group, and only one exists', (tester) async {
      await openCreate(tester);
      server.nextCreateFault = CreateFault.loseResponseAfterStoring;
      await tester.enterText(find.byType(TextField).first, 'رحلة سيوة');
      await tester.pump();
      await tapText(tester, 'إنشاء الجروب');
      expect(server.groups, hasLength(1));
      expect(find.text('الأعضاء'), findsOneWidget);
    });

    testWidgets('a failed create shows the message in place and the form keeps its input', (tester) async {
      await openCreate(tester);
      server.nextCreateFault = CreateFault.validation;
      await tester.enterText(find.byType(TextField).first, 'x');
      await tester.pump();
      await tapText(tester, 'إنشاء الجروب');
      expect(find.textContaining('في بيانات مش مظبوطة'), findsOneWidget);
      expect(find.text('x'), findsOneWidget);
    });

    for (final c in allConfigs) {
      testWidgets('fits at ${c.name}', (tester) async {
        await openCreate(tester, locale: c.locale, scale: c.textScale);
        expect(tester.takeException(), isNull);
        expect(find.text(_t(c, 'إنشاء الجروب', 'Create group'), skipOffstage: false), findsOneWidget);
      });
    }
  });

  group('group home, edit and delete', () {
    testWidgets('shell: header, tabs in RTL order, the Balances stub is marked, members tab works', (tester) async {
      server.seed(name: 'Dahab', type: 'TRIP', total: 106179);
      await pumpGroupsApp(tester, server);
      await tapText(tester, 'Dahab');

      expect(find.text('Dahab'), findsWidgets);
      final expenses = tester.getCenter(find.text('المصاريف'));
      final balances = tester.getCenter(find.text('الأرصدة'));
      final members = tester.getCenter(find.text('الأعضاء'));
      expect(expenses.dx, greaterThan(balances.dx), reason: 'Arabic: the first tab sits on the right');
      expect(balances.dx, greaterThan(members.dx));
      expect(find.text('الشاشة دي لسه تحت الإنشاء.'), findsNothing, reason: 'the Expenses tab is the real list since FL4');
      await tapText(tester, 'الأرصدة');
      expect(find.text('الشاشة دي لسه تحت الإنشاء.'), findsOneWidget);

      await tapText(tester, 'الأعضاء');
      expect(find.text('Me'), findsOneWidget);
      expect(find.text('(أنت)'), findsOneWidget);
    });

    testWidgets('the owner member can be renamed but is never offered for deletion', (tester) async {
      server.seed(name: 'Dahab');
      await pumpGroupsApp(tester, server);
      await tapText(tester, 'Dahab');
      await tapText(tester, 'الأعضاء');
      await tester.tap(find.byTooltip('خيارات Me'));
      await tester.pumpAndSettle();
      expect(find.text('تغيير الاسم'), findsOneWidget);
      expect(find.text('مسح العضو'), findsNothing);
    });

    testWidgets('add member: saved; the same name again shows the inline duplicate error with the suggestion', (tester) async {
      final g = server.seed(name: 'Dahab');
      await pumpGroupsApp(tester, server);
      await tapText(tester, 'Dahab');
      await tapText(tester, 'الأعضاء');

      await tapText(tester, 'إضافة عضو');
      await tester.enterText(find.byType(TextField).last, 'عاصم');
      await tester.pump();
      await tapText(tester, 'حفظ العضو');
      expect(g.members.map((m) => m.name), contains('عاصم'));
      expect(find.text('عاصم'), findsOneWidget);

      await tapText(tester, 'إضافة عضو');
      await tester.enterText(find.byType(TextField).last, 'عاصم');
      await tester.pump();
      await tapText(tester, 'حفظ العضو');
      expect(find.textContaining('«عاصم» موجود قبل كده'), findsOneWidget);
      expect(g.members.where((m) => m.name == 'عاصم'), hasLength(1));
    });

    testWidgets('deleting a member with transactions shows the blocked dialog', (tester) async {
      final g = server.seed(name: 'Dahab');
      g.members.add(FakeMember(id: 'g1-m2', name: 'Asem', hasTransactions: true, sortOrder: 2));
      await pumpGroupsApp(tester, server);
      await tapText(tester, 'Dahab');
      await tapText(tester, 'الأعضاء');
      await tester.tap(find.byTooltip('خيارات Asem'));
      await tester.pumpAndSettle();
      await tapText(tester, 'مسح العضو');
      await tapText(tester, 'امسح'); // confirm
      expect(find.text('مينفعش نمسح العضو'), findsOneWidget);
      expect(g.members, hasLength(2));
    });

    testWidgets('edit: a conflict opens the dialog; reloading keeps what the user typed; saving again works', (tester) async {
      final g = server.seed(name: 'Dahab');
      await pumpGroupsApp(tester, server);
      await tapText(tester, 'Dahab');
      await tester.tap(find.byTooltip('تعديل الجروب'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'تعديلي');
      await tester.pump();
      g
        ..name = 'اتعدل من مكان تاني'
        ..version = 2;

      await tapText(tester, 'حفظ التعديلات');
      expect(find.text('اتعدّل من مكان تاني'), findsOneWidget);
      await tapText(tester, 'حمّل آخر نسخة');
      expect(find.text('تعديلي'), findsOneWidget, reason: 'the typed input stays');

      await tapText(tester, 'حفظ التعديلات');
      expect(g.name, 'تعديلي');
    });

    testWidgets('delete: confirm, then blocked when the group has expenses (with the recorded total)', (tester) async {
      server.seed(name: 'Dahab', hasExpenses: true, total: 106179);
      await pumpGroupsApp(tester, server);
      await tapText(tester, 'Dahab');
      await tester.tap(find.byTooltip('تعديل الجروب'));
      await tester.pumpAndSettle();
      await tapText(tester, 'امسح الجروب');
      expect(find.text('مسح الجروب؟'), findsOneWidget);
      await tapText(tester, 'امسح');
      expect(find.text('مينفعش نمسح المجموعة'), findsOneWidget);
      expect(find.textContaining('إجمالي المصاريف المسجلة'), findsOneWidget);
      expect(server.groups, hasLength(1));
    });

    testWidgets('delete of an empty group returns to the list without it', (tester) async {
      server.seed(name: 'Dahab');
      server.seed(name: 'Keep');
      await pumpGroupsApp(tester, server);
      await tapText(tester, 'Dahab');
      await tester.tap(find.byTooltip('تعديل الجروب'));
      await tester.pumpAndSettle();
      await tapText(tester, 'امسح الجروب');
      await tapText(tester, 'امسح');
      expect(find.text('المجموعات'), findsOneWidget);
      expect(find.text('Dahab'), findsNothing);
      expect(find.text('Keep'), findsOneWidget);
    });

    testWidgets('a group that no longer exists shows "no longer available" with a way back', (tester) async {
      server.seed(name: 'Dahab');
      await pumpGroupsApp(tester, server);
      await tapText(tester, 'Dahab');
      // Open the edit screen, then the group disappears on the server.
      server.groups.clear();
      await tester.tap(find.byTooltip('تعديل الجروب'));
      await tester.pumpAndSettle();
      expect(find.text('الجروب ده مبقاش متاح.'), findsOneWidget);
      await tapText(tester, 'الرجوع للمجموعات');
      expect(find.text('المجموعات'), findsOneWidget);
    });

    for (final c in allConfigs) {
      testWidgets('shell, members and edit fit at ${c.name}', (tester) async {
        final g = server.seed(name: _t(c, 'رحلة دهب', 'Dahab trip'));
        g.members.add(FakeMember(id: 'g1-m2', name: _t(c, 'عاصم عبد الرحمن الطويل جدًا', 'Asem with a very long family name'), sortOrder: 2));
        await pumpGroupsApp(tester, server, locale: c.locale, textScale: c.textScale);
        await tapText(tester, _t(c, 'رحلة دهب', 'Dahab trip'));
        expect(tester.takeException(), isNull);
        await tapText(tester, _t(c, 'الأعضاء', 'Members'));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip(_t(c, 'تعديل الجروب', 'Edit group')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('nothing omitted from the design is built', () {
    const forbiddenAr = ['صورة', 'كاميرا', 'جهات الاتصال', 'دعوة', 'أدمن', 'ادمن', 'لون', 'شهري', 'جاهز للتسوية', 'سدد الآن'];
    const forbiddenEn = ['photo', 'camera', 'contacts', 'cover', 'invite', 'admin', 'monthly', 'ready to settle', 'colour', 'color', 'pay now'];

    test('neither ARB file has such copy', () {
      for (final (file, words) in [('ar', forbiddenAr), ('en', forbiddenEn)]) {
        final arb = jsonDecode(File('lib/core/l10n/app_$file.arb').readAsStringSync()) as Map<String, dynamic>;
        for (final entry in arb.entries.where((e) => !e.key.startsWith('@'))) {
          for (final word in words) {
            expect((entry.value as String).toLowerCase(), isNot(contains(word)), reason: '${entry.key} in $file');
          }
        }
      }
    });

    testWidgets('no screen shows such text, bell, photo button or avatar stack', (tester) async {
      final g = server.seed(name: 'Dahab');
      g.members.add(FakeMember(id: 'g1-m2', name: 'Asem', sortOrder: 2));
      await pumpGroupsApp(tester, server);

      String allText() => tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').join(' | ');
      void check(String where) {
        final text = allText();
        for (final word in forbiddenAr) {
          expect(text, isNot(contains(word)), reason: where);
        }
        expect(find.byIcon(Icons.notifications_none), findsNothing, reason: where);
        expect(find.byIcon(Icons.camera_alt), findsNothing, reason: where);
        expect(find.byIcon(Icons.photo_camera), findsNothing, reason: where);
      }

      check('list');
      await tapText(tester, 'Dahab');
      check('shell');
      await tapText(tester, 'الأعضاء');
      check('members');
      await tester.tap(find.byTooltip('تعديل الجروب'));
      await tester.pumpAndSettle();
      check('edit');
    });
  });
}
