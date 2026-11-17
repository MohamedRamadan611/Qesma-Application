import 'package:qesma_engine/qesma_engine.dart';

/// A contract error of the local backend (STANDALONE_SPEC 3.1): the same HTTP status and stable `code` (spec 8.5)
/// the Java backend answers for the same request. The router turns it into Problem JSON; anything that is not a
/// [LocalApiException] becomes `500 INTERNAL_ERROR`.
///
/// [title] is the safe, data-free message (Java puts its message in `title`); [extras] are extra top-level
/// Problem members such as `currentVersion` and `current` of a VERSION_CONFLICT (A113).
final class LocalApiException implements Exception {
  const LocalApiException(this.status, this.code, this.title, {this.extras = const {}});

  final int status;
  final String code;
  final String title;
  final Map<String, Object?> extras;

  /// 422 VALIDATION_ERROR, the default for input rules (`ApiException.validation`).
  factory LocalApiException.validation(String title) => LocalApiException(422, 'VALIDATION_ERROR', title);

  /// 400 VALIDATION_ERROR: the body or a path/query value could not be read at all (Jackson/Spring parse errors).
  factory LocalApiException.unreadable(String title) => LocalApiException(400, 'VALIDATION_ERROR', title);

  /// 404 NOT_FOUND: an unknown id, a soft-deleted expense, an unknown route or a server-only endpoint.
  factory LocalApiException.notFound() => const LocalApiException(404, 'NOT_FOUND', 'Not found');

  /// 401 UNAUTHORIZED: no local profile exists yet (the local equivalent of "not signed in").
  factory LocalApiException.unauthorized() => const LocalApiException(401, 'UNAUTHORIZED', 'Authentication required');

  /// 409 with a domain conflict code (GROUP_NOT_EMPTY, DUPLICATE_MEMBER_NAME, ...).
  factory LocalApiException.conflict(String code, String title) => LocalApiException(409, code, title);

  /// 422 with a domain rule code (MEMBER_NOT_IN_GROUP, IDEMPOTENCY_KEY_REUSED, ...).
  factory LocalApiException.unprocessable(String code, String title) => LocalApiException(422, code, title);

  /// 409 VERSION_CONFLICT with the B17 body: the stored version and what GET returns now (A113).
  factory LocalApiException.versionConflict(String title, int currentVersion, Object current) => LocalApiException(
        409,
        'VERSION_CONFLICT',
        title,
        extras: {'currentVersion': currentVersion, 'current': current},
      );

  /// The one mapping of engine rule violations to API errors (Java `EngineErrors.toApi`): every code is a 422.
  factory LocalApiException.fromEngine(EngineException e) => LocalApiException(422, e.code.wireName, e.message);

  @override
  String toString() => 'LocalApiException($status $code)';
}

/// `https://qesma.app/problems/<code in lower case with dashes>`, as `ErrorCode.type()` builds it.
String problemType(String code) => 'https://qesma.app/problems/${code.toLowerCase().replaceAll('_', '-')}';

/// The Problem JSON body (`application/problem+json`) for [e]: `{type, title, status, instance, code, requestId}`
/// plus the exception's extras at the top level.
Map<String, Object?> problemBody(LocalApiException e, {required String instance, required String requestId}) => {
      'type': problemType(e.code),
      'title': e.title,
      'status': e.status,
      'instance': instance,
      'code': e.code,
      'requestId': requestId,
      ...e.extras,
    };
