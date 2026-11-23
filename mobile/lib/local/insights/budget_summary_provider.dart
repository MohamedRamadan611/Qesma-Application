import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/clock.dart';
import '../db/local_database_provider.dart';
import 'budget_summary_repository.dart';

final budgetSummaryRepositoryProvider = Provider<BudgetSummaryRepository>(
  (ref) => BudgetSummaryRepository(ref.watch(localDatabaseProvider)),
);

/// A group's trip-budget figures, live (SA20); null when no budget is set. Local mode only (A191): callers gate on
/// `ModeFeatures.budget`.
final budgetSummaryProvider = StreamProvider.autoDispose.family<BudgetSummary?, String>(
  (ref, gid) => ref.watch(budgetSummaryRepositoryProvider).watch(gid, ref.watch(cairoTodayProvider)),
);
