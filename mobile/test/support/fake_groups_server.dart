import 'dart:convert';
import 'dart:io' show HttpException;
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'fake_backend.dart';

/// How the next `POST /groups` should misbehave.
enum CreateFault { none, loseResponseAfterStoring, serverErrorNothingStored, validation }

class FakeGroup {
  FakeGroup({
    required this.id,
    required this.name,
    required this.type,
    this.currency = 'EGP',
    this.totalSpentMinor = 0,
    this.yourNetMinor = 0,
    this.hasExpenses = false,
    this.lastExpenseAt,
  }) : createdAt = DateTime.utc(2026, 10, 1, 9);

  final String id;
  String name;
  String type;
  String currency;
  int version = 1;
  int totalSpentMinor;
  int yourNetMinor;
  bool hasExpenses;
  DateTime? lastExpenseAt;
  final DateTime createdAt;
  final List<FakeMember> members = [];
}

class FakeMember {
  FakeMember({required this.id, required this.name, this.isYou = false, this.hasTransactions = false, required this.sortOrder});

  final String id;
  String name;
  final bool isYou;
  bool hasTransactions;
  final int sortOrder;
}

/// The groups/members endpoints of the backend, as far as the client depends on them:
/// paging, ETag and `If-Match` (409 `VERSION_CONFLICT`), duplicate member names, blocked
/// deletes and a create whose response can be lost. Auth endpoints come from [FakeBackend].
class FakeGroupsServer extends FakeBackend {
  FakeGroupsServer() : super(refreshDelay: Duration.zero);

  final Map<String, FakeGroup> groups = {};
  final List<String> requests = [];
  CreateFault nextCreateFault = CreateFault.none;
  bool offline = false;

  /// After a faulty create the network drops (the client cannot check the list at once).
  bool goOfflineAfterFault = false;
  int _n = 0;

  /// Adds a group with the owner member ("you") already in it, like `POST /groups` does.
  FakeGroup seed({
    String? name,
    String type = 'TRIP',
    int total = 0,
    int net = 0,
    bool hasExpenses = false,
    String currency = 'EGP',
    DateTime? lastExpenseAt,
  }) {
    _n++;
    final g = FakeGroup(
      id: 'g$_n',
      name: name ?? 'Group $_n',
      type: type,
      currency: currency,
      totalSpentMinor: total,
      yourNetMinor: net,
      hasExpenses: hasExpenses,
      lastExpenseAt: lastExpenseAt,
    );
    g.members.add(FakeMember(id: '${g.id}-m1', name: 'Me', isYou: true, sortOrder: 1));
    groups[g.id] = g;
    return g;
  }

  Map<String, dynamic> _member(FakeMember m) => {
        'id': m.id,
        'displayName': m.name,
        'isYou': m.isYou,
        'sortOrder': m.sortOrder,
        'createdAt': '2026-10-01T09:00:00Z',
      };

  Map<String, dynamic> _group(FakeGroup g) => {
        'id': g.id,
        'name': g.name,
        'type': g.type,
        'currencyCode': g.currency,
        'version': g.version,
        'totalSpentMinor': g.totalSpentMinor,
        'yourNetMinor': g.yourNetMinor,
        'yourMemberId': g.members.firstWhere((m) => m.isYou).id,
        if (g.lastExpenseAt != null) 'lastExpenseAt': g.lastExpenseAt!.toUtc().toIso8601String(),
        'members': [for (final m in g.members) _member(m)],
        'createdAt': g.createdAt.toIso8601String(),
        'updatedAt': g.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _summary(FakeGroup g) => {
        'id': g.id,
        'name': g.name,
        'type': g.type,
        'currencyCode': g.currency,
        'memberCount': g.members.length,
        'totalSpentMinor': g.totalSpentMinor,
        'yourNetMinor': g.yourNetMinor,
        if (g.lastExpenseAt != null) 'lastExpenseAt': g.lastExpenseAt!.toUtc().toIso8601String(),
      };

  ResponseBody jsonOk(int status, Object? body, {String? etag}) => ResponseBody.fromString(
        body == null ? '' : jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [body == null ? 'text/plain' : 'application/json'],
          if (etag != null) 'etag': ['"$etag"'],
        },
      );

