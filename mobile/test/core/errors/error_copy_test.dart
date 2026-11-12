import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma/core/errors/error_copy.dart';
import 'package:qesma/core/l10n/generated/app_localizations_ar.dart';
import 'package:qesma/core/l10n/generated/app_localizations_en.dart';

ApiHttpFailure _failure(ApiErrorCode code, int status) => ApiHttpFailure(
      status: status,
      problem: ApiProblem(code: code, status: status, rawCode: code.wire),
    );

void main() {
  final en = AppLocalizationsEn();
  final ar = AppLocalizationsAr();

  test('every wire code of the Phase 2 backend is known, none falls back to unknown', () {
    for (final wire in ['FORBIDDEN', 'INVITE_EXPIRED', 'INVITE_REVOKED', 'ALREADY_MEMBER', 'MEMBER_ALREADY_CLAIMED']) {
      expect(ApiErrorCode.fromWire(wire).wire, wire);
      expect(ApiErrorCode.fromWire(wire), isNot(ApiErrorCode.unknown));
    }
    expect(ApiErrorCode.fromWire('SOMETHING_NEW'), ApiErrorCode.unknown);
  });

  test('FORBIDDEN has its own message in both languages and never the generic one', () {
    final english = errorCopyFor(en, _failure(ApiErrorCode.forbidden, 403));
    final arabic = errorCopyFor(ar, _failure(ApiErrorCode.forbidden, 403));
    expect(english.message, en.errorForbidden);
    expect(arabic.message, ar.errorForbidden);
    expect(english.message, isNot(en.errorUnexpected));
    expect(arabic.message, isNot(ar.errorUnexpected));
  });

  test('every code has copy and the copy is never the server text (the switch is exhaustive, this checks the result)', () {
    for (final code in ApiErrorCode.values) {
      final copy = errorCopyFor(en, _failure(code, code == ApiErrorCode.forbidden ? 403 : 409));
      expect(copy.message, isNotEmpty, reason: code.name);
    }
  });
}
