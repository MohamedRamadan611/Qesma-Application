import 'package:qesma_engine/qesma_engine.dart';

/// The Khorouga calculator's only door to `qesma_engine` (A149): features build plain inputs, this facade runs
/// the engine (STANDALONE_SPEC 11, A139-A141) and answers with a result or a reason the screen can explain.
/// It never throws to the UI and never saves anything (A142).

/// Input bounds the screen parses against, so a typed value is checked before the engine sees it.
abstract final class CalculatorLimits {
  static const int maxDistanceTenthsKm = FuelSplit.maxDistanceTenthsKm;
  static const int minConsumptionTenths = FuelSplit.minConsumptionTenths;
  static const int maxConsumptionTenths = FuelSplit.maxConsumptionTenths;
  static const int maxPricePerLitreMinor = FuelSplit.maxPricePerLitreMinor;
  static const int maxTolls = FuelSplit.maxTolls;
  static const int maxLegs = MultiStopSplit.maxLegs;
  static const int maxLegDistanceTenthsKm = MultiStopSplit.maxLegDistanceTenthsKm;
}

/// A group member as the calculator needs it.
final class CalcMember {
  const CalcMember(this.id, this.sortOrder);

  final String id;
  final int sortOrder;
}

final class FuelInputs {
  const FuelInputs({
    required this.distanceTenthsKm,
    required this.consumptionTenths,
    required this.pricePerLitreMinor,
    required this.tollsMinor,
    required this.driver,
    required this.driverIncluded,
    required this.passengers,
  });

  final int distanceTenthsKm;
  final int consumptionTenths;
  final int pricePerLitreMinor;
  final List<int> tollsMinor;
  final CalcMember driver;
  final bool driverIncluded;
  final List<CalcMember> passengers;
}

/// One rider: boards at stop [boardStop], leaves at stop [leaveStop] (stops 0..legs).
final class CalcRider {
  const CalcRider(this.member, {required this.boardStop, required this.leaveStop});

  final CalcMember member;
  final int boardStop;
  final int leaveStop;
}

final class RideInputs {
  const RideInputs({required this.fareMinor, required this.legDistancesTenthsKm, required this.riders});

  final int fareMinor;
  final List<int> legDistancesTenthsKm;
  final List<CalcRider> riders;
}

enum CalcInvalidReason {
  /// Nobody shares the cost (fuel: no passengers and the driver is out; ride: no riders).
  noSharers,

  /// Some legs have nobody on board (A141): [CalcInvalid.legs] names them (0-based).
  legsWithoutRiders,

  /// The total is zero: nothing to split.
  zeroTotal,

  /// The total is above 10^12 piasters.
  totalTooLarge,

  /// Any other input the engine refuses (out of its range).
  outOfRange,
}

sealed class CalcOutcome {
  const CalcOutcome();
}

final class CalcResult extends CalcOutcome {
  const CalcResult({
    required this.totalMinor,
    required this.shares,
    required this.payerMemberId,
    this.fuelMinor,
    this.tollsMinor,
    this.legFaresMinor,
  });

  final int totalMinor;

  /// memberId -> share, in sortOrder order.
  final Map<String, int> shares;

  /// Fuel: the driver. Ride: null (the screen picks who paid the fare).
  final String? payerMemberId;
  final int? fuelMinor;
  final int? tollsMinor;
  final List<int>? legFaresMinor;
}

final class CalcInvalid extends CalcOutcome {
  const CalcInvalid(this.reason, {this.legs = const []});

  final CalcInvalidReason reason;
  final List<int> legs;
}

final class KhorougaCalculator {
  const KhorougaCalculator();

  CalcOutcome fuel(FuelInputs i) {
    if (i.passengers.isEmpty && !i.driverIncluded) return const CalcInvalid(CalcInvalidReason.noSharers);
    // The total first, through the engine's own fuel formula, so "zero" and "too large" get their own message.
    final int fuel;
    try {
      fuel = FuelSplit.fuelMinor(i.distanceTenthsKm, i.consumptionTenths, i.pricePerLitreMinor);
    } on Object {
      return const CalcInvalid(CalcInvalidReason.outOfRange);
    }
    var total = fuel;
    for (final t in i.tollsMinor) {
      if (t > Limits.maxAmountMinor) return const CalcInvalid(CalcInvalidReason.totalTooLarge);
      total += t; // each <= 10^12, at most a few dozen: no overflow before the check below
      if (total > Limits.maxAmountMinor) return const CalcInvalid(CalcInvalidReason.totalTooLarge);
    }
    if (total == 0) return const CalcInvalid(CalcInvalidReason.zeroTotal);
    try {
      final r = FuelSplit.compute(
        distanceTenthsKm: i.distanceTenthsKm,
        consumptionTenths: i.consumptionTenths,
        pricePerLitreMinor: i.pricePerLitreMinor,
        tollsMinor: i.tollsMinor,
        driver: MemberRef(i.driver.id, i.driver.sortOrder),
        driverIncluded: i.driverIncluded,
        passengers: [for (final p in i.passengers) MemberRef(p.id, p.sortOrder)],
      );
      return CalcResult(
        totalMinor: r.totalMinor,
        fuelMinor: r.fuelMinor,
        tollsMinor: r.tollsMinor,
        payerMemberId: r.payerMemberId,
        shares: {for (final s in r.shares) s.memberId: s.amountMinor},
      );
    } on EngineException {
      return const CalcInvalid(CalcInvalidReason.outOfRange);
    }
  }

  CalcOutcome ride(RideInputs i) {
    if (i.riders.isEmpty) return const CalcInvalid(CalcInvalidReason.noSharers);
    if (i.fareMinor > Limits.maxAmountMinor) return const CalcInvalid(CalcInvalidReason.totalTooLarge);
    if (i.fareMinor <= 0) return const CalcInvalid(CalcInvalidReason.zeroTotal);
    final riders = [
      for (final r in i.riders)
        RideRider(memberId: r.member.id, sortOrder: r.member.sortOrder, boardStop: r.boardStop, leaveStop: r.leaveStop),
    ];
    final empty = MultiStopSplit.legsWithoutRiders(i.legDistancesTenthsKm.length, riders);
    if (empty.isNotEmpty) return CalcInvalid(CalcInvalidReason.legsWithoutRiders, legs: empty);
    try {
      final r = MultiStopSplit.compute(fareMinor: i.fareMinor, legDistancesTenthsKm: i.legDistancesTenthsKm, riders: riders);
      return CalcResult(
        totalMinor: i.fareMinor,
        legFaresMinor: r.legFaresMinor,
        payerMemberId: null,
        shares: {for (final s in r.shares) s.memberId: s.amountMinor},
      );
    } on EngineException {
      return const CalcInvalid(CalcInvalidReason.outOfRange);
    }
  }
}
