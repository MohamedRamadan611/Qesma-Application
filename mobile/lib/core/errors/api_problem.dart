import 'dart:convert';

/// Stable error codes of the backend (spec 8.5, `Problem.code` in docs/openapi.json).
///
/// Unknown codes map to [unknown] so a newer backend never crashes an older app.
enum ApiErrorCode {
  validationError('VALIDATION_ERROR'),
  payersTotalMismatch('PAYERS_TOTAL_MISMATCH'),
  splitTotalMismatch('SPLIT_TOTAL_MISMATCH'),
  memberNotInGroup('MEMBER_NOT_IN_GROUP'),
  idempotencyKeyReused('IDEMPOTENCY_KEY_REUSED'),
  duplicateMemberName('DUPLICATE_MEMBER_NAME'),
  memberHasTransactions('MEMBER_HAS_TRANSACTIONS'),
  ownerMemberProtected('OWNER_MEMBER_PROTECTED'),
  versionConflict('VERSION_CONFLICT'),
  groupNotEmpty('GROUP_NOT_EMPTY'),
  notFound('NOT_FOUND'),
  unauthorized('UNAUTHORIZED'),
  internalError('INTERNAL_ERROR'),
  rateLimited('RATE_LIMITED'),
  authProviderUnavailable('AUTH_PROVIDER_UNAVAILABLE'),
  usernameTaken('USERNAME_TAKEN'),
  unknown('');

  const ApiErrorCode(this.wire);

  /// The value sent by the server.
  final String wire;

  static ApiErrorCode fromWire(String? value) {
    for (final code in values) {
      if (code != unknown && code.wire == value) return code;
    }
    return unknown;
  }
}

/// A parsed `application/problem+json` body.
///
/// Only the machine-readable parts are kept. `title` and `detail` are English and
/// technical: they are never shown to users (the UI maps [code] to localized copy).
class ApiProblem {
  const ApiProblem({
    required this.code,
    required this.status,
    this.rawCode,
    this.requestId,
  });

  final ApiErrorCode code;

  /// HTTP status from the body (falls back to the response status).
  final int status;

  /// The code exactly as received (kept for support / logs when [code] is `unknown`).
  final String? rawCode;

  /// Server request id, safe to show to the user for support.
  final String? requestId;

  /// Parses a response body (already decoded JSON map, or a raw JSON string).
  /// Returns null when the body is not a problem document (e.g. an HTML 502 page).
  static ApiProblem? tryParse(Object? body, {required int fallbackStatus}) {
    Object? decoded = body;
    if (decoded is String) {
      try {
        decoded = jsonDecode(decoded);
      } on FormatException {
        return null;
      }
    }
    if (decoded is! Map) return null;
    final rawCode = decoded['code'];
    if (rawCode is! String) return null;
    final status = decoded['status'];
    final requestId = decoded['requestId'];
    return ApiProblem(
      code: ApiErrorCode.fromWire(rawCode),
      rawCode: rawCode,
      status: status is int ? status : fallbackStatus,
      requestId: requestId is String ? requestId : null,
    );
  }

  @override
  String toString() => 'ApiProblem($rawCode, status=$status, requestId=$requestId)';
}
