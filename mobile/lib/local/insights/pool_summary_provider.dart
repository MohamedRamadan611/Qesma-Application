import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/local_database_provider.dart';
import 'pool_summary_repository.dart';

final poolSummaryRepositoryProvider = Provider<PoolSummaryRepository>(
  (ref) => PoolSummaryRepository(ref.watch(localDatabaseProvider)),
);

/// A group's pool breakdown, live: re-emits after every deposit, cancel and expense change (SA10).
final poolSummaryProvider = StreamProvider.autoDispose.family<PoolSummary, String>(
  (ref, gid) => ref.watch(poolSummaryRepositoryProvider).watch(gid),
);
