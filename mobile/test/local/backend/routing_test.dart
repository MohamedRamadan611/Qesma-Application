import 'package:flutter_test/flutter_test.dart';

import 'support/local_http.dart';

/// Local-mode routing (STANDALONE_SPEC 4): server-only endpoints are 404 NOT_FOUND, unknown routes 404, a known
/// path with another method 405, unreadable input 400, and no profile yet 401. Every error is Problem JSON.
void main() {
  const g = '11111111-2222-4333-8444-555555555555';
  const m = '66666666-7777-4888-8999-aaaaaaaaaaaa';

  group('with a profile', () {
    late LocalHttp http;
    setUp(() async => http = await LocalHttp.open());
    tearDown(() => http.close());

    void expectProblem(dynamic r, int status, String code) {
      expect((r.statusCode, r.data['code']), (status, code), reason: '${r.requestOptions.method} ${r.requestOptions.path}');
      expect(r.headers.value('content-type'), contains('application/problem+json'));
      expect(r.data['type'], 'https://qesma.app/problems/${code.toLowerCase().replaceAll('_', '-')}');
      expect(r.data['requestId'], r.headers.value('x-request-id'));
      expect(r.data['status'], status);
    }

    test('every server-only endpoint answers 404 NOT_FOUND, even for a group the caller owns', () async {
      final gid = (await http.group())['id'] as String;
      final calls = <Future<dynamic> Function()>[
        () => http.post('/auth/google', {'idToken': 'x'}),
        () => http.post('/auth/refresh', {'refreshToken': 'x'}),
        () => http.post('/auth/login', {'username': 'a', 'password': 'b'}),
        () => http.post('/auth/register', {'username': 'a', 'password': 'b'}),
        () => http.post('/auth/logout', {'refreshToken': 'x'}),
        () => http.post('/me/password', {'currentPassword': 'a', 'newPassword': 'b'}),
        () => http.delete('/me'),
        () => http.put('/me/notification-prefs', {'enabled': false}),
        () => http.get('/notifications'),
        () => http.get('/notifications/unread-count'),
        () => http.post('/notifications/read', <String, Object?>{}),
        () => http.get('/invites/ABCDEFGH'),
        () => http.post('/invites/ABCDEFGH/join', <String, Object?>{}),
        () => http.post('/groups/$gid/invites', <String, Object?>{}),
        () => http.get('/groups/$gid/invites'),
        () => http.delete('/groups/$gid/invites/$m'),
        () => http.get('/groups/$gid/join-requests'),
        () => http.post('/groups/$gid/join-requests/$m/approve', null),
        () => http.post('/groups/$gid/join-requests/$m/reject', null),
        () => http.post('/groups/$gid/members/$m/unlink', null),
        () => http.post('/groups/$gid/leave', null),
        () => http.post('/groups/$gid/transfer-ownership', {'toMemberId': m}),
        () => http.post('/groups/$gid/settlements/$m/confirm', null),
        () => http.post('/groups/$gid/settlements/$m/dispute', null),
        () => http.post('/groups/$gid/transfers/remind', {'fromMemberId': m, 'toMemberId': m}),
        () => http.get('/groups/$gid/activity'),
        () => http.put('/groups/$gid/notification-prefs', {'muted': true}),
      ];
      for (final call in calls) {
        expectProblem(await call(), 404, 'NOT_FOUND');
      }
      expect(http.failures, isEmpty);
    });

    test('unknown route 404, wrong method 405, unknown group 404, bad path id 400', () async {
      expectProblem(await http.get('/nothing-here'), 404, 'NOT_FOUND');
      expectProblem(await http.dio.get<dynamic>('/elsewhere'), 404, 'NOT_FOUND');
      expectProblem(await http.put('/groups', <String, Object?>{}), 405, 'VALIDATION_ERROR');
      expectProblem(await http.get('/groups/$g'), 404, 'NOT_FOUND');
      expectProblem(await http.get('/groups/$g/balances'), 404, 'NOT_FOUND');
      expectProblem(await http.get('/groups/not-a-uuid'), 400, 'VALIDATION_ERROR');
    });

    test('unreadable bodies are 400; missing fields are 422', () async {
      final gid = (await http.group())['id'] as String;
      expectProblem(await http.dio.post<dynamic>('/api/v1/groups', data: '{"name": '), 400, 'VALIDATION_ERROR');
      expectProblem(await http.post('/groups', {'name': 5, 'type': 'TRIP'}), 400, 'VALIDATION_ERROR');
      expectProblem(await http.post('/groups/$gid/members', {'displayName': null}), 422, 'VALIDATION_ERROR');
      expectProblem(
        await http.expense(gid, {'title': 'x', 'expenseDate': '2026-11-01', 'splitType': 'EQUAL', 'totalMinor': 1.5}),
        400,
        'VALIDATION_ERROR',
      );
      expectProblem(await http.expense(gid, {'title': 'x', 'splitType': 'EQUAL', 'totalMinor': 100}), 422, 'VALIDATION_ERROR');
    });

    test('GET /me is the local profile; PATCH /me renames it (1..60, trimmed)', () async {
      final me = await http.get('/me');
      expect(me.data['displayName'], 'Tester');
      expect((me.data['hasPassword'], me.data['emailVerified'], me.data['notificationsEnabled']), (false, false, false));
      final renamed = await http.patch('/me', {'displayName': '  منى  '});
      expect(renamed.data['displayName'], 'منى');
      expectProblem(await http.patch('/me', {'displayName': 'x' * 61}), 422, 'VALIDATION_ERROR');
      final g = await http.group();
      expect((g['members'] as List).single['displayName'], 'منى', reason: 'member #1 takes the profile name');
    });
  });

  test('before onboarding (no profile) every served endpoint is 401 UNAUTHORIZED', () async {
    final http = await LocalHttp.open(withProfile: false);
    addTearDown(http.close);
    for (final r in [await http.get('/me'), await http.get('/groups'), await http.post('/groups', {'name': 'x', 'type': 'TRIP'})]) {
      expect((r.statusCode, r.data['code']), (401, 'UNAUTHORIZED'));
    }
    expect(await http.count('expense_groups'), 0);
  });
}
