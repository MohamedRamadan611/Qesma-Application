import 'civil_date.dart';
import 'engine_exception.dart';
import 'exact.dart';
import 'internal.dart';
import 'limits.dart';
import 'lrm.dart';
import 'values.dart';

/// EQUAL (spec 7.2), EXACT (spec 7.3) and SHARES (STANDALONE_SPEC 19) splits. Results map memberId to owed minor units, in insertion order.
/// Port of the Java `SplitCalculator`.
abstract final class SplitCalculator {
  /// Spec 7.2: LRM with weight 1 each; extra minor units go to the lowest sortOrder.
  /// Participants are returned in sortOrder order (stable on ties), including any that owe 0.
  static Map<String, int> equal(int total, List<MemberRef> participants) {
    if (total <= 0) {
      throw EngineException.invalid('Total must be greater than zero');
    }
    if (participants.isEmpty) {
      throw EngineException.invalid('At least one participant is required');
    }
    final sorted = stableSortedBy(participants, (m) => m.sortOrder);
    final seen = <String>{};
    for (final m in sorted) {
      if (!seen.add(m.id)) {
        throw EngineException.invalid('Duplicate participant');
      }
    }
    final parts = Lrm.allocate(total, List<int>.filled(sorted.length, 1), [for (final m in sorted) m.sortOrder]);
    return Map.unmodifiable(<String, int>{
      for (var i = 0; i < parts.length; i++) sorted[i].id: parts[i],
    });
  }

  /// Spec 7.3: each amount >= 0, at least one > 0, sum must equal [total], otherwise `SPLIT_TOTAL_MISMATCH`.
  /// Zero shares are kept as given, in input order.
  static Map<String, int> exact(int total, List<Share> shares) {
    if (total <= 0) {
      throw EngineException.invalid('Total must be greater than zero');
    }
    if (shares.isEmpty) {
      throw EngineException.invalid('At least one share is required');
    }
    final owed = <String, int>{};
    var sum = 0;
    var anyPositive = false;
    for (final s in shares) {
      if (s.amountMinor < 0) {
        throw EngineException.invalid('Share amounts must not be negative');
      }
      if (owed.containsKey(s.memberId)) {
        throw EngineException.invalid('Duplicate member in shares');
      }
      owed[s.memberId] = s.amountMinor;
      anyPositive |= s.amountMinor > 0;
      sum = Exact.add(sum, s.amountMinor);
    }
    if (!anyPositive) {
      throw EngineException.invalid('At least one share must be greater than zero');
    }
    if (sum != total) {
      throw EngineException(EngineErrorCode.splitTotalMismatch, 'Shares do not add up to the total');
    }
    return Map.unmodifiable(owed);
  }

  /// SHARES (STANDALONE_SPEC 19.1, A185-A187, A194): weight = `shareUnits x days present` with a [period], else
  /// `shareUnits`; owed = [Lrm.allocate] (ties to the lower sortOrder), so the parts sum to [total]. Days are
  /// inclusive; presence bounds default to the period bounds. Participants are returned in sortOrder order (stable
  /// on ties), including any that owe 0. The engine rejects every A187 rule itself (`VALIDATION_ERROR`).
  static Map<String, int> shares(int total, List<WeightedShare> shares, {SharePeriod? period}) {
    if (total <= 0) {
      throw EngineException.invalid('Total must be greater than zero');
    }
    if (shares.isEmpty) {
      throw EngineException.invalid('At least one participant is required');
    }
    int? periodFrom, periodTo;
    if (period != null) {
      if (period.from == null || period.to == null) {
        throw EngineException.invalid('periodFrom and periodTo must both be set or both be absent');
      }
      periodFrom = CivilDate.epochDay(period.from!);
      periodTo = CivilDate.epochDay(period.to!);
      if (periodTo < periodFrom) {
        throw EngineException.invalid('periodTo must not be before periodFrom');
      }
      if (periodTo - periodFrom + 1 > Limits.maxPeriodDays) {
        throw EngineException.invalid('The period must be at most ${Limits.maxPeriodDays} days');
      }
    }
    final sorted = stableSortedBy(shares, (s) => s.sortOrder);
    final seen = <String>{};
    final weights = List<int>.filled(sorted.length, 0);
    final order = List<int>.filled(sorted.length, 0);
    var weightSum = 0;
    for (var i = 0; i < sorted.length; i++) {
      final s = sorted[i];
      if (!seen.add(s.memberId)) {
        throw EngineException.invalid('Duplicate participant');
      }
      if (s.shareUnits < Limits.minShareUnits || s.shareUnits > Limits.maxShareUnits) {
        throw EngineException.invalid(
            'shareUnits must be between ${Limits.minShareUnits} and ${Limits.maxShareUnits}');
      }
      var days = 1;
      if (periodFrom == null || periodTo == null) {
        if (s.presentFrom != null || s.presentTo != null) {
          throw EngineException.invalid('Presence dates need a period');
        }
      } else {
        final from = s.presentFrom == null ? periodFrom : CivilDate.epochDay(s.presentFrom!);
        final to = s.presentTo == null ? periodTo : CivilDate.epochDay(s.presentTo!);
        if (from < periodFrom || to > periodTo) {
          throw EngineException.invalid('Presence must lie inside the period');
        }
        if (to < from) {
          throw EngineException.invalid('presentTo must not be before presentFrom');
        }
        days = to - from + 1;
      }
      weights[i] = Exact.multiply(s.shareUnits, days);
      weightSum = Exact.add(weightSum, weights[i]);
      order[i] = s.sortOrder;
    }
    if (weightSum == 0) {
      // Unreachable by the rules above; rejected rather than falling back to equal (A187).
      throw EngineException.invalid('The sum of weights must be greater than zero');
    }
    final parts = Lrm.allocate(total, weights, order);
    return Map.unmodifiable(<String, int>{
      for (var i = 0; i < parts.length; i++) sorted[i].memberId: parts[i],
    });
  }

  /// Inclusive day count of two `YYYY-MM-DD` dates: the same date is one day (A186). Malformed dates are rejected.
  static int inclusiveDays(String from, String to) => CivilDate.epochDay(to) - CivilDate.epochDay(from) + 1;
}
