import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart' show Date;

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
  const CreateGroupState({
    this.submitting = false,
    this.failure,
    this.outcomeUnknown = false,
    this.createdGroupId,
    this.failedMemberNames = const [],
    this.treasurerFailed = false,
    this.budgetFailed = false,
  });

  final bool submitting;
  final ApiFailure? failure;

  /// The last attempt may have created the group. The next submit checks the list first.
  final bool outcomeUnknown;
  final String? createdGroupId;

  /// Names that could not be added after the group was created (the group is kept).
  final List<String> failedMemberNames;

  /// A treasurer was asked for but could not be set after the group was created (the group is kept).
  final bool treasurerFailed;

  /// A budget was asked for but could not be saved after the group was created (the group is kept; A199).
  final bool budgetFailed;
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
  ///
  /// [members] are name-only members added one by one after the group exists. A failure
  /// there never undoes the group: the names that failed are in [CreateGroupState.failedMemberNames].
  Future<String?> submit({required String name, required String type, String currencyCode = 'EGP', List<String> members = const [], bool poolOn = false, String? treasurerName, int? budgetMinor, Date? tripStart, Date? tripEnd}) async {
    if (state.submitting) return null;
    state = const CreateGroupState(submitting: true);
    try {
      // Snapshot before the first attempt (also proves we are online).
      _before ??= {for (final g in await _repo.listAll()) g.id};

      if (state.outcomeUnknown || _attempted) {
        final found = await _findCreated(name, type);
        if (found != null) return await _succeeded(found, members, poolOn, treasurerName, budgetMinor, tripStart, tripEnd);
      }

      _attempted = true;
      final group = await _repo.create(name: name, type: type, currencyCode: currencyCode);
      return await _succeeded(group.id, members, poolOn, treasurerName, budgetMinor, tripStart, tripEnd);
    } on ApiFailure catch (failure) {
      final unknown = _attempted && outcomeUnknown(failure);
      if (unknown) {
        // Look once more right away: the group may already exist.
        try {
          final found = await _findCreated(name, type);
          if (found != null) return await _succeeded(found, members, poolOn, treasurerName, budgetMinor, tripStart, tripEnd);
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

  /// [treasurerName] null with [poolOn] = the creator is the treasurer.
  Future<String> _succeeded(
    String id,
    List<String> members,
    bool poolOn,
    String? treasurerName,
    int? budgetMinor,
    Date? tripStart,
    Date? tripEnd,
  ) async {
    final failed = <String>[];
    for (final member in members) {
      try {
        await _repo.addMember(id, member);
      } on ApiFailure {
        failed.add(member);
      }
    }
    var treasurerFailed = false;
    if (poolOn) {
      try {
        final g = await _repo.get(id);
        final mid = treasurerName == null
            ? g.yourMemberId
            : g.members.where((m) => m.id != g.yourMemberId && m.displayName == treasurerName).firstOrNull?.id;
        if (mid == null) {
          treasurerFailed = true;
        } else {
          await _repo.update(id, name: g.name, type: g.type, treasurerMemberId: mid);
        }
      } on ApiFailure {
        treasurerFailed = true;
      }
    }
    // A199: the pool and the budget are exclusive; the screen sends at most one of them.
    var budgetFailed = false;
    if (!poolOn && budgetMinor != null) {
      try {
        final g = await _repo.get(id);
        await _repo.update(id, name: g.name, type: g.type, budgetMinor: budgetMinor, tripStartDate: tripStart, tripEndDate: tripEnd);
      } on ApiFailure {
        budgetFailed = true;
      }
    }
    state = CreateGroupState(createdGroupId: id, failedMemberNames: failed, treasurerFailed: treasurerFailed, budgetFailed: budgetFailed);
    unawaited(ref.read(groupsListControllerProvider.notifier).refresh());
    return id;
  }
}

final createGroupControllerProvider = NotifierProvider.autoDispose<CreateGroupController, CreateGroupState>(CreateGroupController.new);
