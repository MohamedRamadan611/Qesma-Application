import 'engine_exception.dart';
import 'exact.dart';

/// Largest Remainder Method (spec 7.1): the single allocation primitive of the engine (port of the Java `Lrm`).
///
/// Allocates an integer total across recipients proportionally to integer weights so that the parts sum
/// exactly to the total. Products use [BigInt] exactly where Java uses `BigInteger`; no floating point.
abstract final class Lrm {
  /// Spec 7.1 steps 1-6.
  ///
  /// [total] may be negative (its absolute value is allocated, then the sign applied). [weights] are
  /// non-negative, one per recipient; if all are zero every weight is treated as 1. [sortOrders] are the
  /// tie-break keys aligned with [weights]; the lower value wins a tied remainder. Returns parts aligned with
  /// the inputs that sum exactly to [total].
  static List<int> allocate(int total, List<int> weights, List<int> sortOrders) {
    final n = weights.length;
    if (n == 0) {
      throw EngineException.invalid('At least one recipient is required');
    }
    if (sortOrders.length != n) {
      throw EngineException.invalid('Weights and sort orders must have the same length');
    }
    if (total == Exact.minInt64) {
      throw EngineException.invalid('Amount too large');
    }

    var sum = BigInt.zero;
    for (final w in weights) {
      if (w < 0) {
        throw EngineException.invalid('Weights must not be negative');
      }
      sum += BigInt.from(w);
    }
    var effective = weights;
    if (sum == BigInt.zero) {
      // spec 7.1 step 5
      effective = List<int>.filled(n, 1);
      sum = BigInt.from(n);
    }

    final abs = total.abs();
    final absBig = BigInt.from(abs);
    final parts = List<int>.filled(n, 0);
    final remainders = List<BigInt>.filled(n, BigInt.zero);
    var allocated = 0;
    for (var i = 0; i < n; i++) {
      // steps 1-2: exact share, floor (all operands are non-negative, so ~/ is the floor)
      final product = absBig * BigInt.from(effective[i]);
      final quotient = product ~/ sum;
      if (!quotient.isValidInt) {
        throw StateError('Engine invariant violated: an LRM part exceeds the total');
      }
      parts[i] = quotient.toInt();
      remainders[i] = product.remainder(sum);
      allocated += parts[i]; // each part <= abs and the parts sum to <= abs: cannot overflow
    }

    final leftover = abs - allocated; // always < n
    // steps 3-4: largest remainder first, tie -> lower sortOrder, then lower index. The comparator is total,
    // so the (unstable) sort is deterministic.
    final order = List<int>.generate(n, (i) => i)
      ..sort((a, b) {
        final byRemainder = remainders[b].compareTo(remainders[a]);
        if (byRemainder != 0) return byRemainder;
        final bySortOrder = sortOrders[a].compareTo(sortOrders[b]);
        if (bySortOrder != 0) return bySortOrder;
        return a.compareTo(b);
      });
    for (var k = 0; k < leftover; k++) {
      parts[order[k]]++;
    }

    if (total < 0) {
      // step 6
      for (var i = 0; i < n; i++) {
        parts[i] = -parts[i];
      }
    }
    return parts;
  }
}
