import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/local_database_provider.dart';
import 'trip_recap_repository.dart';

final tripRecapRepositoryProvider = Provider<TripRecapRepository>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return TripRecapRepository(db);
});

final tripRecapProvider = StreamProvider.family<TripRecapResult?, String>((ref, groupId) {
  final repo = ref.watch(tripRecapRepositoryProvider);
  return repo.watchTripRecap(groupId);
});
