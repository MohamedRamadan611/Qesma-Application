import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/username_auth_screens.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/expenses/presentation/expense_details_screen.dart';
import '../../features/expenses/presentation/expense_form_screen.dart';
import '../../features/groups/presentation/create_group_screen.dart';
import '../../features/groups/presentation/edit_group_screen.dart';
import '../../features/groups/presentation/group_home_screen.dart';
import '../../features/groups/presentation/groups_list_screen.dart';
import '../../features/invites/application/invite_code.dart';
import '../../features/invites/application/pending_invite.dart';
import '../../features/invites/presentation/enter_code_screen.dart';
import '../../features/invites/presentation/join_screen.dart';
import '../../features/profile/presentation/account_settings_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_hub_screen.dart';
import '../widgets/main_shell.dart';
import '../widgets/catalogue/component_catalogue.dart';

/// Route paths in one place.
abstract final class Routes {
  static const String home = '/';
  static const String newGroup = '/groups/new';
  static const String account = '/account';
  static const String editProfile = '/account/edit';
  static const String accountSettings = '/account/settings';
  static String group(String gid) => '/groups/$gid';
  static String editGroup(String gid) => '/groups/$gid/edit';
  static String addExpense(String gid) => '/groups/$gid/expenses/new';
  static String expense(String gid, String eid) => '/groups/$gid/expenses/$eid';
  static String editExpense(String gid, String eid) => '/groups/$gid/expenses/$eid/edit';
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String signIn = '/sign-in';
  static const String usernameSignIn = '/sign-in/username';
  static const String register = '/sign-in/register';
  static const String changePassword = '/account/password';

  /// Code entry (fallback of the join flow) and the App Link path `https://<host>/join/<code>`.
  static const String join = '/join';
  static String joinCode(String code) => '/join/$code';

  /// Debug-only component catalogue. Declared only when [kDebugMode] is true, so it does
  /// not exist in release builds (a guard test checks this).
  static const String catalogue = '/_catalog';
}

/// The navigator the session-expired dialog is shown on (it must outlive any screen).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Debug builds can start on any route: `flutter run --dart-define=INITIAL_ROUTE=/_catalog`.
/// Ignored in release builds.
const String _initialRouteDefine = String.fromEnvironment('INITIAL_ROUTE');

const Set<String> _authPaths = {Routes.splash, Routes.welcome, Routes.signIn, Routes.usernameSignIn, Routes.register};

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
///
/// [pendingInvite] is an invite code that waited for sign-in (FL11): once signed in, a person who lands on home or on
/// an auth screen without a return location is sent to the join screen of that code.
String? authRedirect(AuthState state, Uri location, {String? pendingInvite}) {
  final path = location.path;
  final pendingJoin = pendingInvite == null ? null : Routes.joinCode(pendingInvite);
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
      if (isAuthPath) return safeReturnLocation(carried) ?? pendingJoin ?? Routes.home;
      if (path == Routes.home && pendingJoin != null) return pendingJoin;
      return null;
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
  // A code left by a killed process; a code remembered now makes the router look again.
  ref.listen<PendingInviteState>(pendingInviteProvider, (previous, next) => refresh.ping());
  Future.microtask(() async {
    await ref.read(pendingInviteProvider.notifier).restore();
  });
  final initial = kDebugMode && _initialRouteDefine.isNotEmpty ? _initialRouteDefine : Routes.home;
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initial,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final pending = ref.read(pendingInviteProvider);
      // A signed-out person opening an invite link: keep the code (memory and secure storage, never logged) until
      // it is used, so it survives sign-in even if the process dies during the Google picker.
      if (auth is! AuthSignedIn) {
        final code = codeFromJoinPath(state.uri.path);
        if (code != null) Future.microtask(() => ref.read(pendingInviteProvider.notifier).remember(code));
      }
      return authRedirect(auth, state.uri, pendingInvite: pending.delivered ? null : pending.code);
    },
    routes: [
      // The two top-level tabs share the bottom bar; everything pushed from them covers it.
      ShellRoute(
        builder: (context, state, child) => MainShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: Routes.home, builder: (context, state) => const GroupsListScreen()),
          GoRoute(path: Routes.account, builder: (context, state) => const ProfileHubScreen()),
        ],
      ),
      GoRoute(path: Routes.editProfile, builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: Routes.accountSettings, builder: (context, state) => const AccountSettingsScreen()),
      GoRoute(path: Routes.newGroup, builder: (context, state) => const CreateGroupScreen()),
      GoRoute(
        path: '/groups/:gid',
        builder: (context, state) => GroupHomeScreen(gid: state.pathParameters['gid']!, initialTab: state.uri.queryParameters['tab']),
        routes: [
          GoRoute(path: 'edit', builder: (context, state) => EditGroupScreen(gid: state.pathParameters['gid']!)),
          // 'expenses/new' must stay before 'expenses/:eid' (first match wins).
          GoRoute(path: 'expenses/new', builder: (context, state) => ExpenseFormScreen(gid: state.pathParameters['gid']!)),
          GoRoute(
            path: 'expenses/:eid',
            builder: (context, state) => ExpenseDetailsScreen(gid: state.pathParameters['gid']!, eid: state.pathParameters['eid']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => ExpenseFormScreen(gid: state.pathParameters['gid']!, eid: state.pathParameters['eid']),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: Routes.join, builder: (context, state) => const EnterCodeScreen()),
      GoRoute(
        path: '${Routes.join}/:codeOrToken',
        builder: (context, state) {
          final raw = state.pathParameters['codeOrToken'] ?? '';
          final code = normaliseInviteCode(raw);
          // A link whose code cannot be right: the entry screen shows the error and nothing is stored or sent.
          return code == null ? EnterCodeScreen(initial: raw, invalid: true) : JoinScreen(code: code);
        },
      ),
      GoRoute(path: Routes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: Routes.welcome, builder: (context, state) => WelcomeScreen(from: state.uri.queryParameters['from'])),
      GoRoute(path: Routes.signIn, builder: (context, state) => const SignInScreen()),
      GoRoute(path: Routes.usernameSignIn, builder: (context, state) => const UsernameSignInScreen()),
      GoRoute(path: Routes.register, builder: (context, state) => const RegisterScreen()),
      GoRoute(path: Routes.changePassword, builder: (context, state) => const ChangePasswordScreen()),
      if (kDebugMode) GoRoute(path: Routes.catalogue, builder: (context, state) => const ComponentCatalogue()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
