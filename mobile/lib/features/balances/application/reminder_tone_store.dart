import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../local/db/local_database.dart';
import '../../../local/db/local_database_provider.dart';
import '../domain/reminder_tone.dart';

/// Store for persisting the user's last-used reminder tone (A148).
abstract class ReminderToneStore {
  Future<ReminderTone> getLastTone();
  Future<void> setLastTone(ReminderTone tone);
}

final class LocalReminderToneStore implements ReminderToneStore {
  const LocalReminderToneStore(this._db);

  final LocalDatabase _db;

  @override
  Future<ReminderTone> getLastTone() async {
    final meta = await _db.metaDao.get();
    return ReminderTone.fromDb(meta.lastReminderTone);
  }

  @override
  Future<void> setLastTone(ReminderTone tone) async {
    await _db.metaDao.setLastReminderTone(tone.dbValue);
  }
}

final reminderToneStoreProvider = Provider<ReminderToneStore>((ref) {
  return LocalReminderToneStore(ref.watch(localDatabaseProvider));
});
