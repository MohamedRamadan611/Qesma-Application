import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/uuid_v4.dart';
import 'package:qesma/local/errors.dart';
import 'package:qesma/local/service/commands.dart';
import 'package:qesma/local/service/expense_service.dart';
import 'package:qesma/local/service/expense_validator.dart';
import 'package:qesma/local/service/json_fields.dart';

import 'support/local_http.dart';

/// SHARES through the local HTTP contract (SA18, STANDALONE_SPEC 19, A185-A189, A195, A197): create, preview, edit,
/// revisions, replay, a pool expense and the V27/V28 validation matrix, as the Java backend serves them.
void main() {
  late LocalHttp http;
  late String gid;
  late String you;
  late String ali;
  late String sara;

  setUp(() async {
    http = await LocalHttp.open();
    final g = await http.group(name: 'Flat', type: 'HOUSING');
    gid = g['id'] as String;
    you = g['yourMemberId'] as String;
    ali = await http.member(gid, 'Ali');
    sara = await http.member(gid, 'Sara');
  });
  tearDown(() => http.close());

  void expectProblem(dynamic r, int status, String code) =>
      expect((r.statusCode, r.data['code']), (status, code), reason: '${r.data}');

  /// V23: rent 9,000.00 for November, units 2 / 1 / 1, Sara present from the 12th.
  Map<String, Object?> rent({List<Map<String, Object?>>? participants, int total = 900000}) => {
        'title': 'Rent',
        'expenseDate': '2026-12-01',
        'splitType': 'SHARES',
        'totalMinor': total,
        'periodFrom': '2026-11-01',
        'periodTo': '2026-11-30',
        'payers': [
          {'memberId': you, 'amountMinor': total},
        ],
        'shareParticipants': participants ??
            [
              {'memberId': you, 'shareUnits': 2},
              {'memberId': ali, 'shareUnits': 1},
              {'memberId': sara, 'shareUnits': 1, 'presentFrom': '2026-11-12'},
            ],
      };

  Map<String, Object?> owedOf(dynamic data, [String key = 'shares']) =>
      {for (final s in data[key] as List) s['memberId'] as String: s['owedMinor']};

  group('create, read and preview', () {
    test('V23 over HTTP: owed, units, normalized presence and the period are returned and stored', () async {
      final r = await http.expense(gid, rent());
      expect(r.statusCode, 201, reason: '${r.data}');
      expect(owedOf(r.data), {you: 495413, ali: 247706, sara: 156881});
      expect((r.data['splitType'], r.data['periodFrom'], r.data['periodTo']), ('SHARES', '2026-11-01', '2026-11-30'));
      final shares = {for (final s in r.data['shares'] as List) s['memberId']: (s['shareUnits'], s['presentFrom'], s['presentTo'])};
      expect(shares, {
        you: (2, '2026-11-01', '2026-11-30'),
        ali: (1, '2026-11-01', '2026-11-30'),
        sara: (1, '2026-11-12', '2026-11-30'),
      });
      final got = await http.get('/groups/$gid/expenses/${r.data['id']}');
      expect(got.data, r.data);
      final listed = (await http.get('/groups/$gid/expenses')).data['items'] as List;
      expect(listed.single, r.data);
    });

    test('no period: units 1 for everyone equals EQUAL; presence and period are null', () async {
      final body = {...rent(total: 1000), 'periodFrom': null, 'periodTo': null};
      body['shareParticipants'] = [
        for (final m in [you, ali, sara]) {'memberId': m, 'shareUnits': 1},
      ];
      final shares = await http.expense(gid, body);
      expect(shares.statusCode, 201, reason: '${shares.data}');
      final equal = await http.expense(gid, equalBody(1000, [(id: you, amount: 1000)]));
      expect(owedOf(shares.data), owedOf(equal.data));
      expect(shares.data.containsKey('periodFrom'), isFalse);
      for (final s in shares.data['shares'] as List) {
        expect((s['shareUnits'], s.containsKey('presentFrom'), s.containsKey('itemsMinor')), (1, false, false));
      }
    });

    test('preview returns the same numbers and the period, and saves nothing', () async {
      final p = await http.post('/groups/$gid/expenses/preview', rent());
      expect(p.statusCode, 200, reason: '${p.data}');
      expect(owedOf(p.data, 'members'), {you: 495413, ali: 247706, sara: 156881});
      expect((p.data['periodFrom'], p.data['periodTo'], p.data['payersTotalMatches']), ('2026-11-01', '2026-11-30', true));
      expect(await http.count('expenses'), 0);
    });

    test('balances read owed only', () async {
      await http.expense(gid, rent());
      final b = (await http.get('/groups/$gid/balances')).data;
      final nets = {for (final m in b['nets'] as List) m['memberId']: m['netMinor']};
      expect(nets, {you: 900000 - 495413, ali: -247706, sara: -156881});
    });
  });

  group('edit and revisions', () {
    test('EQUAL -> SHARES -> EQUAL: the SHARES columns are set, then cleared; revisions carry them', () async {
      final created = await http.expense(gid, equalBody(900000, [(id: you, amount: 900000)]));
      final id = created.data['id'];
      final toShares = await http.put('/groups/$gid/expenses/$id', rent(), ifMatch: '"1"');
      expect(toShares.statusCode, 200, reason: '${toShares.data}');
      expect(owedOf(toShares.data), {you: 495413, ali: 247706, sara: 156881});
      final back = await http.put('/groups/$gid/expenses/$id', equalBody(900000, [(id: you, amount: 900000)]), ifMatch: '"2"');
      expect(back.statusCode, 200, reason: '${back.data}');
      expect(back.data.containsKey('periodFrom'), isFalse);
      expect((back.data['shares'] as List).every((s) => !(s as Map).containsKey('shareUnits')), isTrue);
      final rows = await http.db
          .customSelect('SELECT COUNT(*) AS n FROM expense_splits WHERE share_units IS NOT NULL OR present_from IS NOT NULL')
          .getSingle();
      expect(rows.read<int>('n'), 0);
      final stored = await http.db.customSelect("SELECT period_from, period_to FROM expenses WHERE id = '$id'").getSingle();
      expect((stored.readNullable<String>('period_from'), stored.readNullable<String>('period_to')), (null, null));

      final revs = (await http.get('/groups/$gid/expenses/$id/revisions')).data as List;
      expect([for (final r in revs) r['version']], [1, 2, 3]);
      expect(revs[1]['snapshot']['periodFrom'], '2026-11-01');
      expect((revs[1]['snapshot']['shares'] as List).map((s) => s['shareUnits']).toList(), [2, 1, 1]);
      expect(revs[0]['snapshot'].containsKey('periodFrom'), isFalse);
    });

    test('a snapshot written before SA18 (no SHARES keys) reads back with them null (A197)', () async {
      final created = await http.expense(gid, equalBody(1000, [(id: you, amount: 1000)]));
      final id = created.data['id'];
      // The stored CREATE snapshot as SA17 wrote it: no SHARES keys at all.
      final snap = await http.db.customSelect("SELECT snapshot FROM expense_revisions WHERE expense_id = '$id'").getSingle();
      expect(snap.read<String>('snapshot').contains('shareUnits'), isFalse);
      final revs = (await http.get('/groups/$gid/expenses/$id/revisions')).data as List;
      expect(revs.single['snapshot']['shares'], created.data['shares']);
    });

    test('a SHARES expense keeps a stored member on edit and owes 0 when the share rounds to nothing', () async {
      final tiny = rent(total: 1, participants: [
        {'memberId': you, 'shareUnits': 1},
        {'memberId': ali, 'shareUnits': 1},
      ]);
      final r = await http.expense(gid, tiny);
      expect(owedOf(r.data), {you: 1, ali: 0});
    });
  });

  group('replay (A189, A195)', () {
    test('same key: participant order and an explicit default bound are the same request', () async {
      final key = newUuidV4();
      final first = await http.expense(gid, rent(), key: key);
      final reordered = rent(participants: [
        {'memberId': sara, 'shareUnits': 1, 'presentFrom': '2026-11-12', 'presentTo': '2026-11-30'},
        {'memberId': ali, 'shareUnits': 1, 'presentFrom': '2026-11-01'},
        {'memberId': you, 'shareUnits': 2},
      ]);
      final again = await http.expense(gid, reordered, key: key);
      expect((again.statusCode, again.headers.value('idempotency-replayed')), (201, 'true'));
      expect(again.data, first.data);
      expect(await http.count('expenses'), 1);
    });

    test('same key with different units is IDEMPOTENCY_KEY_REUSED', () async {
      final key = newUuidV4();
      await http.expense(gid, rent(), key: key);
      final changed = rent(participants: [
        {'memberId': you, 'shareUnits': 3},
        {'memberId': ali, 'shareUnits': 1},
        {'memberId': sara, 'shareUnits': 1, 'presentFrom': '2026-11-12'},
      ]);
      expectProblem(await http.expense(gid, changed, key: key), 422, 'IDEMPOTENCY_KEY_REUSED');
    });

    test('the hash of a non-SHARES request has no SHARES keys (pre-SA18 replays keep their hash)', () {
      final v = ExpenseValidator.validate(ExpenseIn.read(JsonFields(equalBody(1000, [(id: you, amount: 1000)]))));
      final c = ExpenseService.canonical('e', 'g', v);
      expect(c.keys.where((String k) => k == 'shareParticipants' || k.startsWith('period')), isEmpty);
    });
  });

  group('pool (STANDALONE_SPEC 19.1 rule 7)', () {
    test('a SHARES pool expense: the treasurer owes a share like anyone, the meter goes down by the total', () async {
      final g = (await http.get('/groups/$gid')).data;
      expect((await http.patch('/groups/$gid', {'treasurerMemberId': ali}, ifMatch: '"${g['version']}"')).statusCode, 200);
      await http.settlement(gid, {'fromMemberId': you, 'toMemberId': ali, 'amountMinor': 1000000, 'settledOn': '2026-11-01', 'kind': 'POOL_DEPOSIT'});
      final body = {
        ...rent(),
        'paidFromPool': true,
        'payers': [
          {'memberId': ali, 'amountMinor': 900000},
        ],
      };
      final r = await http.expense(gid, body);
      expect(r.statusCode, 201, reason: '${r.data}');
      expect(owedOf(r.data), {you: 495413, ali: 247706, sara: 156881});
      expect((await http.get('/groups/$gid')).data['poolBalanceMinor'], 1000000 - 900000);
    });
  });

  group('validation (V27, V28, A187)', () {
    List<Map<String, Object?>> two({int a = 1, int b = 1}) => [
          {'memberId': you, 'shareUnits': a},
          {'memberId': ali, 'shareUnits': b},
        ];

    final cases = <String, Map<String, Object?> Function()>{
      'units 0': () => rent(participants: two(a: 0)),
      'units 101': () => rent(participants: two(b: 101)),
      'the same member twice': () => rent(participants: [...two(), {'memberId': you, 'shareUnits': 1}]),
      'no participants': () => rent(participants: []),
      'participants missing': () => {...rent()}..remove('shareParticipants'),
      'presence before the period': () => rent(participants: [
            {'memberId': you, 'shareUnits': 1, 'presentFrom': '2026-10-31'},
          ]),
      'presence after the period': () => rent(participants: [
            {'memberId': you, 'shareUnits': 1, 'presentTo': '2026-12-01'},
          ]),
      'presence without a period': () => {...rent(participants: [
            {'memberId': you, 'shareUnits': 1, 'presentFrom': '2026-11-05'},
          ])}..removeWhere((k, _) => k.startsWith('period')),
      'only periodFrom': () => {...rent()}..remove('periodTo'),
      'only periodTo': () => {...rent()}..remove('periodFrom'),
      'a reversed period': () => {...rent(), 'periodFrom': '2026-11-30', 'periodTo': '2026-11-01'},
      'a period of 367 days': () => {...rent(), 'periodFrom': '2026-01-01', 'periodTo': '2027-01-02'},
      'a period before 2000': () => {...rent(), 'periodFrom': '1999-12-31', 'periodTo': '2000-01-01'},
      'reversed presence': () => rent(participants: [
            {'memberId': you, 'shareUnits': 1, 'presentFrom': '2026-11-20', 'presentTo': '2026-11-10'},
          ]),
      'participantMemberIds on SHARES': () => {...rent(), 'participantMemberIds': [you]},
      'shares on SHARES': () => {...rent(), 'shares': [{'memberId': you, 'amountMinor': 900000}]},
      'items on SHARES': () => {...rent(), 'items': []},
      'shareParticipants on EQUAL': () => {...equalBody(1000, [(id: you, amount: 1000)]), 'shareParticipants': two()},
      'a period on EXACT': () => {
            'title': 'x', 'expenseDate': '2026-11-01', 'splitType': 'EXACT', 'totalMinor': 1000,
            'payers': [{'memberId': you, 'amountMinor': 1000}],
            'shares': [{'memberId': you, 'amountMinor': 1000}],
            'periodFrom': '2026-11-01', 'periodTo': '2026-11-02',
          },
      'a period on ITEMIZED': () => {
            'title': 'x', 'expenseDate': '2026-11-01', 'splitType': 'ITEMIZED',
            'payers': [{'memberId': you, 'amountMinor': 1000}],
            'items': [{'name': 'a', 'amountMinor': 1000, 'assigneeMemberIds': [you]}],
            'periodFrom': '2026-11-01', 'periodTo': '2026-11-02',
          },
      'no total': () => {...rent()}..remove('totalMinor'),
    };
    for (final c in cases.entries) {
      test('${c.key} is 422 VALIDATION_ERROR on create and preview', () async {
        expectProblem(await http.expense(gid, c.value()), 422, 'VALIDATION_ERROR');
        expectProblem(await http.post('/groups/$gid/expenses/preview', c.value()), 422, 'VALIDATION_ERROR');
      });
    }

    test('a malformed presence date is 400 like Jackson', () async {
      final r = await http.expense(gid, rent(participants: [
        {'memberId': you, 'shareUnits': 1, 'presentFrom': '2026-11-31'},
      ]));
      expect(r.statusCode, 400);
    });

    test('a member of another group is MEMBER_NOT_IN_GROUP', () async {
      final other = await http.group(name: 'Other');
      final stranger = await http.member(other['id'] as String, 'Stranger');
      expectProblem(
        await http.expense(gid, rent(participants: [...two(), {'memberId': stranger, 'shareUnits': 1}])),
        422,
        'MEMBER_NOT_IN_GROUP',
      );
    });

    test('messages name the field like Java (shareParticipants[i].field)', () {
      String message(Map<String, Object?> body) {
        try {
          ExpenseValidator.validate(ExpenseIn.read(JsonFields(body)));
        } on LocalApiException catch (e) {
          return e.title;
        }
        fail('accepted');
      }

      expect(message(rent(participants: [...two(), {'memberId': ali, 'shareUnits': 1}])),
          'shareParticipants[2].memberId appears more than once');
      expect(message(rent(participants: two(b: 0))), 'shareParticipants[1].shareUnits must be between 1 and 100');
      expect(message(rent(participants: [{'memberId': you, 'shareUnits': 1, 'presentFrom': '2026-10-01'}])),
          'shareParticipants[0].presentFrom must lie inside the period');
      expect(message(rent(participants: [{'memberId': you, 'shareUnits': 1, 'presentTo': '2026-12-02'}])),
          'shareParticipants[0].presentTo must lie inside the period');
      expect(
          message(rent(participants: [
            {'memberId': you, 'shareUnits': 1, 'presentFrom': '2026-11-20', 'presentTo': '2026-11-10'}
          ])),
          'shareParticipants[0].presentTo must not be before presentFrom');
      expect(
          message({...rent(participants: [{'memberId': you, 'shareUnits': 1, 'presentTo': '2026-11-02'}])}
            ..removeWhere((k, _) => k.startsWith('period'))),
          'shareParticipants[0].presentFrom/presentTo need periodFrom and periodTo');
      expect(message(rent(participants: [{'shareUnits': 1}])), 'shareParticipants[0].memberId is required');
      expect(message({...rent()}..remove('periodTo')), 'periodFrom and periodTo must both be set or both be absent');
      expect(message({...rent(), 'periodFrom': '2026-11-30', 'periodTo': '2026-11-01'}),
          'periodTo must not be before periodFrom');
      expect(message({...rent(), 'periodFrom': '2026-01-01', 'periodTo': '2027-01-02'}),
          'The period (periodFrom..periodTo) must be at most 366 days');
      expect(message({...rent(), 'splitType': 'PERCENT'}), 'splitType must be EQUAL, EXACT, ITEMIZED or SHARES');
    });
  });
}
