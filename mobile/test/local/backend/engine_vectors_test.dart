import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/local_http.dart';

/// The shared engine vectors V1-V8 (`/fixtures/engine`, the Java reference) reproduced end-to-end through the HTTP
/// contract: members are created (fixture sortOrder 1 = "you", the group creator), expenses and settlements are
/// POSTed, then each expense's shares and charges and `GET balances` must equal the fixture.
void main() {
  final files = Directory('../fixtures/engine').listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('all eight vectors are present', () {
    expect(files.map((f) => f.uri.pathSegments.last.split('-').first).toList(), ['V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7', 'V8']);
  });

  for (final file in files) {
    final vector = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    test('${vector['name']} via the local HTTP contract', () async {
      final http = await LocalHttp.open();
      addTearDown(http.close);
      final input = vector['input'] as Map<String, dynamic>;
      final expected = vector['expected'] as Map<String, dynamic>;

      // Members: fixture sortOrder 1 is the creator ("you"); the others are added in sortOrder.
      final members = [...(input['members'] as List).cast<Map<String, dynamic>>()]
        ..sort((a, b) => (a['sortOrder'] as int).compareTo(b['sortOrder'] as int));
      expect(members.map((m) => m['sortOrder']).toList(), List.generate(members.length, (i) => i + 1));
      final g = await http.group();
      final gid = g['id'] as String;
      final ids = <String, String>{members.first['id'] as String: g['yourMemberId'] as String};
      for (final m in members.skip(1)) {
        ids[m['id'] as String] = await http.member(gid, 'Member ${m['id']}');
      }
      final back = {for (final e in ids.entries) e.value: e.key};
      List<String> mapIds(Object? list) => [for (final id in (list as List)) ids[id]!];
      List<Map<String, Object?>> mapAmounts(Object? list) => [
            for (final a in (list as List).cast<Map<String, dynamic>>()) {'memberId': ids[a['memberId']], 'amountMinor': a['amountMinor']},
          ];

      final expenses = (input['expenses'] as List).cast<Map<String, dynamic>>();
      final expectedExpenses = (expected['expenses'] as List?)?.cast<Map<String, dynamic>>();
      for (var i = 0; i < expenses.length; i++) {
        final x = expenses[i];
        final body = <String, Object?>{
          'title': 'Vector expense $i',
          'expenseDate': '2026-10-17',
          'splitType': x['type'],
          'totalMinor': ?x['totalMinor'],
          'payers': mapAmounts(x['payers']),
          if (x['participantMemberIds'] != null) 'participantMemberIds': mapIds(x['participantMemberIds']),
          if (x['shares'] != null) 'shares': mapAmounts(x['shares']),
          if (x['items'] != null)
            'items': [
              for (final it in (x['items'] as List).cast<Map<String, dynamic>>())
                {'name': it['name'], 'amountMinor': it['amountMinor'], 'assigneeMemberIds': mapIds(it['assigneeMemberIds'])},
            ],
          if (x['serviceBps'] != null) 'service': {'bps': x['serviceBps']},
          'tax': ?x['tax'],
          'adjustmentMinor': ?x['adjustmentMinor'],
        };
        final r = await http.expense(gid, body);
        expect(r.statusCode, 201, reason: '${r.data}');
        final view = r.data as Map<String, dynamic>;
        final want = expectedExpenses?[i];
        if (want == null) continue;
        final owed = {for (final s in (view['shares'] as List)) back[s['memberId']]!: s['owedMinor'] as int};
        final wantOwed = (want['owed'] as Map).cast<String, int>();
        for (final e in wantOwed.entries) {
          expect(owed[e.key], e.value, reason: 'owed of ${e.key} in expense $i');
        }
        for (final e in owed.entries.where((e) => !wantOwed.containsKey(e.key))) {
          expect(e.value, 0, reason: 'a member the vector does not list owes nothing');
        }
        if (want['totalMinor'] != null) expect(view['totalMinor'], want['totalMinor']);
        final charges = view['charges'] as Map<String, dynamic>?;
        if (want['subtotalMinor'] != null) expect(charges!['subtotalMinor'], want['subtotalMinor']);
        if (want['serviceMinor'] != null) expect((charges!['service'] as Map?)?['amountMinor'] ?? 0, want['serviceMinor']);
        if (want['taxMinor'] != null) expect((charges!['tax'] as Map?)?['amountMinor'] ?? 0, want['taxMinor']);
      }

      for (final s in (input['settlements'] as List).cast<Map<String, dynamic>>()) {
        final r = await http.settlement(gid, {
          'fromMemberId': ids[s['fromMemberId']],
          'toMemberId': ids[s['toMemberId']],
          'amountMinor': s['amountMinor'],
          'settledOn': '2026-10-18',
        });
        expect(r.statusCode, 201, reason: '${r.data}');
        expect(r.data['status'], 'CONFIRMED');
      }

      final b = await http.get('/groups/$gid/balances');
      expect(b.statusCode, 200);
      final nets = {for (final n in (b.data['nets'] as List)) back[n['memberId']]!: n['netMinor'] as int};
      if (expected['nets'] != null) expect(nets, (expected['nets'] as Map).cast<String, int>());
      if (expected['transfers'] != null) {
        expect(
          [for (final t in (b.data['transfers'] as List)) (back[t['fromMemberId']], back[t['toMemberId']], t['amountMinor'])],
          [for (final t in (expected['transfers'] as List)) (t['fromMemberId'], t['toMemberId'], t['amountMinor'])],
        );
      }
      expect(nets.values.fold<int>(0, (a, v) => a + v), 0, reason: 'nets sum to zero');
      expect(http.failures, isEmpty);
    });
  }
}
