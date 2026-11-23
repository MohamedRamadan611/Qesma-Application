import 'package:flutter_test/flutter_test.dart';

import 'support/local_http.dart';

/// Trip budget settings on the group and the member default weight through the local contract (SA18, A188, A190,
/// A193; Java `GroupService.update` / `MemberService.update`). The budget figures themselves are SA20.
void main() {
  late LocalHttp http;
  late String gid;
  late String you;
  late String ali;

  setUp(() async {
    http = await LocalHttp.open();
    final g = await http.group();
    gid = g['id'] as String;
    you = g['yourMemberId'] as String;
    ali = await http.member(gid, 'Ali');
  });
  tearDown(() => http.close());

  void expectProblem(dynamic r, int status, String code) =>
      expect((r.statusCode, r.data['code']), (status, code), reason: '${r.data}');

  Future<int> version() async => (await http.get('/groups/$gid')).data['version'] as int;

  Future<dynamic> patchGroup(Map<String, Object?> body) async =>
      http.patch('/groups/$gid', body, ifMatch: '"${await version()}"');

  group('group budget and trip dates', () {
    test('absent by default; set, read back, then each cleared on its own', () async {
      final g = (await http.get('/groups/$gid')).data as Map;
      expect(g.keys, isNot(containsAll(['budgetMinor', 'tripStartDate', 'tripEndDate'])));
      final v0 = g['version'] as int;

      final set = await patchGroup({'budgetMinor': 500000, 'tripStartDate': '2026-07-01', 'tripEndDate': '2026-07-05'});
      expect(set.statusCode, 200, reason: '${set.data}');
      expect((set.data['budgetMinor'], set.data['tripStartDate'], set.data['tripEndDate'], set.data['version']),
          (500000, '2026-07-01', '2026-07-05', v0 + 1));
      expect((await http.get('/groups/$gid')).data['budgetMinor'], 500000);

      final noBudget = await patchGroup({'clearBudget': true});
      expect((noBudget.data.containsKey('budgetMinor'), noBudget.data['tripStartDate']), (false, '2026-07-01'));
      final noStart = await patchGroup({'clearTripStartDate': true});
      expect((noStart.data.containsKey('tripStartDate'), noStart.data['tripEndDate']), (false, '2026-07-05'));
      final noEnd = await patchGroup({'clearTripEndDate': true});
      expect(noEnd.data.containsKey('tripEndDate'), isFalse);
      expect(noEnd.data['version'], v0 + 4);
    });

    test('null or absent means no change and does not move the version', () async {
      await patchGroup({'budgetMinor': 1000});
      final v = await version();
      final same = await patchGroup({'budgetMinor': null, 'name': 'Dahab'});
      expect((same.statusCode, same.data['budgetMinor'], same.data['version']), (200, 1000, v));
      final again = await patchGroup({'budgetMinor': 1000});
      expect(again.data['version'], v);
    });

    test('one date alone is fine; end before the stored start is refused (checked on the resulting state)', () async {
      expect((await patchGroup({'tripEndDate': '2026-07-05'})).statusCode, 200);
      expectProblem(await patchGroup({'tripStartDate': '2026-07-06'}), 422, 'VALIDATION_ERROR');
      expect((await patchGroup({'tripStartDate': '2026-07-05'})).statusCode, 200);
      expectProblem(await patchGroup({'tripEndDate': '2026-07-04'}), 422, 'VALIDATION_ERROR');
    });

    test('invalid values are 422 and change nothing', () async {
      final v = await version();
      for (final bad in <Map<String, Object?>>[
        {'budgetMinor': 0},
        {'budgetMinor': -5},
        {'budgetMinor': 1000000000001},
        {'budgetMinor': 10, 'clearBudget': true},
        {'tripStartDate': '2026-07-01', 'clearTripStartDate': true},
        {'tripEndDate': '2026-07-01', 'clearTripEndDate': true},
        {'tripStartDate': '1999-12-31'},
        {'tripEndDate': '2101-01-01'},
        {'tripStartDate': '2026-07-10', 'tripEndDate': '2026-07-09'},
      ]) {
        expectProblem(await patchGroup(bad), 422, 'VALIDATION_ERROR');
      }
      expect((await patchGroup({'tripStartDate': '2026-02-30'})).statusCode, 400);
      expect(await version(), v);
      expect((await patchGroup({'budgetMinor': 1000000000000})).data['budgetMinor'], 1000000000000);
    });
  });

  group('pool treasurer and trip budget are exclusive (A199)', () {
    test('a budget on a pool group, and a treasurer on a budget group, are 422 and change nothing', () async {
      expect((await patchGroup({'treasurerMemberId': you})).statusCode, 200);
      final v = await version();
      expectProblem(await patchGroup({'budgetMinor': 1000}), 422, 'VALIDATION_ERROR');
      expect(await version(), v);
      // Trip dates alone are not a budget.
      expect((await patchGroup({'tripStartDate': '2026-07-01'})).statusCode, 200);

      final other = await http.group(name: 'Second');
      final gid2 = other['id'] as String;
      final me2 = other['yourMemberId'] as String;
      final v2 = (await http.get('/groups/$gid2')).data['version'];
      expect((await http.patch('/groups/$gid2', {'budgetMinor': 1000}, ifMatch: '"$v2"')).statusCode, 200);
      final r = await http.patch('/groups/$gid2', {'treasurerMemberId': me2}, ifMatch: '"${v2 + 1}"');
      expectProblem(r, 422, 'VALIDATION_ERROR');
    });

    test('clearing the budget in the same patch frees the pool', () async {
      await patchGroup({'budgetMinor': 1000});
      final r = await patchGroup({'clearBudget': true, 'treasurerMemberId': you});
      expect((r.statusCode, r.data['treasurerMemberId'], r.data.containsKey('budgetMinor')), (200, you, false));
    });
  });

  group('member default weight (A188)', () {
    Future<dynamic> patchMember(String mid, Map<String, Object?> body) => http.patch('/groups/$gid/members/$mid', body);

    Map<String, dynamic> memberIn(dynamic group, String mid) =>
        (group['members'] as List).cast<Map<String, dynamic>>().firstWhere((m) => m['id'] == mid);

    test('set, read back in the group, and cleared', () async {
      final r = await patchMember(ali, {'defaultShareUnits': 2});
      expect((r.statusCode, r.data['defaultShareUnits'], r.data['displayName']), (200, 2, 'Ali'));
      expect(memberIn((await http.get('/groups/$gid')).data, ali)['defaultShareUnits'], 2);
      final cleared = await patchMember(ali, {'clearDefaultShareUnits': true});
      expect(cleared.data.containsKey('defaultShareUnits'), isFalse);
      expect((await patchMember(you, {'defaultShareUnits': 100})).data['defaultShareUnits'], 100);
    });

    test('a rename and a weight together; a rejected weight applies nothing', () async {
      final r = await patchMember(ali, {'displayName': 'Aly', 'defaultShareUnits': 3});
      expect((r.data['displayName'], r.data['defaultShareUnits']), ('Aly', 3));
      for (final bad in <Map<String, Object?>>[
        {'displayName': 'Ali', 'defaultShareUnits': 0},
        {'defaultShareUnits': 101},
        {'defaultShareUnits': 2, 'clearDefaultShareUnits': true},
        {},
        {'role': 'ADMIN'},
      ]) {
        expectProblem(await patchMember(ali, bad), 422, 'VALIDATION_ERROR');
      }
      final now = memberIn((await http.get('/groups/$gid')).data, ali);
      expect((now['displayName'], now['defaultShareUnits']), ('Aly', 3));
    });

    test('changing a default never changes an existing expense', () async {
      final body = {
        'title': 'Rent',
        'expenseDate': '2026-11-01',
        'splitType': 'SHARES',
        'totalMinor': 3000,
        'payers': [
          {'memberId': you, 'amountMinor': 3000},
        ],
        'shareParticipants': [
          {'memberId': you, 'shareUnits': 2},
          {'memberId': ali, 'shareUnits': 1},
        ],
      };
      final created = await http.expense(gid, body);
      await patchMember(ali, {'defaultShareUnits': 5});
      final after = await http.get('/groups/$gid/expenses/${created.data['id']}');
      expect(after.data, created.data);
    });
  });
}
