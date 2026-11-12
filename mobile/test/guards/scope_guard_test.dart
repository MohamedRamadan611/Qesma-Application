import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Scope audit (FL9, reworked in FL10). `.claude/mobile/SCREEN_MAP.md` lists the elements of the designs that are NOT
/// built: some are omitted for good (guest mode, receipt scan, export, ...), the others are Phase 2 features that
/// arrive one prompt at a time. This guard fails if a user-visible string, an icon or a route of a feature that is not
/// built yet reaches the app: not disabled, not faked, not "coming soon".
///
/// How to enable a Phase 2 feature: the prompt that builds it (FL11 invites, FL13 settlements, FL14 handles and
/// reminders, FL15 notifications, FL16 account deletion) adds the feature name to [enabledFeatures], in the same
/// commit as its screens. The permanently omitted elements are never enabled.
const enabledFeatures = <String>{'invites'}; // FL11: invite sheet, join screen, code entry

/// Words, Arabic words, phrases, icons and routes of one Phase 2 feature.
class Phase2Feature {
  const Phase2Feature({this.words = const [], this.arabic = const [], this.phrases = const [], this.icons = const [], this.routes = const []});

  final List<String> words;
  final List<String> arabic;
  final List<String> phrases;
  final List<String> icons;
  final List<String> routes;
}

const phase2Features = <String, Phase2Feature>{
  'invites': Phase2Feature(
    words: ['invite', 'invitation'],
    arabic: ['دعوة'],
    icons: ['Icons.share', 'Icons.person_add', 'Icons.group_add'],
    routes: ["'/invite"],
  ),
  'settlements': Phase2Feature(words: ['dispute'], arabic: ['نزاع'], routes: ["'/disputes"]),
  'handles': Phase2Feature(words: ['instapay', 'wallet']),
  'reminders': Phase2Feature(words: ['remind', 'reminder'], arabic: ['تذكير']),
  'notifications': Phase2Feature(
    words: ['notification', 'notifications'],
    arabic: ['إشعارات', 'اشعارات'],
    icons: ['Icons.notifications', 'Icons.notification'],
    routes: ["'/notifications", "'/activity"],
  ),
  'accountDeletion': Phase2Feature(phrases: ['delete account', 'delete my account']),
};

/// Omitted for good (not Phase 2): never enabled.
const _permanentWords = <String, String>{
  'guest': 'guest mode (SCREEN_MAP: no guest mode)',
  'receipt': 'receipt photo / scan (omitted)',
  'scan': 'scan the receipt (omitted)',
  'export': 'export (out of scope)',
  'contacts': 'add from contacts (no contacts access)',
  'coupon': 'not a concept of the app',
  'premium': 'not a concept of the app',
  'subscribe': 'not a concept of the app',
  'ads': 'not a concept of the app',
};
const _permanentPhrases = <String>['coming soon', 'sign out everywhere', 'monthly spend', 'cover photo', 'pay now', 'ready to settle'];
const _permanentArabic = <String>['ضيف', 'قريبا', 'قريباً', 'إيصال'];
const _permanentIcons = <String>[
  'Icons.camera', 'Icons.photo', 'Icons.qr_code', 'Icons.document_scanner', 'Icons.receipt', 'Icons.contacts',
  'Icons.download', 'Icons.upload', 'Icons.file_download',
];
const _permanentRoutes = <String>["'/guest"];

/// key -> reason, for strings that contain a forbidden word legitimately
const _allowedKeys = <String, String>{
  'expensesEmptyBody': 'Arabic "ضيف" here is the imperative "add", not "guest"',
};

Iterable<Phase2Feature> _notBuilt(Set<String> enabled) =>
    phase2Features.entries.where((e) => !enabled.contains(e.key)).map((e) => e.value);

