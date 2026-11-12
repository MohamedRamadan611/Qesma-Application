import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/errors/api_failure.dart';

/// The only code that talks to the generated invitation API. Everything it throws is an [ApiFailure].
/// It returns what the server said and calculates nothing. The invite code is a secret: it is never logged here.
class InvitesRepository {
  InvitesRepository(this._api);

  final QesmaApi _api;

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error) {
      throw mapApiError(error);
    }
  }

  /// `POST /groups/{gid}/invites` (201). [key] is the `Idempotency-Key` of this user action.
  Future<InviteView> create(String gid, {required int expiresInDays, required bool requiresApproval, required String key}) => _run(() async {
        final command = InviteCommand((b) => b
          ..expiresInDays = expiresInDays
          ..requiresApproval = requiresApproval);
        final body = (await _api.getInviteControllerApi().createInvite(gid: gid, idempotencyKey: key, inviteCommand: command)).data;
        if (body == null) throw const ApiUnexpected();
        return body;
      });

  /// Every invite of the group the server returns (first page of up to 100, newest first).
  Future<List<InviteView>> list(String gid) => _run(() async {
        final body = (await _api.getInviteControllerApi().listInvites(gid: gid, page: 0, size: 100)).data;
        if (body == null) throw const ApiUnexpected();
        return body.items.toList();
      });

  /// `DELETE` (204). Revoking again is not an error.
  Future<void> revoke(String gid, String iid) => _run(() async {
        await _api.getInviteControllerApi().revokeInvite(gid: gid, iid: iid);
      });

  Future<InvitePreview> preview(String code) => _run(() async {
        final body = (await _api.getJoinControllerApi().getInvitePreview(code: code)).data;
        if (body == null) throw const ApiUnexpected();
        return body;
      });

  /// 201 JOINED or 202 PENDING_APPROVAL (both are a [JoinView]; branch on `status`).
  Future<JoinView> join(String code, {String? claimMemberId, String? newMemberName, required String key}) => _run(() async {
        final command = JoinCommand((b) {
          if (claimMemberId != null) b.claimMemberId = claimMemberId;
          if (newMemberName != null) b.newMemberName = newMemberName;
        });
        final body = (await _api.getJoinControllerApi().joinGroup(code: code, idempotencyKey: key, joinCommand: command)).data;
        if (body == null) throw const ApiUnexpected();
        return body;
      });
}

final invitesRepositoryProvider = Provider<InvitesRepository>((ref) => InvitesRepository(ref.watch(qesmaApiProvider)));
