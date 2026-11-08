import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/groups/presentation/create_group_screen.dart';
import '../../features/groups/presentation/edit_group_screen.dart';
import '../../features/groups/presentation/group_home_screen.dart';
import '../../features/groups/presentation/groups_list_screen.dart';
import '../widgets/catalogue/component_catalogue.dart';

/// Route paths in one place.
abstract final class Routes {
  static const String home = '/';
  static const String newGroup = '/groups/new';
  static String group(String gid) => '/groups/$gid';
  static String editGroup(String gid) => '/groups/$gid/edit';
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String signIn = '/sign-in';

  /// Debug-only component catalogue. Declared only when [kDebugMode] is true, so it does
  /// not exist in release builds (a guard test checks this).
  static const String catalogue = '/_catalog';
}

/// The navigator the session-expired dialog is shown on (it must outlive any screen).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Debug builds can start on any route: `flutter run --dart-define=INITIAL_ROUTE=/_catalog`.
/// Ignored in release builds.
const String _initialRouteDefine = String.fromEnvironment('INITIAL_ROUTE');

const Set<String> _authPaths = {Routes.splash, Routes.welcome, Routes.signIn};

/// Where to go after signing in. Only an in-app absolute path is accepted, so a crafted
/// `from` value can never redirect to another site (open redirect) or back into the auth screens.
String? safeReturnLocation(String? raw) {
  if (raw == null || raw.isEmpty || raw.length > 300) return null;
  if (!raw.startsWith('/') || raw.startsWith('//') || raw.contains(r'\') || raw.codeUnits.any((c) => c < 0x20)) return null;
  final uri = Uri.tryParse(raw);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  if (_authPaths.contains(uri.path)) return null;
  return raw;
}

String? _returnLocationOf(Uri location) {
  final text = location.toString();
  return text == Routes.home ? null : safeReturnLocation(text);
}

String _withFrom(String path, String? from) =>
    from == null ? path : Uri(path: path, queryParameters: {'from': from}).toString();

/// The route guard (client-side authorization is route guards only). Pure, so it is
/// tested as a table. Returns the location to redirect to, or null to stay.
String? authRedirect(AuthState state, Uri location) {
  final path = location.path;
  final isAuthPath = _authPaths.contains(path);
  final isPublic = isAuthPath || (kDebugMode && path == Routes.catalogue);
  final carried = location.queryParameters['from'];

  switch (state) {
    case AuthRestoring() || AuthRestoreFailed():
      if (path == Routes.splash) return null;
      return _withFrom(Routes.splash, isAuthPath ? safeReturnLocation(carried) : _returnLocationOf(location));
    case AuthSignedOut():
      if (path == Routes.splash) return _withFrom(Routes.welcome, safeReturnLocation(carried));
      if (isPublic) return null;
      return _withFrom(Routes.welcome, _returnLocationOf(location));
    case AuthSigningIn():
      return null;
    case AuthSignedIn():
      return isAuthPath ? (safeReturnLocation(carried) ?? Routes.home) : null;
    case AuthSessionExpired():
      return null; // the dialog is shown over whatever the user was doing
  }
}

class _AuthRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh();
  ref.listen<AuthState>(authControllerProvider, (previous, next) => refresh.ping());
  final initial = kDebugMode && _initialRouteDefine.isNotEmpty ? _initialRouteDefine : Routes.home;
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initial,
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(ref.read(authControllerProvider), state.uri),
    routes: [
      GoRoute(path: Routes.home, builder: (context, state) => const GroupsListScreen()),
      GoRoute(path: Routes.newGroup, builder: (context, state) => const CreateGroupScreen()),
      GoRoute(
        path: '/groups/:gid',
        builder: (context, state) => GroupHomeScreen(gid: state.pathParameters['gid']!, initialTab: state.uri.queryParameters['tab']),
        routes: [
          GoRoute(path: 'edit', builder: (context, state) => EditGroupScreen(gid: state.pathParameters['gid']!)),
        ],
      ),
      GoRoute(path: Routes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: Routes.welcome, builder: (context, state) => WelcomeScreen(from: state.uri.queryParameters['from'])),
      GoRoute(path: Routes.signIn, builder: (context, state) => const SignInScreen()),
      if (kDebugMode) GoRoute(path: Routes.catalogue, builder: (context, state) => const ComponentCatalogue()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
