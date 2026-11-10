import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/app.dart';
import 'package:qesma/core/format/clock.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/l10n/locale_controller.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/widgets/widgets.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma/features/expenses/application/expense_preview_controller.dart';
import 'package:qesma_api/qesma_api.dart';

import 'auth_ui.dart';
import 'expenses_rig.dart';
import 'fake_expenses_server.dart';

final UserDto _user = UserDto((b) => b
  ..hasPassword = false
  ..emailVerified = true
  ..id = 'u1'
  ..displayName = 'Test User'
  ..email = 'test@example.com');

/// "Today" in the widget tests, so the list headers say "Today" / "Yesterday" predictably.
final DateTime testNow = DateTime(2026, 10, 18, 12);

/// The whole real app (router, guard, controllers, repository, generated client) on the
/// fake expenses server, signed in, standing on the group home (Expenses tab).
Future<ProviderContainer> pumpExpensesApp(
  WidgetTester tester,
  FakeExpensesServer server, {
  Locale locale = const Locale('ar'),
  double textScale = 1.0,
  bool settle = true,
  String? route,
  double height = 2400,
  List<Override> overrides = const [],
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(360, height);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final container = expensesContainer(
    server,
    autoLoad: true,
    extra: [
      authControllerProvider.overrideWith(() => StubAuth(AuthSignedIn(_user))),
      clockProvider.overrideWithValue(() => testNow),
      // A zero debounce keeps widget tests quick; the 300 ms rule itself is tested on the controller.
      previewDebounceProvider.overrideWithValue(Duration.zero),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  container.read(localeProvider.notifier).set(locale);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const QesmaApp()));
  await tester.pumpAndSettle();
  container.read(routerProvider).go(route ?? Routes.group(server.gid));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return container;
}

AppLocalizations l10nFor(Locale locale) => lookupAppLocalizations(locale);

/// What the app writes for an amount (the same formatter, fed the fixture's integer).
String money(Locale locale, int minor, {bool signed = false}) => moneyDisplay(l10nFor(locale), minor, signed: signed);

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).first;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Scrolls the page until [finder] is on screen.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

String t(Locale locale, String ar, String en) => locale.languageCode == 'ar' ? ar : en;

/// Lets debounced previews, their replies and the rebuilds they cause finish.
Future<void> settleForm(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 5));
    await tester.pumpAndSettle();
  }
}
