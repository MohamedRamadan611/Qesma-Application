import 'dart:convert';
import 'dart:io';

import 'package:qesma_engine/qesma_engine.dart';
import 'package:test/test.dart';

/// Port of the Java FixtureTest: runs every shared vector in /fixtures/engine against the Dart engine.
/// Only the keys present under "expected" are asserted (fixtures/README.md). The working directory under
/// `dart test` is the package root, so the repo-root fixtures are three levels up.
final Directory _dir = Directory('../../../fixtures/engine');

List<File> _fixtureFiles() =>
    _dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
      ..sort((a, b) => _name(a).compareTo(_name(b)));

String _name(File f) => f.uri.pathSegments.last;

void main() {
  test('all eight spec vectors are present', () {
    final names = _fixtureFiles().map(_name).toList();
    expect(names.length, greaterThanOrEqualTo(8));
    for (var v = 1; v <= 8; v++) {
      expect(names.any((n) => n.startsWith('V$v-')), isTrue, reason: 'V$v missing');
    }
  });

  for (final file in _fixtureFiles()) {
    test(_name(file), () => _run(jsonDecode(file.readAsStringSync()) as Map<String, dynamic>));
  }
}

void _run(Map<String, dynamic> fixture) {
  final input = fixture['input'] as Map<String, dynamic>;
  final expected = fixture['expected'] as Map<String, dynamic>;

  final members = [
    for (final m in _list(input['members'])) MemberRef(m['id'] as String, m['sortOrder'] as int),
  ];

  final ledger = <ExpenseLedgerEntry>[];
  final expenses = _list(input['expenses']);
  for (var i = 0; i < expenses.length; i++) {
    final e = expenses[i];
    final int total;
    final Map<String, int> owed;
    ItemizedResult? itemized;
    switch (e['type']) {
      case 'EQUAL':
        total = e['totalMinor'] as int;
        final participants = [
          for (final id in e['participantMemberIds'] as List<dynamic>) members.firstWhere((m) => m.id == id),
        ];
        owed = SplitCalculator.equal(total, participants);
      case 'EXACT':
        total = e['totalMinor'] as int;
        owed = SplitCalculator.exact(total, [
          for (final s in _list(e['shares'])) Share(s['memberId'] as String, s['amountMinor'] as int),
        ]);
      case 'ITEMIZED':
        final items = [
          for (final it in _list(e['items']))
            Item(it['name'] as String, it['amountMinor'] as int,
                [for (final a in it['assigneeMemberIds'] as List<dynamic>) a as String]),
        ];
        final taxJson = e['tax'] as Map<String, dynamic>?;
        final tax = taxJson == null
            ? null
            : TaxSpec(taxJson['bps'] as int, taxJson['base'] == null ? null : TaxBase.fromWire(taxJson['base'] as String));
        final result = ItemizedCalculator.calculate(
            ItemizedInput(members, items, e['serviceBps'] as int?, tax, (e['adjustmentMinor'] as int?) ?? 0));
        itemized = result;
        total = result.totalMinor;
        owed = {for (final b in result.members) b.memberId: b.owedMinor};
      default:
        throw ArgumentError('unknown expense type ${e['type']}');
    }

    final payers = [for (final p in _list(e['payers'])) Payer(p['memberId'] as String, p['amountMinor'] as int)];
    PayerValidator.validate(total, payers);
    ledger.add(ExpenseLedgerEntry(payers, owed));

    if (expected.containsKey('expenses')) {
      final exp = _list(expected['expenses'])[i];
      if (exp.containsKey('owed')) {
        expect(owed, _intMap(exp['owed']), reason: 'expense $i owed');
      }
      if (exp.containsKey('totalMinor')) {
        expect(total, exp['totalMinor'], reason: 'expense $i total');
      }
      if (itemized != null) {
        _field(exp, 'subtotalMinor', itemized.subtotalMinor);
        _field(exp, 'serviceMinor', itemized.serviceMinor);
        _field(exp, 'taxMinor', itemized.taxMinor);
      }
    }
  }

  final settlements = [
    for (final s in _list(input['settlements'] ?? <dynamic>[]))
      SettlementEntry(s['fromMemberId'] as String, s['toMemberId'] as String, s['amountMinor'] as int),
  ];

  final nets = BalanceCalculator.nets(members, ledger, settlements);
  if (expected.containsKey('nets')) {
    final exp = _intMap(expected['nets']);
    expect(nets, exp, reason: 'nets');
    expect(nets.keys.toList(), exp.keys.toList(), reason: 'nets are in sortOrder');
  }
  if (expected.containsKey('transfers')) {
    expect(Simplifier.simplify(nets, members), [
      for (final t in _list(expected['transfers']))
        Transfer(t['fromMemberId'] as String, t['toMemberId'] as String, t['amountMinor'] as int),
    ], reason: 'transfers (ordered)');
  }
}

List<Map<String, dynamic>> _list(Object? json) => [for (final o in json! as List<dynamic>) o as Map<String, dynamic>];

Map<String, int> _intMap(Object? json) => (json! as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));

void _field(Map<String, dynamic> exp, String field, int actual) {
  if (exp.containsKey(field)) {
    expect(actual, exp[field], reason: field);
  }
}
