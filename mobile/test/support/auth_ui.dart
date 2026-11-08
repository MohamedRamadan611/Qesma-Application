import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/theme/app_theme.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma/features/auth/presentation/auth_widgets.dart';
import 'package:qesma/features/auth/presentation/session_expired_dialog.dart';

/// A controller that only records what the screens ask for.
class StubAuth extends AuthController {
  StubAuth(this.initial);

  final AuthState initial;
  int googleTaps = 0;
  int fakeTaps = 0;
  int leaves = 0;
  int restores = 0;

  @override
  AuthState build() => initial;

  void set(AuthState next) => state = next;

  @override
  Future<void> signInWithGoogle() async => googleTaps++;

  @override
  Future<void> signInWithIdToken(String idToken) async => fakeTaps++;

  @override
  void leaveExpiredSession() => leaves++;

  @override
  Future<void> restore() async => restores++;
}

late StubAuth stub;

/// Pumps [screen] as the home of a router, so `context.go` works.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen,
  AuthState state, {
  Locale locale = const Locale('ar'),
  double textScale = 1.0,
  Future<bool> Function(Uri)? opener,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(360, 800);
  addTearDown(tester.view.reset);
  stub = StubAuth(state);
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(path: '/', builder: (context, _) => screen),
      GoRoute(path: Routes.signIn, builder: (context, _) => const Scaffold(body: Text('SIGN-IN-PAGE'))),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => stub),
        if (opener != null) urlOpenerProvider.overrideWithValue(opener),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: buildAppTheme(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: true),
          child: SessionExpiredHost(child: child!),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

