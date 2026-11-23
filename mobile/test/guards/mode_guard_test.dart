import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:qesma/core/app_mode.dart';
import 'package:qesma/core/features_for_mode.dart';
import 'scope_guard_test.dart' show copyViolations;

/// Per-mode scope guard (SA4, STANDALONE_SPEC 2 and 15). Build mode `local` must not be able to show a server-only
/// word, control or route. The runtime proof is `test/features/mode/local_mode_hidden_test.dart`; this guard is the
/// cheap early alarm that fails when new code reaches a server-only feature without going through `ModeFeatures`.

/// Words that never belong in the copy of a local-only screen (key prefixes in [localOnlyKeyPrefixes]).
const _localBannedWords = [
  'sign in', 'sign-in', 'signin', 'login', 'log in', 'google', 'password', 'account', 'email', 'invite', 'invitation', 'join',
  'owner', 'admin', 'role', 'remind', 'confirm', 'dispute', 'pending', 'notification', 'session', 'server', 'online',
];
const _localBannedArabic = ['تسجيل الدخول', 'جوجل', 'كلمة المرور', 'كلمة السر', 'حساب', 'دعوة', 'انضم', 'صلاحية', 'تذكير', 'نزاع', 'إشعار', 'سيرفر', 'أونلاين'];

/// ARB keys written for local mode only. Arabic "حساب" also means "calculation", so Arabic entries are checked on the
/// whole phrases above only for the account/sign-in meanings.
const localOnlyKeyPrefixes = ['onboarding'];

/// Symbols of server-only features. A file that mentions one must also go through the mode table (or `Permissions`,
/// which is built from it), unless it IS the server feature ([_serverFeatureFiles]).
final _serverSymbols = RegExp(
  r'showInviteSheet|JoinRequestsScreen|joinRequestsControllerProvider|ReceiverCard|IncomingPayments(Section|Banner)|'
  r'SettlementStatusChip|remindControllerProvider|Routes\.(join|joinCode|joinRequests|signIn|usernameSignIn|register|changePassword|accountSettings)\b|'
  r'confirmSignOut|AuthSessionExpired|SessionExpiredHost|membersRole(Owner|Admin)|membersTransfer|membersLeave|runTransferFlow|runLeaveFlow',
);
final _gate = RegExp(r'modeFeaturesProvider|ModeFeatures|permissions\.can|Permissions');

/// Files that are the server feature itself (reachable only through gated routes or gated callers).
const _serverFeatureFiles = <String, String>{
  'lib/features/auth/': 'sign-in, registration, session and splash: no route exists in local mode',
  'lib/features/invites/': 'invites and join: routes and entry points are gated',
  'lib/features/members/': 'join requests, member lifecycle and options: entry points are gated through Permissions',
  'lib/core/auth/': 'tokens, sessions and the local replacement',
  'lib/features/balances/application/remind_controller.dart': 'server Remind: its only caller is gated',
  'lib/features/balances/presentation/settlement_status_chip.dart': 'the chip widget itself: every use is gated',
  'lib/features/profile/presentation/account_settings_screen.dart': 'no route in local mode',
  'lib/core/features_for_mode.dart': 'the mode table',
  'lib/core/router/app_router.dart': 'the route table is checked by its own test below',
};

