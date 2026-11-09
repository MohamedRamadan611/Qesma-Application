import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../data/expenses_repository.dart';
import 'expense_refresh.dart';

/// Tests switch this off to drive [ExpenseDetailController.load] themselves.
final expenseDetailAutoLoadProvider = Provider<bool>((ref) => true);

/// `(gid, eid)`: records compare by value, so they work as a family key.
typedef ExpenseKey = ({String gid, String eid});

class ExpenseDetailState {
  const ExpenseDetailState({this.expense, this.loading = true, this.failure, this.busy = false, this.deleted = false});

  final ExpenseView? expense;
  final bool loading;

  /// The last read failed (the expense, if any, is the previous copy).
  final ApiFailure? failure;

  /// A delete is in flight; its button stays disabled.
  final bool busy;

  /// The expense was deleted (by this user, or it was already gone).
  final bool deleted;

  /// The server says this expense does not exist (or is not yours / was deleted).
  bool get gone => failure is ApiHttpFailure && (failure as ApiHttpFailure).problem?.code == ApiErrorCode.notFound;

  ExpenseDetailState copyWith({
    ExpenseView? expense,
    bool? loading,
    ApiFailure? failure,
    bool clearFailure = false,
    bool? busy,
    bool? deleted,
  }) =>
      ExpenseDetailState(
        expense: expense ?? this.expense,
        loading: loading ?? this.loading,
        failure: clearFailure ? null : (failure ?? this.failure),
        busy: busy ?? this.busy,
        deleted: deleted ?? this.deleted,
      );
}

/// What a delete attempt came to.
enum DeleteOutcome {
  /// 204: the expense is deleted.
  deleted,

  /// 404: it was already gone (a lost reply to an earlier delete, or deleted elsewhere). Same end state.
  alreadyGone,

  /// Anything else; the failure is returned next to this value.
  failed,
}

/// One expense as the details page sees it. Keeps the version (via the repository's ETag
/// store) so the FL5/FL6 edit flows can send `If-Match`.
class ExpenseDetailController extends Notifier<ExpenseDetailState> {
  ExpenseDetailController(this.key);

  final ExpenseKey key;

  late final ExpensesRepository _repo = ref.read(expensesRepositoryProvider);

  @override
  ExpenseDetailState build() {
    if (ref.read(expenseDetailAutoLoadProvider)) scheduleMicrotask(load);
    return const ExpenseDetailState();
  }

  /// (Re)reads the expense. Keeps the previous copy on failure.
  Future<ApiFailure?> load() async {
    state = state.copyWith(loading: true, clearFailure: true);
    try {
      final expense = await _repo.get(key.gid, key.eid);
      if (!ref.mounted) return null;
      state = ExpenseDetailState(expense: expense, loading: false);
      return null;
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return failure;
      state = state.copyWith(loading: false, failure: failure);
      return failure;
    }
  }

  /// Soft delete with `If-Match`. On success the list and the group totals are refreshed.
  Future<(DeleteOutcome, ApiFailure?)> delete() async {
    if (state.busy || state.expense == null) return (DeleteOutcome.failed, null);
    state = state.copyWith(busy: true);
    // The user may leave the page while this runs; staying alive lets the reply still refresh the list.
    final keepAlive = ref.keepAlive();
    try {
      await _repo.delete(key.gid, key.eid);
      _afterGone();
      return (DeleteOutcome.deleted, null);
    } on ApiFailure catch (failure) {
      if (failure is ApiHttpFailure && failure.problem?.code == ApiErrorCode.notFound) {
        _afterGone();
        return (DeleteOutcome.alreadyGone, null);
      }
      if (ref.mounted) state = state.copyWith(busy: false);
      return (DeleteOutcome.failed, failure);
    } finally {
      keepAlive.close();
    }
  }

  void _afterGone() {
    if (!ref.mounted) return;
    state = state.copyWith(busy: false, deleted: true);
    refreshExpenseViews(ref, key.gid);
  }
}

final expenseDetailControllerProvider =
    NotifierProvider.autoDispose.family<ExpenseDetailController, ExpenseDetailState, ExpenseKey>(ExpenseDetailController.new);

/// The history of one expense (oldest first). A plain read; the sheet retries by invalidating.
/// Riverpod's automatic retry is off: the user's "try again" button is the only retry.
final expenseRevisionsProvider = FutureProvider.autoDispose.family<List<ExpenseRevisionView>, ExpenseKey>(
  (ref, key) => ref.read(expensesRepositoryProvider).revisions(key.gid, key.eid),
  retry: (_, _) => null,
);
