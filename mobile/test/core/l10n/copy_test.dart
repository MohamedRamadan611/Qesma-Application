import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma/core/errors/error_copy.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';

import '../../support/test_app.dart';

Map<String, dynamic> _arb(String name) => jsonDecode(File('lib/core/l10n/app_$name.arb').readAsStringSync()) as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) => arb.keys.where((k) => !k.startsWith('@')).toSet();

Set<String> _placeholders(String value) => RegExp(r'\{(\w+)\}').allMatches(value).map((m) => m.group(1)!).toSet();

void main() {
  final ar = _arb('ar');
  final en = _arb('en');

  group('ARB files', () {
    test('ar (template) and en define exactly the same keys', () {
      expect(_keys(en), _keys(ar), reason: 'a key exists in one language only');
    });

    test('every key uses the same placeholders in both languages', () {
      for (final key in _keys(ar).where((k) => k != '@@locale')) {
        expect(_placeholders(en[key] as String), _placeholders(ar[key] as String), reason: key);
      }
    });

    test('every ar key has a description for translators', () {
      for (final key in _keys(ar).where((k) => k != '@@locale')) {
        final meta = ar['@$key'];
        expect(meta, isA<Map<String, dynamic>>(), reason: '@$key missing');
        expect((meta as Map<String, dynamic>)['description'], isA<String>(), reason: '@$key has no description');
      }
    });

    test('no value contains Arabic-Indic digits (digits are Western everywhere)', () {
      for (final arb in [ar, en]) {
        for (final key in _keys(arb)) {
          expect(hasNonWesternDigits(arb[key] as String), isFalse, reason: key);
        }
      }
    });

    test('numeric placeholders are strings, so intl can never format them with local digits', () {
      for (final key in _keys(ar)) {
        final meta = ar['@$key'];
        if (meta is Map<String, dynamic> && meta['placeholders'] is Map<String, dynamic>) {
          for (final p in (meta['placeholders'] as Map<String, dynamic>).entries) {
            expect((p.value as Map<String, dynamic>)['type'], 'String', reason: '$key.${p.key}');
          }
        }
      }
    });

    test('key names follow the area-prefix scheme', () {
      const prefixes = ['app', 'bootstrap', 'common', 'field', 'balance', 'money', 'state', 'error', 'brand', 'welcome', 'legal', 'signIn', 'dev', 'sessionExpired', 'home', 'group', 'member'];
      for (final key in _keys(ar).where((k) => k != '@@locale')) {
        expect(prefixes.any(key.startsWith), isTrue, reason: '$key has no known area prefix');
      }
    });
  });

  group('errorCopyFor', () {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      final l10n = lookupAppLocalizations(locale);

      test('${locale.languageCode}: every error code has copy, without Arabic-Indic digits', () {
        for (final code in ApiErrorCode.values) {
          final failure = ApiHttpFailure(status: 409, problem: ApiProblem(code: code, status: 409));
          final copy = errorCopyFor(l10n, failure, memberName: 'عاصم');
          expect(copy.message, isNotEmpty, reason: '$code');
          expect(hasNonWesternDigits(copy.message), isFalse, reason: '$code');
        }
      });

      test('${locale.languageCode}: blocked and conflict codes come with a dialog title', () {
        for (final code in [
          ApiErrorCode.memberHasTransactions,
          ApiErrorCode.groupNotEmpty,
          ApiErrorCode.ownerMemberProtected,
          ApiErrorCode.versionConflict,
        ]) {
          final copy = errorCopyFor(l10n, ApiHttpFailure(status: 409, problem: ApiProblem(code: code, status: 409)));
          expect(copy.title, isNotNull, reason: '$code');
        }
      });

      test('${locale.languageCode}: duplicate member name quotes the rejected name', () {
        final copy = errorCopyFor(
          l10n,
          ApiHttpFailure(status: 409, problem: const ApiProblem(code: ApiErrorCode.duplicateMemberName, status: 409)),
          memberName: 'Asem',
        );
        expect(copy.message, contains('Asem'));
      });

      test('${locale.languageCode}: network failures and unknown shapes', () {
        expect(errorCopyFor(l10n, const ApiTimeout()).message, l10n.errorTimeout);
        expect(errorCopyFor(l10n, const ApiNoConnection()).title, l10n.stateNoInternetTitle);
        expect(errorCopyFor(l10n, const ApiUnexpected()).message, l10n.errorUnexpected);
        expect(errorCopyFor(l10n, const ApiHttpFailure(status: 502)).message, l10n.errorInternal);
        expect(errorCopyFor(l10n, const ApiHttpFailure(status: 418)).message, l10n.errorUnexpected);
        expect(errorCopyFor(l10n, const ApiHttpFailure(status: 400, problem: ApiProblem(code: ApiErrorCode.unknown, status: 400))).message,
            l10n.errorUnexpected);
      });
    }

    test('idempotency-key reuse never leaks technical wording (client bug => generic)', () {
      final l10n = lookupAppLocalizations(const Locale('ar'));
      final copy = errorCopyFor(
        l10n,
        ApiHttpFailure(status: 409, problem: const ApiProblem(code: ApiErrorCode.idempotencyKeyReused, status: 409)),
      );
      expect(copy.message, l10n.errorUnexpected);
    });
  });
}
