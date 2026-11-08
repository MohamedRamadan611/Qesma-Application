import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/etag_store.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/errors/api_failure.dart';

/// One page of the groups list.
typedef GroupsPage = ({List<GroupSummaryDto> items, int page, int totalPages});

/// The only code that talks to the generated groups and members API. Everything it
/// throws is an [ApiFailure]; widgets and notifiers never see Dio.
class GroupsRepository {
  GroupsRepository(this._api, this._etags);

  final QesmaApi _api;
  final ETagStore _etags;

  static const int pageSize = 20;

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error) {
      throw mapApiError(error);
    }
  }

  Future<GroupsPage> list({int page = 0}) => _run(() async {
        final response = await _api.getGroupControllerApi().listGroups(page: page, size: pageSize);
        final body = response.data;
        if (body == null) throw const ApiUnexpected();
        return (items: body.items.toList(), page: body.page, totalPages: body.totalPages);
      });

  /// Every page of the list, up to [maxPages] (used to reconcile after a lost create response).
  Future<List<GroupSummaryDto>> listAll({int maxPages = 10}) async {
    final all = <GroupSummaryDto>[];
    var page = 0;
    while (page < maxPages) {
      final result = await list(page: page);
      all.addAll(result.items);
      page++;
      if (page >= result.totalPages) break;
    }
    return all;
  }

  /// Reads a group and remembers its version for the next `If-Match`.
  Future<GroupDto> get(String gid) => _run(() async {
        final response = await _api.getGroupControllerApi().getGroup(gid: gid);
        final group = response.data;
        if (group == null) throw const ApiUnexpected();
        _etags.remember(gid, response.headers.value('etag'));
        if (_etags.versionOf(gid) == null) _etags.remember(gid, '"${group.version}"');
        return group;
      });

  Future<GroupDto> create({required String name, required String type, String currencyCode = 'EGP'}) => _run(() async {
        final response = await _api.getGroupControllerApi().createGroup(
              createGroupRequest: CreateGroupRequest((b) => b
                ..name = name
                ..type = type
                ..currencyCode = currencyCode),
            );
        final group = response.data;
        if (group == null) throw const ApiUnexpected();
        _etags.remember(group.id, response.headers.value('etag'));
        return group;
      });

  /// `PATCH` with `If-Match`. The group must have been read first (no blind edits).
  Future<GroupDto> update(String gid, {required String name, required String type}) => _run(() async {
        final ifMatch = _etags.ifMatchFor(gid);
        if (ifMatch == null) throw const ApiUnexpected();
        final response = await _api.getGroupControllerApi().updateGroup(
              gid: gid,
              ifMatch: ifMatch,
              updateGroupRequest: UpdateGroupRequest((b) => b
                ..name = name
                ..type = type),
            );
        final group = response.data;
        if (group == null) throw const ApiUnexpected();
        _etags.remember(gid, response.headers.value('etag'));
        if (_etags.versionOf(gid) == null) _etags.remember(gid, '"${group.version}"');
        return group;
      });

  Future<void> delete(String gid) => _run(() async {
        await _api.getGroupControllerApi().deleteGroup(gid: gid);
        _etags.forget(gid);
      });

  Future<MemberDto> addMember(String gid, String name) => _run(() async {
        final response = await _api.getMemberControllerApi().addMember(
              gid: gid,
              createMemberRequest: CreateMemberRequest((b) => b.displayName = name),
            );
        final member = response.data;
        if (member == null) throw const ApiUnexpected();
        return member;
      });

  Future<MemberDto> renameMember(String gid, String mid, String name) => _run(() async {
        final response = await _api.getMemberControllerApi().renameMember(
              gid: gid,
              mid: mid,
              updateMemberRequest: UpdateMemberRequest((b) => b.displayName = name),
            );
        final member = response.data;
        if (member == null) throw const ApiUnexpected();
        return member;
      });

  Future<void> deleteMember(String gid, String mid) =>
      _run(() async => _api.getMemberControllerApi().deleteMember(gid: gid, mid: mid));
}

final groupsRepositoryProvider = Provider<GroupsRepository>(
  (ref) => GroupsRepository(ref.watch(qesmaApiProvider), ref.watch(etagStoreProvider)),
);
