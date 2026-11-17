/// Engine-local error codes. [wireName] is the stable API code of spec 8.5, so the local backend can map
/// them one-to-one (same names as the Java `EngineErrorCode`).
enum EngineErrorCode {
  /// Malformed or out-of-range input, including arithmetic overflow.
  validationError('VALIDATION_ERROR'),

  /// EXACT shares do not sum to the expense total (spec 7.3).
  splitTotalMismatch('SPLIT_TOTAL_MISMATCH'),

  /// Payer amounts do not sum to the expense total (spec 7.5).
  payersTotalMismatch('PAYERS_TOTAL_MISMATCH'),

  /// A referenced member is not part of the supplied roster.
  memberNotInGroup('MEMBER_NOT_IN_GROUP');

  const EngineErrorCode(this.wireName);

  final String wireName;
}

/// Typed failure for any rule violation inside the engine. Messages contain no personal data.
final class EngineException implements Exception {
  EngineException(this.code, this.message, [this.cause]);

  /// A [EngineErrorCode.validationError] with [message].
  factory EngineException.invalid(String message) => EngineException(EngineErrorCode.validationError, message);

  final EngineErrorCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'EngineException(${code.wireName}): $message';
}
