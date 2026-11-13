import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../data/balances_repository.dart';

/// Tests switch this off to drive [SettlementsController.load] themselves.
final settlementsAutoLoadProvider = Provider<bool>((ref) => true);

enum SettlementsStatus { loading, ready, failed }

/// The settlement history of one group, every status (cancelled included), newest first as the server sorts it. Immutable.
class SettlementsState {
  const SettlementsState({
    this.status = SettlementsStatus.loading,
    this.items = const [],
    this.page = 0,
    this.totalPages = 1,
    this.total = 0,
    this.failure,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  final SettlementsStatus status;
  final List<SettlementView> items;
  final int page;
  final int totalPages;

  /// How many payments exist (the server's count, not the number loaded).
  final int total;
  final ApiFailure? failure;
  final bool loadingMore;
  final bool loadMoreFailed;

  bool get hasMore => page + 1 < totalPages;

  SettlementsState copyWith({
    SettlementsStatus? status,
    List<SettlementView>? items,
    int? page,
    int? totalPages,
    int? total,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) =>
      SettlementsState(
        status: status ?? this.status,
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        failure: failure,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      );

  @override
  String toString() => 'SettlementsState($status, ${items.length} payments)';
}

class SettlementsController extends Notifier<SettlementsState> {
  SettlementsController(this.gid);

  final String gid;

  late final BalancesRepository _repo = ref.read(balancesRepositoryProvider);
  int _generation = 0;

  @override
  SettlementsState build() {
    if (ref.read(settlementsAutoLoadProvider)) scheduleMicrotask(load);
    return const SettlementsState();
  }

  Future<void> load() async {
    final generation = ++_generation;
    state = const SettlementsState();
    try {
      final result = await _repo.settlements(gid);
      if (!ref.mounted || generation != _generation) return;
      state = SettlementsState(
        status: SettlementsStatus.ready,
        items: _dedupe(result.items),
        page: result.page,
        totalPages: result.totalPages,
        total: result.total,
      );
    } on ApiFailure catch (failure) {
      if (!ref.mounted || generation != _generation) return;
      state = SettlementsState(status: SettlementsStatus.failed, failure: failure);
    }
  }

  /// After a change or pull to refresh: page 0 again; keeps the list when it fails.
  Future<ApiFailure?> refresh() async {
    if (state.status != SettlementsStatus.ready) {
      await load();
      return ref.mounted ? state.failure : null;
    }
    final generation = ++_generation;
    state = state.copyWith(loadingMore: false, loadMoreFailed: false);
    try {
      final result = await _repo.settlements(gid);
      if (!ref.mounted || generation != _generation) return null;
      state = SettlementsState(
        status: SettlementsStatus.ready,
        items: _dedupe(result.items),
        page: result.page,
        totalPages: result.totalPages,
        total: result.total,
      );
      return null;
    } on ApiFailure catch (failure) {
      return failure;
    }
  }

  /// Next page; one at a time. After a failure it waits for an explicit [retry].
  Future<ApiFailure?> loadMore({bool retry = false}) async {
    if (state.status != SettlementsStatus.ready || !state.hasMore || state.loadingMore) return null;
    if (state.loadMoreFailed && !retry) return null;
    final generation = _generation;
    state = state.copyWith(loadingMore: true, loadMoreFailed: false);
    try {
      final result = await _repo.settlements(gid, page: state.page + 1);
      if (!ref.mounted || generation != _generation) return null;
      state = state.copyWith(
        items: _dedupe([...state.items, ...result.items]),
        page: result.page,
        totalPages: result.totalPages,
        total: result.total,
        loadingMore: false,
      );
      return null;
    } on ApiFailure catch (failure) {
      if (ref.mounted && generation == _generation) state = state.copyWith(loadingMore: false, loadMoreFailed: true);
      return failure;
    }
  }

  List<SettlementView> _dedupe(List<SettlementView> items) {
    final seen = <String>{};
    return [
      for (final s in items)
        if (seen.add(s.id)) s,
    ];
  }
}

final settlementsControllerProvider =
    NotifierProvider.autoDispose.family<SettlementsController, SettlementsState, String>(SettlementsController.new);
