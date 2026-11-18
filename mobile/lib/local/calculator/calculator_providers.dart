import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/local_database_provider.dart';
import 'fuel_prices_repository.dart';
import 'khorouga_calculator.dart';

final khorougaCalculatorProvider = Provider<KhorougaCalculator>((ref) => const KhorougaCalculator());

final fuelPricesRepositoryProvider = Provider<FuelPricesRepository>(
  (ref) => FuelPricesRepository(ref.watch(localDatabaseProvider)),
);

/// Saved prices, re-emitted after every edit.
final fuelPricesProvider = StreamProvider.autoDispose<Map<FuelType, SavedFuelPrice>>(
  (ref) => ref.watch(fuelPricesRepositoryProvider).watch(),
);
