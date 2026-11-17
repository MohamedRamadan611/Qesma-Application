import 'package:flutter_test/flutter_test.dart';

import 'support/local_http.dart';

/// SA4: `PATCH /me` is the local onboarding. With no profile it creates it; the same 1..60 rule applies.
void main() {
  test('PATCH /me on a fresh database creates the profile (trimmed), and GET /me then answers 200', () async {
    final http = await LocalHttp.open(withProfile: false);
    addTearDown(http.close);
    expect((await http.get('/me')).statusCode, 401);
    final created = await http.patch('/me', {'displayName': '  منى  '});
    expect(created.statusCode, 200, reason: '${created.data}');
    expect(created.data['displayName'], 'منى');
    expect(await http.count('local_profile'), 1);
    expect((await http.get('/me')).data['displayName'], 'منى');
    // A second PATCH renames; it never creates a second profile.
    expect((await http.patch('/me', {'displayName': 'Mona'})).data['displayName'], 'Mona');
    expect(await http.count('local_profile'), 1);
  });

  test('a blank or too long name creates nothing', () async {
    final http = await LocalHttp.open(withProfile: false);
    addTearDown(http.close);
    for (final name in ['   ', '', 'x' * 61]) {
      final r = await http.patch('/me', {'displayName': name});
      expect((r.statusCode, r.data['code']), (422, 'VALIDATION_ERROR'), reason: 'name length ${name.length}');
    }
    expect(await http.count('local_profile'), 0);
  });
}
