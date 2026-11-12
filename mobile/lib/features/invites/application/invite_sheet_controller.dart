import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/idempotent_action.dart';
import '../../../core/errors/api_failure.dart';
import '../data/invites_repository.dart';

/// Expiry choices of the design (days). The API allows 1..30; "never" in the mock-up is omitted.
const List<int> inviteExpiryChoices = [1, 7, 30];
const int inviteDefaultExpiryDays = 7;

/// Opens the system share sheet. Behind an interface so tests see exactly what would be shared.
abstract interface class InviteSharer {
  Future<void> share(String text);
}

class SystemInviteSharer implements InviteSharer {
  const SystemInviteSharer();

  @override
  Future<void> share(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }
}

final inviteSharerProvider = Provider<InviteSharer>((ref) => const SystemInviteSharer());

/// Puts text on the clipboard. Behind a provider so tests can record it.
typedef ClipboardWriter = Future<void> Function(String text);
final clipboardWriterProvider = Provider<ClipboardWriter>((ref) => (text) => Clipboard.setData(ClipboardData(text: text)));

/// Time left of an invite, computed from the server's `expiresAt` (never from a stored duration).
sealed class InviteRemaining {
  const InviteRemaining();
}

final class RemainingDays extends InviteRemaining {
  const RemainingDays(this.days);
  final int days;
}

final class RemainingHours extends InviteRemaining {
  const RemainingHours(this.hours);
  final int hours;
}

final class RemainingSoon extends InviteRemaining {
  const RemainingSoon();
}

final class RemainingNone extends InviteRemaining {
  const RemainingNone();
}

/// Days when a day or more is left (rounded down), hours when less, "soon" under an hour, none once past.
InviteRemaining inviteRemaining(DateTime? expiresAt, DateTime now) {
  if (expiresAt == null) return const RemainingNone();
  final left = expiresAt.difference(now);
  if (left <= Duration.zero) return const RemainingNone();
  if (left.inDays >= 1) return RemainingDays(left.inDays);
  if (left.inHours >= 1) return RemainingHours(left.inHours);
  return const RemainingSoon();
}

class InviteSheetState {
  const InviteSheetState({
    this.loading = true,
    this.invites = const [],
    this.failure,
    this.creating = false,
    this.expiresInDays = inviteDefaultExpiryDays,
    this.requiresApproval = false,
    this.revokingId,
  });

  final bool loading;

  /// Active invites only, newest first.
  final List<InviteView> invites;
  final ApiFailure? failure;
  final bool creating;
  final int expiresInDays;
  final bool requiresApproval;
  final String? revokingId;

  bool get busy => creating || revokingId != null;

  InviteSheetState copyWith({
    bool? loading,
    List<InviteView>? invites,
    ApiFailure? failure,
    bool clearFailure = false,
    bool? creating,
    int? expiresInDays,
    bool? requiresApproval,
    String? revokingId,
    bool clearRevoking = false,
  }) =>
      InviteSheetState(
        loading: loading ?? this.loading,
        invites: invites ?? this.invites,
        failure: clearFailure ? null : (failure ?? this.failure),
        creating: creating ?? this.creating,
        expiresInDays: expiresInDays ?? this.expiresInDays,
        requiresApproval: requiresApproval ?? this.requiresApproval,
        revokingId: clearRevoking ? null : (revokingId ?? this.revokingId),
      );

  @override
  String toString() => 'InviteSheetState(loading: $loading, invites: ${invites.length})';
}

/// Tests switch this off to drive [InviteSheetController.load] themselves.
final inviteSheetAutoLoadProvider = Provider<bool>((ref) => true);

/// The invitations of one group, for the Owner/Admin. Create is idempotent (one key per user action, reused when the
/// same settings are sent again after an unknown outcome); revoke is a soft delete and repeating it is harmless.
class InviteSheetController extends Notifier<InviteSheetState> {
  InviteSheetController(this.gid);

  final String gid;

  late final InvitesRepository _repo = ref.read(invitesRepositoryProvider);
  final IdempotentAction _action = IdempotentAction();

  @override
  InviteSheetState build() {
    if (ref.read(inviteSheetAutoLoadProvider)) scheduleMicrotask(load);
    return const InviteSheetState();
  }

  static List<InviteView> _active(List<InviteView> all) {
    final active = all.where((i) => i.status == 'ACTIVE' && i.revokedAt == null).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return active;
  }

  Future<ApiFailure?> load() async {
    state = state.copyWith(loading: true, clearFailure: true);
    try {
      final all = await _repo.list(gid);
      if (!ref.mounted) return null;
      state = state.copyWith(loading: false, invites: _active(all));
      return null;
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return failure;
      state = state.copyWith(loading: false, failure: failure);
      return failure;
    }
  }

  void setExpiry(int days) {
    if (state.busy || !inviteExpiryChoices.contains(days)) return;
    state = state.copyWith(expiresInDays: days);
  }

  void setRequiresApproval(bool value) {
    if (state.busy) return;
    state = state.copyWith(requiresApproval: value);
  }

  /// Creates an invite with the chosen settings. Returns the failure (null = success).
  Future<ApiFailure?> create() async {
    if (state.busy) return null;
    state = state.copyWith(creating: true);
    final days = state.expiresInDays;
    final approval = state.requiresApproval;
    try {
      await _action.run(
        {'expiresInDays': days, 'requiresApproval': approval},
        (key) => _repo.create(gid, expiresInDays: days, requiresApproval: approval, key: key),
      );
    } on ApiFailure catch (failure) {
      if (ref.mounted) state = state.copyWith(creating: false);
      return failure;
    }
    if (!ref.mounted) return null;
    state = state.copyWith(creating: false);
    await load();
    return null;
  }

  /// Revokes one invite, then re-reads the list. Returns the failure (null = success).
  Future<ApiFailure?> revoke(String iid) async {
    if (state.busy) return null;
    state = state.copyWith(revokingId: iid);
    try {
      await _repo.revoke(gid, iid);
    } on ApiFailure catch (failure) {
      if (ref.mounted) state = state.copyWith(clearRevoking: true);
      return failure;
    }
    if (!ref.mounted) return null;
    state = state.copyWith(clearRevoking: true);
    await load();
    return null;
  }

  /// For tests.
  String? get currentKey => _action.currentKey;
}

final inviteSheetControllerProvider =
    NotifierProvider.autoDispose.family<InviteSheetController, InviteSheetState, String>(InviteSheetController.new);
