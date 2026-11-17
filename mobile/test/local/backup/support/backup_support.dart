import 'dart:convert';
import 'dart:typed_data';

import 'package:qesma/local/backup/backup_service.dart';
import 'package:qesma/local/db/local_database.dart';

import '../../backend/support/local_http.dart';

/// A ledger that exercises every table: two groups; EQUAL (multi-payer), EXACT and ITEMIZED expenses; one expense
/// edited (revision 2) and one deleted (revision 2, soft); a confirmed and a cancelled settlement; both payment handles.
Future<void> seedRichLedger(LocalHttp http) async {
  Future<void> ok(Future<dynamic> call) async {
    final r = await call;
    if ((r.statusCode as int) >= 300) throw StateError('seed failed: ${r.statusCode} ${r.data}');
  }

  final g = await http.group(name: 'Dahab trip');
  final gid = g['id'] as String;
  final you = g['yourMemberId'] as String;
  final ali = await http.member(gid, 'Ali');
  final sara = await http.member(gid, 'سارة');

  Map<String, Object?> equal(int total, List<Map<String, Object?>> payers, String title) =>
      {'title': title, 'expenseDate': '2026-11-10', 'splitType': 'EQUAL', 'totalMinor': total, 'payers': payers};

  await ok(http.expense(gid, equal(30001, [
    {'memberId': you, 'amountMinor': 20001},
    {'memberId': ali, 'amountMinor': 10000},
  ], 'Hotel')));
  await ok(http.expense(gid, {
    'title': 'Dinner',
    'expenseDate': '2026-11-11',
    'splitType': 'EXACT',
    'totalMinor': 9000,
    'payers': [
      {'memberId': sara, 'amountMinor': 9000}
    ],
    'shares': [
      {'memberId': you, 'amountMinor': 2000},
      {'memberId': ali, 'amountMinor': 3000},
      {'memberId': sara, 'amountMinor': 4000},
    ],
  }));
  await ok(http.expense(gid, {
    'title': 'Restaurant',
    'expenseDate': '2026-11-12',
    'splitType': 'ITEMIZED',
    'items': [
      {'name': 'Fish', 'amountMinor': 6000, 'assigneeMemberIds': [you, ali]},
      {'name': 'Salad', 'amountMinor': 4000, 'assigneeMemberIds': [sara]},
    ],
    'service': {'bps': 1200},
    'tax': {'bps': 1400, 'base': 'SUBTOTAL_PLUS_SERVICE'},
    'adjustmentMinor': 0,
    'payers': [
      {'memberId': you, 'amountMinor': 12768}
    ],
  }));
  final edited = await http.expense(gid, equal(5000, [
    {'memberId': you, 'amountMinor': 5000}
  ], 'Taxi'));
  final eid = edited.data['id'] as String;
  await ok(http.put('/groups/$gid/expenses/$eid', equal(7000, [
    {'memberId': you, 'amountMinor': 7000}
  ], 'Taxi (edited)'), ifMatch: '"1"'));
  final doomed = await http.expense(gid, equal(1000, [
    {'memberId': ali, 'amountMinor': 1000}
  ], 'Snacks'));
  await ok(http.delete('/groups/$gid/expenses/${doomed.data['id']}', ifMatch: '"1"'));

  await ok(http.settlement(gid, {'fromMemberId': ali, 'toMemberId': you, 'amountMinor': 2500, 'settledOn': '2026-11-13', 'note': 'cash'}));
  final cancelled = await http.settlement(gid, {'fromMemberId': sara, 'toMemberId': you, 'amountMinor': 100, 'settledOn': '2026-11-13'});
  await ok(http.post('/groups/$gid/settlements/${cancelled.data['id']}/cancel', null));

  final g2 = await http.group(name: 'Flat', type: 'HOUSING');
  final you2 = g2['yourMemberId'] as String;
  await ok(http.expense(g2['id'] as String, equal(4500, [
    {'memberId': you2, 'amountMinor': 4500}
  ], 'Electricity')));
  await ok(http.put('/me/payment-handles', {'instapay': 'mona@instapay', 'wallet': '01012345678'}));
}

/// Everything the app can read about the ledger through the contract, as one comparable value.
Future<Map<String, Object?>> contractDump(LocalHttp http) async {
  Future<Object?> get(String path, {Map<String, dynamic>? query}) async {
    final r = await http.get(path, query: query);
    if (r.statusCode != 200) throw StateError('GET $path -> ${r.statusCode}');
    return r.data;
  }

  final out = <String, Object?>{'me': await get('/me'), 'handles': await get('/me/payment-handles')};
  final groups = (await get('/groups', query: {'limit': 100}) as Map)['items'] as List;
  out['groups'] = groups;
  for (final g in groups.cast<Map<String, dynamic>>()) {
    final gid = g['id'] as String;
    out['group $gid'] = await get('/groups/$gid');
    out['balances $gid'] = await get('/groups/$gid/balances');
    out['settlements $gid'] = await get('/groups/$gid/settlements', query: {'limit': 100});
    final list = (await get('/groups/$gid/expenses', query: {'limit': 100}) as Map)['items'] as List;
    out['expenses $gid'] = list;
    for (final e in list.cast<Map<String, dynamic>>()) {
      out['expense ${e['id']}'] = await get('/groups/$gid/expenses/${e['id']}');
      out['revisions ${e['id']}'] = await get('/groups/$gid/expenses/${e['id']}/revisions');
    }
  }
  return out;
}

/// Row counts plus a hash-like digest of every ledger table: equal before and after proves "nothing changed".
Future<String> fingerprint(LocalDatabase db) async {
  final tables = [
    'local_profile', 'payment_handles', 'expense_groups', 'members', 'expenses', 'expense_payers', 'expense_splits',
    'expense_items', 'expense_item_assignees', 'expense_revisions', 'settlements', 'idempotency_keys',
  ];
  final parts = <String>[];
  for (final t in tables) {
    final rows = await db.customSelect('SELECT * FROM $t ORDER BY 1, 2').get();
    parts.add('$t:${jsonEncode([for (final r in rows) r.data])}');
  }
  return parts.join('\n');
}

Future<Uint8List> exportBytes(LocalDatabase db, {int Function()? clock}) async {
  final service = BackupService(db, appVersion: '0.1.0+1', clock: clock);
  return service.encode(await service.snapshot());
}

Map<String, dynamic> decodeBackup(Uint8List bytes) => jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

Uint8List encodeBackup(Map<String, dynamic> json) => Uint8List.fromList(utf8.encode(jsonEncode(json)));
