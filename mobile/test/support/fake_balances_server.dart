import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'fake_expenses_server.dart';
import 'fake_groups_server.dart';

/// A response body captured from the real backend (the files in test/fixtures/balances).
dynamic balancesFixture(String name) => jsonDecode(File('test/fixtures/balances/$name.json').readAsStringSync());

Map<String, dynamic> balancesMap(String name) => (balancesFixture(name) as Map).cast<String, dynamic>();

/// The balances and settlements endpoints of the backend, as far as the client depends on them.
///
/// The server's numbers are NOT calculated here: the nets and transfers are real responses captured
/// from the backend ([balances] starts as the V1 capture), and a test says what the server answers
/// after a payment is recorded or deleted ([balancesAfterCreate], [balancesAfterDelete]). What the
/// fake does check is the contract the client depends on: `Idempotency-Key` (replay, reuse), the
/// validation codes, members of the group, paging newest first, soft delete and the second delete
/// being a 404.
class FakeBalancesServer extends FakeExpensesServer {
  FakeBalancesServer() {
    final captured = balancesMap('group_v1');
    group.members.clear();
    for (final m in (captured['members'] as List).cast<Map<String, dynamic>>()) {
      group.members.add(FakeMember(id: m['id'] as String, name: m['displayName'] as String, isYou: m['isYou'] as bool, sortOrder: m['sortOrder'] as int));
    }
    group.totalSpentMinor = captured['totalSpentMinor'] as int;
    group.yourNetMinor = captured['yourNetMinor'] as int;
    balances = balancesMap('balances_v1');
  }

  /// What `GET .../balances` answers now.
  late Map<String, dynamic> balances;

  /// What the server answers from now on once a payment is recorded / deleted.
  Map<String, dynamic>? balancesAfterCreate;
  Map<String, dynamic>? balancesAfterDelete;

  /// The payments the server lists (any order; they are served newest `settledOn` first).
  final List<Map<String, dynamic>> settlements = [];

  /// Every create request, in arrival order (replays included).
  final List<({String? key, Map<String, dynamic> body})> settlementCreates = [];

  /// The Idempotency-Key of every create attempt that reached the door, including ones never answered (offline).
  final List<String?> settlementAttemptKeys = [];

  bool balancesOffline = false;
  bool loseNextSettlementResponse = false;
  bool failNextSettlementCreate = false;
  String? forceNextSettlementCode;
  bool failNextBalances = false;
  bool failNextSettlementList = false;

  Completer<void>? holdNextBalances;
  Completer<void>? holdNextSettlementDelete;

  final Map<String, ({String body, Map<String, dynamic> response})> _stored = {};
  int _n = 0;

  String get you => group.members.firstWhere((m) => m.isYou).id;
  String member(String name) => group.members.firstWhere((m) => m.name == name).id;

  int count(String method, String part) => requests.where((r) => r.startsWith('$method ') && r.contains(part)).length;

  static final RegExp _path = RegExp(r'/api/v1/groups/([^/]+)/(balances|settlements)(?:/([^/]+))?$');

