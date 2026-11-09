import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../data/expenses_repository.dart';
import 'expense_filters.dart';

/// Tests switch this off to drive [ExpensesListController.load] themselves.
final expensesAutoLoadProvider = Provider<bool>((ref) => true);

enum ExpensesStatus { loading, ready, failed }

/// The paged, filtered expenses list of one group. Immutable; replaced as a whole.
class ExpensesListState {
  const ExpensesListState({
    this.status = ExpensesStatus.loading,
    this.items = const [],
    this.page = 0,
    this.totalPages = 1,
    this.failure,
    this.loadingMore = false,
    this.refreshing = false,
    this.loadMoreFailed = false,
    this.filters = ExpenseFilters.none,
  });

  final ExpensesStatus status;
  final List<ExpenseView> items;
  final int page;
  final int totalPages;
  final ApiFailure? failure;
  final bool loadingMore;
  final bool refreshing;

  /// The last attempt to load the next page failed: the list shows a "try again" row and scrolling
  /// no longer retries by itself (a scroll event must not be the only way to retry).
  final bool loadMoreFailed;
  final ExpenseFilters filters;

  bool get hasMore => page + 1 < totalPages;

  ExpensesListState copyWith({
    ExpensesStatus? status,
    List<ExpenseView>? items,
    int? page,
    int? totalPages,
    bool? loadingMore,
    bool? refreshing,
    bool? loadMoreFailed,
  }) =>
      ExpensesListState(
        status: status ?? this.status,
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        failure: failure,
        loadingMore: loadingMore ?? this.loadingMore,
        refreshing: refreshing ?? this.refreshing,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
        filters: filters,
      );

  @override
  String toString() => 'ExpensesListState($status, ${items.length} expenses, filters: ${filters.isActive})';
}

class ExpensesListController extends Notifier<ExpensesListState> {
  ExpensesListController(this.gid);

  final String gid;

  late final ExpensesRepository _repo = ref.read(expensesRepositoryProvider);

  /// Bumped by every (re)load, so a reply for filters the user has since changed is dropped.
  int _generation = 0;

  @override
  ExpensesListState build() {
    if (ref.read(expensesAutoLoadProvider)) scheduleMicrotask(load);
    return const ExpensesListState();
  }

  Future<ExpensesPage> _fetch(int page, ExpenseFilters f) =>
      _repo.list(gid, page: page, fromDate: f.from, toDate: f.to, memberId: f.memberId);

  /// First page with the current filters. Shows the skeleton; on failure the error state.
  Future<void> load() async {
    final filters = state.filters;
    final generation = ++_generation;
    state = ExpensesListState(filters: filters);
    try {
      final result = await _fetch(0, filters);
      if (!ref.mounted || generation != _generation) return;
      state = ExpensesListState(
        status: ExpensesStatus.ready,
        items: _dedupe(result.items),
        page: result.page,
        totalPages: result.totalPages,
        filters: filters,
      );
    } on ApiFailure catch (failure) {
      if (!ref.mounted || generation != _generation) return;
      state = ExpensesListState(status: ExpensesStatus.failed, failure: failure, filters: filters);
    }
  }

  /// Sets the filters and reloads from page 0. Returns false (nothing changes) when the
  /// range is backwards.
  Future<bool> applyFilters(ExpenseFilters filters) async {
    if (!filters.rangeValid) return false;
    if (filters == state.filters) return true;
    state = ExpensesListState(filters: filters);
    await load();
    return true;
  }

  Future<void> clearFilters() async {
    await applyFilters(ExpenseFilters.none);
  }

  /// Pull to refresh / after a change. Keeps the current list when it fails.
  Future<ApiFailure?> refresh() async {
    if (state.status != ExpensesStatus.ready) {
      await load();
      return ref.mounted ? state.failure : null;
    }
    if (state.refreshing) return null;
    final filters = state.filters;
    final generation = ++_generation;
    // A refresh supersedes a page request in flight (its reply will be dropped), so its flag must not stay on.
    state = state.copyWith(refreshing: true, loadingMore: false, loadMoreFailed: false);
    try {
      final result = await _fetch(0, filters);
      if (!ref.mounted || generation != _generation) return null;
      state = ExpensesListState(
        status: ExpensesStatus.ready,
        items: _dedupe(result.items),
        page: result.page,
        totalPages: result.totalPages,
        filters: filters,
      );
      return null;
    } on ApiFailure catch (failure) {
      if (ref.mounted && generation == _generation) state = state.copyWith(refreshing: false);
      return failure;
    }
  }

  /// Next page. One at a time; does nothing at the end or while refreshing. After a failure it
  /// waits for an explicit [retry] (the "try again" row) instead of retrying on every scroll event.
  Future<ApiFailure?> loadMore({bool retry = false}) async {
    if (state.status != ExpensesStatus.ready || !state.hasMore || state.loadingMore || state.refreshing) return null;
    if (state.loadMoreFailed && !retry) return null;
    final filters = state.filters;
    final generation = _generation;
    state = state.copyWith(loadingMore: true, loadMoreFailed: false);
    try {
      final result = await _fetch(state.page + 1, filters);
      if (!ref.mounted || generation != _generation) return null;
      state = state.copyWith(
        items: _dedupe([...state.items, ...result.items]),
        page: result.page,
        totalPages: result.totalPages,
        loadingMore: false,
      );
      return null;
    } on ApiFailure catch (failure) {
      if (ref.mounted && generation == _generation) state = state.copyWith(loadingMore: false, loadMoreFailed: true);
      return failure;
    }
  }

  /// Items are keyed by id, so a refresh or an overlapping page never shows a row twice.
  List<ExpenseView> _dedupe(List<ExpenseView> items) {
    final seen = <String>{};
    return [
      for (final e in items)
        if (seen.add(e.id)) e,
    ];
  }
}

final expensesListControllerProvider =
    NotifierProvider.autoDispose.family<ExpensesListController, ExpensesListState, String>(ExpensesListController.new);
