import '../db/local_database.dart';

/// The backup file format (STANDALONE_SPEC 6, A127 and the SA5 decisions). One UTF-8 JSON object named
/// `qesma-backup-v1.json`; rows use the database column names (snake_case); money, basis points and timestamps are
/// JSON integers; ids are preserved. Idempotency keys and `local_meta` (per-device state) are not exported.
const int backupFormatVersion = 1;
const String backupFileName = 'qesma-backup-v1.json';

/// Limits applied before anything is decoded or written (a hostile or corrupted file must not exhaust memory).
const int maxBackupBytes = 50 * 1024 * 1024;
const int maxBackupGroups = 1000;
const int maxBackupExpenses = 200000;
const int maxBackupRows = 1000000;

/// Why a backup was refused. The UI maps each code to one plain message; none carries file content.
enum BackupError {
  /// Empty, not UTF-8, not JSON, or not a JSON object.
  unreadable,

  /// Larger than [maxBackupBytes] or more rows than the caps.
  tooLarge,

  /// `formatVersion` or `schemaVersion` is newer than this app understands: update the app.
  newerFormat,

  /// A missing or malformed field, a value outside its limits, a broken reference or a duplicate.
  invalid,

  /// The ledger does not add up (shares versus total, nets versus zero).
  inconsistent,

  /// The write failed and was rolled back (nothing changed).
  failed,
}

/// Thrown by the validator and the importer. [path] is a location such as `expenses[12].payers`, never a value.
final class BackupException implements Exception {
  const BackupException(this.code, [this.path = '']);

  final BackupError code;
  final String path;

  @override
  String toString() => 'BackupException(${code.name}${path.isEmpty ? '' : ' at $path'})';
}

/// A whole ledger as the file holds it, in typed rows.
final class BackupData {
  const BackupData({
    required this.formatVersion,
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.profile,
    required this.paymentHandles,
    required this.groups,
    required this.members,
    required this.expenses,
    required this.payers,
    required this.splits,
    required this.items,
    required this.assignees,
    required this.revisions,
    required this.settlements,
  });

  final int formatVersion;
  final int schemaVersion;
  final int exportedAt;
  final String appVersion;
  final LocalProfileRow profile;
  final List<PaymentHandleRow> paymentHandles;
  final List<GroupRow> groups;
  final List<MemberRow> members;
  final List<ExpenseRow> expenses;
  final List<PayerRow> payers;
  final List<SplitRow> splits;
  final List<ItemRow> items;
  final List<AssigneeRow> assignees;
  final List<RevisionRow> revisions;
  final List<SettlementRow> settlements;

  int get liveExpenseCount => expenses.where((e) => e.deletedAt == null).length;

  int get rowCount =>
      1 +
      paymentHandles.length +
      groups.length +
      members.length +
      expenses.length +
      payers.length +
      splits.length +
      items.length +
      assignees.length +
      revisions.length +
      settlements.length;

  /// The JSON document (rows keep the database column names).
  Map<String, Object?> toJson() => {
        'formatVersion': formatVersion,
        'schemaVersion': schemaVersion,
        'exportedAt': exportedAt,
        'appVersion': appVersion,
        'profile': profile.toJson(),
        'payment_handles': [for (final r in paymentHandles) r.toJson()],
        'groups': [for (final r in groups) r.toJson()],
        'members': [for (final r in members) r.toJson()],
        'expenses': [for (final r in expenses) r.toJson()],
        'expense_payers': [for (final r in payers) r.toJson()],
        'expense_splits': [for (final r in splits) r.toJson()],
        'expense_items': [for (final r in items) r.toJson()],
        'expense_item_assignees': [for (final r in assignees) r.toJson()],
        'expense_revisions': [for (final r in revisions) r.toJson()],
        'settlements': [for (final r in settlements) r.toJson()],
      };
}