  Future<Map<String, dynamic>> _readBody(RequestOptions options, Stream<Uint8List>? stream) async {
    if (stream == null) return (options.data as Map?)?.cast<String, dynamic>() ?? {};
    final bytes = <int>[];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
    }
    return bytes.isEmpty ? {} : (jsonDecode(utf8.decode(bytes)) as Map).cast<String, dynamic>();
  }

  String _canon(Object? value) {
    Object? sorted(Object? v) {
      if (v is Map) return {for (final k in (v.keys.map((k) => '$k').toList()..sort())) k: sorted(v[k])};
      if (v is List) return v.map(sorted).toList();
      return v;
    }

    return jsonEncode(sorted(value));
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final match = _path.firstMatch(options.uri.path);
    if (match == null) return super.fetch(options, requestStream, cancelFuture);

    requests.add('${options.method} ${options.uri.path}${options.uri.hasQuery ? '?${options.uri.query}' : ''}');
    if (options.method == 'POST' && match.group(2) == 'settlements') settlementAttemptKeys.add(options.headers['Idempotency-Key'] as String?);
    if (offline || balancesOffline) {
      throw DioException.connectionError(requestOptions: options, reason: 'offline', error: const HttpException('offline'));
    }
    if (match.group(1) != gid) return problemResponse(404, 'NOT_FOUND');

    if (match.group(2) == 'balances') {
      final gate = holdNextBalances;
      holdNextBalances = null;
      if (gate != null) await gate.future;
      if (failNextBalances) {
        failNextBalances = false;
        return problemResponse(500, 'INTERNAL_ERROR');
      }
      return jsonOk(200, balances);
    }

    final sid = match.group(3);
    if (sid == null) {
      if (options.method == 'POST') return _create(options, requestStream);
      if (failNextSettlementList) {
        failNextSettlementList = false;
        return problemResponse(500, 'INTERNAL_ERROR');
      }
      return _list(options);
    }
    if (options.method == 'DELETE') {
      final current = settlements.where((s) => s['id'] == sid).firstOrNull;
      final gate = holdNextSettlementDelete;
      holdNextSettlementDelete = null;
      if (gate != null) await gate.future;
      if (current == null) return problemResponse(404, 'NOT_FOUND');
      settlements.remove(current);
      if (balancesAfterDelete != null) balances = balancesAfterDelete!;
      return jsonOk(204, null);
    }
    return problemResponse(404, 'NOT_FOUND');
  }

  ResponseBody _list(RequestOptions options) {
    final page = int.parse(options.uri.queryParameters['page'] ?? '0');
    final size = int.parse(options.uri.queryParameters['size'] ?? '20');
    final all = settlements.toList()..sort((a, b) => '${b['settledOn']}${b['createdAt']}'.compareTo('${a['settledOn']}${a['createdAt']}'));
    final pages = all.isEmpty ? 0 : (all.length + size - 1) ~/ size;
    return jsonOk(200, {'items': all.skip(page * size).take(size).toList(), 'page': page, 'size': size, 'totalElements': all.length, 'totalPages': pages});
  }

  Future<ResponseBody> _create(RequestOptions options, Stream<Uint8List>? stream) async {
    final body = await _readBody(options, stream);
    final key = options.headers['Idempotency-Key'] as String?;
    settlementCreates.add((key: key, body: copyJson(body)));
    final uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (key == null || !uuid.hasMatch(key)) return problemResponse(422, 'VALIDATION_ERROR');

    final canonical = _canon(body);
    final stored = _stored[key];
    if (stored != null) {
      if (stored.body != canonical) return problemResponse(422, 'IDEMPOTENCY_KEY_REUSED');
      return jsonOk(201, stored.response);
    }
    if (failNextSettlementCreate) {
      failNextSettlementCreate = false;
      return problemResponse(500, 'INTERNAL_ERROR');
    }
    final forced = forceNextSettlementCode;
    if (forced != null) {
      forceNextSettlementCode = null;
      return problemResponse(forced == 'NOT_FOUND' ? 404 : 422, forced);
    }
    final from = body['fromMemberId'];
    final to = body['toMemberId'];
    final amount = body['amountMinor'];
    final note = body['note'];
    final settledOn = body['settledOn'];
    final ids = group.members.map((m) => m.id).toSet();
    if (!ids.contains(from) || !ids.contains(to)) return problemResponse(422, 'MEMBER_NOT_IN_GROUP');
    if (from == to ||
        amount is! int ||
        amount < 1 ||
        amount > 1000000000000 ||
        settledOn is! String ||
        settledOn.compareTo('2000-01-01') < 0 ||
        settledOn.compareTo('2100-12-31') > 0 ||
        (note is String && note.runes.length > 200)) {
      return problemResponse(422, 'VALIDATION_ERROR');
    }
    final created = {
      'id': 'pay-${_n++}',
      'groupId': gid,
      'fromMemberId': from,
      'toMemberId': to,
      'amountMinor': amount,
      'settledOn': settledOn,
      if (note is String && note.trim().isNotEmpty) 'note': note.trim(),
      'createdAt': '2026-11-10T10:00:${(_n % 60).toString().padLeft(2, '0')}Z',
    };
    settlements.add(created);
    _stored[key] = (body: canonical, response: created);
    if (balancesAfterCreate != null) balances = balancesAfterCreate!;
    if (loseNextSettlementResponse) {
      loseNextSettlementResponse = false;
      throw DioException.receiveTimeout(requestOptions: options, timeout: const Duration(seconds: 20));
    }
    return jsonOk(201, created);
  }

  /// Loads the captured payment (8000 from Asem to you, "cash on the road") and the V2 balances the
  /// server answered with after it, as a state the server is already in.
  void seedV2() {
    settlements.add(Map<String, dynamic>.from((balancesMap('settlement_created'))));
    balances = balancesMap('balances_v2');
    group.yourNetMinor = balancesMap('group_v2')['yourNetMinor'] as int;
  }
}
