import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/errors.dart';
import 'package:qesma/local/service/archive_service.dart';
import 'package:qesma/local/service/local_context.dart';

import 'support/local_http.dart';

/// A184: the archive of settled groups. A group is archived only when settled (all nets 0, pool empty), disappears
/// from the groups list, comes back on restore, and is deleted with its ledger once the retention period is over.
void main() {
  late LocalHttp http;
  late ArchiveService archive;
  late String gid;
  late String you;

  setUp(() async {
    http = await LocalHttp.open();
    archive = ArchiveService(LocalContext(http.db, clock: () => http.now[0]));
    final g = await http.group();
    gid = g['id'] as String;
    you = g['yourMemberId'] as String;
  });
  tearDown(() => http.close());

  Future<List<String>> listedIds() async => [for (final g in (await http.get('/groups')).data['items'] as List) (g as Map)['id'] as String];

  /// An open balance: Ali owes half of a 90.00 dinner you paid.
  Future<String> openBalance() async {
    final ali = await http.member(gid, 'Ali');
    await http.expense(gid, equalBody(9000, [(id: you, amount: 9000)], participants: [you, ali]));
    return ali;
  }

  group('archive', () {
    test('a settled group is hidden from the groups list and listed in the archive', () async {
      expect(await listedIds(), [gid]);
      await archive.archive(gid);
      expect(await listedIds(), isEmpty);
      final archived = await archive.list();
      expect(archived.map((g) => g.id), [gid]);
      expect(archived.single.deletesAt - archived.single.archivedAt, 30 * ArchiveService.dayMillis);
    });

    test('a group with an open balance cannot be archived', () async {
      await openBalance();
      await expectLater(archive.archive(gid), throwsA(isA<LocalApiException>().having((e) => e.code, 'code', 'GROUP_NOT_EMPTY')));
      expect(await listedIds(), [gid]);
      expect(await archive.list(), isEmpty);
    });

    test('a group whose pool still holds money cannot be archived until it is empty', () async {
      final ali = await http.member(gid, 'Ali');
      expect((await http.patch('/groups/$gid', {'treasurerMemberId': you}, ifMatch: '"${(await http.get('/groups/$gid')).data['version']}"')).statusCode, 200);
      final dep = await http.settlement(gid, {'fromMemberId': ali, 'toMemberId': you, 'amountMinor': 1000, 'settledOn': '2026-11-12', 'kind': 'POOL_DEPOSIT'});
      expect(dep.statusCode, 201, reason: '${dep.data}');
      await expectLater(archive.archive(gid), throwsA(isA<LocalApiException>().having((e) => e.code, 'code', 'GROUP_NOT_EMPTY')));
      // Cancelling the deposit empties the pool again.
      expect((await http.post('/groups/$gid/settlements/${dep.data['id']}/cancel', null)).data['status'], 'CANCELLED');
      await archive.archive(gid);
      expect(await listedIds(), isEmpty);
    });

    test('restore brings the group back to the list', () async {
      await archive.archive(gid);
      await archive.restore(gid);
      expect(await listedIds(), [gid]);
      expect(await archive.list(), isEmpty);
    });

    test('archiving twice keeps the first archive time', () async {
      await archive.archive(gid);
      final first = (await archive.list()).single.archivedAt;
      http.advance(const Duration(days: 1));
      await archive.archive(gid);
      expect((await archive.list()).single.archivedAt, first);
    });
  });

  group('retention and purge', () {
    test('the period is 7, 15 or 30 days (default 30) and nothing else', () async {
      expect(await archive.retentionDays(), 30);
      for (final d in [7, 15, 30]) {
        await archive.setRetentionDays(d);
        expect(await archive.retentionDays(), d);
      }
      await expectLater(archive.setRetentionDays(10), throwsArgumentError);
    });

    test('an archived group is deleted with its whole ledger once the period is over, not before', () async {
      final ali = await openBalance();
      await http.settlement(gid, {'fromMemberId': ali, 'toMemberId': you, 'amountMinor': 4500, 'settledOn': '2026-11-01'});
      await archive.setRetentionDays(7);
      await archive.archive(gid);

      http.advance(const Duration(days: 6, hours: 23));
      expect(await archive.purgeExpired(), 0);
      expect(await http.count('expense_groups'), 1);

      http.advance(const Duration(hours: 2));
      expect(await archive.purgeExpired(), 1);
      for (final table in ['expense_groups', 'members', 'expenses', 'expense_payers', 'expense_splits', 'settlements']) {
        expect(await http.count(table), 0, reason: table);
      }
    });

    test('a group that is no longer settled is restored instead of deleted', () async {
      await archive.archive(gid);
      // Something changes it while archived (a direct write: the app has no screen for it).
      final ali = await http.member(gid, 'Ali');
      await http.expense(gid, equalBody(9000, [(id: you, amount: 9000)], participants: [you, ali]));
      http.advance(const Duration(days: 31));
      expect(await archive.purgeExpired(), 0);
      expect(await listedIds(), [gid]);
      expect(await http.count('expenses'), 1);
    });

    test('delete now removes an archived settled group at once, and refuses an unsettled one', () async {
      await archive.archive(gid);
      await archive.deleteNow(gid);
      expect(await http.count('expense_groups'), 0);

      final g2 = (await http.group(name: 'Second'))['id'] as String;
      final y2 = (await http.get('/groups/$g2')).data['yourMemberId'] as String;
      final ali = await http.member(g2, 'Ali');
      await http.expense(g2, equalBody(9000, [(id: y2, amount: 9000)], participants: [y2, ali]));
      await expectLater(archive.deleteNow(g2), throwsA(isA<LocalApiException>()));
      expect(await http.count('expense_groups'), 1);
    });
  });
}
