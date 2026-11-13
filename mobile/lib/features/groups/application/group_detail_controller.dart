import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../../balances/application/balances_refresh.dart';
import '../data/groups_repository.dart';
import 'groups_list_controller.dart';

/// Tests switch this off to drive [GroupDetailController.load] themselves.
final groupDetailAutoLoadProvider = Provider<bool>((ref) => true);

class GroupDetailState {
  const GroupDetailState({this.group, this.loading = true, this.failure, this.busy = false});

  final GroupDto? group;

  /// First load or an explicit reload is running.
  final bool loading;

  /// The last load failed (the group, if any, is the previous copy).
  final ApiFailure? failure;

  /// A change (save, delete, member change) is in flight; buttons stay disabled.
  final bool busy;

  /// The server says this group does not exist (or is not yours).
  bool get gone => failure is ApiHttpFailure && (failure as ApiHttpFailure).problem?.code == ApiErrorCode.notFound;

  GroupDetailState copyWith({GroupDto? group, bool? loading, ApiFailure? failure, bool clearFailure = false, bool? busy}) =>
      GroupDetailState(
        group: group ?? this.group,
        loading: loading ?? this.loading,
        failure: clearFailure ? null : (failure ?? this.failure),
        busy: busy ?? this.busy,
      );

  @override
  String toString() => 'GroupDetailState(loading: $loading, busy: $busy)';
}

/// One group as the group home, the edit screen and the members tab see it.
/// Every change method returns the failure (null = success) so the screen decides how to
/// show it; after a successful change the group is re-read, which also refreshes its version.
class GroupDetailController extends Notifier<GroupDetailState> {
  GroupDetailController(this.gid);

  final String gid;

  late final GroupsRepository _repo = ref.read(groupsRepositoryProvider);

  @override
  GroupDetailState build() {
    if (ref.read(groupDetailAutoLoadProvider)) scheduleMicrotask(load);
    return const GroupDetailState();
  }

  /// (Re)reads the group. Keeps the previous copy on failure.
  Future<ApiFailure?> load() async {
    state = state.copyWith(loading: true, clearFailure: true);
    try {
      final group = await _repo.get(gid);
      if (!ref.mounted) return null; // the user left the screen meanwhile
      state = GroupDetailState(group: group, loading: false);
      return null;
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return failure;
      state = state.copyWith(loading: false, failure: failure);
      return failure;
    }
  }

  Future<ApiFailure?> _change(Future<void> Function() change, {bool reload = true}) async {
    if (state.busy) return null;
    state = state.copyWith(busy: true);
    try {
      await change();
    } on ApiFailure catch (failure) {
      if (ref.mounted) state = state.copyWith(busy: false);
      return failure;
    }
    if (!ref.mounted) return null;
    if (reload) {
      try {
        final group = await _repo.get(gid);
        if (ref.mounted) state = GroupDetailState(group: group, loading: false);
      } on ApiFailure {
        // The change itself worked; the next read will catch up.
        if (ref.mounted) state = state.copyWith(busy: false);
      }
    } else {
      state = state.copyWith(busy: false);
    }
    if (ref.mounted) {
      unawaited(ref.read(groupsListControllerProvider.notifier).refresh());
      // Members changed (left, unlinked, roles): the balances tab shows server data for them too.
      if (reload) refreshBalanceTab(ref, gid, settlements: false);
    }
    return null;
  }

  /// `PATCH` with `If-Match`. On `VERSION_CONFLICT` the caller shows the conflict dialog and
  /// calls [load] when the user agrees; the form keeps what they typed.
  Future<ApiFailure?> save({required String name, required String type}) => _change(() async {
        final updated = await _repo.update(gid, name: name, type: type);
        state = state.copyWith(group: updated);
      });

  Future<ApiFailure?> delete() => _change(() => _repo.delete(gid), reload: false);

  Future<ApiFailure?> addMember(String name) => _change(() => _repo.addMember(gid, name));

  Future<ApiFailure?> renameMember(String mid, String name) => _change(() => _repo.renameMember(gid, mid, name));

  Future<ApiFailure?> deleteMember(String mid) => _change(() => _repo.deleteMember(gid, mid));

  // Member lifecycle (B12, FL12). Roles and status are never edited locally: the group is re-read after each call.
  Future<ApiFailure?> setRole(String mid, String role) => _change(() => _repo.setRole(gid, mid, role));

  Future<ApiFailure?> setStatus(String mid, String status) => _change(() => _repo.setStatus(gid, mid, status));

  Future<ApiFailure?> unlinkMember(String mid) => _change(() => _repo.unlink(gid, mid));

  Future<ApiFailure?> transferOwnership(String toMemberId) => _change(() => _repo.transferOwnership(gid, toMemberId));

  /// After success the group is no longer readable by this person (404), so it is not re-read.
  Future<ApiFailure?> leave() => _change(() => _repo.leave(gid), reload: false);
}

final groupDetailControllerProvider =
    NotifierProvider.autoDispose.family<GroupDetailController, GroupDetailState, String>(GroupDetailController.new);
