import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../groups/application/group_detail_controller.dart';
import '../../groups/application/group_permissions.dart';
import '../data/join_requests_repository.dart';

class JoinRequestsState {
  const JoinRequestsState({this.items = const [], this.loading = true, this.failure, this.deciding = const {}});

  final List<JoinRequestView> items;
  final bool loading;
  final ApiFailure? failure;

  /// Request ids whose approve/reject call is in flight.
  final Set<String> deciding;

  JoinRequestsState copyWith({List<JoinRequestView>? items, bool? loading, ApiFailure? failure, bool clearFailure = false, Set<String>? deciding}) =>
      JoinRequestsState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        failure: clearFailure ? null : (failure ?? this.failure),
        deciding: deciding ?? this.deciding,
      );
}

/// Tests switch this off to drive [JoinRequestsController.load] themselves.
final joinRequestsAutoLoadProvider = Provider<bool>((ref) => true);

/// The pending join requests of one group. Only Owner/Admin read them (a member never triggers the call; the
/// server would answer 403 anyway).
class JoinRequestsController extends Notifier<JoinRequestsState> {
  JoinRequestsController(this.gid);

  final String gid;

  late final JoinRequestsRepository _repo = ref.read(joinRequestsRepositoryProvider);

  @override
  JoinRequestsState build() {
    final allowed = ref.watch(groupPermissionsProvider(gid)).canApproveJoins;
    if (!allowed) return const JoinRequestsState(loading: false);
    if (ref.read(joinRequestsAutoLoadProvider)) scheduleMicrotask(load);
    return const JoinRequestsState();
  }

  Future<ApiFailure?> load() async {
    state = state.copyWith(loading: true, clearFailure: true);
    try {
      final items = await _repo.listPending(gid);
      if (!ref.mounted) return null;
      state = state.copyWith(items: items, loading: false);
      return null;
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return failure;
      state = state.copyWith(loading: false, failure: failure);
      return failure;
    }
  }

  Future<ApiFailure?> approve(String rid) => _decide(rid, () => _repo.approve(gid, rid), approved: true);

  Future<ApiFailure?> reject(String rid) => _decide(rid, () => _repo.reject(gid, rid), approved: false);

  Future<ApiFailure?> _decide(String rid, Future<void> Function() call, {required bool approved}) async {
    if (state.deciding.contains(rid)) return null;
    state = state.copyWith(deciding: {...state.deciding, rid});
    ApiFailure? failure;
    try {
      await call();
    } on ApiFailure catch (f) {
      failure = f;
    }
    if (!ref.mounted) return failure;
    state = state.copyWith(deciding: {...state.deciding}..remove(rid));
    // Success or not, show what the server now says (somebody else may have decided, or a name was taken).
    await load();
    if (ref.mounted && (failure == null && approved || failure != null)) {
      if (ref.read(groupDetailControllerProvider(gid).exists)) unawaited(ref.read(groupDetailControllerProvider(gid).notifier).load());
    }
    return failure;
  }
}

final joinRequestsControllerProvider =
    NotifierProvider.autoDispose.family<JoinRequestsController, JoinRequestsState, String>(JoinRequestsController.new);
