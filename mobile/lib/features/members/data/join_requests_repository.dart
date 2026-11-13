import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/errors/api_failure.dart';

/// The join-request endpoints (Owner/Admin). Everything it throws is an [ApiFailure]. Shows what the server said.
class JoinRequestsRepository {
  JoinRequestsRepository(this._api);

  final QesmaApi _api;

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error) {
      throw mapApiError(error);
    }
  }

  /// The pending requests of the group (first page of up to 100).
  Future<List<JoinRequestView>> listPending(String gid) => _run(() async {
        final body = (await _api.getJoinRequestControllerApi().listJoinRequests(gid: gid, page: 0, size: 100)).data;
        if (body == null) throw const ApiUnexpected();
        return body.items.where((r) => r.status == null || r.status == 'PENDING').toList();
      });

  Future<void> approve(String gid, String rid) =>
      _run(() async => _api.getJoinRequestControllerApi().approveJoinRequest(gid: gid, rid: rid));

  Future<void> reject(String gid, String rid) =>
      _run(() async => _api.getJoinRequestControllerApi().rejectJoinRequest(gid: gid, rid: rid));
}

final joinRequestsRepositoryProvider =
    Provider<JoinRequestsRepository>((ref) => JoinRequestsRepository(ref.watch(qesmaApiProvider)));
