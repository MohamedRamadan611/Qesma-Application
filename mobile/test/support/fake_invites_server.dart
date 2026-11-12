import 'dart:convert';
import 'dart:io' show HttpException;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:qesma/features/invites/application/invite_sheet_controller.dart';

import 'fake_groups_server.dart';

class FakeInvite {
  FakeInvite({
    required this.id,
    required this.gid,
    required this.code,
    required this.expiresAt,
    required this.createdAt,
    this.requiresApproval = false,
    this.maxUses,
    this.useCount = 0,
    this.status = 'ACTIVE',
  });

  final String id;
  final String gid;
  final String code;
  final DateTime expiresAt;
  final DateTime createdAt;
  final bool requiresApproval;
  final int? maxUses;
  int useCount;
  String status;
  DateTime? revokedAt;
}

/// What `GET /invites/{code}` answers for one code (the shape of `InvitePreview`: no balances, no expense counts).
class FakePreview {
  FakePreview({
    this.groupName = 'رحلة دهب',
    this.groupType = 'TRIP',
    this.inviterName = 'محمد',
    this.memberCount = 5,
    this.requiresApproval = false,
    this.callerState = 'NONE',
    List<({String id, String name})>? unclaimed,
  }) : unclaimed = unclaimed ?? [(id: 'u1', name: 'محسن'), (id: 'u2', name: 'يوسف'), (id: 'u3', name: 'كريم')];

  String groupName;
  String groupType;
  String inviterName;
  int memberCount;
  bool requiresApproval;
  String callerState;
  List<({String id, String name})> unclaimed;
}

/// The invitation endpoints on top of the groups server: create/list/revoke for the Owner/Admin and preview/join for
/// anyone. Faults are queued per operation; every request is recorded WITHOUT the code (it is a secret).
class FakeInvitesServer extends FakeGroupsServer {
  final Map<String, FakeInvite> invites = {};
  final Map<String, FakePreview> previews = {};

  /// `(status, code)` answered by the next preview / join / create call, in order.
  final List<(int, String)> previewFaults = [];
  final List<(int, String)> joinFaults = [];
  final List<(int, String)> createFaults = [];

  /// The next join call loses its answer (timeout) after the server stored the join.
  bool loseNextJoinResponse = false;

  final List<Map<String, dynamic>> joinBodies = [];
  final List<String> joinKeys = [];
  final List<String> createKeys = [];
  final List<Map<String, dynamic>> createBodies = [];
  final List<String> revoked = [];
  int previewCalls = 0;
  int _n = 0;

  /// Result of the next successful join: 201 JOINED (default) or 202 PENDING_APPROVAL.
  bool joinNeedsApproval = false;
  String joinedGroupId = 'g1';

  FakeInvite addInvite(String gid, {String? code, Duration expiresIn = const Duration(days: 7), bool requiresApproval = false, int? maxUses, DateTime? createdAt}) {
    _n++;
    final invite = FakeInvite(
      id: 'i$_n',
      gid: gid,
      code: code ?? 'ABCD${2345 + _n}',
      expiresAt: _now.add(expiresIn),
      createdAt: createdAt ?? _now.subtract(Duration(minutes: 10 - _n)),
      requiresApproval: requiresApproval,
      maxUses: maxUses,
    );
    invites[invite.id] = invite;
    return invite;
  }

  /// The server clock of the fixtures: the widget tests fix the device clock to the same instant.
  static final DateTime serverNow = DateTime.utc(2026, 10, 18, 12);
  DateTime get _now => serverNow;

  Map<String, dynamic> inviteJson(FakeInvite i) => {
        'id': i.id,
        'groupId': i.gid,
        'code': i.code,
        'link': 'https://qesma.app/join/${i.code}',
        'expiresAt': i.expiresAt.toIso8601String(),
        'createdAt': i.createdAt.toIso8601String(),
        'maxUses': i.maxUses,
        'useCount': i.useCount,
        'requiresApproval': i.requiresApproval,
        'status': i.status,
        'revokedAt': i.revokedAt?.toIso8601String(),
      }..removeWhere((_, v) => v == null);