List<String> ungatedServerUses(Map<String, String> sources) {
  final hits = <String>[];
  sources.forEach((path, source) {
    final normalised = path.replaceAll(r'\', '/');
    if (normalised.startsWith('lib/local/') || normalised.contains('/generated/')) return;
    if (_serverFeatureFiles.keys.any(normalised.startsWith)) return;
    final match = _serverSymbols.firstMatch(source);
    if (match != null && !_gate.hasMatch(source)) hits.add('$normalised uses ${match.group(0)} without ModeFeatures/Permissions');
  });
  return hits;
}

/// Every route of a server-only screen in the route table sits under an `if (features.…)`.
List<String> ungatedServerRoutes(String router) {
  final lines = router.split('\n');
  final screens = RegExp(r'\b(JoinRequestsScreen|EnterCodeScreen|JoinScreen|SignInScreen|UsernameSignInScreen|RegisterScreen|ChangePasswordScreen|AccountSettingsScreen)\(');
  final hits = <String>[];
  for (var i = 0; i < lines.length; i++) {
    if (!screens.hasMatch(lines[i]) || lines[i].trimLeft().startsWith('import')) continue;
    final window = lines.sublist(i - 10 < 0 ? 0 : i - 10, i + 1).join('\n');
    if (!window.contains('if (features.')) hits.add('app_router.dart:${i + 1} ${lines[i].trim()}');
  }
  return hits;
}

/// ARB keys of the shares split (SA19). It works in both modes, so its copy must read right in local mode too.
bool _isSharesKey(String key) =>
    key.startsWith('shares') || key.startsWith('membersActionDefaultShare') || key.startsWith('membersDefaultShare') || key.startsWith('memberDefaultShare') || key == 'expenseSplitShares' || key == 'expenseFormSplitSubtitleShares';

/// Server-only words in the given strings (no key prefix filter).
List<String> serverWordsIn(Map<String, Map<String, dynamic>> arb, bool Function(String key) wanted) {
  final hits = <String>[];
  arb.forEach((lang, strings) {
    strings.forEach((key, value) {
      if (value is! String || key.startsWith('@') || !wanted(key)) return;
      final text = value.toLowerCase();
      for (final word in _localBannedWords) {
        if (RegExp('\\b${RegExp.escape(word)}\\b').hasMatch(text)) hits.add('$lang:$key contains "$word"');
      }
      for (final word in _localBannedArabic) {
        if (value.contains(word)) hits.add('$lang:$key contains "$word"');
      }
    });
  });
  return hits;
}

List<String> localCopyViolations(Map<String, Map<String, dynamic>> arb) {
  final hits = <String>[...copyViolations(arb, const <String>{})];
  arb.forEach((lang, strings) {
    strings.forEach((key, value) {
      if (value is! String || !localOnlyKeyPrefixes.any(key.startsWith)) return;
      final text = value.toLowerCase();
      for (final word in _localBannedWords) {
        if (RegExp('\\b${RegExp.escape(word)}\\b').hasMatch(text)) hits.add('$lang:$key contains "$word" (server-only word in local copy)');
      }
      for (final word in _localBannedArabic) {
        if (value.contains(word)) hits.add('$lang:$key contains "$word" (server-only word in local copy)');
      }
    });
  });
  return hits;
}

void main() {
  final arb = <String, Map<String, dynamic>>{
    'en': jsonDecode(File('lib/core/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>,
    'ar': jsonDecode(File('lib/core/l10n/app_ar.arb').readAsStringSync()) as Map<String, dynamic>,
  };
  final sources = <String, String>{
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')))
      file.path.replaceAll(r'\', '/'): file.readAsStringSync(),
  };

  test('the copy of local-only screens has no server-only word, in English or Arabic', () {
    final local = {
      for (final e in arb.entries) e.key: {for (final k in e.value.entries.where((k) => localOnlyKeyPrefixes.any(k.key.startsWith))) k.key: k.value},
    };
    expect(local['en']!.keys.where((k) => !k.startsWith('@')), isNotEmpty, reason: 'the local keys exist');
    final hits = localCopyViolations(local);
    expect(hits, isEmpty, reason: hits.join('\n'));
    expect(local['ar']!.keys.toSet(), local['en']!.keys.toSet().union(local['ar']!.keys.where((k) => k.startsWith('@')).toSet()));
  });

  test('the shares copy (SA19) has no server-only word: the feature works in local mode', () {
    final shares = {for (final e in arb.entries) e.key: {for (final k in e.value.entries.where((k) => _isSharesKey(k.key))) k.key: k.value}};
    expect(shares['en']!.keys.where((k) => !k.startsWith('@')).length, greaterThan(20), reason: 'the shares keys exist');
    final hits = serverWordsIn(shares, (_) => true);
    expect(hits, isEmpty, reason: hits.join('\n'));
    expect(serverWordsIn({'en': <String, dynamic>{'sharesX': 'Ask the owner to join'}}, _isSharesKey), isNotEmpty, reason: 'the check is alive');
  });

  test('every use of a server-only feature outside its own files goes through the mode table', () {
    final hits = ungatedServerUses(sources);
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('every server-only route of the route table is declared only when its feature is on', () {
    final hits = ungatedServerRoutes(sources['lib/core/router/app_router.dart']!);
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('the trip budget exists in local mode only (SA20): the tables, the route and both entry points are gated', () {
    expect(ModeFeatures.of(AppMode.server).budget, isFalse);
    expect(ModeFeatures.of(AppMode.local).budget, isTrue);
    expect(sources['lib/core/router/app_router.dart'], contains("if (features.budget) GoRoute(path: 'budget'"));
    expect(sources['lib/features/groups/presentation/group_home_screen.dart'], contains('modeFeaturesProvider).budget && group.budgetMinor != null'));
    expect(sources['lib/features/groups/presentation/edit_group_screen.dart'], contains('modeFeaturesProvider).budget;'));
    expect(sources['lib/features/groups/presentation/edit_group_screen.dart'], contains('if (budgetOn && _treasurerId == null) ...['));
    // A199: the create screen offers the budget choice only where the budget exists.
    expect(sources['lib/features/groups/presentation/create_group_screen.dart'], contains('if (features.budget)'));
  });

  group('the guard is alive', () {
    test('an ungated use of a server-only widget is caught; going through Permissions passes', () {
      expect(ungatedServerUses({'lib/features/groups/presentation/x.dart': 'onPressed: () => showInviteSheet(context)'}), isNotEmpty);
      expect(ungatedServerUses({'lib/features/groups/presentation/x.dart': 'if (permissions.canManageInvites) showInviteSheet(context)'}), isEmpty);
      expect(ungatedServerUses({'lib/features/groups/presentation/y.dart': 'context.push(Routes.join)'}), isNotEmpty);
      expect(ungatedServerUses({'lib/local/service/z.dart': 'Routes.join'}), isEmpty, reason: 'the local backend is not UI');
    });

    test('an ungated server route is caught', () {
      expect(ungatedServerRoutes("GoRoute(path: '/x', builder: (c, s) => const JoinScreen()),"), isNotEmpty);
      expect(ungatedServerRoutes("if (features.joinByCode) GoRoute(path: '/x', builder: (c, s) => const JoinScreen()),"), isEmpty);
    });

    test('a server-only word in local copy is caught in both languages', () {
      expect(localCopyViolations({'en': <String, dynamic>{'onboardingX': 'Sign in with Google'}}), isNotEmpty);
      expect(localCopyViolations({'ar': <String, dynamic>{'onboardingX': 'سجّل بحساب جوجل'}}), isNotEmpty);
      expect(localCopyViolations({'en': <String, dynamic>{'onboardingX': 'What is your name?'}}), isEmpty);
    });
  });
}
