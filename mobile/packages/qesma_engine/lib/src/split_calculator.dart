import 'engine_exception.dart';
import 'exact.dart';
import 'internal.dart';
import 'lrm.dart';
import 'values.dart';

/// EQUAL (spec 7.2) and EXACT (spec 7.3) splits. Results map memberId to owed minor units, in insertion order.
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
}
