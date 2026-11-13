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
/// after a payment is created or a settlement changes state ([balancesAfterCreate], [balancesAfterAction]).
/// What the fake does check is the contract the client depends on: `Idempotency-Key` (replay, reuse), the
/// validation codes, members of the group, paging newest first, the status filter, who creates what (A85), the
/// transition table (A84: who may confirm / dispute / cancel, the idempotent repeat, 409 INVALID_STATE_TRANSITION).
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

  /// What the server answers from now on once a payment is created / a settlement changes state.
  Map<String, dynamic>? balancesAfterCreate;
  Map<String, dynamic>? balancesAfterAction;

  /// The payments the server lists (any order; they are served newest `settledOn` first), every status.
  final List<Map<String, dynamic>> settlements = [];

  /// Every create request, in arrival order (replays included).
  final List<({String? key, Map<String, dynamic> body})> settlementCreates = [];

  /// The Idempotency-Key of every create attempt that reached the door, including ones never answered (offline).
  final List<String?> settlementAttemptKeys = [];

  /// Every confirm / dispute / cancel that reached the door, as `action sid`.
  final List<String> transitions = [];

  bool balancesOffline = false;
  bool loseNextSettlementResponse = false;
  bool failNextSettlementCreate = false;
  String? forceNextSettlementCode;
  bool failNextBalances = false;
  bool failNextSettlementList = false;

  /// Answer the next transition with this status and problem code, then forget it.
  ({int status, String code})? forceNextTransition;

  Completer<void>? holdNextBalances;
  Completer<void>? holdNextSettlementAction;

  final Map<String, ({String body, Map<String, dynamic> response})> _stored = {};
  int _n = 0;

  String get you => group.members.firstWhere((m) => m.isYou).id;
  String member(String name) => group.members.firstWhere((m) => m.name == name).id;

  int count(String method, String part) => requests.where((r) => r.startsWith('$method ') && r.contains(part)).length;

  bool get _isAdmin => group.yourRole == 'OWNER' || group.yourRole == 'ADMIN';

  static final RegExp _path = RegExp(r'/api/v1/groups/([^/]+)/(balances|settlements)(?:/([^/]+)(?:/(confirm|dispute|cancel))?)?$');

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
    if (options.method == 'POST' && match.group(2) == 'settlements' && match.group(3) == null) {
      settlementAttemptKeys.add(options.headers['Idempotency-Key'] as String?);
    }
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
    final action = match.group(4);
    if (options.method == 'POST' && action != null) return _transition(sid, action);
    return problemResponse(404, 'NOT_FOUND');
  }

  /// The state machine of B13 (A84) as far as the client depends on it. The balances are NOT recalculated: a test says
  /// what the server answers afterwards ([balancesAfterAction]).
  Future<ResponseBody> _transition(String sid, String action) async {
    transitions.add('$action $sid');
    final gate = holdNextSettlementAction;
    holdNextSettlementAction = null;
    if (gate != null) await gate.future;
    final forced = forceNextTransition;
    if (forced != null) {
      forceNextTransition = null;
      return problemResponse(forced.status, forced.code);
    }
    final current = settlements.where((s) => s['id'] == sid).firstOrNull;
    if (current == null) return problemResponse(404, 'NOT_FOUND');
    final isPayer = current['fromMemberId'] == you;
    final isReceiver = current['toMemberId'] == you;
    final allowed = switch (action) {
      'confirm' => isReceiver || (_isAdmin && !isPayer),
      'dispute' => isReceiver,
      _ => isPayer || _isAdmin,
    };
    if (!allowed) return problemResponse(403, 'FORBIDDEN');
    final from = current['status'] as String;
    final to = switch (action) {
      'confirm' => 'CONFIRMED',
      'dispute' => 'DISPUTED',
      _ => 'CANCELLED',
    };
    if (from == to) return jsonOk(200, current);
    final ok = switch (action) {
      'confirm' => from == 'PENDING' || from == 'DISPUTED',
      'dispute' => from == 'PENDING',
      _ => from == 'PENDING' || from == 'DISPUTED',
    };
    if (!ok) return problemResponse(409, 'INVALID_STATE_TRANSITION');
    current['status'] = to;
    current[switch (action) {
      'confirm' => 'confirmedAt',
      'dispute' => 'disputedAt',
      _ => 'cancelledAt',
    }] = '2026-11-10T13:00:00Z';
    if (balancesAfterAction != null) balances = balancesAfterAction!;
    return jsonOk(200, current);
  }

  ResponseBody _list(RequestOptions options) {
    final page = int.parse(options.uri.queryParameters['page'] ?? '0');
    final size = int.parse(options.uri.queryParameters['size'] ?? '20');
    final statuses = options.uri.queryParametersAll['status'] ?? const <String>[];
    final all = settlements.where((s) => statuses.isEmpty || statuses.contains(s['status'])).toList()
      ..sort((a, b) => '${b['settledOn']}${b['createdAt']}'.compareTo('${a['settledOn']}${a['createdAt']}'));
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
    // A85: the status is the server's decision. The payer declaring to a member with an account = PENDING; the receiver
    // recording = CONFIRMED; an Owner/Admin on behalf = CONFIRMED; a plain Member for anybody else, or paying a member
    // without an account (nobody could confirm) = 403.
    final receiverHasAccount = group.members.firstWhere((m) => m.id == to).hasAccount;
    final String status;
    var byAdmin = false;
    if (from == you) {
      if (receiverHasAccount) {
        status = 'PENDING';
      } else if (_isAdmin) {
        status = 'CONFIRMED';
        byAdmin = true;
      } else {
        return problemResponse(403, 'FORBIDDEN');
      }
    } else if (to == you) {
      status = 'CONFIRMED';
    } else if (_isAdmin) {
      status = 'CONFIRMED';
      byAdmin = true;
    } else {
      return problemResponse(403, 'FORBIDDEN');
    }
    final stamp = '2026-11-10T10:00:${(_n % 60).toString().padLeft(2, '0')}Z';
    final created = {
      'id': 'pay-${_n++}',
      'groupId': gid,
      'fromMemberId': from,
      'toMemberId': to,
      'amountMinor': amount,
      'settledOn': settledOn,
      if (note is String && note.trim().isNotEmpty) 'note': note.trim(),
      'createdAt': stamp,
      'declaredAt': stamp,
      'status': status,
      'recordedByAdmin': byAdmin,
      'createdByMemberId': you,
      if (status == 'CONFIRMED') 'confirmedAt': stamp,
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

  /// Makes the signed-in person [name] with [role] (the members and their ids stay the captured ones).
  void actAs(String name, {String role = 'MEMBER'}) {
    final old = group.members.toList();
    group.members.clear();
    for (final m in old) {
      final me = m.name == name;
      group.members.add(FakeMember(
        id: m.id,
        name: m.name,
        isYou: me,
        sortOrder: m.sortOrder,
        role: me ? role : (m.role == 'OWNER' ? 'MEMBER' : m.role),
        linked: m.linked || me,
      ));
    }
    group.yourRole = role;
  }

  /// Gives every member an account (a pending payment needs a payer and a receiver with one).
  void linkAll() {
    for (final m in group.members) {
      m.linked = true;
    }
  }

  /// Adds one of the settlements of `settlements_by_status.json` (pending, disputed, confirmed, cancelled, adminRecorded).
  Map<String, dynamic> seedSettlement(String key) {
    final s = (balancesMap('settlements_by_status')[key] as Map).cast<String, dynamic>();
    settlements.add(s);
    return s;
  }

  /// Loads the captured payment (8000 from Asem to you, "cash on the road") and the V2 balances the
  /// server answered with after it, as a state the server is already in.
  void seedV2() {
    settlements.add(Map<String, dynamic>.from((balancesMap('settlement_created'))));
    balances = balancesMap('balances_v2');
    group.yourNetMinor = balancesMap('group_v2')['yourNetMinor'] as int;
  }
}
