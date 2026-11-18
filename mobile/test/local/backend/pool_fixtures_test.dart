import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/insights/pool_summary_repository.dart';

import 'support/local_http.dart';

/// The pool scenarios of `/fixtures/pool` (SA10, STANDALONE_SPEC 10, A135-A138) run end-to-end through the local
/// HTTP contract: deposits are settlements of kind POOL_DEPOSIT to the treasurer, pool expenses are paid by the
/// treasurer alone with `paidFromPool`, and the meter is `GroupDto.poolBalanceMinor` (computed, never stored).
/// Each scenario also runs with every deposit sent as a plain PAYMENT: the kind never changes a net (A136).
void main() {
  final files = Directory('../fixtures/pool').listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('the pool fixtures exist', () => expect(files.length, greaterThanOrEqualTo(6)));

  for (final file in files) {
    final fixture = (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();
    final expected = (fixture['expected'] as Map).cast<String, dynamic>();

    test('${fixture['name']}', () async {
      final run = await _run(fixture, kind: 'POOL_DEPOSIT');
      try {
        expect(run.group['treasurerMemberId'], run.ids[fixture['treasurer']]);
        expect(run.group['poolBalanceMinor'], expected['poolBalanceMinor']);
        expect(run.nets, (expected['nets'] as Map).cast<String, int>());
        expect(run.transfers, [
          for (final t in expected['transfers'] as List) '${t['from']}->${t['to']}:${t['amountMinor']}',
        ]);

        final summary = await PoolSummaryRepository(run.http.db).summary(run.gid);
        expect((summary.depositedMinor, summary.spentMinor), (expected['depositedMinor'], expected['spentMinor']));
        expect(summary.locked, isTrue);
        // The read-model and the contract agree on the meter (the card shows poolBalanceMinor itself).
        expect(summary.depositedMinor - summary.spentMinor, run.group['poolBalanceMinor']);
        // Deposits only; the cancelled ones stay in the list with their status.
        final deposits = [for (final s in fixture['steps'] as List) if (s['op'] == 'deposit') s];
        expect(summary.deposits.length, deposits.length);
      } finally {
        await run.http.close();
      }
    });

    test('${fixture['name']} — identical nets when every deposit is a plain PAYMENT', () async {
      final pool = await _run(fixture, kind: 'POOL_DEPOSIT');
      final plain = await _run(fixture, kind: 'PAYMENT');
      try {
        expect(plain.nets, pool.nets);
        expect(plain.transfers, pool.transfers);
      } finally {
        await pool.http.close();
        await plain.http.close();
      }
    });
  }
}

class _Run {
  _Run(this.http, this.gid, this.ids, this.group, this.nets, this.transfers);
  final LocalHttp http;
  final String gid;
  final Map<String, String> ids;
  final Map<String, dynamic> group;
  final Map<String, int> nets;
  final List<String> transfers;
}

Future<_Run> _run(Map<String, dynamic> fixture, {required String kind}) async {
  final http = await LocalHttp.open();
  final g = await http.group();
  final gid = g['id'] as String;
  final labels = (fixture['members'] as List).cast<String>();
  final ids = <String, String>{labels.first: g['yourMemberId'] as String};
  for (final label in labels.skip(1)) {
    ids[label] = await http.member(gid, label);
  }
  final names = {for (final e in ids.entries) e.value: e.key};
  final treasurer = ids[fixture['treasurer']]!;
  var version = (await http.get('/groups/$gid')).data['version'] as int;
  final set = await http.patch('/groups/$gid', {'treasurerMemberId': treasurer}, ifMatch: '"$version"');
  expect(set.statusCode, 200, reason: '${set.data}');

  final refs = <String, Map<String, dynamic>>{};
  for (final raw in fixture['steps'] as List) {
    final step = (raw as Map).cast<String, dynamic>();
    switch (step['op']) {
      case 'deposit':
        final r = await http.settlement(gid, {
          'fromMemberId': ids[step['from']],
          'toMemberId': treasurer,
          'amountMinor': step['amountMinor'],
          'settledOn': '2026-11-12',
          'kind': kind,
        });
        expect(r.statusCode, 201, reason: '${r.data}');
        expect(r.data['kind'], kind);
        refs[step['ref'] as String] = (r.data as Map).cast<String, dynamic>();
      case 'poolExpense':
        final participants = (step['participants'] as List?)?.map((l) => ids[l]).toList();
        final r = await http.expense(gid, {
          ...equalBody(step['totalMinor'] as int, [(id: treasurer, amount: step['totalMinor'] as int)],
              participants: participants?.cast<String>()),
          'paidFromPool': true,
        });
        expect(r.statusCode, 201, reason: '${r.data}');
        expect(r.data['paidFromPool'], isTrue);
        refs[step['ref'] as String] = (r.data as Map).cast<String, dynamic>();
      case 'deleteExpense':
        final e = refs[step['ref']]!;
        final r = await http.delete('/groups/$gid/expenses/${e['id']}', ifMatch: '"${e['version']}"');
        expect(r.statusCode, 204, reason: '${r.data}');
      case 'cancel':
        final r = await http.post('/groups/$gid/settlements/${refs[step['ref']]!['id']}/cancel', null);
        expect((r.statusCode, r.data['status']), (200, 'CANCELLED'));
      case 'expectMeter':
        if (kind == 'POOL_DEPOSIT') {
          expect((await http.get('/groups/$gid')).data['poolBalanceMinor'], step['poolBalanceMinor']);
        }
      default:
        throw StateError('unknown op ${step['op']}');
    }
  }
  final group = ((await http.get('/groups/$gid')).data as Map).cast<String, dynamic>();
  version = group['version'] as int;
  final balances = (await http.get('/groups/$gid/balances')).data as Map;
  final nets = {for (final n in balances['nets'] as List) names[n['memberId']]!: n['netMinor'] as int};
  final transfers = [
    for (final t in balances['transfers'] as List) '${names[t['fromMemberId']]}->${names[t['toMemberId']]}:${t['amountMinor']}',
  ];
  return _Run(http, gid, ids, group, nets, transfers);
}
