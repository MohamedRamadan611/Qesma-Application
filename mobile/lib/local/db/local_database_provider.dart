import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'local_database.dart';

/// File name of the local database inside the app documents directory (Android: `<data dir>/app_flutter/`).
/// SA5's Android backup rules include this file; never rename a shipped file.
const localDatabaseFileName = 'qesma_local.sqlite';

/// The app-wide local database, opened lazily on first use and closed with the provider container.
/// Tests override it with `LocalDatabase.inMemory()`.
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase(LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    return LocalDatabase.openFile(File('${dir.path}${Platform.pathSeparator}$localDatabaseFileName'));
  }));
  ref.onDispose(db.close);
  return db;
});
