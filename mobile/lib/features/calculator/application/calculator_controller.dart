import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/money/money.dart';
import '../../../local/calculator/calculator_providers.dart';
import '../../../local/calculator/fuel_prices_repository.dart';
import '../../../local/calculator/khorouga_calculator.dart';
import '../../groups/application/group_detail_controller.dart';
import 'calculator_state.dart';

/// The calculator's inputs, per group (SA11). Every number shown comes from the local facade.
class CalculatorController extends Notifier<CalculatorState> {
  CalculatorController(this.gid);

  final String gid;

  @override
  CalculatorState build() => const CalculatorState();

  List<MemberDto> get _members => calculatorMembers(ref.read(groupDetailControllerProvider(gid)).group);

  void setTab(int tab) => state = state.copyWith(tab: tab);

  // ---- fuel ----
  void setDistance(String text) => state = state.copyWith(distanceText: text);
  void setConsumption(String text) => state = state.copyWith(consumptionText: text);
  void setFuelType(FuelType type) => state = state.copyWith(fuelType: type);

  void addToll() {
    if (state.tolls.length >= CalculatorLimits.maxTolls) return;
    state = state.copyWith(tolls: [...state.tolls, TollRow(state.nextTollId, '')], nextTollId: state.nextTollId + 1);
  }

  void setToll(int id, String text) =>
      state = state.copyWith(tolls: [for (final t in state.tolls) t.id == id ? TollRow(id, text) : t]);

  void removeToll(int id) => state = state.copyWith(tolls: [for (final t in state.tolls) if (t.id != id) t]);

  /// A new driver is never also a passenger.
  void setDriver(String memberId) {
    final group = ref.read(groupDetailControllerProvider(gid)).group;
    final passengers = {...resolvedPassengers(state, group)}..remove(memberId);
    final old = resolvedDriver(state, group);
    if (old != null && old != memberId) passengers.add(old);
    state = state.copyWith(driverId: memberId, passengerIds: passengers);
  }

  void setDriverIncluded(bool value) => state = state.copyWith(driverIncluded: value);

  void togglePassenger(String memberId) {
    final passengers = {...resolvedPassengers(state, ref.read(groupDetailControllerProvider(gid)).group)};
    if (!passengers.remove(memberId)) passengers.add(memberId);
    state = state.copyWith(passengerIds: passengers);
  }

  // ---- ride ----
  void setFare(String text) => state = state.copyWith(fareText: text);
  void setFarePayer(String memberId) => state = state.copyWith(farePayerId: memberId);
  void setLeg(int index, String text) =>
      state = state.copyWith(legTexts: [for (var i = 0; i < state.legTexts.length; i++) i == index ? text : state.legTexts[i]]);

  /// A new last stop: riders who stayed to the old end now stay to the new end.
  void addStop() {
    final legs = state.legTexts.length;
    if (legs >= CalculatorLimits.maxLegs) return;
    final riders = resolvedRiders(state, _members);
    state = state.copyWith(
      legTexts: [...state.legTexts, ''],
      riders: {
        for (final e in riders.entries)
          e.key: e.value.leaveStop == legs ? RiderStops(e.value.boardStop, legs + 1) : e.value,
      },
    );
  }

  /// Drops the last stop; anyone past it now gets out at the new last stop.
  void removeStop() {
    final legs = state.legTexts.length;
    if (legs <= 1) return;
    final last = legs - 1;
    final riders = resolvedRiders(state, _members);
    state = state.copyWith(
      legTexts: state.legTexts.sublist(0, last),
      riders: {
        for (final e in riders.entries)
          e.key: RiderStops(e.value.boardStop >= last ? last - 1 : e.value.boardStop, e.value.leaveStop > last ? last : e.value.leaveStop),
      },
    );
  }

  void toggleRider(String memberId) {
    final riders = {...resolvedRiders(state, _members)};
    if (riders.remove(memberId) == null) riders[memberId] = RiderStops(0, state.legTexts.length);
    state = state.copyWith(riders: riders);
  }

  /// Getting in at or after the leaving stop moves the leaving stop one further (and back for the reverse).
  void setRiderStops(String memberId, {int? board, int? leave}) {
    final riders = {...resolvedRiders(state, _members)};
    final current = riders[memberId];
    if (current == null) return;
    final legs = state.legTexts.length;
    var b = board ?? current.boardStop;
    var l = leave ?? current.leaveStop;
    if (board != null && b >= l) l = b + 1 > legs ? legs : b + 1;
    if (leave != null && l <= b) b = l - 1 < 0 ? 0 : l - 1;
    riders[memberId] = RiderStops(b, l);
    state = state.copyWith(riders: riders);
  }
}

final calculatorControllerProvider =
    NotifierProvider.autoDispose.family<CalculatorController, CalculatorState, String>(CalculatorController.new);

// ---- defaults resolved against the group ----

/// The group's members in their fixed order.
List<MemberDto> calculatorMembers(GroupDto? group) =>
    (group?.members.toList() ?? <MemberDto>[])..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

String? _you(GroupDto? group) => group?.yourMemberId ?? calculatorMembers(group).firstOrNull?.id;

String? resolvedDriver(CalculatorState s, GroupDto? group) => s.driverId ?? _you(group);

String? resolvedFarePayer(CalculatorState s, GroupDto? group) => s.farePayerId ?? _you(group);

Set<String> resolvedPassengers(CalculatorState s, GroupDto? group) {
  final driver = resolvedDriver(s, group);
  return s.passengerIds ?? {for (final m in calculatorMembers(group)) if (m.id != driver) m.id};
}

Map<String, RiderStops> resolvedRiders(CalculatorState s, List<MemberDto> members) =>
    s.riders ?? {for (final m in members) m.id: RiderStops(0, s.legTexts.length)};

