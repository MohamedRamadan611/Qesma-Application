import 'engine_exception.dart';
import 'exact.dart';
import 'values.dart';

/// Payer rules (spec 7.5). Payers need not be participants. Port of the Java `PayerValidator`.
abstract final class PayerValidator {
  /// At least one payer, each amount > 0, no duplicate member, sum equals [total] or `PAYERS_TOTAL_MISMATCH`.
  static void validate(int total, List<Payer> payers) {
    if (payers.isEmpty) {
      throw EngineException.invalid('At least one payer is required');
    }
    final seen = <String>{};
    var sum = 0;
    for (final p in payers) {
      if (p.amountMinor <= 0) {
        throw EngineException.invalid('Payer amounts must be greater than zero');
      }
      if (!seen.add(p.memberId)) {
        throw EngineException.invalid('Duplicate payer');
      }
      sum = Exact.add(sum, p.amountMinor);
    }
    if (sum != total) {
      throw EngineException(EngineErrorCode.payersTotalMismatch, 'Payers do not add up to the total');
    }
  }
}
