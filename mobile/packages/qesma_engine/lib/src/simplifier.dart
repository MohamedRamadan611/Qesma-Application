import 'dart:math';

import 'engine_exception.dart';
import 'exact.dart';
import 'internal.dart';
import 'values.dart';

/// Debt simplification (spec 7.7, Decision A5): deterministic greedy, not a guaranteed minimum.
/// Port of the Java `Simplifier`.
abstract final class Simplifier {
  /// Repeatedly pairs the creditor with the largest net and the debtor with the most negative net
  /// (ties: lower sortOrder) and transfers `min(credit, debt)`, until all nets are 0.
  /// Nets must sum to 0; roster members missing from [nets] count as 0.
  static List<Transfer> simplify(Map<String, int> nets, List<MemberRef> members) {
    final roster = stableSortedBy(members, (m) => m.sortOrder); // index order == tie-break order
    final n = roster.length;
    final index = <String, int>{};
    for (var i = 0; i < n; i++) {
      index[roster[i].id] = i;
    }
    final net = List<int>.filled(n, 0);
    var sum = 0;
    for (final e in nets.entries) {
      final i = index[e.key];
      if (i == null) {
        throw EngineException(EngineErrorCode.memberNotInGroup, 'A member in the balances is not in the group');
      }
      net[i] = e.value;
      sum = Exact.add(sum, e.value);
    }
    if (sum != 0) {
      throw EngineException.invalid('Net balances must sum to zero');
    }

    final transfers = <Transfer>[];
    while (true) {
      var creditor = -1;
      var debtor = -1;
      for (var i = 0; i < n; i++) {
        // strict comparisons keep the lowest index (lowest sortOrder) on ties
        if (net[i] > 0 && (creditor < 0 || net[i] > net[creditor])) {
          creditor = i;
        }
        if (net[i] < 0 && (debtor < 0 || net[i] < net[debtor])) {
          debtor = i;
        }
      }
      if (creditor < 0 || debtor < 0) {
        return List.unmodifiable(transfers); // sum is 0, so both are absent together
      }
      final amount = min(net[creditor], -net[debtor]); // net[debtor] > minInt64: the sum check bounds it
      transfers.add(Transfer(roster[debtor].id, roster[creditor].id, amount));
      net[creditor] -= amount;
      net[debtor] += amount;
    }
  }
}
