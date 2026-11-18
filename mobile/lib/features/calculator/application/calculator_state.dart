import '../../../local/calculator/fuel_prices_repository.dart';

/// One editable toll row (كارتة); [id] keeps the text field stable while rows are added and removed.
final class TollRow {
  const TollRow(this.id, this.text);

  final int id;
  final String text;
}

/// Where one rider gets in and out (stops 0..legs).
final class RiderStops {
  const RiderStops(this.boardStop, this.leaveStop);

  final int boardStop;
  final int leaveStop;
}

/// What the user typed and chose on the calculator screen (SA11). Text is kept exactly as typed; it is parsed by
/// `core/money` and computed by the local facade (A149), never here.
final class CalculatorState {
  const CalculatorState({
    this.tab = 0,
    this.distanceText = '',
    this.consumptionText = '',
    this.fuelType = FuelType.gasoline92,
    this.tolls = const [],
    this.nextTollId = 0,
    this.driverId,
    this.driverIncluded = true,
    this.passengerIds,
    this.fareText = '',
    this.legTexts = const [''],
    this.farePayerId,
    this.riders,
  });

  /// 0 = fuel, 1 = shared ride.
  final int tab;

  // ---- fuel ----
  final String distanceText;
  final String consumptionText;
  final FuelType fuelType;
  final List<TollRow> tolls;
  final int nextTollId;

  /// Null = "you" (or the first member).
  final String? driverId;
  final bool driverIncluded;

  /// Null = every member but the driver.
  final Set<String>? passengerIds;

  // ---- ride ----
  final String fareText;

  /// One distance per leg; stops = legs + 1.
  final List<String> legTexts;

  /// Null = "you" (or the first member).
  final String? farePayerId;

  /// Null = every member rides the whole trip.
  final Map<String, RiderStops>? riders;

  CalculatorState copyWith({
    int? tab,
    String? distanceText,
    String? consumptionText,
    FuelType? fuelType,
    List<TollRow>? tolls,
    int? nextTollId,
    String? driverId,
    bool? driverIncluded,
    Set<String>? passengerIds,
    String? fareText,
    List<String>? legTexts,
    String? farePayerId,
    Map<String, RiderStops>? riders,
  }) =>
      CalculatorState(
        tab: tab ?? this.tab,
        distanceText: distanceText ?? this.distanceText,
        consumptionText: consumptionText ?? this.consumptionText,
        fuelType: fuelType ?? this.fuelType,
        tolls: tolls ?? this.tolls,
        nextTollId: nextTollId ?? this.nextTollId,
        driverId: driverId ?? this.driverId,
        driverIncluded: driverIncluded ?? this.driverIncluded,
        passengerIds: passengerIds ?? this.passengerIds,
        fareText: fareText ?? this.fareText,
        legTexts: legTexts ?? this.legTexts,
        farePayerId: farePayerId ?? this.farePayerId,
        riders: riders ?? this.riders,
      );
}