  ResponseBody problemResponse(int status, String code) => ResponseBody.fromString(
        jsonEncode({'type': 'https://qesma.app/problems/x', 'title': 'x', 'status': status, 'code': code, 'requestId': 'req-$status'}),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/problem+json'],
        },
      );

  Future<Map<String, dynamic>> _json(RequestOptions options, Stream<Uint8List>? stream) async {
    if (stream == null) return (options.data as Map?)?.cast<String, dynamic>() ?? {};
    final bytes = <int>[];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
    }
    return bytes.isEmpty ? {} : jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final path = options.uri.path;
    if (!path.contains('/api/v1/groups')) return super.fetch(options, requestStream, cancelFuture);

    requests.add('${options.method} ${options.uri.path}${options.uri.hasQuery ? '?${options.uri.query}' : ''}'
        '${options.headers['If-Match'] != null ? ' if-match=${options.headers['If-Match']}' : ''}');
    if (offline) {
      throw DioException.connectionError(requestOptions: options, reason: 'offline', error: const HttpException('offline'));
    }

    final parts = path.split('/api/v1/groups').last.split('/').where((p) => p.isNotEmpty).toList();
    final method = options.method;

    // /groups
    if (parts.isEmpty) {
      if (method == 'GET') {
        final page = int.parse(options.uri.queryParameters['page'] ?? '0');
        final size = int.parse(options.uri.queryParameters['size'] ?? '20');
        final all = groups.values.toList();
        final pages = all.isEmpty ? 1 : (all.length + size - 1) ~/ size;
        final slice = all.skip(page * size).take(size).toList();
        return jsonOk(200, {'items': [for (final g in slice) _summary(g)], 'page': page, 'size': size, 'totalElements': all.length, 'totalPages': pages});
      }
      if (method == 'POST') return _create(options, requestStream);
    }

    final group = groups[parts.first];
    if (group == null) return problemResponse(404, 'NOT_FOUND');

    // /groups/{gid}
    if (parts.length == 1) {
      switch (method) {
        case 'GET':
          return jsonOk(200, _group(group), etag: '${group.version}');
        case 'PATCH':
          final sent = options.headers['If-Match'] as String?;
          if (sent != '"${group.version}"') return problemResponse(409, 'VERSION_CONFLICT');
          final body = await _json(options, requestStream);
          group
            ..name = body['name'] as String
            ..type = body['type'] as String
            ..version += 1;
          return jsonOk(200, _group(group), etag: '${group.version}');
        case 'DELETE':
          if (group.hasExpenses) return problemResponse(409, 'GROUP_NOT_EMPTY');
          groups.remove(group.id);
          return jsonOk(204, null);
      }
    }

    // /groups/{gid}/members[/{mid}]
    if (parts.length >= 2 && parts[1] == 'members') {
      if (parts.length == 2 && method == 'POST') {
        final name = (await _json(options, requestStream))['displayName'] as String;
        if (group.members.any((m) => m.name == name)) return problemResponse(409, 'DUPLICATE_MEMBER_NAME');
        final member = FakeMember(id: '${group.id}-m${group.members.length + 1}', name: name, sortOrder: group.members.length + 1);
        group.members.add(member);
        return jsonOk(201, _member(member));
      }
      final member = parts.length == 3 ? group.members.where((m) => m.id == parts[2]).firstOrNull : null;
      if (member == null) return problemResponse(404, 'NOT_FOUND');
      if (method == 'PATCH') {
        final name = (await _json(options, requestStream))['displayName'] as String;
        if (group.members.any((m) => m.name == name && m.id != member.id)) return problemResponse(409, 'DUPLICATE_MEMBER_NAME');
        member.name = name;
        return jsonOk(200, _member(member));
      }
      if (method == 'DELETE') {
        if (member.isYou) return problemResponse(409, 'OWNER_MEMBER_PROTECTED');
        if (member.hasTransactions) return problemResponse(409, 'MEMBER_HAS_TRANSACTIONS');
        group.members.remove(member);
        return jsonOk(204, null);
      }
    }
    return problemResponse(404, 'NOT_FOUND');
  }

  Future<ResponseBody> _create(RequestOptions options, Stream<Uint8List>? stream) async {
    final fault = nextCreateFault;
    nextCreateFault = CreateFault.none;
    final body = await _json(options, stream);
    switch (fault) {
      case CreateFault.validation:
        return problemResponse(422, 'VALIDATION_ERROR');
      case CreateFault.serverErrorNothingStored:
        return problemResponse(500, 'INTERNAL_ERROR');
      case CreateFault.none:
      case CreateFault.loseResponseAfterStoring:
        break;
    }
    final g = seed(name: body['name'] as String, type: body['type'] as String);
    if (fault == CreateFault.loseResponseAfterStoring) {
      if (goOfflineAfterFault) offline = true;
      throw DioException.receiveTimeout(requestOptions: options, timeout: const Duration(seconds: 20));
    }
    return jsonOk(201, _group(g), etag: '${g.version}');
  }
}
