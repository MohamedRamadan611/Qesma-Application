import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/api/idempotent_action.dart';
import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_state.dart';
import '../../groups/application/groups_list_controller.dart';
import '../data/invites_repository.dart';
import 'pending_invite.dart';

/// Longest name the backend accepts for a member (code points).
const int joinNameMax = 40;

/// Tests switch this off to drive [JoinController.load] themselves.
final joinAutoLoadProvider = Provider<bool>((ref) => true);

/// Which screen the join flow shows.
enum JoinPhase {
  loading,

  /// The preview is on screen and a choice can be made.
  ready,
  expired,
  revoked,
  notFound,

  /// The person already belongs to the group (or became a member while waiting).
  alreadyMember,

  /// A request waits for an admin (202, or the preview says so).
  awaitingApproval,
  rateLimited,

  /// The preview could not be read (offline, server error): retry.
  failed,
}

class JoinState {
  const JoinState({
    this.phase = JoinPhase.loading,
    this.preview,
    this.claimMemberId,
    this.joinAsNew = false,
    this.newName = '',
    this.joining = false,
    this.refreshing = false,
    this.duplicateName = false,
    this.claimedNotice = false,
    this.failure,
    this.joinedGroupId,
    this.groupName,
  });

  final JoinPhase phase;
  final InvitePreview? preview;

  /// The unclaimed member picked ("that is me"), or null.
  final String? claimMemberId;

  /// "I am a new member" picked.
  final bool joinAsNew;
  final String newName;

  /// The join request is in flight (the button is disabled).
  final bool joining;

  /// A status refresh of the waiting state is in flight.
  final bool refreshing;

  /// `DUPLICATE_MEMBER_NAME` on the last attempt: shown inline under the name field.
  final bool duplicateName;

  /// `MEMBER_ALREADY_CLAIMED` on the last attempt: somebody took the name, the list was re-read.
  final bool claimedNotice;

  /// The failure of the preview (phase failed) or of the last join attempt that stays on the form.
  final ApiFailure? failure;

  /// Set once when the join succeeded (201): the screen opens this group.
  final String? joinedGroupId;

  /// What the preview said, kept while waiting so the waiting screen can name the group.
  final String? groupName;

  List<Unclaimed> get unclaimed => preview?.unclaimedMembers?.toList() ?? const [];

  bool get hasChoice => claimMemberId != null || (joinAsNew && newName.trim().isNotEmpty);

  bool get canSubmit => phase == JoinPhase.ready && !joining && hasChoice;

  JoinState copyWith({
    JoinPhase? phase,
    InvitePreview? preview,
    String? claimMemberId,
    bool clearClaim = false,
    bool? joinAsNew,
    String? newName,
    bool? joining,
    bool? refreshing,
    bool? duplicateName,
    bool? claimedNotice,
    ApiFailure? failure,
    bool clearFailure = false,
    String? joinedGroupId,
    String? groupName,
  }) =>
      JoinState(
        phase: phase ?? this.phase,
        preview: preview ?? this.preview,
        claimMemberId: clearClaim ? null : (claimMemberId ?? this.claimMemberId),
        joinAsNew: joinAsNew ?? this.joinAsNew,
        newName: newName ?? this.newName,
        joining: joining ?? this.joining,
        refreshing: refreshing ?? this.refreshing,
        duplicateName: duplicateName ?? this.duplicateName,
        claimedNotice: claimedNotice ?? this.claimedNotice,
        failure: clearFailure ? null : (failure ?? this.failure),
        joinedGroupId: joinedGroupId ?? this.joinedGroupId,
        groupName: groupName ?? this.groupName,
      );

  @override
  String toString() => 'JoinState($phase, joining: $joining)';
}

ApiErrorCode? _codeOf(ApiFailure failure) => failure is ApiHttpFailure ? failure.problem?.code : null;

/// One visit to the join screen for one invite code. The code is a secret: it is never logged or put in `toString`.
/// A single [IdempotentAction] makes a retry of the same choice reuse its `Idempotency-Key`, and a changed choice
/// (another member, another name) a new one.
class JoinController extends Notifier<JoinState> {
  JoinController(this._code);

  final String _code;

  late final InvitesRepository _repo = ref.read(invitesRepositoryProvider);
  final IdempotentAction _action = IdempotentAction();

  @override
  JoinState build() {
    final auth = ref.read(authControllerProvider);
    final display = auth is AuthSignedIn ? auth.user.displayName : '';
    if (ref.read(joinAutoLoadProvider)) scheduleMicrotask(load);
    return JoinState(newName: String.fromCharCodes(display.runes.take(joinNameMax)));
  }

  void _forgetPending() => unawaited(ref.read(pendingInviteProvider.notifier).clear());

  /// Reads the preview. Keeps the typed name and the choice when the person is already on the form.
  Future<void> load() async {
    ref.read(pendingInviteProvider.notifier).markDelivered(_code);
    state = state.copyWith(phase: JoinPhase.loading, clearFailure: true);
    await _readPreview();
  }

