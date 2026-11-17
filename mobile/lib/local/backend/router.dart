import 'dart:convert';

import 'package:built_value/serializer.dart';
import 'package:qesma_api/qesma_api.dart';

import '../errors.dart';
import '../service/balance_service.dart';
import '../service/commands.dart';
import '../service/expense_service.dart';
import '../service/group_service.dart';
import '../service/idempotency_service.dart';
import '../service/json_fields.dart';
import '../service/local_context.dart';
import '../service/member_service.dart';
import '../service/profile_service.dart';
import '../service/settlement_service.dart';
import '../service/views.dart';
import 'local_log.dart';

/// One HTTP request as the router sees it. [path] is relative to `/api/v1`; header names are lower case.
final class LocalRequest {
  const LocalRequest({
    required this.method,
    required this.path,
    required this.query,
    required this.headers,
    required this.body,
    required this.requestId,
  });

  final String method;
  final String path;
  final Map<String, List<String>> query;
  final Map<String, String> headers;
  final String? body;
  final String requestId;
}

/// One HTTP response: [body] is JSON text (or null for 204).
final class LocalResponse {
  const LocalResponse(this.status, {this.body, this.headers = const {}, this.problem = false});
  final int status;
  final String? body;
  final Map<String, String> headers;
  final bool problem;
}

typedef _Handler = Future<LocalResponse> Function(LocalRequest request, List<String> params);

final class _Route {
  _Route(this.method, this.template, this.handler)
      : pattern = RegExp('^${template.replaceAll(RegExp(r'\{[a-z]+\}'), '([^/]+)')}\$');
  final String method;
  final String template;
  final RegExp pattern;
  final _Handler handler;
}

