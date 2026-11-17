import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/backup/backup_service.dart';
import 'package:qesma/local/db/local_database.dart';

import 'support/backup_support.dart';

String _id(int kind, int n) => '${kind.toString().padLeft(8, '0')}-0000-4000-8000-${n.toString().padLeft(12, '0')}';

/// 50 groups x 100 expenses = 5,000 expenses (each with payer, splits and a revision), built directly as JSON.
Map<String, dynamic> _bigBackup() {
  const t = 1763337600000;
  final profile = _id(1, 1);
  final groups = <Map<String, dynamic>>[], members = <Map<String, dynamic>>[], expenses = <Map<String, dynamic>>[];
  final payers = <Map<String, dynamic>>[], splits = <Map<String, dynamic>>[], revisions = <Map<String, dynamic>>[];
  var e = 0;
  for (var g = 0; g < 50; g++) {
    groups.add({'id': _id(2, g), 'owner_user_id': profile, 'name': 'Group $g', 'type': 'TRIP', 'currency_code': 'EGP', 'created_at': t, 'updated_at': t, 'version': 1, 'member_seq': 4});
    for (var m = 0; m < 4; m++) {
      members.add({'id': _id(3, g * 4 + m), 'group_id': _id(2, g), 'display_name': 'Member $m', 'name_key': 'member $m', 'user_id': m == 0 ? profile : null, 'sort_order': m + 1, 'role': m == 0 ? 'OWNER' : 'MEMBER', 'status': 'ACTIVE', 'joined_at': m == 0 ? t : null, 'left_at': null, 'created_at': t});
    }
    for (var x = 0; x < 100; x++, e++) {
      final id = _id(4, e);
      expenses.add({'id': id, 'group_id': _id(2, g), 'title': 'Expense $e', 'split_type': 'EQUAL', 'total_minor': 10000, 'expense_date': '2026-11-10', 'subtotal_minor': null, 'service_bps': null, 'service_minor': null, 'tax_bps': null, 'tax_minor': null, 'tax_base': null, 'adjustment_minor': null, 'created_by_user_id': profile, 'created_at': t + e, 'updated_at': t + e, 'deleted_at': null, 'version': 1});
      payers.add({'expense_id': id, 'member_id': _id(3, g * 4), 'amount_minor': 10000});
      for (var m = 0; m < 4; m++) {
        splits.add({'expense_id': id, 'member_id': _id(3, g * 4 + m), 'owed_minor': 2500, 'items_minor': null, 'service_minor': null, 'tax_minor': null, 'adjustment_minor': null});
      }
      revisions.add({'id': _id(5, e), 'expense_id': id, 'version': 1, 'change_type': 'CREATE', 'snapshot': jsonEncode({'title': 'Expense $e', 'totalMinor': 10000}), 'changed_by_user_id': profile, 'changed_at': t + e});
    }
  }
  return {
    'formatVersion': 1,
    'schemaVersion': 2,
    'exportedAt': t,
    'appVersion': '0.1.0+1',
    'profile': {'id': profile, 'display_name': 'Mona', 'created_at': t, 'updated_at': t, 'singleton': 1},
    'payment_handles': <Object?>[],
    'groups': groups,
    'members': members,
    'expenses': expenses,
    'expense_payers': payers,
    'expense_splits': splits,
    'expense_items': <Object?>[],
    'expense_item_assignees': <Object?>[],
    'expense_revisions': revisions,
    'settlements': <Object?>[],
  };
}

void main() {
  test('a backup of 50 groups and 5,000 expenses is validated and imported within 15 seconds (one transaction)', () async {
    final Uint8List bytes = encodeBackup(_bigBackup());
    final db = LocalDatabase.inMemory();
    addTearDown(db.close);
    final service = BackupService(db);

    final watch = Stopwatch()..start();
    final data = await service.prepareRestore(bytes);
    final validated = watch.elapsedMilliseconds;
    await service.restore(data);
    watch.stop();

    // ignore: avoid_print
    print('backup size ${(bytes.length / 1024).round()} KiB; validate $validated ms; total import ${watch.elapsedMilliseconds} ms');
    expect(await db.customSelect('SELECT COUNT(*) AS n FROM expenses').getSingle().then((r) => r.read<int>('n')), 5000);
    expect(await db.customSelect('SELECT COUNT(*) AS n FROM expense_splits').getSingle().then((r) => r.read<int>('n')), 20000);
    expect(watch.elapsed, lessThan(const Duration(seconds: 15)));
  });
}
