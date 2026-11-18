import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/l10n/generated/app_localizations_ar.dart';
import 'package:qesma/core/l10n/generated/app_localizations_en.dart';
import 'package:qesma/features/balances/application/reminder_formatter.dart';
import 'package:qesma/features/balances/domain/reminder_tone.dart';

void main() {
  final l10nAr = AppLocalizationsAr();
  final l10nEn = AppLocalizationsEn();

  group('ReminderFormatter - Arabic', () {
    test('soft tone fills all placeholders with Western digits and no handle line when off', () {
      final msg = ReminderFormatter.formatMessage(
        l10n: l10nAr,
        tone: ReminderTone.soft,
        debtorName: 'كريم',
        amountMinor: 15000,
        groupName: 'رحلة دهب',
        includeInstapay: false,
      );

      expect(msg, contains('كريم'));
      expect(msg, contains('رحلة دهب'));
      expect(msg, contains('150.00 ج.م'));
      expect(msg, contains('صباح الفل'));
      expect(msg, isNot(contains('إنستاباي')));
    });

    test('firm tone fills placeholders and includes handle line when on', () {
      final msg = ReminderFormatter.formatMessage(
        l10n: l10nAr,
        tone: ReminderTone.firm,
        debtorName: 'أحمد',
        amountMinor: 25050,
        groupName: 'عشاء المعادي',
        instapayHandle: 'ahmed@instapay',
        includeInstapay: true,
      );

      expect(msg, contains('أحمد'));
      expect(msg, contains('عشاء المعادي'));
      expect(msg, contains('250.50 ج.م'));
      expect(msg, contains('بنقفل حسابات'));
      expect(msg, contains('بيانات إنستاباي:'));
      expect(msg, contains('ahmed@instapay'));
    });

    test('funny tone never shames and contains friendly Egyptian humor', () {
      final msg = ReminderFormatter.formatMessage(
        l10n: l10nAr,
        tone: ReminderTone.funny,
        debtorName: 'عمر',
        amountMinor: 50000,
        groupName: 'شاليه الساحل',
        includeInstapay: false,
      );

      expect(msg, contains('عمر'));
      expect(msg, contains('شاليه الساحل'));
      expect(msg, contains('500.00 ج.م'));
      expect(msg, contains('قبل ما الجيب يعلن إفلاسه'));
      expect(msg, contains('متخليش المحفظة تعيط!'));
    });
  });

  group('ReminderFormatter - English', () {
    test('soft tone fills placeholders with Western digits and currency', () {
      final msg = ReminderFormatter.formatMessage(
        l10n: l10nEn,
        tone: ReminderTone.soft,
        debtorName: 'Kareem',
        amountMinor: 15000,
        groupName: 'Dahab Trip',
        includeInstapay: false,
      );

      expect(msg, contains('Kareem'));
      expect(msg, contains('Dahab Trip'));
      expect(msg, contains('150.00 EGP'));
      expect(msg, contains('friendly reminder'));
      expect(msg, isNot(contains('InstaPay')));
    });

    test('firm tone with InstaPay handle appends My InstaPay line', () {
      final msg = ReminderFormatter.formatMessage(
        l10n: l10nEn,
        tone: ReminderTone.firm,
        debtorName: 'Sara',
        amountMinor: 32000,
        groupName: 'Flat Expenses',
        instapayHandle: 'sara@instapay',
        includeInstapay: true,
      );

      expect(msg, contains('Sara'));
      expect(msg, contains('Flat Expenses'));
      expect(msg, contains('320.00 EGP'));
      expect(msg, contains('settling up'));
      expect(msg, contains('My InstaPay:'));
      expect(msg, contains('sara@instapay'));
    });

    test('funny tone generates witty wallet reminder', () {
      final msg = ReminderFormatter.formatMessage(
        l10n: l10nEn,
        tone: ReminderTone.funny,
        debtorName: 'Omar',
        amountMinor: 10000,
        groupName: 'Outing',
        includeInstapay: false,
      );

      expect(msg, contains('Omar'));
      expect(msg, contains('Outing'));
      expect(msg, contains('100.00 EGP'));
      expect(msg, contains('my wallet asked me to remind you'));
      expect(msg, contains('cries'));
    });
  });

  group('buildWhatsAppUri', () {
    test('encodes Arabic text, spaces, and newlines safely into https://wa.me/?text=', () {
      const original = 'صباح الفل يا كريم!\nعليك 150.00 ج.م\n\nإنستاباي:\nkareem@instapay';
      final uri = ReminderFormatter.buildWhatsAppUri(original);

      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/');
      expect(uri.queryParameters.containsKey('text'), isTrue);

      final rawQuery = uri.toString();
      expect(rawQuery, startsWith('https://wa.me/?text='));
      // Newlines encoded as %0A
      expect(rawQuery, contains('%0A'));
      // Arabic encoded as %D...
      expect(rawQuery, contains('%D8'));

      // Round-trip decoding restores original string exactly
      expect(uri.queryParameters['text'], equals(original));
    });
  });
}
