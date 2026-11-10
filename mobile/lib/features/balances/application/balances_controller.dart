import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../data/balances_repository.dart';

/// Tests switch this off to drive [BalancesController.load] themselves.
final balancesAutoLoadProvider = Provider<bool>((ref) => true);

enum BalancesStatus { loading, ready, failed }

/// What the server said about the group's balances: the nets and the suggested transfers.
/// Immutable; replaced as a whole. Nothing here is calculated by the app.
class BalancesState {
  const BalancesState({this.status = BalancesStatus.loading, this.balances, this.failure, this.refreshing = false});

  final BalancesStatus status;
  final BalanceView? balances;
  final ApiFailure? failure;
  final bool refreshing;

  @override
  String toString() => 'BalancesState($status, refreshing: $refreshing)';
}

/// The balances of one group. Auto-dispose and never kept alive: opening the tab always asks the
/// server again, so balances are never cached across edits.
class BalancesController extends Notifier<BalancesState> {
  BalancesController(this.gid);

  final String gid;

  late final BalancesRepository _repo = ref.read(balancesRepositoryProvider);

  /// Bumped by every (re)load so an older reply never overwrites a newer one.
  int _generation = 0;

  @override
  BalancesState build() {
    if (ref.read(balancesAutoLoadProvider)) scheduleMicrotask(load);
    return const BalancesState();
  }

  /// First read (shows the skeleton) or a retry after a failure.
  Future<void> load() async {
    final generation = ++_generation;
    state = const BalancesState();
    try {
      final balances = await _repo.balances(gid);
      if (!ref.mounted || generation != _generation) return;
      state = BalancesState(status: BalancesStatus.ready, balances: balances);
    } on ApiFailure catch (failure) {
      if (!ref.mounted || generation != _generation) return;
      state = BalancesState(status: BalancesStatus.failed, failure: failure);
    }
  }

  /// Pull to refresh / after a change: keeps what is shown when it fails (the failure is returned).
  Future<ApiFailure?> refresh() async {
    if (state.status != BalancesStatus.ready) {
      await load();
      return ref.mounted ? state.failure : null;
    }
    final generation = ++_generation;
    state = BalancesState(status: BalancesStatus.ready, balances: state.balances, refreshing: true);
    try {
      final balances = await _repo.balances(gid);
      if (!ref.mounted || generation != _generation) return null;
      state = BalancesState(status: BalancesStatus.ready, balances: balances);
      return null;
    } on ApiFailure catch (failure) {
      if (ref.mounted && generation == _generation) {
        state = BalancesState(status: BalancesStatus.ready, balances: state.balances);
      }
      return failure;
    }
  }
}

final balancesControllerProvider =
    NotifierProvider.autoDispose.family<BalancesController, BalancesState, String>(BalancesController.new);