/// The `/api/v1` routes served in local mode (STANDALONE_SPEC 4). Server-only endpoints answer 404 NOT_FOUND from an
/// explicit deny-list, so they stay unreachable even if a route below ever matched them.
final class LocalRouter {
  LocalRouter(LocalContext ctx, {this.failureLog = debugLocalFailureLog})
      : _groups = GroupService(ctx),
        _members = MemberService(ctx),
        _expenses = ExpenseService(ctx),
        _settlements = SettlementService(ctx),
        _balances = BalanceService(ctx),
        _profile = ProfileService(ctx) {
    _routes = [
      _Route('GET', '/me', (r, p) async => _ok(UserDto.serializer, await _profile.me())),
      _Route('PATCH', '/me', (r, p) async {
        final f = JsonFields.body(r.body);
        return _ok(UserDto.serializer, await _profile.updateMe(f.str('displayName')));
      }),
      _Route('GET', '/me/payment-handles', (r, p) async => _ok(PaymentHandlesView.serializer, await _profile.handles())),
      _Route('PUT', '/me/payment-handles', (r, p) async {
        final f = JsonFields.body(r.body);
        final view = await _profile.replaceHandles(instapay: f.str('instapay'), wallet: f.str('wallet'));
        return _ok(PaymentHandlesView.serializer, view);
      }),
      _Route('GET', '/groups', (r, p) async {
        final page = await _groups.list(_intParam(r, 'page', 0), _intParam(r, 'size', 20));
        return _ok(PageResponseGroupSummaryDto.serializer, page);
      }),
      _Route('POST', '/groups', (r, p) async {
        final f = JsonFields.body(r.body);
        final g = await _groups.create(name: f.str('name'), type: f.str('type'), currencyCode: f.str('currencyCode'));
        return _ok(GroupDto.serializer, g, status: 201, etag: g.version, location: '/api/v1/groups/${g.id}');
      }),
      _Route('GET', '/groups/{gid}', (r, p) async {
        final g = await _groups.get(p[0]);
        return _ok(GroupDto.serializer, g, etag: g.version);
      }),
      _Route('PATCH', '/groups/{gid}', (r, p) async {
        final f = JsonFields.body(r.body);
        final version = _ifMatch(r);
        final g = await _groups.update(p[0], version, name: f.str('name'), type: f.str('type'));
        return _ok(GroupDto.serializer, g, etag: g.version);
      }),
      _Route('DELETE', '/groups/{gid}', (r, p) async {
        await _groups.delete(p[0]);
        return const LocalResponse(204);
      }),
      _Route('POST', '/groups/{gid}/members', (r, p) async {
        final f = JsonFields.body(r.body);
        final m = await _members.add(p[0], f.str('displayName'));
        return _ok(MemberDto.serializer, m, status: 201, location: '/api/v1/groups/${p[0]}/members/${m.id}');
      }),
      _Route('PATCH', '/groups/{gid}/members/{mid}', (r, p) async {
        final f = JsonFields.body(r.body);
        final m = await _members.update(p[0], p[1],
            displayName: f.str('displayName'), role: f.str('role'), status: f.str('status'));
        return _ok(MemberDto.serializer, m);
      }),
      _Route('DELETE', '/groups/{gid}/members/{mid}', (r, p) async {
        await _members.delete(p[0], p[1]);
        return const LocalResponse(204);
      }),
      _Route('POST', '/groups/{gid}/expenses/preview', (r, p) async {
        final command = ExpenseIn.read(JsonFields.body(r.body));
        return _ok(ExpensePreview.serializer, await _expenses.preview(p[0], command));
      }),
      _Route('POST', '/groups/{gid}/expenses', (r, p) async {
        final command = ExpenseIn.read(JsonFields.body(r.body));
        final outcome = await _expenses.create(p[0], _idempotencyKey(r), command);
        return _created(outcome, '/api/v1/groups/${p[0]}/expenses', withEtag: true);
      }),
      _Route('GET', '/groups/{gid}/expenses', (r, p) async {
        final page = await _expenses.list(
          p[0],
          page: _intParam(r, 'page', 0),
          size: _intParam(r, 'size', 20),
          fromDate: _dateParam(r, 'fromDate'),
          toDate: _dateParam(r, 'toDate'),
          memberId: _uuidParam(r, 'memberId'),
          category: _single(r, 'category'),
        );
        return _ok(PageResponseExpenseView.serializer, page);
      }),
      _Route('GET', '/groups/{gid}/expenses/{eid}', (r, p) async {
        final e = await _expenses.get(p[0], p[1]);
        return _ok(ExpenseView.serializer, e, etag: e.version);
      }),
      _Route('PUT', '/groups/{gid}/expenses/{eid}', (r, p) async {
        final command = ExpenseIn.read(JsonFields.body(r.body));
        final e = await _expenses.update(p[0], p[1], _ifMatch(r), command);
        return _ok(ExpenseView.serializer, e, etag: e.version);
      }),
      _Route('DELETE', '/groups/{gid}/expenses/{eid}', (r, p) async {
        final version = await _expenses.delete(p[0], p[1], _ifMatch(r));
        return LocalResponse(204, headers: {'etag': '"$version"'});
      }),
      _Route('GET', '/groups/{gid}/expenses/{eid}/revisions', (r, p) async {
        final list = await _expenses.revisions(p[0], p[1]);
        return LocalResponse(200, body: jsonEncode([for (final v in list) toJsonValue(ExpenseRevisionView.serializer, v)]));
      }),
      _Route('GET', '/groups/{gid}/balances', (r, p) async => _ok(BalanceView.serializer, await _balances.balances(p[0]))),
      _Route('POST', '/groups/{gid}/settlements', (r, p) async {
        final command = SettlementIn.read(JsonFields.body(r.body));
        final outcome = await _settlements.create(p[0], _idempotencyKey(r), command);
        return _created(outcome, '/api/v1/groups/${p[0]}/settlements', withEtag: false);
      }),
      _Route('GET', '/groups/{gid}/settlements', (r, p) async {
        final page = await _settlements.list(
            p[0], r.query['status'] ?? const [], _intParam(r, 'page', 0), _intParam(r, 'size', 20));
        return _ok(PageResponseSettlementView.serializer, page);
      }),
      _Route('POST', '/groups/{gid}/settlements/{sid}/cancel', (r, p) async {
        return _ok(SettlementView.serializer, await _settlements.cancel(p[0], p[1]));
      }),
    ];
  }

  final LocalFailureLog failureLog;
  final GroupService _groups;
  final MemberService _members;
  final ExpenseService _expenses;
  final SettlementService _settlements;
  final BalanceService _balances;
  final ProfileService _profile;
  late final List<_Route> _routes;

  /// Server-only operations (STANDALONE_SPEC 4): always 404 NOT_FOUND in local mode, whatever the method.
  static final List<RegExp> serverOnly = [
    RegExp(r'^/auth(/.*)?$'),
    RegExp(r'^/me/password$'),
    RegExp(r'^/me/notification-prefs$'),
    RegExp(r'^/notifications(/.*)?$'),
    RegExp(r'^/invites(/.*)?$'),
    RegExp(r'^/groups/[^/]+/invites(/.*)?$'),
    RegExp(r'^/groups/[^/]+/join-requests(/.*)?$'),
    RegExp(r'^/groups/[^/]+/members/[^/]+/unlink$'),
    RegExp(r'^/groups/[^/]+/leave$'),
    RegExp(r'^/groups/[^/]+/transfer-ownership$'),
    RegExp(r'^/groups/[^/]+/settlements/[^/]+/(confirm|dispute)$'),
    RegExp(r'^/groups/[^/]+/transfers/remind$'),
    RegExp(r'^/groups/[^/]+/activity$'),
    RegExp(r'^/groups/[^/]+/notification-prefs$'),
  ];

  static bool isServerOnly(String method, String path) =>
      (method == 'DELETE' && path == '/me') || serverOnly.any((p) => p.hasMatch(path));

