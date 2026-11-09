import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:qesma_api/qesma_api.dart';

import 'fake_groups_server.dart';

/// A response body captured from the real backend (the files in test/fixtures/expenses).
dynamic fixtureJson(String name) => jsonDecode(File('test/fixtures/expenses/$name.json').readAsStringSync());

Map<String, dynamic> fixtureMap(String name) => (fixtureJson(name) as Map).cast<String, dynamic>();

/// Deep copy, so a test can change a fixture without touching the shared one.
Map<String, dynamic> copyJson(Map<String, dynamic> json) => (jsonDecode(jsonEncode(json)) as Map).cast<String, dynamic>();

/// Parses with the generated serializers, exactly like the app does.
ExpenseView expenseFrom(Map<String, dynamic> json) => standardSerializers.deserializeWith(ExpenseView.serializer, json)!;

ExpenseView expenseFixture(String name) => expenseFrom(fixtureMap(name));

/// A new expense shaped like [base] (an EQUAL or EXACT fixture) with its own id, title and date.
Map<String, dynamic> cloneExpense(Map<String, dynamic> base, {required String id, required String title, String? date, int? version}) {
  final copy = copyJson(base);
  copy['id'] = id;
  copy['title'] = title;
  if (date != null) copy['expenseDate'] = date;
  if (version != null) copy['version'] = version;
  return copy;
}

/// The expenses endpoints of the backend, as far as the client depends on them: newest-first
/// paging, the date and member filters, `ETag` on the detail read, `If-Match` on delete and edit
/// (409 `VERSION_CONFLICT`, 404 once gone), the revisions list, the preview, and create with an
/// `Idempotency-Key` (replay, key reuse, the validation codes). List/detail bodies are real
/// responses captured from the backend. The preview and create/update calculate with the same
/// rules as the backend's engine (largest remainder, extra piasters to the lowest sort order) so
/// the app is tested against realistic server numbers: the app itself never calculates them.
class FakeExpensesServer extends FakeGroupsServer {
  FakeExpensesServer() {
    final json = fixtureMap('group');
    group = FakeGroup(id: json['id'] as String, name: json['name'] as String, type: json['type'] as String);
    for (final m in (json['members'] as List).cast<Map<String, dynamic>>()) {
      group.members.add(FakeMember(id: m['id'] as String, name: m['displayName'] as String, isYou: m['isYou'] as bool, sortOrder: m['sortOrder'] as int));
    }
    groups[group.id] = group;
  }

  late final FakeGroup group;

  /// Live expenses of the group, any order (the server sorts on read).
  final List<Map<String, dynamic>> expenses = [];

  /// Revisions per expense id, oldest first.
  final Map<String, List<Map<String, dynamic>>> revisions = {};

  /// Only the expenses endpoints are unreachable (the group itself still loads).
  bool expensesOffline = false;

  /// The next DELETE is applied but its reply is lost (the client sees a timeout).
  bool loseNextDeleteResponse = false;

  /// The next list request waits for this to complete before it is answered (a slow reply).
  Completer<void>? holdNextList;

  /// The next DELETE is applied, then waits for this to complete before it is answered.
  Completer<void>? holdNextDelete;

  /// Replies to detail reads carry no ETag header (the client must fall back to the body's version).
  bool omitEtag = false;

  /// The next revisions read fails with a server error.
  bool failNextRevisions = false;

  // ---- preview / create / update ----

  /// Every preview request body, in arrival order.
  final List<Map<String, dynamic>> previewBodies = [];

  /// Preview requests whose HTTP call the client cancelled.
  int previewsCancelled = 0;

  /// Each arriving preview takes the first gate here (if any) and waits for it: lets a test answer
  /// preview #1 after preview #2 (out-of-order replies).
  final List<Completer<void>> previewGates = [];

  /// When set, every preview reports this for payersTotalMatches regardless of the amounts (the server's word is final).
  bool? forcePayersTotalMatches;

  /// The next preview fails with a 500.
  bool failNextPreview = false;

  /// Every create request: the key and the body, in arrival order (including replays).
  final List<({String? key, Map<String, dynamic> body})> creates = [];

  /// The Idempotency-Key of every create attempt that reached the server's door, including the ones
  /// that never got an answer (offline).
  final List<String?> createAttemptKeys = [];

  /// Every update request body, in arrival order.
  final List<Map<String, dynamic>> updates = [];

  /// The next create is stored but its reply is lost (the client sees a timeout).
  bool loseNextCreateResponse = false;

  /// The next create fails with a 500 before anything is stored.
  bool failNextCreate = false;