// ---- output ----

/// What the screen shows: per-field errors, and the facade's answer once the inputs are complete.
final class CalculatorOutput {
  const CalculatorOutput({
    this.distanceError = false,
    this.consumptionError = false,
    this.tollErrors = const {},
    this.fareError = false,
    this.legErrors = const {},
    this.outcome,
    this.payerId,
    this.distanceTenths,
  });

  final bool distanceError;
  final bool consumptionError;

  /// Toll row ids with an amount that is not valid.
  final Set<int> tollErrors;
  final bool fareError;

  /// Leg indices with a distance that is not valid.
  final Set<int> legErrors;

  /// Null while something needed is still empty or invalid.
  final CalcOutcome? outcome;
  final String? payerId;
  final int? distanceTenths;

  CalcResult? get result => outcome is CalcResult ? outcome! as CalcResult : null;
}

CalculatorOutput fuelOutput(
  CalculatorState s,
  GroupDto? group, {
  required int? pricePerLitreMinor,
  required KhorougaCalculator calculator,
}) {
  final members = calculatorMembers(group);
  final driverId = resolvedDriver(s, group);
  final distanceTyped = s.distanceText.trim().isNotEmpty;
  final distance = distanceTyped ? Tenths.parse(s.distanceText, min: 0, max: CalculatorLimits.maxDistanceTenthsKm) : 0;
  final consumptionTyped = s.consumptionText.trim().isNotEmpty;
  final consumption = consumptionTyped
      ? Tenths.parse(s.consumptionText, min: CalculatorLimits.minConsumptionTenths, max: CalculatorLimits.maxConsumptionTenths)
      : null;
  final tollErrors = <int>{};
  final tolls = <int>[];
  for (final t in s.tolls) {
    if (t.text.trim().isEmpty) continue;
    final minor = Money.parse(t.text);
    if (minor == null) {
      tollErrors.add(t.id);
    } else {
      tolls.add(minor);
    }
  }
  final errors = CalculatorOutput(
    distanceError: distance == null,
    consumptionError: consumptionTyped && consumption == null,
    tollErrors: tollErrors,
    payerId: driverId,
    distanceTenths: distance,
  );
  if (distance == null || (consumptionTyped && consumption == null) || tollErrors.isNotEmpty || driverId == null) return errors;
  // A distance needs a consumption and a saved price; with no distance only the tolls count.
  final driving = distance > 0;
  if (driving && (consumption == null || pricePerLitreMinor == null)) return errors;
  if (!driving && tolls.isEmpty) return errors;

  final passengers = resolvedPassengers(s, group);
  final driver = members.where((m) => m.id == driverId).firstOrNull;
  if (driver == null) return errors;
  final outcome = calculator.fuel(FuelInputs(
    distanceTenthsKm: distance,
    consumptionTenths: consumption ?? CalculatorLimits.minConsumptionTenths, // unused at distance 0
    pricePerLitreMinor: driving ? pricePerLitreMinor! : 0,
    tollsMinor: tolls,
    driver: CalcMember(driver.id, driver.sortOrder),
    driverIncluded: s.driverIncluded,
    passengers: [for (final m in members) if (passengers.contains(m.id) && m.id != driverId) CalcMember(m.id, m.sortOrder)],
  ));
  return CalculatorOutput(
    tollErrors: tollErrors,
    outcome: outcome,
    payerId: driverId,
    distanceTenths: distance,
  );
}

CalculatorOutput rideOutput(CalculatorState s, GroupDto? group, {required KhorougaCalculator calculator}) {
  final members = calculatorMembers(group);
  final payerId = resolvedFarePayer(s, group);
  final fareTyped = s.fareText.trim().isNotEmpty;
  final fare = fareTyped ? Money.parse(s.fareText) : null;
  final legErrors = <int>{};
  final legs = <int>[];
  var legsComplete = true;
  for (var i = 0; i < s.legTexts.length; i++) {
    final text = s.legTexts[i];
    if (text.trim().isEmpty) {
      legsComplete = false;
      continue;
    }
    final tenths = Tenths.parse(text, min: 0, max: CalculatorLimits.maxLegDistanceTenthsKm);
    if (tenths == null) {
      legErrors.add(i);
    } else {
      legs.add(tenths);
    }
  }
  final errors = CalculatorOutput(fareError: fareTyped && fare == null, legErrors: legErrors, payerId: payerId);
  if (fare == null || legErrors.isNotEmpty || !legsComplete || payerId == null) return errors;
  final riders = resolvedRiders(s, members);
  final outcome = calculator.ride(RideInputs(
    fareMinor: fare,
    legDistancesTenthsKm: legs,
    riders: [
      for (final m in members)
        if (riders[m.id] case final stops?) CalcRider(CalcMember(m.id, m.sortOrder), boardStop: stops.boardStop, leaveStop: stops.leaveStop),
    ],
  ));
  return CalculatorOutput(legErrors: legErrors, outcome: outcome, payerId: payerId);
}

/// The live result for the current tab: re-evaluated on every keystroke, price change and group change.
final calculatorOutputProvider = Provider.autoDispose.family<CalculatorOutput, String>((ref, gid) {
  final s = ref.watch(calculatorControllerProvider(gid));
  final group = ref.watch(groupDetailControllerProvider(gid)).group;
  final calculator = ref.watch(khorougaCalculatorProvider);
  if (s.tab == 1) return rideOutput(s, group, calculator: calculator);
  final prices = ref.watch(fuelPricesProvider).value;
  return fuelOutput(s, group, pricePerLitreMinor: prices?[s.fuelType]?.pricePerLitreMinor, calculator: calculator);
});