/// Offending entries of the ARB files: `{lang: {key: value}}`.
List<String> copyViolations(Map<String, Map<String, dynamic>> arb, Set<String> enabled) {
  final words = <String, String>{..._permanentWords};
  final phrases = <String>[..._permanentPhrases];
  final arabicWords = <String>[..._permanentArabic];
  for (final f in _notBuilt(enabled)) {
    for (final w in f.words) {
      words[w] = 'a Phase 2 feature that is not built yet';
    }
    phrases.addAll(f.phrases);
    arabicWords.addAll(f.arabic);
  }
  final hits = <String>[];
  arb.forEach((lang, strings) {
    strings.forEach((key, value) {
      if (key.startsWith('@') || value is! String || _allowedKeys.containsKey(key)) return;
      final text = value.toLowerCase();
      final found = RegExp(r"[a-z']+").allMatches(text).map((m) => m.group(0)!).toSet();
      words.forEach((word, why) {
        if (found.contains(word)) hits.add('$lang:$key contains "$word" - $why');
      });
      for (final phrase in phrases) {
        if (text.contains(phrase)) hits.add('$lang:$key contains "$phrase"');
      }
      final foundArabic = RegExp(r'[؀-ۿ]+').allMatches(value).map((m) => m.group(0)!).toSet();
      for (final word in arabicWords) {
        // whole words only: "ضيف" (guest) is also inside "يضيف" (adds)
        if (foundArabic.contains(word)) hits.add('$lang:$key contains "$word"');
      }
    });
  });
  return hits;
}

/// Offending icons and routes in Dart sources: `{path: text}`.
List<String> sourceViolations(Map<String, String> sources, Set<String> enabled) {
  final icons = <String>[..._permanentIcons];
  final routes = <String>[..._permanentRoutes];
  for (final f in _notBuilt(enabled)) {
    icons.addAll(f.icons);
    routes.addAll(f.routes);
  }
  final hits = <String>[];
  sources.forEach((path, source) {
    for (final icon in icons) {
      if (RegExp('${RegExp.escape(icon)}(?![a-z_])').hasMatch(source) || source.contains('$icon.') || source.contains('$icon,')) {
        hits.add('$path: $icon');
      }
    }
    for (final route in routes) {
      if (source.contains(route)) hits.add('$path: route $route');
    }
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
      if (!file.path.contains('generated') && !file.path.contains('catalogue')) file.path: file.readAsStringSync(),
  };

  test('no omitted or not-yet-built feature appears in the user-visible copy', () {
    final hits = copyViolations(arb, enabledFeatures);
    expect(hits, isEmpty, reason: 'omitted/unbuilt element in copy:\n${hits.join('\n')}');
  });

  test('no omitted or not-yet-built icon or route is in the widget tree', () {
    final hits = sourceViolations(sources, enabledFeatures);
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('every enabled feature is a known feature (no typos that would silently switch nothing)', () {
    expect(phase2Features.keys.toSet().containsAll(enabledFeatures), isTrue, reason: 'unknown feature in enabledFeatures: $enabledFeatures');
  });

  group('the guard is alive', () {
    test('an unbuilt feature in the copy is caught, in English and in Arabic, and passes once the feature is enabled', () {
      final english = {'en': <String, dynamic>{'inviteFriend': 'Invite a friend'}};
      final arabic = {'ar': <String, dynamic>{'inviteFriend': 'ابعت دعوة'}};
      expect(copyViolations(english, const {}), isNotEmpty);
      expect(copyViolations(arabic, const {}), isNotEmpty);
      expect(copyViolations(english, const {'invites'}), isEmpty);
      expect(copyViolations(arabic, const {'invites'}), isEmpty);
      expect(copyViolations(english, const {'notifications'}), isNotEmpty, reason: 'enabling another feature does not help');
    });

    test('an unbuilt icon or route in the sources is caught and passes once the feature is enabled', () {
      final icon = {'lib/a.dart': 'const x = Icon(Icons.notifications);'};
      final route = {'lib/b.dart': "context.push('/invite/abc');"};
      expect(sourceViolations(icon, const {}), isNotEmpty);
      expect(sourceViolations(route, const {}), isNotEmpty);
      expect(sourceViolations(icon, const {'notifications'}), isEmpty);
      expect(sourceViolations(route, const {'invites'}), isEmpty);
    });

    test('permanently omitted elements stay forbidden even when every Phase 2 feature is enabled', () {
      final all = phase2Features.keys.toSet();
      expect(copyViolations({'en': <String, dynamic>{'k': 'Coming soon'}}, all), isNotEmpty);
      expect(copyViolations({'en': <String, dynamic>{'k': 'Continue as guest'}}, all), isNotEmpty);
      expect(copyViolations({'ar': <String, dynamic>{'k': 'قريبا'}}, all), isNotEmpty);
      expect(sourceViolations({'lib/c.dart': 'Icon(Icons.camera, size: 8)'}, all), isNotEmpty);
      expect(sourceViolations({'lib/d.dart': "go('/guest')"}, all), isNotEmpty);
    });

    test('whole words only: the Arabic "adds" is not "guest"', () {
      expect(copyViolations({'ar': <String, dynamic>{'k': 'يضيف عضو'}}, const {}), isEmpty);
    });
  });
}