  Future<Map<String, dynamic>> _body(RequestOptions options, Stream<Uint8List>? stream) async {
    if (stream == null) return (options.data as Map?)?.cast<String, dynamic>() ?? {};
    final bytes = <int>[];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
    }
    return bytes.isEmpty ? {} : jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  ResponseBody? _fault(List<(int, String)> queue) {
    if (queue.isEmpty) return null;
    final (status, code) = queue.removeAt(0);
    return problemResponse(status, code);
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final path = options.uri.path;
    final method = options.method;
    final isInviteApi = path.contains('/api/v1/invites/') || RegExp(r'/api/v1/groups/[^/]+/invites').hasMatch(path);
    if (!isInviteApi) return super.fetch(options, requestStream, cancelFuture);

    // The code is a secret: the request log keeps only the shape of the call.
    requests.add('$method ${path.replaceAllMapped(RegExp(r'(/invites/)[^/]+'), (m) => '${m[1]}*')}');
    if (offline) {
      throw DioException.connectionError(requestOptions: options, reason: 'offline', error: const HttpException('offline'));
    }

    // /groups/{gid}/invites[/{iid}]
    final groupMatch = RegExp(r'/api/v1/groups/([^/]+)/invites(?:/([^/]+))?$').firstMatch(path);
    if (groupMatch != null) {
      final gid = groupMatch.group(1)!;
      final iid = groupMatch.group(2);
      if (iid == null && method == 'GET') {
        final items = invites.values.where((i) => i.gid == gid).toList();
        return jsonOk(200, {'items': [for (final i in items) inviteJson(i)], 'page': 0, 'size': 100, 'totalElements': items.length, 'totalPages': 1});
      }
      if (iid == null && method == 'POST') {
        final fault = _fault(createFaults);
        final body = await _body(options, requestStream);
        createBodies.add(body);
        createKeys.add('${options.headers['Idempotency-Key']}');
        if (fault != null) return fault;
        final invite = addInvite(gid, expiresIn: Duration(days: body['expiresInDays'] as int? ?? 7), requiresApproval: body['requiresApproval'] as bool? ?? false);
        return jsonOk(201, inviteJson(invite));
      }
      if (iid != null && method == 'DELETE') {
        final invite = invites[iid];
        if (invite == null) return problemResponse(404, 'NOT_FOUND');
        revoked.add(iid);
        invite.status = 'REVOKED';
        invite.revokedAt = _now;
        return jsonOk(204, null);
      }
    }

    // /invites/{code}[/join]
    final inviteMatch = RegExp(r'/api/v1/invites/([^/]+)(/join)?$').firstMatch(path);
    if (inviteMatch != null) {
      final code = inviteMatch.group(1)!;
      if (inviteMatch.group(2) == null && method == 'GET') {
        previewCalls++;
        final fault = _fault(previewFaults);
        if (fault != null) return fault;
        final preview = previews[code];
        if (preview == null) return problemResponse(404, 'NOT_FOUND');
        return jsonOk(200, {
          'groupName': preview.groupName,
          'groupType': preview.groupType,
          'inviterName': preview.inviterName,
          'memberCount': preview.memberCount,
          'requiresApproval': preview.requiresApproval,
          'callerState': preview.callerState,
          'expiresAt': _now.add(const Duration(days: 5)).toIso8601String(),
          'unclaimedMembers': [for (final m in preview.unclaimed) {'id': m.id, 'name': m.name}],
        });
      }
      if (inviteMatch.group(2) != null && method == 'POST') {
        final body = await _body(options, requestStream);
        joinBodies.add(body);
        joinKeys.add('${options.headers['Idempotency-Key']}');
        final fault = _fault(joinFaults);
        if (fault != null) return fault;
        if (loseNextJoinResponse) {
          loseNextJoinResponse = false;
          throw DioException.receiveTimeout(requestOptions: options, timeout: const Duration(seconds: 20));
        }
        if (joinNeedsApproval) {
          return jsonOk(202, {'status': 'PENDING_APPROVAL', 'groupId': joinedGroupId, 'requestId': 'r1'});
        }
        return jsonOk(201, {
          'status': 'JOINED',
          'groupId': joinedGroupId,
          'member': {'id': 'm9', 'displayName': body['newMemberName'] ?? 'محسن', 'role': 'MEMBER'},
        });
      }
    }
    return problemResponse(404, 'NOT_FOUND');
  }
}

/// Records what would be shared or copied.
class RecordingSharer implements InviteSharer {
  final List<String> shared = [];

  @override
  Future<void> share(String text) async => shared.add(text);
}