  /// The next create is refused with this 422 code (nothing stored), as if the server disagreed.
  String? forceNextCreateCode;

  /// The next update is applied but its reply is lost.
  bool loseNextUpdateResponse = false;

  final Map<String, ({String body, Map<String, dynamic> response})> _idempotency = {};
  int _newId = 0;

  /// Replaces the stored version, as if someone else edited the expense (for the 409 test).
  void bumpVersion(String id) {
    final e = expenses.firstWhere((x) => x['id'] == id);
    e['version'] = (e['version'] as int) + 1;
  }

  String get gid => group.id;

  /// Member ids in their fixed order.
  List<String> get memberOrder => (group.members.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))).map((m) => m.id).toList();

  static final RegExp _path = RegExp(r'/api/v1/groups/([^/]+)/expenses(?:/([^/]+))?(/revisions)?$');

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final match = _path.firstMatch(options.uri.path);
    if (match == null) return super.fetch(options, requestStream, cancelFuture);

    requests.add('${options.method} ${options.uri.path}${options.uri.hasQuery ? '?${options.uri.query}' : ''}'
        '${options.headers['If-Match'] != null ? ' if-match=${options.headers['If-Match']}' : ''}');
    if (options.method == 'POST' && match.group(2) == null) createAttemptKeys.add(options.headers['Idempotency-Key'] as String?);
    if (offline || expensesOffline) {
      throw DioException.connectionError(requestOptions: options, reason: 'offline', error: const HttpException('offline'));
    }
    if (match.group(1) != gid) return problemResponse(404, 'NOT_FOUND');

    final eid = match.group(2);
    if (eid == null) {
      if (options.method == 'POST') return _create(options, requestStream);
      final gate = holdNextList;
      holdNextList = null;
      if (gate != null) await gate.future;
      return _list(options);
    }
    if (eid == 'preview' && options.method == 'POST') return _preview(options, requestStream, cancelFuture);
    final current = expenses.where((e) => e['id'] == eid).firstOrNull;

    if (match.group(3) != null) {
      if (failNextRevisions) {
        failNextRevisions = false;
        return problemResponse(500, 'INTERNAL_ERROR');
      }
      final list = revisions[eid];
      // A revisions list survives the expense's deletion (A40).
      if (list == null && current == null) return problemResponse(404, 'NOT_FOUND');
      return jsonOk(200, list ?? const <Map<String, dynamic>>[]);
    }

    if (options.method == 'GET') {
      if (current == null) return problemResponse(404, 'NOT_FOUND');
      return jsonOk(200, current, etag: omitEtag ? null : '${current['version']}');
    }
    if (options.method == 'PUT') return _update(options, requestStream, current);
    if (options.method == 'DELETE') {
      if (current == null) return problemResponse(404, 'NOT_FOUND');
      if (options.headers['If-Match'] != '"${current['version']}"') return problemResponse(409, 'VERSION_CONFLICT');
      expenses.remove(current);
      final newVersion = (current['version'] as int) + 1;
      revisions.putIfAbsent(eid, () => []).add({
        'version': newVersion,
        'changeType': 'DELETE',
        'changedAt': '2026-11-09T10:00:00Z',
        'changedByUserId': 'u1',
        'snapshot': {...current, 'version': newVersion},
      });
      final gate = holdNextDelete;
      holdNextDelete = null;
      if (gate != null) await gate.future;
      if (loseNextDeleteResponse) {
        loseNextDeleteResponse = false;
        throw DioException.receiveTimeout(requestOptions: options, timeout: const Duration(seconds: 20));
      }
      return jsonOk(204, null, etag: '$newVersion');
    }
    return problemResponse(404, 'NOT_FOUND');
  }

  ResponseBody _list(RequestOptions options) {
    final q = options.uri.queryParameters;
    final page = int.parse(q['page'] ?? '0');
    final size = int.parse(q['size'] ?? '20');
    final from = q['fromDate'];
    final to = q['toDate'];
    final member = q['memberId'];

    bool involves(Map<String, dynamic> e) =>
        (e['payers'] as List).any((p) => p['memberId'] == member) || (e['shares'] as List).any((s) => s['memberId'] == member);

    // Newest first by expenseDate; the sort is stable, so ties keep insertion order.
    final matching = [
      for (final e in expenses)
        if ((from == null || (e['expenseDate'] as String).compareTo(from) >= 0) &&
            (to == null || (e['expenseDate'] as String).compareTo(to) <= 0) &&
            (member == null || involves(e)))
          e,
    ]..sort((a, b) => (b['expenseDate'] as String).compareTo(a['expenseDate'] as String));

    final pages = matching.isEmpty ? 1 : (matching.length + size - 1) ~/ size;
    final slice = matching.skip(page * size).take(size).toList();
    return jsonOk(200, {'items': slice, 'page': page, 'size': size, 'totalElements': matching.length, 'totalPages': pages});
  }

  // ---- body handling and the engine's rules ----

  Future<Map<String, dynamic>> _body(RequestOptions options, Stream<Uint8List>? stream) async {
    if (stream == null) return (options.data as Map?)?.cast<String, dynamic>() ?? {};
    final bytes = <int>[];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
    }
    return bytes.isEmpty ? {} : (jsonDecode(utf8.decode(bytes)) as Map).cast<String, dynamic>();
  }

  /// Largest remainder with weight 1: everybody gets the integer part, the extra piasters go to
  /// the lowest sort order first (spec 7.2).
  Map<String, int> _equalShares(int total, List<String> ids) {
    final ordered = [for (final id in memberOrder) if (ids.contains(id)) id];
    final base = total ~/ ordered.length;
    final extra = total % ordered.length;
    return {for (var i = 0; i < ordered.length; i++) ordered[i]: base + (i < extra ? 1 : 0)};
  }

  ResponseBody? _problem;

  /// Validates like the backend. Returns the shares per member, or null after setting [_problem].
  Map<String, int>? _validate(Map<String, dynamic> body, {required bool requirePayers, bool checkPayersTotal = true}) {
    _problem = null;
    final title = (body['title'] as String?)?.trim() ?? '';
    final total = body['totalMinor'] as int?;
    if (title.isEmpty || title.runes.length > 100 || total == null || total <= 0) {
      _problem = problemResponse(422, 'VALIDATION_ERROR');
      return null;
    }
    final known = memberOrder.toSet();
    final payers = (body['payers'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (requirePayers && payers.isEmpty) {
      _problem = problemResponse(422, 'VALIDATION_ERROR');
      return null;
    }
    if (payers.any((p) => !known.contains(p['memberId']))) {
      _problem = problemResponse(422, 'MEMBER_NOT_IN_GROUP');
      return null;
    }
    Map<String, int> shares;
    if (body['splitType'] == 'EXACT') {
      final list = (body['shares'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      if (list.any((s) => !known.contains(s['memberId']))) {
        _problem = problemResponse(422, 'MEMBER_NOT_IN_GROUP');
        return null;
      }
      shares = {for (final s in list) s['memberId'] as String: s['amountMinor'] as int};
      final sum = shares.values.fold<int>(0, (a, b) => a + b);
      if (sum != total || shares.values.every((v) => v == 0)) {
        _problem = problemResponse(422, 'SPLIT_TOTAL_MISMATCH');
        return null;
      }
    } else {
      final explicit = (body['participantMemberIds'] as List?)?.cast<String>();
      if (explicit != null && explicit.isEmpty) {
        _problem = problemResponse(422, 'VALIDATION_ERROR');
        return null;
      }
      if (explicit != null && explicit.any((id) => !known.contains(id))) {
        _problem = problemResponse(422, 'MEMBER_NOT_IN_GROUP');
        return null;
      }
      shares = _equalShares(total, explicit ?? memberOrder);
    }
    if (checkPayersTotal && payers.isNotEmpty && payers.fold<int>(0, (a, p) => a + (p['amountMinor'] as int)) != total) {
      _problem = problemResponse(422, 'PAYERS_TOTAL_MISMATCH');
      return null;
    }
    return shares;
  }

  Map<String, dynamic> _expenseJson(String id, int version, Map<String, dynamic> body, Map<String, int> shares) => {
        'id': id,
        'groupId': gid,
        'title': (body['title'] as String).trim(),
        'splitType': body['splitType'],
        'totalMinor': body['totalMinor'],
        'expenseDate': body['expenseDate'],
        'payers': [for (final p in (body['payers'] as List).cast<Map<String, dynamic>>()) {'memberId': p['memberId'], 'amountMinor': p['amountMinor']}],
        'shares': [
          for (final id in memberOrder)
            if (shares.containsKey(id)) {'memberId': id, 'owedMinor': shares[id], 'itemsMinor': null, 'serviceMinor': null, 'taxMinor': null, 'adjustmentMinor': null},
        ],
        'items': null,
        'charges': null,
        'createdAt': '2026-11-09T10:00:00Z',
        'version': version,
      };

  ResponseBody _created(Map<String, dynamic> expense, {bool replayed = false}) => ResponseBody.fromString(
        jsonEncode(expense),
        201,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
          'etag': ['"${expense['version']}"'],
          if (replayed) 'idempotency-replayed': ['true'],
        },
      );

  String _canonical(Object? value) {
    Object? sorted(Object? v) {
      if (v is Map) return {for (final k in (v.keys.map((k) => '$k').toList()..sort())) k: sorted(v[k])};
      if (v is List) return v.map(sorted).toList();
      return v;
    }

    return jsonEncode(sorted(value));
  }

  // ---- endpoints ----

  Future<ResponseBody> _preview(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancelFuture) async {
    final body = await _body(options, stream);
    previewBodies.add(body);
    var cancelled = false;
    unawaited(cancelFuture?.then((_) {
      cancelled = true;
      previewsCancelled++;
    }));
    final gate = previewGates.isEmpty ? null : previewGates.removeAt(0);
    if (gate != null) await gate.future;
    if (cancelled) throw DioException.requestCancelled(requestOptions: options, reason: 'cancelled');
    if (failNextPreview) {
      failNextPreview = false;
      return problemResponse(500, 'INTERNAL_ERROR');
    }
    final shares = _validate(body, requirePayers: false, checkPayersTotal: false);
    if (shares == null) return _problem!;
    final payers = (body['payers'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final matches = forcePayersTotalMatches ?? (payers.isNotEmpty && payers.fold<int>(0, (a, p) => a + (p['amountMinor'] as int)) == body['totalMinor']);
    return jsonOk(200, {
      'totalMinor': body['totalMinor'],
      'members': [
        for (final id in memberOrder)
          if (shares.containsKey(id)) {'memberId': id, 'owedMinor': shares[id], 'itemsMinor': null, 'serviceMinor': null, 'taxMinor': null, 'adjustmentMinor': null},
      ],
      'payersTotalMatches': matches,
    });
  }

  Future<ResponseBody> _create(RequestOptions options, Stream<Uint8List>? stream) async {
    final body = await _body(options, stream);
    final key = options.headers['Idempotency-Key'] as String?;
    creates.add((key: key, body: body));
    final uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (key == null || !uuid.hasMatch(key)) return problemResponse(422, 'VALIDATION_ERROR');

    final canonical = _canonical(body);
    final stored = _idempotency[key];
    if (stored != null) {
      if (stored.body != canonical) return problemResponse(422, 'IDEMPOTENCY_KEY_REUSED');
      return _created(stored.response, replayed: true);
    }
    if (failNextCreate) {
      failNextCreate = false;
      return problemResponse(500, 'INTERNAL_ERROR');
    }
    final forced = forceNextCreateCode;
    if (forced != null) {
      forceNextCreateCode = null;
      return problemResponse(422, forced);
    }
    final shares = _validate(body, requirePayers: true);
    if (shares == null) return _problem!;

    final expense = _expenseJson('new-${_newId++}', 1, body, shares);
    expenses.add(expense);
    _idempotency[key] = (body: canonical, response: expense);
    revisions['${expense['id']}'] = [
      {'version': 1, 'changeType': 'CREATE', 'changedAt': '2026-11-09T10:00:00Z', 'changedByUserId': 'u1', 'snapshot': expense},
    ];
    if (loseNextCreateResponse) {
      loseNextCreateResponse = false;
      throw DioException.receiveTimeout(requestOptions: options, timeout: const Duration(seconds: 20));
    }
    return _created(expense);
  }

  Future<ResponseBody> _update(RequestOptions options, Stream<Uint8List>? stream, Map<String, dynamic>? current) async {
    final body = await _body(options, stream);
    updates.add(body);
    if (current == null) return problemResponse(404, 'NOT_FOUND');
    if (options.headers['If-Match'] != '"${current['version']}"') return problemResponse(409, 'VERSION_CONFLICT');
    final shares = _validate(body, requirePayers: true);
    if (shares == null) return _problem!;

    final version = (current['version'] as int) + 1;
    final updated = _expenseJson('${current['id']}', version, body, shares);
    expenses[expenses.indexOf(current)] = updated;
    revisions.putIfAbsent('${current['id']}', () => []).add({'version': version, 'changeType': 'UPDATE', 'changedAt': '2026-11-09T10:00:00Z', 'changedByUserId': 'u1', 'snapshot': updated});
    if (loseNextUpdateResponse) {
      loseNextUpdateResponse = false;
      throw DioException.receiveTimeout(requestOptions: options, timeout: const Duration(seconds: 20));
    }
    return jsonOk(200, updated, etag: '$version');
  }
}
