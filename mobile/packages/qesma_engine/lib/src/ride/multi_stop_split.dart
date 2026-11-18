import '../engine_exception.dart';
import '../limits.dart';
import '../lrm.dart';
import '../values.dart';

/// One rider of a multi-stop ride: boards at stop [boardStop] and leaves at stop [leaveStop] (stops are numbered
/// 0..legCount; leg `i` runs from stop `i` to stop `i + 1`).
final class RideRider {
  const RideRider({required this.memberId, required this.sortOrder, required this.boardStop, required this.leaveStop});

  final String memberId;
  final int sortOrder;
  final int boardStop;
  final int leaveStop;

  bool onBoardIn(int leg) => boardStop <= leg && leg < leaveStop;
}

/// The result of [MultiStopSplit.compute]: the fare per leg and each rider's share, in sortOrder order.
final class MultiStopSplitResult {
  const MultiStopSplitResult({required this.legFaresMinor, required this.shares});

  final List<int> legFaresMinor;
  final List<Share> shares;
}

/// Multi-stop ride split (STANDALONE_SPEC 11, A140, A141). Pure integer math through [Lrm].
abstract final class MultiStopSplit {
  /// At most 10 stops.
  static const int maxLegs = 9;

  /// 10,000.0 km per leg.
  static const int maxLegDistanceTenthsKm = 100000;

  /// Indices of the legs nobody is on board for (A141), so the UI can name them.
  static List<int> legsWithoutRiders(int legCount, List<RideRider> riders) => [
        for (var leg = 0; leg < legCount; leg++)
          if (!riders.any((r) => r.onBoardIn(leg))) leg,
      ];

  /// Leg fare = LRM of [fareMinor] by leg distance (all zero -> equal); each leg split equally (LRM, ties by
  /// sortOrder) among the riders on board; a rider's share is the sum over their legs. Throws [EngineException]
  /// (`VALIDATION_ERROR`) on invalid input, including a leg without riders.
  static MultiStopSplitResult compute({
    required int fareMinor,
    required List<int> legDistancesTenthsKm,
    required List<RideRider> riders,
  }) {
    if (fareMinor < 1 || fareMinor > Limits.maxAmountMinor) {
      throw EngineException.invalid('Fare must be between 1 and ${Limits.maxAmountMinor}');
    }
    final legCount = legDistancesTenthsKm.length;
    if (legCount < 1 || legCount > maxLegs) {
      throw EngineException.invalid('A ride has 1 to $maxLegs legs');
    }
    for (final d in legDistancesTenthsKm) {
      if (d < 0 || d > maxLegDistanceTenthsKm) throw EngineException.invalid('Leg distance is out of range');
    }
    if (riders.isEmpty) throw EngineException.invalid('At least one rider is required');
    final ids = <String>{};
    for (final r in riders) {
      if (!ids.add(r.memberId)) throw EngineException.invalid('Duplicate rider');
      if (r.boardStop < 0 || r.leaveStop > legCount || r.boardStop >= r.leaveStop) {
        throw EngineException.invalid('A rider must board before leaving, within the stops');
      }
    }
    if (legsWithoutRiders(legCount, riders).isNotEmpty) {
      throw EngineException.invalid('A leg has no riders on board');
    }

    final sorted = [...riders]..sort((a, b) {
        final c = a.sortOrder.compareTo(b.sortOrder);
        return c != 0 ? c : a.memberId.compareTo(b.memberId);
      });
    final legFares = Lrm.allocate(fareMinor, legDistancesTenthsKm, List<int>.generate(legCount, (i) => i));
    final totals = List<int>.filled(sorted.length, 0);
    for (var leg = 0; leg < legCount; leg++) {
      final onBoard = [for (var i = 0; i < sorted.length; i++) if (sorted[i].onBoardIn(leg)) i];
      final parts = Lrm.allocate(
        legFares[leg],
        List<int>.filled(onBoard.length, 1),
        [for (final i in onBoard) sorted[i].sortOrder],
      );
      for (var k = 0; k < onBoard.length; k++) {
        totals[onBoard[k]] += parts[k]; // sums of parts of fareMinor <= 10^12
      }
    }
    return MultiStopSplitResult(
      legFaresMinor: legFares,
      shares: [for (var i = 0; i < sorted.length; i++) Share(sorted[i].memberId, totals[i])],
    );
  }
}