  Future<void> _readPreview() async {
    try {
      final preview = await _repo.preview(_code);
      if (!ref.mounted) return;
      final ids = preview.unclaimedMembers?.map((m) => m.id).toSet() ?? const <String?>{};
      final stillThere = state.claimMemberId != null && ids.contains(state.claimMemberId);
      final noNames = ids.isEmpty;
      // The state of the caller decides first: a member has nothing to choose, a waiting request waits.
      if (preview.callerState == 'ALREADY_MEMBER') {
        state = state.copyWith(phase: JoinPhase.alreadyMember, preview: preview, groupName: preview.groupName, refreshing: false);
        _forgetPending();
        return;
      }
      if (preview.callerState == 'PENDING_APPROVAL') {
        state = state.copyWith(phase: JoinPhase.awaitingApproval, preview: preview, groupName: preview.groupName, refreshing: false);
        _forgetPending();
        return;
      }
      state = state.copyWith(
        phase: JoinPhase.ready,
        preview: preview,
        groupName: preview.groupName,
        clearClaim: !stillThere,
        // With no unclaimed names the only possible choice is "new member".
        joinAsNew: noNames ? true : state.joinAsNew,
        refreshing: false,
        clearFailure: true,
      );
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      await _onFailure(failure, fromPreview: true);
    }
  }

  void selectMember(String id) {
    if (state.joining) return;
    state = state.copyWith(claimMemberId: id, joinAsNew: false, duplicateName: false, clearFailure: true, claimedNotice: false);
  }

  void selectNew() {
    if (state.joining) return;
    state = state.copyWith(clearClaim: true, joinAsNew: true, claimedNotice: false, clearFailure: true);
  }

  void setName(String name) {
    state = state.copyWith(newName: name, duplicateName: false);
  }

  /// Sends the join request. A definitive answer is shown; an unknown outcome keeps the key for a retry.
  Future<void> submit() async {
    if (!state.canSubmit) return;
    state = state.copyWith(joining: true, clearFailure: true, duplicateName: false, claimedNotice: false);
    final claim = state.claimMemberId;
    final name = state.newName.trim();
    final body = claim != null ? {'claimMemberId': claim} : {'newMemberName': name};
    Future<JoinView> send(String key) => _repo.join(_code, claimMemberId: claim, newMemberName: claim == null ? name : null, key: key);
    try {
      JoinView view;
      try {
        view = await _action.run(body, send);
      } on ApiHttpFailure catch (failure) {
        if (failure.problem?.code != ApiErrorCode.idempotencyKeyReused) rethrow;
        // A client bug (SCREEN_MAP): one new key, one retry.
        _action.reset();
        view = await _action.run(body, send);
      }
      if (!ref.mounted) return;
      if (view.status == 'PENDING_APPROVAL') {
        state = state.copyWith(phase: JoinPhase.awaitingApproval, joining: false);
        _forgetPending();
        return;
      }
      final groupId = view.groupId;
      _forgetPending();
      // The new group must be in the list before the screen opens it.
      await ref.read(groupsListControllerProvider.notifier).refresh();
      if (!ref.mounted) return;
      state = state.copyWith(joining: false, joinedGroupId: groupId ?? '');
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(joining: false);
      await _onFailure(failure, fromPreview: false);
    }
  }

  /// "Refresh status" of the waiting screen: asks the server again. An approval turns it into "already a member".
  Future<void> refreshStatus() async {
    if (state.refreshing) return;
    state = state.copyWith(refreshing: true);
    final before = state.phase;
    await _readPreview();
    if (!ref.mounted) return;
    // A refresh that fails keeps the waiting screen (the request is still there).
    if (state.phase == JoinPhase.failed || state.phase == JoinPhase.rateLimited) {
      state = state.copyWith(phase: before, refreshing: false);
    }
    state = state.copyWith(refreshing: false);
  }

  Future<void> _onFailure(ApiFailure failure, {required bool fromPreview}) async {
    switch (_codeOf(failure)) {
      case ApiErrorCode.inviteExpired:
        state = state.copyWith(phase: JoinPhase.expired, refreshing: false);
        _forgetPending();
      case ApiErrorCode.inviteRevoked:
        state = state.copyWith(phase: JoinPhase.revoked, refreshing: false);
        _forgetPending();
      case ApiErrorCode.notFound:
        state = state.copyWith(phase: JoinPhase.notFound, refreshing: false);
        _forgetPending();
      case ApiErrorCode.alreadyMember:
        state = state.copyWith(phase: JoinPhase.alreadyMember, refreshing: false);
        _forgetPending();
      case ApiErrorCode.memberAlreadyClaimed:
        // Somebody took the name: read the list again, keep the form (the typed name stays).
        state = state.copyWith(claimedNotice: true, clearClaim: true);
        await _readPreview();
      case ApiErrorCode.duplicateMemberName:
        state = state.copyWith(duplicateName: true);
      case ApiErrorCode.rateLimited:
        state = state.copyWith(phase: fromPreview ? JoinPhase.rateLimited : state.phase, failure: failure, refreshing: false);
      default:
        // Offline, timeout, 5xx, validation: the preview shows a retry screen, the form shows a banner and keeps the key.
        state = state.copyWith(phase: fromPreview ? JoinPhase.failed : state.phase, failure: failure, refreshing: false);
    }
  }

  /// For tests: the key currently held for a retry.
  String? get currentKey => _action.currentKey;
}

final joinControllerProvider =
    NotifierProvider.autoDispose.family<JoinController, JoinState, String>(JoinController.new);
