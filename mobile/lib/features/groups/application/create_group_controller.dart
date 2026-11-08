import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_failure.dart';
import '../data/groups_repository.dart';
import 'groups_list_controller.dart';

/// True when the request may have reached the server, so repeating it could duplicate it.
/// Conservative: anything that is not a clear client-side rejection (4xx) counts.
bool outcomeUnknown(ApiFailure failure) => switch (failure) {
      ApiHttpFailure(:final status) => status >= 500 || status == 0,
      ApiTimeout() || ApiNoConnection() || ApiCancelled() || ApiUnexpected() => true,
    };

class CreateGroupState {
  const CreateGroupState({this.submitting = false, this.failure, this.outcomeUnknown = false, this.createdGroupId});

  final bool submitting;
  final ApiFailure? failure;

  /// The last attempt may have created the group. The next submit checks the list first.
  final bool outcomeUnknown;
  final String? createdGroupId;
}

/// Creates a group without ever duplicating it. `POST /groups` has no idempotency key
/// (A24), so after an attempt whose outcome is unknown the app re-reads the list and looks
/// for the group before it offers another POST.
class CreateGroupController extends Notifier<CreateGroupState> {
  late final GroupsRepository _repo = ref.read(groupsRepositoryProvider);

  /// Ids that existed before the first attempt.
  Set<String>? _before;

  @override
  CreateGroupState build() => const CreateGroupState();

  /// Returns the id of the new group, or null (see [state] for why).
  Future<String?> submit({required String name, required String type}) async {
    if (state.submitting) return null;
    state = const CreateGroupState(submitting: true);
    try {
      // Snapshot before the first attempt (also proves we are online).
      _before ??= {for (final g in await _repo.listAll()) g.id};

      if (state.outcomeUnknown || _attempted) {
        final found = await _findCreated(name, type);
        if (found != null) return _succeeded(found);
      }

      _attempted = true;
      final group = await _repo.create(name: name, type: type);
      return _succeeded(group.id);
    } on ApiFailure catch (failure) {
      final unknown = _attempted && outcomeUnknown(failure);
      if (unknown) {
        // Look once more right away: the group may already exist.
        try {
          final found = await _findCreated(name, type);
          if (found != null) return _succeeded(found);
          // Reachable server and no such group: safe to retry.
          _attempted = false;
          state = CreateGroupState(failure: failure);
          return null;
        } on ApiFailure {
          state = CreateGroupState(failure: failure, outcomeUnknown: true);
          return null;
        }
      }
      _attempted = false;
      state = CreateGroupState(failure: failure);
      return null;
    }
  }

  bool _attempted = false;

  Future<String?> _findCreated(String name, String type) async {
    final now = await _repo.listAll();
    for (final g in now) {
      if (!_before!.contains(g.id) && g.name == name && g.type == type) return g.id;
    }
    return null;
  }

  String _succeeded(String id) {
    state = CreateGroupState(createdGroupId: id);
    ref.read(groupsListControllerProvider.notifier).refresh();
    return id;
  }
}

final createGroupControllerProvider = NotifierProvider.autoDispose<CreateGroupController, CreateGroupState>(CreateGroupController.new);
