import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../data/groups_repository.dart';

/// Tests switch this off to drive [GroupsListController.load] themselves.
final groupsAutoLoadProvider = Provider<bool>((ref) => true);

enum GroupsStatus { loading, ready, failed }

/// The paged groups list. Immutable; replaced as a whole on every change.
class GroupsListState {
  const GroupsListState({
    this.status = GroupsStatus.loading,
    this.items = const [],
    this.page = 0,
    this.totalPages = 1,
    this.failure,
    this.loadingMore = false,
    this.refreshing = false,
  });

  final GroupsStatus status;
  final List<GroupSummaryDto> items;
  final int page;
  final int totalPages;

  /// Set when the first load failed (status failed).
  final ApiFailure? failure;
  final bool loadingMore;
  final bool refreshing;

  bool get hasMore => page + 1 < totalPages;

  /// Net across all groups, as an integer sum of the values the server sent.
  /// Only when EVERY group is loaded and they all share one currency; otherwise null
  /// (a partial or mixed-currency sum would be wrong). The server's `yourNetMinor` is
  /// never recomputed here.
  int? get netTotalMinor {
    if (status != GroupsStatus.ready || hasMore || items.isEmpty) return null;
    final currency = items.first.currencyCode;
    if (items.any((g) => g.currencyCode != currency)) return null;
    return items.fold<int>(0, (sum, g) => sum + g.yourNetMinor);
  }

  GroupsListState copyWith({
    GroupsStatus? status,
    List<GroupSummaryDto>? items,
    int? page,
    int? totalPages,
    ApiFailure? failure,
    bool clearFailure = false,
    bool? loadingMore,
    bool? refreshing,
  }) =>
      GroupsListState(
        status: status ?? this.status,
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        failure: clearFailure ? null : (failure ?? this.failure),
        loadingMore: loadingMore ?? this.loadingMore,
        refreshing: refreshing ?? this.refreshing,
      );

  @override
  String toString() => 'GroupsListState($status, ${items.length} groups)';
}

class GroupsListController extends Notifier<GroupsListState> {
  late final GroupsRepository _repo = ref.read(groupsRepositoryProvider);

  @override
  GroupsListState build() {
    if (ref.read(groupsAutoLoadProvider)) scheduleMicrotask(load);
    return const GroupsListState();
  }

  /// First page. Shows the skeleton; on failure the error state with retry.
  Future<void> load() async {
    state = const GroupsListState();
    try {
      final result = await _repo.list(page: 0);
      if (!ref.mounted) return;
      state = GroupsListState(status: GroupsStatus.ready, items: _dedupe(result.items), page: result.page, totalPages: result.totalPages);
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = GroupsListState(status: GroupsStatus.failed, failure: failure);
    }
  }

  /// Pull to refresh / after a change. Keeps the current list when it fails; returns the
  /// failure so the screen can say so.
  Future<ApiFailure?> refresh() async {
    if (state.status != GroupsStatus.ready) {
      await load();
      return ref.mounted ? state.failure : null;
    }
    if (state.refreshing) return null;
    state = state.copyWith(refreshing: true);
    try {
      final result = await _repo.list(page: 0);
      if (!ref.mounted) return null;
      state = GroupsListState(status: GroupsStatus.ready, items: _dedupe(result.items), page: result.page, totalPages: result.totalPages);
      return null;
    } on ApiFailure catch (failure) {
      if (ref.mounted) state = state.copyWith(refreshing: false);
      return failure;
    }
  }

  /// Next page. One at a time; does nothing at the end or while refreshing.
  Future<ApiFailure?> loadMore() async {
    if (state.status != GroupsStatus.ready || !state.hasMore || state.loadingMore || state.refreshing) return null;
    state = state.copyWith(loadingMore: true);
    try {
      final next = state.page + 1;
      final result = await _repo.list(page: next);
      if (!ref.mounted) return null;
      final merged = _dedupe([...state.items, ...result.items]);
      state = state.copyWith(items: merged, page: result.page, totalPages: result.totalPages, loadingMore: false);
      return null;
    } on ApiFailure catch (failure) {
      if (ref.mounted) state = state.copyWith(loadingMore: false);
      return failure;
    }
  }

  /// Items are keyed by id, so a refresh or an overlapping page never shows a row twice.
  List<GroupSummaryDto> _dedupe(List<GroupSummaryDto> items) {
    final seen = <String>{};
    return [
      for (final g in items)
        if (seen.add(g.id)) g,
    ];
  }
}

final groupsListControllerProvider = NotifierProvider<GroupsListController, GroupsListState>(GroupsListController.new);
