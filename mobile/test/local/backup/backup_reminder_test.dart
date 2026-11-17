import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/backup/backup_reminder.dart';
import 'package:qesma/local/backup/backup_service.dart';

import '../backend/support/local_http.dart';

const _day = 86400000;

void main() {
  const installed = 1000 * _day;
  bool show({int now = installed, int live = 1, int since = 0, int? last, int? snoozed}) => BackupReminder.shouldShow(
      now: now, liveExpenseCount: live, expensesSinceExport: since, lastExportAt: last, installedAt: installed, snoozedUntil: snoozed);

  group('the rule (10 expenses or 14 days)', () {
    test('nothing to save, nothing to remind', () {
      expect(show(live: 0, since: 0, now: installed + 100 * _day), isFalse);
    });
    test('expense threshold: 9 no, 10 yes', () {
      expect(show(since: 9, live: 9), isFalse);
      expect(show(since: 10, live: 10), isTrue);
    });
    test('day threshold counted from install when never exported: 13 days no, 14 days yes', () {
      expect(show(now: installed + 14 * _day - 1), isFalse);
      expect(show(now: installed + 14 * _day), isTrue);
    });
    test('day threshold counted from the last export once there is one', () {
      final last = installed + 20 * _day;
      expect(show(now: last + 13 * _day, last: last), isFalse);
      expect(show(now: last + 14 * _day, last: last), isTrue);
    });
    test('a snooze hides it until it expires', () {
      final now = installed + 30 * _day;
      expect(show(now: now, snoozed: now + 1), isFalse);
      expect(show(now: now, snoozed: now), isTrue);
      expect(BackupReminder.snoozeUntil(now), now + 7 * _day);
    });
  });

  group('from the database', () {
    late LocalHttp http;
    late int now;
    late BackupService service;

    setUp(() async {
      http = await LocalHttp.open(profileName: 'Mona');
      now = DateTime.now().toUtc().millisecondsSinceEpoch;
      service = BackupService(http.db, clock: () => now);
    });
    tearDown(() => http.close());

    test('a new install with no expenses shows nothing; the banner appears after 10 expenses and export resets it', () async {
      expect((await service.status()).showReminder, isFalse);
      final g = await http.group();
      final gid = g['id'] as String;
      for (var i = 0; i < 9; i++) {
        await http.expense(gid, {'title': 'E$i', 'expenseDate': '2026-11-10', 'splitType': 'EQUAL', 'totalMinor': 1000, 'payers': [{'memberId': g['yourMemberId'], 'amountMinor': 1000}]});
      }
      expect((await service.status()).showReminder, isFalse);
      await http.expense(gid, {'title': 'E9', 'expenseDate': '2026-11-10', 'splitType': 'EQUAL', 'totalMinor': 1000, 'payers': [{'memberId': g['yourMemberId'], 'amountMinor': 1000}]});
      expect((await service.status()).showReminder, isTrue);

      await service.snoozeReminder();
      expect((await service.status()).showReminder, isFalse, reason: 'dismissed');
      now += 8 * _day;
      expect((await service.status()).showReminder, isTrue, reason: 'the snooze expired');

      await service.markExported(await service.snapshot());
      final status = await service.status();
      expect((status.showReminder, status.lastExportAt != null), (false, true));
    });

    test('14 days after install with at least one expense', () async {
      final g = await http.group();
      await http.expense(g['id'] as String, {'title': 'One', 'expenseDate': '2026-11-10', 'splitType': 'EQUAL', 'totalMinor': 1000, 'payers': [{'memberId': g['yourMemberId'], 'amountMinor': 1000}]});
      expect((await service.status()).showReminder, isFalse);
      now += 15 * _day;
      expect((await service.status()).showReminder, isTrue);
    });
  });
}
