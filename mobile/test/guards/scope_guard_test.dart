import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// FL9 scope audit. `.claude/mobile/SCREEN_MAP.md` section 3 lists elements of the designs that are OMITTED in Phase 1 (not
/// disabled, not faked, not "coming soon"), and P12-P14 (invites, transfer status/disputes, activity, notifications) are
/// Phase 2. This guard fails if a user-visible string or an icon of such an element reaches the app.
///
/// Add to [_allowed] only with a reason: the word is used for something that IS in Phase 1.
void main() {
  // user-visible words of omitted / Phase 2 features (case-insensitive, matched on whole words in ARB values)
  const forbiddenWords = <String, String>{
    'guest': 'guest mode (SCREEN_MAP: no guest mode)',
    'invite': 'invites (P12, Phase 2)',
    'invitation': 'invites (P12, Phase 2)',
    'notification': 'notifications (P14, Phase 2)',
    'notifications': 'notifications (P14, Phase 2)',
    'dispute': 'disputes (P13, Phase 2)',
    'remind': 'transfer reminders (P13, Phase 2)',
    'reminder': 'transfer reminders (P13, Phase 2)',
    'receipt': 'receipt photo / scan (omitted)',
    'scan': 'scan the receipt (omitted)',
    'instapay': 'payment handles (Phase 2)',
    'wallet': 'payment handles (Phase 2)',
    'export': 'export (out of scope)',
    'contacts': 'add from contacts (no contacts access in Phase 1)',
    'coupon': 'not a Phase 1 concept',
    'premium': 'not a Phase 1 concept',
    'subscribe': 'not a Phase 1 concept',
    'ads': 'not a Phase 1 concept',
  };
  const forbiddenPhrases = <String>[
    'coming soon',
    'delete account',
    'delete my account',
    'sign out everywhere',
    'monthly spend',
    'cover photo',
    'pay now',
    'ready to settle',
  ];
  // Arabic words of the same features
  const forbiddenArabic = <String>['ضيف', 'دعوة', 'إشعارات', 'اشعارات', 'نزاع', 'تذكير', 'قريبا', 'قريباً', 'إيصال'];
  // key -> reason, for strings that contain a forbidden word legitimately
  const allowed = <String, String>{
    'expensesEmptyBody': 'Arabic "ضيف" here is the imperative "add", not "guest"',
  };

  final arb = <String, Map<String, dynamic>>{
    'en': jsonDecode(File('lib/core/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>,
    'ar': jsonDecode(File('lib/core/l10n/app_ar.arb').readAsStringSync()) as Map<String, dynamic>,
  };

  test('no omitted or Phase 2 feature appears in the user-visible copy', () {
    final hits = <String>[];
    arb.forEach((lang, strings) {
      strings.forEach((key, value) {
        if (key.startsWith('@') || value is! String || allowed.containsKey(key)) return;
        final text = value.toLowerCase();
        final words = RegExp(r"[a-z']+").allMatches(text).map((m) => m.group(0)!).toSet();
        forbiddenWords.forEach((word, why) {
          if (words.contains(word)) hits.add('$lang:$key contains "$word" - $why');
        });
        for (final phrase in forbiddenPhrases) {
          if (text.contains(phrase)) hits.add('$lang:$key contains "$phrase"');
        }
        final arabicWords = RegExp(r'[؀-ۿ]+').allMatches(value).map((m) => m.group(0)!).toSet();
        for (final word in forbiddenArabic) {
          // whole words only: "ضيف" (guest) is also inside "يضيف" (adds)
          if (arabicWords.contains(word)) hits.add('$lang:$key contains "$word"');
        }
      });
    });
    expect(hits, isEmpty, reason: 'omitted/Phase 2 element in copy:\n${hits.join('\n')}');
  });

  test('no omitted or Phase 2 icon or route is in the widget tree', () {
    const forbiddenIcons = [
      'Icons.notifications', 'Icons.notification', 'Icons.camera', 'Icons.photo', 'Icons.qr_code',
      'Icons.document_scanner', 'Icons.receipt', 'Icons.contacts', 'Icons.person_add', 'Icons.group_add',
      'Icons.share', 'Icons.download', 'Icons.upload', 'Icons.file_download',
    ];
    const forbiddenRoutes = ["'/invite", "'/activity", "'/notifications", "'/disputes", "'/guest"];
    final hits = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      if (file.path.contains('generated') || file.path.contains('catalogue')) continue;
      final source = file.readAsStringSync();
      for (final icon in forbiddenIcons) {
        if (RegExp('${RegExp.escape(icon)}(?![a-z_])').hasMatch(source) || source.contains('$icon.') || source.contains('$icon,')) {
          hits.add('${file.path}: $icon');
        }
      }
      for (final route in forbiddenRoutes) {
        if (source.contains(route)) hits.add('${file.path}: route $route');
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}
