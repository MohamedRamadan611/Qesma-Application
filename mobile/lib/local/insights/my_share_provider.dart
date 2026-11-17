import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/local_database_provider.dart';
import 'my_share_repository.dart';

final myShareRepositoryProvider = Provider<MyShareRepository>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return MyShareRepository(db);
});

final myShareStreamProvider = StreamProvider.autoDispose((ref) {
  final repo = ref.watch(myShareRepositoryProvider);
  return repo.watchMyShare();
});