  /// Dispatches [request]. Contract errors become Problem JSON with their status and code; anything else is
  /// logged by id and type only and answered `500 INTERNAL_ERROR` without details.
  Future<LocalResponse> handle(LocalRequest request) async {
    var routeName = request.path;
    try {
      if (isServerOnly(request.method, request.path)) throw LocalApiException.notFound();
      final candidates = [
        for (final route in _routes)
          if (route.pattern.firstMatch(request.path) case final m?) (route, m),
      ];
      if (candidates.isEmpty) throw LocalApiException.notFound();
      final hit = candidates.where((c) => c.$1.method == request.method).firstOrNull;
      if (hit == null) {
        throw const LocalApiException(405, 'VALIDATION_ERROR', 'Method not supported for this resource');
      }
      final (route, match) = hit;
      routeName = route.template;
      final params = [
        for (var i = 1; i <= match.groupCount; i++) JsonFields.uuidValue(Uri.decodeComponent(match.group(i)!), 'path')!,
      ];
      return await route.handler(request, params);
    } on LocalApiException catch (e) {
      return _problem(e, request);
    } catch (e) {
      final mapped = _mapStoreError(e);
      if (mapped != null) return _problem(mapped, request);
      failureLog(LocalFailure(
        requestId: request.requestId,
        method: request.method,
        route: routeName,
        errorType: e.runtimeType.toString(),
      ));
      return _problem(const LocalApiException(500, 'INTERNAL_ERROR', 'Unexpected error'), request);
    }
  }

  /// The members name-key UNIQUE index lost a race with another write: the same 409 as the service check
  /// (Java maps `ux_members_group_name` the same way).
  static LocalApiException? _mapStoreError(Object e) {
    final text = e.toString();
    if (text.contains('UNIQUE constraint failed: members.group_id, members.name_key')) {
      return LocalApiException.conflict('DUPLICATE_MEMBER_NAME', 'A member with this name already exists');
    }
    return null;
  }

  LocalResponse _problem(LocalApiException e, LocalRequest r) => LocalResponse(
        e.status,
        body: jsonEncode(problemBody(e, instance: '/api/v1${r.path}', requestId: r.requestId)),
        problem: true,
      );

  static LocalResponse _ok<T>(Serializer<T> serializer, T value, {int status = 200, int? etag, String? location}) =>
      LocalResponse(
        status,
        body: jsonEncode(toJsonValue(serializer, value)),
        headers: {
          if (etag != null) 'etag': '"$etag"',
          'location': ?location,
        },
      );

  /// A create answer, fresh or replayed: Location (and ETag for expenses) are derived from the stored body.
  static LocalResponse _created(Outcome outcome, String collection, {required bool withEtag}) {
    final body = jsonDecode(outcome.body) as Map<String, Object?>;
    return LocalResponse(outcome.status, body: outcome.body, headers: {
      'location': '$collection/${body['id']}',
      if (withEtag) 'etag': '"${body['version']}"',
      if (outcome.replayed) 'idempotency-replayed': 'true',
    });
  }

  /// `If-Match` with the current version: `"3"`, `W/"3"` or `3`. Missing is 428, anything else 422 (Java `IfMatch`).
  static int _ifMatch(LocalRequest r) {
    final raw = r.headers['if-match']?.trim();
    if (raw == null || raw.isEmpty) {
      throw const LocalApiException(428, 'VALIDATION_ERROR', 'If-Match header with the current version is required');
    }
    final m = RegExp(r'^(?:(?:W/)?"(\d{1,9})"|(\d{1,9}))$').firstMatch(raw);
    if (m == null) throw LocalApiException.validation('If-Match must be the version, for example "3"');
    return int.parse(m.group(1) ?? m.group(2)!);
  }

  /// `Idempotency-Key`: required, a UUID, compared in lower case.
  static String _idempotencyKey(LocalRequest r) {
    final raw = r.headers['idempotency-key']?.trim();
    if (raw == null || raw.isEmpty) throw LocalApiException.validation('Idempotency-Key header is required');
    if (!isUuid(raw)) throw LocalApiException.validation('Idempotency-Key must be a UUID');
    return raw.toLowerCase();
  }

  static String? _single(LocalRequest r, String name) {
    final values = r.query[name];
    return values == null || values.isEmpty ? null : values.first;
  }

  static int _intParam(LocalRequest r, String name, int fallback) {
    final raw = _single(r, name);
    if (raw == null) return fallback;
    return int.tryParse(raw) ?? (throw LocalApiException.unreadable('$name must be an integer'));
  }

  static String? _dateParam(LocalRequest r, String name) {
    final raw = _single(r, name);
    if (raw == null || raw.isEmpty) return null;
    if (!isIsoDate(raw)) throw LocalApiException.unreadable('$name must be a date (YYYY-MM-DD)');
    return raw;
  }

  static String? _uuidParam(LocalRequest r, String name) {
    final raw = _single(r, name);
    if (raw == null || raw.isEmpty) return null;
    return JsonFields.uuidValue(raw, name);
  }
}
