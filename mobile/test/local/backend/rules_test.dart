import 'package:flutter_test/flutter_test.dart';

import 'support/local_http.dart';

/// Group and member rules of the server, served locally: deletes blocked by ledger use (A23, A30), the protected
/// "you" member, normalized duplicate names (A152), and the server-only member fields.
void main() {
  late LocalHttp http;
  late String gid;
  late String you;

  setUp(() async {
    http = await LocalHttp.open();
    final g = await http.group();
    gid = g['id'] as String;
    you = g['yourMemberId'] as String;
  });
  tearDown(() => http.close());

  Future<void> expectCode(Future<dynamic> call, int status, String code) async {
    final r = await call;
    expect((r.statusCode, r.data['code']), (status, code), reason: '${r.data}');
  }

  group('group delete', () {
    test('an empty group is deleted with its members', () async {
      await http.member(gid, 'Ali');
      expect((await http.delete('/groups/$gid')).statusCode, 204);
      expect((await http.get('/groups/$gid')).statusCode, 404);
      expect(await http.count('members'), 0);
    });

    test('blocked by a live expense, by a soft-deleted one, and by a cancelled payment', () async {
      final eid = (await http.expense(gid, equalBody(9000, [(id: you, amount: 9000)]))).data['id'];
      await expectCode(http.delete('/groups/$gid'), 409, 'GROUP_NOT_EMPTY');
      expect((await http.delete('/groups/$gid/expenses/$eid', ifMatch: '"1"')).statusCode, 204);
      await expectCode(http.delete('/groups/$gid'), 409, 'GROUP_NOT_EMPTY');

      final other = (await http.group(name: 'Second'))['id'] as String;
      final otherYou = (await http.get('/groups/$other')).data['yourMemberId'];
      final ali = await http.member(other, 'Ali');
      final s = await http.settlement(other, {'fromMemberId': ali, 'toMemberId': otherYou, 'amountMinor': 100, 'settledOn': '2026-11-01'});
      expect((await http.post('/groups/$other/settlements/${s.data['id']}/cancel', null)).data['status'], 'CANCELLED');
      await expectCode(http.delete('/groups/$other'), 409, 'GROUP_NOT_EMPTY');
    });

    test('an unknown group is 404', () async {
      await expectCode(http.delete('/groups/00000000-0000-4000-8000-000000000000'), 404, 'NOT_FOUND');
    });
  });

  group('member delete', () {
    test('"you" (linked) is protected', () async {
      await expectCode(http.delete('/groups/$gid/members/$you'), 409, 'OWNER_MEMBER_PROTECTED');
    });

    test('blocked as payer, as a share, on a soft-deleted expense and by a payment; free once unused', () async {
      final payer = await http.member(gid, 'Payer');
      final sharer = await http.member(gid, 'Sharer');
      final eid = (await http.expense(gid, equalBody(9000, [(id: payer, amount: 9000)], participants: [you, sharer])))
          .data['id'];
      await expectCode(http.delete('/groups/$gid/members/$payer'), 409, 'MEMBER_HAS_TRANSACTIONS');
      await expectCode(http.delete('/groups/$gid/members/$sharer'), 409, 'MEMBER_HAS_TRANSACTIONS');
      expect((await http.delete('/groups/$gid/expenses/$eid', ifMatch: '"1"')).statusCode, 204);
      await expectCode(http.delete('/groups/$gid/members/$sharer'), 409, 'MEMBER_HAS_TRANSACTIONS');

      final receiver = await http.member(gid, 'Receiver');
      await http.settlement(gid, {'fromMemberId': you, 'toMemberId': receiver, 'amountMinor': 100, 'settledOn': '2026-11-01'});
      await expectCode(http.delete('/groups/$gid/members/$receiver'), 409, 'MEMBER_HAS_TRANSACTIONS');

      final free = await http.member(gid, 'Free');
      expect((await http.delete('/groups/$gid/members/$free')).statusCode, 204);
      await expectCode(http.delete('/groups/$gid/members/$free'), 404, 'NOT_FOUND');
    });

    test('an item assignee who owes 0 (a 0-piaster item share) still blocks the delete', () async {
      final zero = await http.member(gid, 'Zero');
      // The share of a 1-piaster item split between two goes to the lower sortOrder ("you"): Zero owes 0.
      final r = await http.expense(gid, {
        'title': 'Gum',
        'expenseDate': '2026-11-01',
        'splitType': 'ITEMIZED',
        'items': [
          {'name': 'Gum', 'amountMinor': 1, 'assigneeMemberIds': [you, zero]},
        ],
        'payers': [
          {'memberId': you, 'amountMinor': 1},
        ],
      });
      expect(r.statusCode, 201, reason: '${r.data}');
      // Members owing 0 are not participants (engine step 6): no share row, only the item assignee row.
      expect((r.data['shares'] as List).where((s) => s['memberId'] == zero), isEmpty);
      expect((r.data['items'] as List).single['assigneeMemberIds'], [you, zero]);
      await expectCode(http.delete('/groups/$gid/members/$zero'), 409, 'MEMBER_HAS_TRANSACTIONS');
    });
  });

  group('member names', () {
    test('Arabic duplicates are found after trimming, space collapsing and case folding', () async {
      await http.member(gid, 'سارة');
      await expectCode(http.post('/groups/$gid/members', {'displayName': '  سارة  '}), 409, 'DUPLICATE_MEMBER_NAME');
      await http.member(gid, 'Ali Hassan');
      await expectCode(http.post('/groups/$gid/members', {'displayName': 'ali   HASSAN'}), 409, 'DUPLICATE_MEMBER_NAME');
      expect((await http.post('/groups/$gid/members', {'displayName': 'ساره'})).statusCode, 201,
          reason: 'a different letter (ه vs ة) is a different name');
    });

    test('rename to another member\'s name is 409; renaming to your own name is fine', () async {
      final a = await http.member(gid, 'Asem');
      await http.member(gid, 'Mohsen');
      await expectCode(http.patch('/groups/$gid/members/$a', {'displayName': 'mohsen'}), 409, 'DUPLICATE_MEMBER_NAME');
      final r = await http.patch('/groups/$gid/members/$a', {'displayName': 'ASEM'});
      expect((r.statusCode, r.data['displayName']), (200, 'ASEM'));
    });

    test('role or status in a member PATCH is 422 (server-only); an empty PATCH is 422', () async {
      final a = await http.member(gid, 'Asem');
      await expectCode(http.patch('/groups/$gid/members/$a', {'role': 'ADMIN'}), 422, 'VALIDATION_ERROR');
      await expectCode(http.patch('/groups/$gid/members/$a', {'status': 'LEFT'}), 422, 'VALIDATION_ERROR');
      await expectCode(http.patch('/groups/$gid/members/$a', <String, Object?>{}), 422, 'VALIDATION_ERROR');
    });

    test('sort orders are never reused after a delete (A20)', () async {
      final a = await http.member(gid, 'A');
      expect((await http.delete('/groups/$gid/members/$a')).statusCode, 204);
      await http.member(gid, 'B');
      final members = (await http.get('/groups/$gid')).data['members'] as List;
      expect([for (final m in members) m['sortOrder']], [1, 3]);
    });
  });
}
