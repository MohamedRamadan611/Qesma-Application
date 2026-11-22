// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class LocalProfile extends Table with TableInfo<LocalProfile, LocalProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LocalProfile(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 36)',
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(trim(display_name)) BETWEEN 1 AND 60)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _singletonMeta = const VerificationMeta(
    'singleton',
  );
  late final GeneratedColumn<int> singleton = GeneratedColumn<int>(
    'singleton',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 UNIQUE CHECK (singleton = 1)',
    defaultValue: const CustomExpression('1'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    createdAt,
    updatedAt,
    singleton,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('singleton')) {
      context.handle(
        _singletonMeta,
        singleton.isAcceptableOrUnknown(data['singleton']!, _singletonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      singleton: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton'],
      )!,
    );
  }

  @override
  LocalProfile createAlias(String alias) {
    return LocalProfile(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class LocalProfileRow extends DataClass implements Insertable<LocalProfileRow> {
  final String id;
  final String displayName;
  final int createdAt;
  final int updatedAt;
  final int singleton;
  const LocalProfileRow({
    required this.id,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
    required this.singleton,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['singleton'] = Variable<int>(singleton);
    return map;
  }

  LocalProfileCompanion toCompanion(bool nullToAbsent) {
    return LocalProfileCompanion(
      id: Value(id),
      displayName: Value(displayName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      singleton: Value(singleton),
    );
  }

  factory LocalProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProfileRow(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['display_name']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
      singleton: serializer.fromJson<int>(json['singleton']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'display_name': serializer.toJson<String>(displayName),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
      'singleton': serializer.toJson<int>(singleton),
    };
  }

  LocalProfileRow copyWith({
    String? id,
    String? displayName,
    int? createdAt,
    int? updatedAt,
    int? singleton,
  }) => LocalProfileRow(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    singleton: singleton ?? this.singleton,
  );
  LocalProfileRow copyWithCompanion(LocalProfileCompanion data) {
    return LocalProfileRow(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      singleton: data.singleton.present ? data.singleton.value : this.singleton,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfileRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('singleton: $singleton')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, displayName, createdAt, updatedAt, singleton);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProfileRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.singleton == this.singleton);
}

class LocalProfileCompanion extends UpdateCompanion<LocalProfileRow> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> singleton;
  final Value<int> rowid;
  const LocalProfileCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.singleton = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProfileCompanion.insert({
    required String id,
    required String displayName,
    required int createdAt,
    required int updatedAt,
    this.singleton = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalProfileRow> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? singleton,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (singleton != null) 'singleton': singleton,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProfileCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? singleton,
    Value<int>? rowid,
  }) {
    return LocalProfileCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      singleton: singleton ?? this.singleton,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (singleton.present) {
      map['singleton'] = Variable<int>(singleton.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfileCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('singleton: $singleton, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LocalMeta extends Table with TableInfo<LocalMeta, LocalMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LocalMeta(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (id = 1)',
  );
  static const VerificationMeta _createdSchemaVersionMeta =
      const VerificationMeta('createdSchemaVersion');
  late final GeneratedColumn<int> createdSchemaVersion = GeneratedColumn<int>(
    'created_schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (created_schema_version >= 1)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _lastExportAtMeta = const VerificationMeta(
    'lastExportAt',
  );
  late final GeneratedColumn<int> lastExportAt = GeneratedColumn<int>(
    'last_export_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _lastExportFormatVersionMeta =
      const VerificationMeta('lastExportFormatVersion');
  late final GeneratedColumn<int> lastExportFormatVersion =
      GeneratedColumn<int>(
        'last_export_format_version',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: 'CHECK (last_export_format_version IS NULL OR last_export_format_version >= 1)',
      );
  static const VerificationMeta _backupReminderSnoozedUntilMeta =
      const VerificationMeta('backupReminderSnoozedUntil');
  late final GeneratedColumn<int> backupReminderSnoozedUntil =
      GeneratedColumn<int>(
        'backup_reminder_snoozed_until',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _lastReminderToneMeta = const VerificationMeta(
    'lastReminderTone',
  );
  late final GeneratedColumn<String> lastReminderTone = GeneratedColumn<String>(
    'last_reminder_tone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (last_reminder_tone IS NULL OR last_reminder_tone IN (\'SOFT\', \'FIRM\', \'FUNNY\'))',
  );
  static const VerificationMeta _ocrConsentAtMeta = const VerificationMeta(
    'ocrConsentAt',
  );
  late final GeneratedColumn<int> ocrConsentAt = GeneratedColumn<int>(
    'ocr_consent_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _ocrScanDayMeta = const VerificationMeta(
    'ocrScanDay',
  );
  late final GeneratedColumn<String> ocrScanDay = GeneratedColumn<String>(
    'ocr_scan_day',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (ocr_scan_day IS NULL OR ocr_scan_day GLOB \'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\')',
  );
  static const VerificationMeta _ocrScanCountMeta = const VerificationMeta(
    'ocrScanCount',
  );
  late final GeneratedColumn<int> ocrScanCount = GeneratedColumn<int>(
    'ocr_scan_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (ocr_scan_count >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _ocrPermissionErrorsMeta =
      const VerificationMeta('ocrPermissionErrors');
  late final GeneratedColumn<int> ocrPermissionErrors = GeneratedColumn<int>(
    'ocr_permission_errors',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (ocr_permission_errors >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _ocrHiddenUntilMeta = const VerificationMeta(
    'ocrHiddenUntil',
  );
  late final GeneratedColumn<int> ocrHiddenUntil = GeneratedColumn<int>(
    'ocr_hidden_until',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _archiveRetentionDaysMeta =
      const VerificationMeta('archiveRetentionDays');
  late final GeneratedColumn<int> archiveRetentionDays = GeneratedColumn<int>(
    'archive_retention_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT 30 CHECK (archive_retention_days IN (7, 15, 30))',
    defaultValue: const CustomExpression('30'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdSchemaVersion,
    createdAt,
    lastExportAt,
    lastExportFormatVersion,
    backupReminderSnoozedUntil,
    lastReminderTone,
    ocrConsentAt,
    ocrScanDay,
    ocrScanCount,
    ocrPermissionErrors,
    ocrHiddenUntil,
    archiveRetentionDays,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_schema_version')) {
      context.handle(
        _createdSchemaVersionMeta,
        createdSchemaVersion.isAcceptableOrUnknown(
          data['created_schema_version']!,
          _createdSchemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdSchemaVersionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_export_at')) {
      context.handle(
        _lastExportAtMeta,
        lastExportAt.isAcceptableOrUnknown(
          data['last_export_at']!,
          _lastExportAtMeta,
        ),
      );
    }
    if (data.containsKey('last_export_format_version')) {
      context.handle(
        _lastExportFormatVersionMeta,
        lastExportFormatVersion.isAcceptableOrUnknown(
          data['last_export_format_version']!,
          _lastExportFormatVersionMeta,
        ),
      );
    }
    if (data.containsKey('backup_reminder_snoozed_until')) {
      context.handle(
        _backupReminderSnoozedUntilMeta,
        backupReminderSnoozedUntil.isAcceptableOrUnknown(
          data['backup_reminder_snoozed_until']!,
          _backupReminderSnoozedUntilMeta,
        ),
      );
    }
    if (data.containsKey('last_reminder_tone')) {
      context.handle(
        _lastReminderToneMeta,
        lastReminderTone.isAcceptableOrUnknown(
          data['last_reminder_tone']!,
          _lastReminderToneMeta,
        ),
      );
    }
    if (data.containsKey('ocr_consent_at')) {
      context.handle(
        _ocrConsentAtMeta,
        ocrConsentAt.isAcceptableOrUnknown(
          data['ocr_consent_at']!,
          _ocrConsentAtMeta,
        ),
      );
    }
    if (data.containsKey('ocr_scan_day')) {
      context.handle(
        _ocrScanDayMeta,
        ocrScanDay.isAcceptableOrUnknown(
          data['ocr_scan_day']!,
          _ocrScanDayMeta,
        ),
      );
    }
    if (data.containsKey('ocr_scan_count')) {
      context.handle(
        _ocrScanCountMeta,
        ocrScanCount.isAcceptableOrUnknown(
          data['ocr_scan_count']!,
          _ocrScanCountMeta,
        ),
      );
    }
    if (data.containsKey('ocr_permission_errors')) {
      context.handle(
        _ocrPermissionErrorsMeta,
        ocrPermissionErrors.isAcceptableOrUnknown(
          data['ocr_permission_errors']!,
          _ocrPermissionErrorsMeta,
        ),
      );
    }
    if (data.containsKey('ocr_hidden_until')) {
      context.handle(
        _ocrHiddenUntilMeta,
        ocrHiddenUntil.isAcceptableOrUnknown(
          data['ocr_hidden_until']!,
          _ocrHiddenUntilMeta,
        ),
      );
    }
    if (data.containsKey('archive_retention_days')) {
      context.handle(
        _archiveRetentionDaysMeta,
        archiveRetentionDays.isAcceptableOrUnknown(
          data['archive_retention_days']!,
          _archiveRetentionDaysMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMetaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      createdSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_schema_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      lastExportAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_export_at'],
      ),
      lastExportFormatVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_export_format_version'],
      ),
      backupReminderSnoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}backup_reminder_snoozed_until'],
      ),
      lastReminderTone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_reminder_tone'],
      ),
      ocrConsentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ocr_consent_at'],
      ),
      ocrScanDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_scan_day'],
      ),
      ocrScanCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ocr_scan_count'],
      )!,
      ocrPermissionErrors: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ocr_permission_errors'],
      )!,
      ocrHiddenUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ocr_hidden_until'],
      ),
      archiveRetentionDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archive_retention_days'],
      )!,
    );
  }

  @override
  LocalMeta createAlias(String alias) {
    return LocalMeta(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const [
    'CHECK((last_export_at IS NULL)=(last_export_format_version IS NULL))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class LocalMetaRow extends DataClass implements Insertable<LocalMetaRow> {
  final int id;
  final int createdSchemaVersion;
  final int createdAt;
  final int? lastExportAt;
  final int? lastExportFormatVersion;
  final int? backupReminderSnoozedUntil;
  final String? lastReminderTone;

  /// SA12 (schema 7): receipt-scan consent and limits, device state (not part of the backup).
  final int? ocrConsentAt;
  final String? ocrScanDay;
  final int ocrScanCount;
  final int ocrPermissionErrors;
  final int? ocrHiddenUntil;

  /// Schema 11 (A184): how long an archived group is kept before it is deleted (days). Device setting, not exported.
  final int archiveRetentionDays;
  const LocalMetaRow({
    required this.id,
    required this.createdSchemaVersion,
    required this.createdAt,
    this.lastExportAt,
    this.lastExportFormatVersion,
    this.backupReminderSnoozedUntil,
    this.lastReminderTone,
    this.ocrConsentAt,
    this.ocrScanDay,
    required this.ocrScanCount,
    required this.ocrPermissionErrors,
    this.ocrHiddenUntil,
    required this.archiveRetentionDays,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_schema_version'] = Variable<int>(createdSchemaVersion);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || lastExportAt != null) {
      map['last_export_at'] = Variable<int>(lastExportAt);
    }
    if (!nullToAbsent || lastExportFormatVersion != null) {
      map['last_export_format_version'] = Variable<int>(
        lastExportFormatVersion,
      );
    }
    if (!nullToAbsent || backupReminderSnoozedUntil != null) {
      map['backup_reminder_snoozed_until'] = Variable<int>(
        backupReminderSnoozedUntil,
      );
    }
    if (!nullToAbsent || lastReminderTone != null) {
      map['last_reminder_tone'] = Variable<String>(lastReminderTone);
    }
    if (!nullToAbsent || ocrConsentAt != null) {
      map['ocr_consent_at'] = Variable<int>(ocrConsentAt);
    }
    if (!nullToAbsent || ocrScanDay != null) {
      map['ocr_scan_day'] = Variable<String>(ocrScanDay);
    }
    map['ocr_scan_count'] = Variable<int>(ocrScanCount);
    map['ocr_permission_errors'] = Variable<int>(ocrPermissionErrors);
    if (!nullToAbsent || ocrHiddenUntil != null) {
      map['ocr_hidden_until'] = Variable<int>(ocrHiddenUntil);
    }
    map['archive_retention_days'] = Variable<int>(archiveRetentionDays);
    return map;
  }

  LocalMetaCompanion toCompanion(bool nullToAbsent) {
    return LocalMetaCompanion(
      id: Value(id),
      createdSchemaVersion: Value(createdSchemaVersion),
      createdAt: Value(createdAt),
      lastExportAt: lastExportAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastExportAt),
      lastExportFormatVersion: lastExportFormatVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(lastExportFormatVersion),
      backupReminderSnoozedUntil:
          backupReminderSnoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(backupReminderSnoozedUntil),
      lastReminderTone: lastReminderTone == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReminderTone),
      ocrConsentAt: ocrConsentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrConsentAt),
      ocrScanDay: ocrScanDay == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrScanDay),
      ocrScanCount: Value(ocrScanCount),
      ocrPermissionErrors: Value(ocrPermissionErrors),
      ocrHiddenUntil: ocrHiddenUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrHiddenUntil),
      archiveRetentionDays: Value(archiveRetentionDays),
    );
  }

  factory LocalMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMetaRow(
      id: serializer.fromJson<int>(json['id']),
      createdSchemaVersion: serializer.fromJson<int>(
        json['created_schema_version'],
      ),
      createdAt: serializer.fromJson<int>(json['created_at']),
      lastExportAt: serializer.fromJson<int?>(json['last_export_at']),
      lastExportFormatVersion: serializer.fromJson<int?>(
        json['last_export_format_version'],
      ),
      backupReminderSnoozedUntil: serializer.fromJson<int?>(
        json['backup_reminder_snoozed_until'],
      ),
      lastReminderTone: serializer.fromJson<String?>(
        json['last_reminder_tone'],
      ),
      ocrConsentAt: serializer.fromJson<int?>(json['ocr_consent_at']),
      ocrScanDay: serializer.fromJson<String?>(json['ocr_scan_day']),
      ocrScanCount: serializer.fromJson<int>(json['ocr_scan_count']),
      ocrPermissionErrors: serializer.fromJson<int>(
        json['ocr_permission_errors'],
      ),
      ocrHiddenUntil: serializer.fromJson<int?>(json['ocr_hidden_until']),
      archiveRetentionDays: serializer.fromJson<int>(
        json['archive_retention_days'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'created_schema_version': serializer.toJson<int>(createdSchemaVersion),
      'created_at': serializer.toJson<int>(createdAt),
      'last_export_at': serializer.toJson<int?>(lastExportAt),
      'last_export_format_version': serializer.toJson<int?>(
        lastExportFormatVersion,
      ),
      'backup_reminder_snoozed_until': serializer.toJson<int?>(
        backupReminderSnoozedUntil,
      ),
      'last_reminder_tone': serializer.toJson<String?>(lastReminderTone),
      'ocr_consent_at': serializer.toJson<int?>(ocrConsentAt),
      'ocr_scan_day': serializer.toJson<String?>(ocrScanDay),
      'ocr_scan_count': serializer.toJson<int>(ocrScanCount),
      'ocr_permission_errors': serializer.toJson<int>(ocrPermissionErrors),
      'ocr_hidden_until': serializer.toJson<int?>(ocrHiddenUntil),
      'archive_retention_days': serializer.toJson<int>(archiveRetentionDays),
    };
  }

  LocalMetaRow copyWith({
    int? id,
    int? createdSchemaVersion,
    int? createdAt,
    Value<int?> lastExportAt = const Value.absent(),
    Value<int?> lastExportFormatVersion = const Value.absent(),
    Value<int?> backupReminderSnoozedUntil = const Value.absent(),
    Value<String?> lastReminderTone = const Value.absent(),
    Value<int?> ocrConsentAt = const Value.absent(),
    Value<String?> ocrScanDay = const Value.absent(),
    int? ocrScanCount,
    int? ocrPermissionErrors,
    Value<int?> ocrHiddenUntil = const Value.absent(),
    int? archiveRetentionDays,
  }) => LocalMetaRow(
    id: id ?? this.id,
    createdSchemaVersion: createdSchemaVersion ?? this.createdSchemaVersion,
    createdAt: createdAt ?? this.createdAt,
    lastExportAt: lastExportAt.present ? lastExportAt.value : this.lastExportAt,
    lastExportFormatVersion: lastExportFormatVersion.present
        ? lastExportFormatVersion.value
        : this.lastExportFormatVersion,
    backupReminderSnoozedUntil: backupReminderSnoozedUntil.present
        ? backupReminderSnoozedUntil.value
        : this.backupReminderSnoozedUntil,
    lastReminderTone: lastReminderTone.present
        ? lastReminderTone.value
        : this.lastReminderTone,
    ocrConsentAt: ocrConsentAt.present ? ocrConsentAt.value : this.ocrConsentAt,
    ocrScanDay: ocrScanDay.present ? ocrScanDay.value : this.ocrScanDay,
    ocrScanCount: ocrScanCount ?? this.ocrScanCount,
    ocrPermissionErrors: ocrPermissionErrors ?? this.ocrPermissionErrors,
    ocrHiddenUntil: ocrHiddenUntil.present
        ? ocrHiddenUntil.value
        : this.ocrHiddenUntil,
    archiveRetentionDays: archiveRetentionDays ?? this.archiveRetentionDays,
  );
  LocalMetaRow copyWithCompanion(LocalMetaCompanion data) {
    return LocalMetaRow(
      id: data.id.present ? data.id.value : this.id,
      createdSchemaVersion: data.createdSchemaVersion.present
          ? data.createdSchemaVersion.value
          : this.createdSchemaVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastExportAt: data.lastExportAt.present
          ? data.lastExportAt.value
          : this.lastExportAt,
      lastExportFormatVersion: data.lastExportFormatVersion.present
          ? data.lastExportFormatVersion.value
          : this.lastExportFormatVersion,
      backupReminderSnoozedUntil: data.backupReminderSnoozedUntil.present
          ? data.backupReminderSnoozedUntil.value
          : this.backupReminderSnoozedUntil,
      lastReminderTone: data.lastReminderTone.present
          ? data.lastReminderTone.value
          : this.lastReminderTone,
      ocrConsentAt: data.ocrConsentAt.present
          ? data.ocrConsentAt.value
          : this.ocrConsentAt,
      ocrScanDay: data.ocrScanDay.present
          ? data.ocrScanDay.value
          : this.ocrScanDay,
      ocrScanCount: data.ocrScanCount.present
          ? data.ocrScanCount.value
          : this.ocrScanCount,
      ocrPermissionErrors: data.ocrPermissionErrors.present
          ? data.ocrPermissionErrors.value
          : this.ocrPermissionErrors,
      ocrHiddenUntil: data.ocrHiddenUntil.present
          ? data.ocrHiddenUntil.value
          : this.ocrHiddenUntil,
      archiveRetentionDays: data.archiveRetentionDays.present
          ? data.archiveRetentionDays.value
          : this.archiveRetentionDays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMetaRow(')
          ..write('id: $id, ')
          ..write('createdSchemaVersion: $createdSchemaVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastExportAt: $lastExportAt, ')
          ..write('lastExportFormatVersion: $lastExportFormatVersion, ')
          ..write('backupReminderSnoozedUntil: $backupReminderSnoozedUntil, ')
          ..write('lastReminderTone: $lastReminderTone, ')
          ..write('ocrConsentAt: $ocrConsentAt, ')
          ..write('ocrScanDay: $ocrScanDay, ')
          ..write('ocrScanCount: $ocrScanCount, ')
          ..write('ocrPermissionErrors: $ocrPermissionErrors, ')
          ..write('ocrHiddenUntil: $ocrHiddenUntil, ')
          ..write('archiveRetentionDays: $archiveRetentionDays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdSchemaVersion,
    createdAt,
    lastExportAt,
    lastExportFormatVersion,
    backupReminderSnoozedUntil,
    lastReminderTone,
    ocrConsentAt,
    ocrScanDay,
    ocrScanCount,
    ocrPermissionErrors,
    ocrHiddenUntil,
    archiveRetentionDays,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMetaRow &&
          other.id == this.id &&
          other.createdSchemaVersion == this.createdSchemaVersion &&
          other.createdAt == this.createdAt &&
          other.lastExportAt == this.lastExportAt &&
          other.lastExportFormatVersion == this.lastExportFormatVersion &&
          other.backupReminderSnoozedUntil == this.backupReminderSnoozedUntil &&
          other.lastReminderTone == this.lastReminderTone &&
          other.ocrConsentAt == this.ocrConsentAt &&
          other.ocrScanDay == this.ocrScanDay &&
          other.ocrScanCount == this.ocrScanCount &&
          other.ocrPermissionErrors == this.ocrPermissionErrors &&
          other.ocrHiddenUntil == this.ocrHiddenUntil &&
          other.archiveRetentionDays == this.archiveRetentionDays);
}

class LocalMetaCompanion extends UpdateCompanion<LocalMetaRow> {
  final Value<int> id;
  final Value<int> createdSchemaVersion;
  final Value<int> createdAt;
  final Value<int?> lastExportAt;
  final Value<int?> lastExportFormatVersion;
  final Value<int?> backupReminderSnoozedUntil;
  final Value<String?> lastReminderTone;
  final Value<int?> ocrConsentAt;
  final Value<String?> ocrScanDay;
  final Value<int> ocrScanCount;
  final Value<int> ocrPermissionErrors;
  final Value<int?> ocrHiddenUntil;
  final Value<int> archiveRetentionDays;
  const LocalMetaCompanion({
    this.id = const Value.absent(),
    this.createdSchemaVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastExportAt = const Value.absent(),
    this.lastExportFormatVersion = const Value.absent(),
    this.backupReminderSnoozedUntil = const Value.absent(),
    this.lastReminderTone = const Value.absent(),
    this.ocrConsentAt = const Value.absent(),
    this.ocrScanDay = const Value.absent(),
    this.ocrScanCount = const Value.absent(),
    this.ocrPermissionErrors = const Value.absent(),
    this.ocrHiddenUntil = const Value.absent(),
    this.archiveRetentionDays = const Value.absent(),
  });
  LocalMetaCompanion.insert({
    this.id = const Value.absent(),
    required int createdSchemaVersion,
    required int createdAt,
    this.lastExportAt = const Value.absent(),
    this.lastExportFormatVersion = const Value.absent(),
    this.backupReminderSnoozedUntil = const Value.absent(),
    this.lastReminderTone = const Value.absent(),
    this.ocrConsentAt = const Value.absent(),
    this.ocrScanDay = const Value.absent(),
    this.ocrScanCount = const Value.absent(),
    this.ocrPermissionErrors = const Value.absent(),
    this.ocrHiddenUntil = const Value.absent(),
    this.archiveRetentionDays = const Value.absent(),
  }) : createdSchemaVersion = Value(createdSchemaVersion),
       createdAt = Value(createdAt);
  static Insertable<LocalMetaRow> custom({
    Expression<int>? id,
    Expression<int>? createdSchemaVersion,
    Expression<int>? createdAt,
    Expression<int>? lastExportAt,
    Expression<int>? lastExportFormatVersion,
    Expression<int>? backupReminderSnoozedUntil,
    Expression<String>? lastReminderTone,
    Expression<int>? ocrConsentAt,
    Expression<String>? ocrScanDay,
    Expression<int>? ocrScanCount,
    Expression<int>? ocrPermissionErrors,
    Expression<int>? ocrHiddenUntil,
    Expression<int>? archiveRetentionDays,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdSchemaVersion != null)
        'created_schema_version': createdSchemaVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (lastExportAt != null) 'last_export_at': lastExportAt,
      if (lastExportFormatVersion != null)
        'last_export_format_version': lastExportFormatVersion,
      if (backupReminderSnoozedUntil != null)
        'backup_reminder_snoozed_until': backupReminderSnoozedUntil,
      if (lastReminderTone != null) 'last_reminder_tone': lastReminderTone,
      if (ocrConsentAt != null) 'ocr_consent_at': ocrConsentAt,
      if (ocrScanDay != null) 'ocr_scan_day': ocrScanDay,
      if (ocrScanCount != null) 'ocr_scan_count': ocrScanCount,
      if (ocrPermissionErrors != null)
        'ocr_permission_errors': ocrPermissionErrors,
      if (ocrHiddenUntil != null) 'ocr_hidden_until': ocrHiddenUntil,
      if (archiveRetentionDays != null)
        'archive_retention_days': archiveRetentionDays,
    });
  }

  LocalMetaCompanion copyWith({
    Value<int>? id,
    Value<int>? createdSchemaVersion,
    Value<int>? createdAt,
    Value<int?>? lastExportAt,
    Value<int?>? lastExportFormatVersion,
    Value<int?>? backupReminderSnoozedUntil,
    Value<String?>? lastReminderTone,
    Value<int?>? ocrConsentAt,
    Value<String?>? ocrScanDay,
    Value<int>? ocrScanCount,
    Value<int>? ocrPermissionErrors,
    Value<int?>? ocrHiddenUntil,
    Value<int>? archiveRetentionDays,
  }) {
    return LocalMetaCompanion(
      id: id ?? this.id,
      createdSchemaVersion: createdSchemaVersion ?? this.createdSchemaVersion,
      createdAt: createdAt ?? this.createdAt,
      lastExportAt: lastExportAt ?? this.lastExportAt,
      lastExportFormatVersion:
          lastExportFormatVersion ?? this.lastExportFormatVersion,
      backupReminderSnoozedUntil:
          backupReminderSnoozedUntil ?? this.backupReminderSnoozedUntil,
      lastReminderTone: lastReminderTone ?? this.lastReminderTone,
      ocrConsentAt: ocrConsentAt ?? this.ocrConsentAt,
      ocrScanDay: ocrScanDay ?? this.ocrScanDay,
      ocrScanCount: ocrScanCount ?? this.ocrScanCount,
      ocrPermissionErrors: ocrPermissionErrors ?? this.ocrPermissionErrors,
      ocrHiddenUntil: ocrHiddenUntil ?? this.ocrHiddenUntil,
      archiveRetentionDays: archiveRetentionDays ?? this.archiveRetentionDays,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdSchemaVersion.present) {
      map['created_schema_version'] = Variable<int>(createdSchemaVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastExportAt.present) {
      map['last_export_at'] = Variable<int>(lastExportAt.value);
    }
    if (lastExportFormatVersion.present) {
      map['last_export_format_version'] = Variable<int>(
        lastExportFormatVersion.value,
      );
    }
    if (backupReminderSnoozedUntil.present) {
      map['backup_reminder_snoozed_until'] = Variable<int>(
        backupReminderSnoozedUntil.value,
      );
    }
    if (lastReminderTone.present) {
      map['last_reminder_tone'] = Variable<String>(lastReminderTone.value);
    }
    if (ocrConsentAt.present) {
      map['ocr_consent_at'] = Variable<int>(ocrConsentAt.value);
    }
    if (ocrScanDay.present) {
      map['ocr_scan_day'] = Variable<String>(ocrScanDay.value);
    }
    if (ocrScanCount.present) {
      map['ocr_scan_count'] = Variable<int>(ocrScanCount.value);
    }
    if (ocrPermissionErrors.present) {
      map['ocr_permission_errors'] = Variable<int>(ocrPermissionErrors.value);
    }
    if (ocrHiddenUntil.present) {
      map['ocr_hidden_until'] = Variable<int>(ocrHiddenUntil.value);
    }
    if (archiveRetentionDays.present) {
      map['archive_retention_days'] = Variable<int>(archiveRetentionDays.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMetaCompanion(')
          ..write('id: $id, ')
          ..write('createdSchemaVersion: $createdSchemaVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastExportAt: $lastExportAt, ')
          ..write('lastExportFormatVersion: $lastExportFormatVersion, ')
          ..write('backupReminderSnoozedUntil: $backupReminderSnoozedUntil, ')
          ..write('lastReminderTone: $lastReminderTone, ')
          ..write('ocrConsentAt: $ocrConsentAt, ')
          ..write('ocrScanDay: $ocrScanDay, ')
          ..write('ocrScanCount: $ocrScanCount, ')
          ..write('ocrPermissionErrors: $ocrPermissionErrors, ')
          ..write('ocrHiddenUntil: $ocrHiddenUntil, ')
          ..write('archiveRetentionDays: $archiveRetentionDays')
          ..write(')'))
        .toString();
  }
}

class Members extends Table with TableInfo<Members, MemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Members(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 36)',
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES expense_groups(id)',
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(trim(display_name)) BETWEEN 1 AND 40)',
  );
  static const VerificationMeta _nameKeyMeta = const VerificationMeta(
    'nameKey',
  );
  late final GeneratedColumn<String> nameKey = GeneratedColumn<String>(
    'name_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (name_key <> \'\' AND name_key = lower(name_key))',
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES local_profile(id)',
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (sort_order >= 1)',
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'MEMBER\' CHECK (role IN (\'OWNER\', \'ADMIN\', \'MEMBER\'))',
    defaultValue: const CustomExpression('\'MEMBER\''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'ACTIVE\' CHECK (status IN (\'ACTIVE\', \'LEFT\'))',
    defaultValue: const CustomExpression('\'ACTIVE\''),
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  late final GeneratedColumn<int> joinedAt = GeneratedColumn<int>(
    'joined_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _leftAtMeta = const VerificationMeta('leftAt');
  late final GeneratedColumn<int> leftAt = GeneratedColumn<int>(
    'left_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    displayName,
    nameKey,
    userId,
    sortOrder,
    role,
    status,
    joinedAt,
    leftAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('name_key')) {
      context.handle(
        _nameKeyMeta,
        nameKey.isAcceptableOrUnknown(data['name_key']!, _nameKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_nameKeyMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    }
    if (data.containsKey('left_at')) {
      context.handle(
        _leftAtMeta,
        leftAt.isAcceptableOrUnknown(data['left_at']!, _leftAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {groupId, sortOrder},
    {groupId, nameKey},
  ];
  @override
  MemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      nameKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_key'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}joined_at'],
      ),
      leftAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}left_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  Members createAlias(String alias) {
    return Members(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const [
    'CONSTRAINT uq_members_group_sort_order UNIQUE(group_id, sort_order)',
    'CONSTRAINT uq_members_group_name_key UNIQUE(group_id, name_key)',
    'CONSTRAINT ck_members_owner_linked_active CHECK(role <> \'OWNER\' OR(user_id IS NOT NULL AND status = \'ACTIVE\'))',
    'CONSTRAINT ck_members_left_at CHECK((status = \'LEFT\')=(left_at IS NOT NULL))',
    'CONSTRAINT ck_members_left_linked CHECK(status <> \'LEFT\' OR user_id IS NOT NULL)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class MemberRow extends DataClass implements Insertable<MemberRow> {
  final String id;
  final String groupId;
  final String displayName;
  final String nameKey;
  final String? userId;
  final int sortOrder;
  final String role;
  final String status;
  final int? joinedAt;
  final int? leftAt;
  final int createdAt;
  const MemberRow({
    required this.id,
    required this.groupId,
    required this.displayName,
    required this.nameKey,
    this.userId,
    required this.sortOrder,
    required this.role,
    required this.status,
    this.joinedAt,
    this.leftAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['display_name'] = Variable<String>(displayName);
    map['name_key'] = Variable<String>(nameKey);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['role'] = Variable<String>(role);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || joinedAt != null) {
      map['joined_at'] = Variable<int>(joinedAt);
    }
    if (!nullToAbsent || leftAt != null) {
      map['left_at'] = Variable<int>(leftAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      id: Value(id),
      groupId: Value(groupId),
      displayName: Value(displayName),
      nameKey: Value(nameKey),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      sortOrder: Value(sortOrder),
      role: Value(role),
      status: Value(status),
      joinedAt: joinedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(joinedAt),
      leftAt: leftAt == null && nullToAbsent
          ? const Value.absent()
          : Value(leftAt),
      createdAt: Value(createdAt),
    );
  }

  factory MemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['group_id']),
      displayName: serializer.fromJson<String>(json['display_name']),
      nameKey: serializer.fromJson<String>(json['name_key']),
      userId: serializer.fromJson<String?>(json['user_id']),
      sortOrder: serializer.fromJson<int>(json['sort_order']),
      role: serializer.fromJson<String>(json['role']),
      status: serializer.fromJson<String>(json['status']),
      joinedAt: serializer.fromJson<int?>(json['joined_at']),
      leftAt: serializer.fromJson<int?>(json['left_at']),
      createdAt: serializer.fromJson<int>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'group_id': serializer.toJson<String>(groupId),
      'display_name': serializer.toJson<String>(displayName),
      'name_key': serializer.toJson<String>(nameKey),
      'user_id': serializer.toJson<String?>(userId),
      'sort_order': serializer.toJson<int>(sortOrder),
      'role': serializer.toJson<String>(role),
      'status': serializer.toJson<String>(status),
      'joined_at': serializer.toJson<int?>(joinedAt),
      'left_at': serializer.toJson<int?>(leftAt),
      'created_at': serializer.toJson<int>(createdAt),
    };
  }

  MemberRow copyWith({
    String? id,
    String? groupId,
    String? displayName,
    String? nameKey,
    Value<String?> userId = const Value.absent(),
    int? sortOrder,
    String? role,
    String? status,
    Value<int?> joinedAt = const Value.absent(),
    Value<int?> leftAt = const Value.absent(),
    int? createdAt,
  }) => MemberRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    displayName: displayName ?? this.displayName,
    nameKey: nameKey ?? this.nameKey,
    userId: userId.present ? userId.value : this.userId,
    sortOrder: sortOrder ?? this.sortOrder,
    role: role ?? this.role,
    status: status ?? this.status,
    joinedAt: joinedAt.present ? joinedAt.value : this.joinedAt,
    leftAt: leftAt.present ? leftAt.value : this.leftAt,
    createdAt: createdAt ?? this.createdAt,
  );
  MemberRow copyWithCompanion(MembersCompanion data) {
    return MemberRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      nameKey: data.nameKey.present ? data.nameKey.value : this.nameKey,
      userId: data.userId.present ? data.userId.value : this.userId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      role: data.role.present ? data.role.value : this.role,
      status: data.status.present ? data.status.value : this.status,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      leftAt: data.leftAt.present ? data.leftAt.value : this.leftAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('displayName: $displayName, ')
          ..write('nameKey: $nameKey, ')
          ..write('userId: $userId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('role: $role, ')
          ..write('status: $status, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('leftAt: $leftAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    displayName,
    nameKey,
    userId,
    sortOrder,
    role,
    status,
    joinedAt,
    leftAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.displayName == this.displayName &&
          other.nameKey == this.nameKey &&
          other.userId == this.userId &&
          other.sortOrder == this.sortOrder &&
          other.role == this.role &&
          other.status == this.status &&
          other.joinedAt == this.joinedAt &&
          other.leftAt == this.leftAt &&
          other.createdAt == this.createdAt);
}

class MembersCompanion extends UpdateCompanion<MemberRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> displayName;
  final Value<String> nameKey;
  final Value<String?> userId;
  final Value<int> sortOrder;
  final Value<String> role;
  final Value<String> status;
  final Value<int?> joinedAt;
  final Value<int?> leftAt;
  final Value<int> createdAt;
  final Value<int> rowid;
  const MembersCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.nameKey = const Value.absent(),
    this.userId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.role = const Value.absent(),
    this.status = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.leftAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String id,
    required String groupId,
    required String displayName,
    required String nameKey,
    this.userId = const Value.absent(),
    required int sortOrder,
    this.role = const Value.absent(),
    this.status = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.leftAt = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       displayName = Value(displayName),
       nameKey = Value(nameKey),
       sortOrder = Value(sortOrder),
       createdAt = Value(createdAt);
  static Insertable<MemberRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? displayName,
    Expression<String>? nameKey,
    Expression<String>? userId,
    Expression<int>? sortOrder,
    Expression<String>? role,
    Expression<String>? status,
    Expression<int>? joinedAt,
    Expression<int>? leftAt,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (displayName != null) 'display_name': displayName,
      if (nameKey != null) 'name_key': nameKey,
      if (userId != null) 'user_id': userId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (role != null) 'role': role,
      if (status != null) 'status': status,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (leftAt != null) 'left_at': leftAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? displayName,
    Value<String>? nameKey,
    Value<String?>? userId,
    Value<int>? sortOrder,
    Value<String>? role,
    Value<String>? status,
    Value<int?>? joinedAt,
    Value<int?>? leftAt,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return MembersCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      displayName: displayName ?? this.displayName,
      nameKey: nameKey ?? this.nameKey,
      userId: userId ?? this.userId,
      sortOrder: sortOrder ?? this.sortOrder,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (nameKey.present) {
      map['name_key'] = Variable<String>(nameKey.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<int>(joinedAt.value);
    }
    if (leftAt.present) {
      map['left_at'] = Variable<int>(leftAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('displayName: $displayName, ')
          ..write('nameKey: $nameKey, ')
          ..write('userId: $userId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('role: $role, ')
          ..write('status: $status, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('leftAt: $leftAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ExpenseGroups extends Table with TableInfo<ExpenseGroups, GroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ExpenseGroups(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 36)',
  );
  static const VerificationMeta _ownerUserIdMeta = const VerificationMeta(
    'ownerUserId',
  );
  late final GeneratedColumn<String> ownerUserId = GeneratedColumn<String>(
    'owner_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES local_profile(id)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 60)',
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (type IN (\'TRIP\', \'HOUSING\', \'OUTING\', \'OTHER\'))',
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'EGP\' CHECK (length(currency_code) = 3 AND currency_code NOT GLOB \'*[^A-Z]*\')',
    defaultValue: const CustomExpression('\'EGP\''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (version >= 1)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _memberSeqMeta = const VerificationMeta(
    'memberSeq',
  );
  late final GeneratedColumn<int> memberSeq = GeneratedColumn<int>(
    'member_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (member_seq >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _treasurerMemberIdMeta = const VerificationMeta(
    'treasurerMemberId',
  );
  late final GeneratedColumn<String> treasurerMemberId =
      GeneratedColumn<String>(
        'treasurer_member_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES members(id)',
      );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  late final GeneratedColumn<int> archivedAt = GeneratedColumn<int>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerUserId,
    name,
    type,
    currencyCode,
    createdAt,
    updatedAt,
    version,
    memberSeq,
    treasurerMemberId,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_user_id')) {
      context.handle(
        _ownerUserIdMeta,
        ownerUserId.isAcceptableOrUnknown(
          data['owner_user_id']!,
          _ownerUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerUserIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('member_seq')) {
      context.handle(
        _memberSeqMeta,
        memberSeq.isAcceptableOrUnknown(data['member_seq']!, _memberSeqMeta),
      );
    }
    if (data.containsKey('treasurer_member_id')) {
      context.handle(
        _treasurerMemberIdMeta,
        treasurerMemberId.isAcceptableOrUnknown(
          data['treasurer_member_id']!,
          _treasurerMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      memberSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_seq'],
      )!,
      treasurerMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}treasurer_member_id'],
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  ExpenseGroups createAlias(String alias) {
    return ExpenseGroups(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class GroupRow extends DataClass implements Insertable<GroupRow> {
  final String id;
  final String ownerUserId;
  final String name;
  final String type;
  final String currencyCode;
  final int createdAt;
  final int updatedAt;
  final int version;
  final int memberSeq;

  /// Schema 5 (SA10, Java V20): the pool treasurer, a member of this group. SQLite cannot add V20's composite FK
  /// with ADD COLUMN, so "same group" is the pair of triggers below the members table; ACTIVE is the service's.
  final String? treasurerMemberId;

  /// Schema 11 (A184): set when the group is archived (UTC epoch ms); NULL = active. An archived group is hidden
  /// from the groups list and is deleted for good after `local_meta.archive_retention_days`.
  final int? archivedAt;
  const GroupRow({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.type,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.memberSeq,
    this.treasurerMemberId,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_user_id'] = Variable<String>(ownerUserId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['currency_code'] = Variable<String>(currencyCode);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['version'] = Variable<int>(version);
    map['member_seq'] = Variable<int>(memberSeq);
    if (!nullToAbsent || treasurerMemberId != null) {
      map['treasurer_member_id'] = Variable<String>(treasurerMemberId);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<int>(archivedAt);
    }
    return map;
  }

  ExpenseGroupsCompanion toCompanion(bool nullToAbsent) {
    return ExpenseGroupsCompanion(
      id: Value(id),
      ownerUserId: Value(ownerUserId),
      name: Value(name),
      type: Value(type),
      currencyCode: Value(currencyCode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
      memberSeq: Value(memberSeq),
      treasurerMemberId: treasurerMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(treasurerMemberId),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory GroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupRow(
      id: serializer.fromJson<String>(json['id']),
      ownerUserId: serializer.fromJson<String>(json['owner_user_id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      currencyCode: serializer.fromJson<String>(json['currency_code']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
      version: serializer.fromJson<int>(json['version']),
      memberSeq: serializer.fromJson<int>(json['member_seq']),
      treasurerMemberId: serializer.fromJson<String?>(
        json['treasurer_member_id'],
      ),
      archivedAt: serializer.fromJson<int?>(json['archived_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'owner_user_id': serializer.toJson<String>(ownerUserId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'currency_code': serializer.toJson<String>(currencyCode),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
      'version': serializer.toJson<int>(version),
      'member_seq': serializer.toJson<int>(memberSeq),
      'treasurer_member_id': serializer.toJson<String?>(treasurerMemberId),
      'archived_at': serializer.toJson<int?>(archivedAt),
    };
  }

  GroupRow copyWith({
    String? id,
    String? ownerUserId,
    String? name,
    String? type,
    String? currencyCode,
    int? createdAt,
    int? updatedAt,
    int? version,
    int? memberSeq,
    Value<String?> treasurerMemberId = const Value.absent(),
    Value<int?> archivedAt = const Value.absent(),
  }) => GroupRow(
    id: id ?? this.id,
    ownerUserId: ownerUserId ?? this.ownerUserId,
    name: name ?? this.name,
    type: type ?? this.type,
    currencyCode: currencyCode ?? this.currencyCode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    memberSeq: memberSeq ?? this.memberSeq,
    treasurerMemberId: treasurerMemberId.present
        ? treasurerMemberId.value
        : this.treasurerMemberId,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  GroupRow copyWithCompanion(ExpenseGroupsCompanion data) {
    return GroupRow(
      id: data.id.present ? data.id.value : this.id,
      ownerUserId: data.ownerUserId.present
          ? data.ownerUserId.value
          : this.ownerUserId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      memberSeq: data.memberSeq.present ? data.memberSeq.value : this.memberSeq,
      treasurerMemberId: data.treasurerMemberId.present
          ? data.treasurerMemberId.value
          : this.treasurerMemberId,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupRow(')
          ..write('id: $id, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('memberSeq: $memberSeq, ')
          ..write('treasurerMemberId: $treasurerMemberId, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerUserId,
    name,
    type,
    currencyCode,
    createdAt,
    updatedAt,
    version,
    memberSeq,
    treasurerMemberId,
    archivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupRow &&
          other.id == this.id &&
          other.ownerUserId == this.ownerUserId &&
          other.name == this.name &&
          other.type == this.type &&
          other.currencyCode == this.currencyCode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.memberSeq == this.memberSeq &&
          other.treasurerMemberId == this.treasurerMemberId &&
          other.archivedAt == this.archivedAt);
}

class ExpenseGroupsCompanion extends UpdateCompanion<GroupRow> {
  final Value<String> id;
  final Value<String> ownerUserId;
  final Value<String> name;
  final Value<String> type;
  final Value<String> currencyCode;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> version;
  final Value<int> memberSeq;
  final Value<String?> treasurerMemberId;
  final Value<int?> archivedAt;
  final Value<int> rowid;
  const ExpenseGroupsCompanion({
    this.id = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.memberSeq = const Value.absent(),
    this.treasurerMemberId = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpenseGroupsCompanion.insert({
    required String id,
    required String ownerUserId,
    required String name,
    required String type,
    this.currencyCode = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.version = const Value.absent(),
    this.memberSeq = const Value.absent(),
    this.treasurerMemberId = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerUserId = Value(ownerUserId),
       name = Value(name),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<GroupRow> custom({
    Expression<String>? id,
    Expression<String>? ownerUserId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? currencyCode,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? version,
    Expression<int>? memberSeq,
    Expression<String>? treasurerMemberId,
    Expression<int>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerUserId != null) 'owner_user_id': ownerUserId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (memberSeq != null) 'member_seq': memberSeq,
      if (treasurerMemberId != null) 'treasurer_member_id': treasurerMemberId,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpenseGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerUserId,
    Value<String>? name,
    Value<String>? type,
    Value<String>? currencyCode,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? version,
    Value<int>? memberSeq,
    Value<String?>? treasurerMemberId,
    Value<int?>? archivedAt,
    Value<int>? rowid,
  }) {
    return ExpenseGroupsCompanion(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      name: name ?? this.name,
      type: type ?? this.type,
      currencyCode: currencyCode ?? this.currencyCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      memberSeq: memberSeq ?? this.memberSeq,
      treasurerMemberId: treasurerMemberId ?? this.treasurerMemberId,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerUserId.present) {
      map['owner_user_id'] = Variable<String>(ownerUserId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (memberSeq.present) {
      map['member_seq'] = Variable<int>(memberSeq.value);
    }
    if (treasurerMemberId.present) {
      map['treasurer_member_id'] = Variable<String>(treasurerMemberId.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<int>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseGroupsCompanion(')
          ..write('id: $id, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('memberSeq: $memberSeq, ')
          ..write('treasurerMemberId: $treasurerMemberId, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Expenses extends Table with TableInfo<Expenses, ExpenseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Expenses(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 36)',
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES expense_groups(id)',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 100)',
  );
  static const VerificationMeta _splitTypeMeta = const VerificationMeta(
    'splitType',
  );
  late final GeneratedColumn<String> splitType = GeneratedColumn<String>(
    'split_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (split_type IN (\'EQUAL\', \'EXACT\', \'ITEMIZED\'))',
  );
  static const VerificationMeta _totalMinorMeta = const VerificationMeta(
    'totalMinor',
  );
  late final GeneratedColumn<int> totalMinor = GeneratedColumn<int>(
    'total_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (total_minor BETWEEN 1 AND 1000000000000)',
  );
  static const VerificationMeta _expenseDateMeta = const VerificationMeta(
    'expenseDate',
  );
  late final GeneratedColumn<String> expenseDate = GeneratedColumn<String>(
    'expense_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (date(expense_date) IS expense_date)',
  );
  static const VerificationMeta _subtotalMinorMeta = const VerificationMeta(
    'subtotalMinor',
  );
  late final GeneratedColumn<int> subtotalMinor = GeneratedColumn<int>(
    'subtotal_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _serviceBpsMeta = const VerificationMeta(
    'serviceBps',
  );
  late final GeneratedColumn<int> serviceBps = GeneratedColumn<int>(
    'service_bps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (service_bps IS NULL OR service_bps BETWEEN 0 AND 10000)',
  );
  static const VerificationMeta _serviceMinorMeta = const VerificationMeta(
    'serviceMinor',
  );
  late final GeneratedColumn<int> serviceMinor = GeneratedColumn<int>(
    'service_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _taxBpsMeta = const VerificationMeta('taxBps');
  late final GeneratedColumn<int> taxBps = GeneratedColumn<int>(
    'tax_bps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (tax_bps IS NULL OR tax_bps BETWEEN 0 AND 10000)',
  );
  static const VerificationMeta _taxMinorMeta = const VerificationMeta(
    'taxMinor',
  );
  late final GeneratedColumn<int> taxMinor = GeneratedColumn<int>(
    'tax_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _taxBaseMeta = const VerificationMeta(
    'taxBase',
  );
  late final GeneratedColumn<String> taxBase = GeneratedColumn<String>(
    'tax_base',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (tax_base IS NULL OR tax_base IN (\'SUBTOTAL\', \'SUBTOTAL_PLUS_SERVICE\'))',
  );
  static const VerificationMeta _adjustmentMinorMeta = const VerificationMeta(
    'adjustmentMinor',
  );
  late final GeneratedColumn<int> adjustmentMinor = GeneratedColumn<int>(
    'adjustment_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdByUserIdMeta = const VerificationMeta(
    'createdByUserId',
  );
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
    'created_by_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES local_profile(id)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (version >= 1)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'OTHER\' CHECK (category IN (\'FOOD\', \'TRANSPORT\', \'FUEL\', \'ACCOMMODATION\', \'GROCERIES\', \'SHOPPING\', \'ENTERTAINMENT\', \'BILLS\', \'OTHER\'))',
    defaultValue: const CustomExpression('\'OTHER\''),
  );
  static const VerificationMeta _paidFromPoolMeta = const VerificationMeta(
    'paidFromPool',
  );
  late final GeneratedColumn<int> paidFromPool = GeneratedColumn<int>(
    'paid_from_pool',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (paid_from_pool IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _discountBpsMeta = const VerificationMeta(
    'discountBps',
  );
  late final GeneratedColumn<int> discountBps = GeneratedColumn<int>(
    'discount_bps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (discount_bps IS NULL OR discount_bps BETWEEN 1 AND 9999)',
  );
  static const VerificationMeta _discountAmountMinorMeta =
      const VerificationMeta('discountAmountMinor');
  late final GeneratedColumn<int> discountAmountMinor = GeneratedColumn<int>(
    'discount_amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (discount_amount_minor IS NULL OR discount_amount_minor BETWEEN 1 AND 1000000000000)',
  );
  static const VerificationMeta _discountMinorMeta = const VerificationMeta(
    'discountMinor',
  );
  late final GeneratedColumn<int> discountMinor = GeneratedColumn<int>(
    'discount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _serviceAmountMinorMeta =
      const VerificationMeta('serviceAmountMinor');
  late final GeneratedColumn<int> serviceAmountMinor = GeneratedColumn<int>(
    'service_amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (service_amount_minor IS NULL OR service_amount_minor BETWEEN 1 AND 1000000000000)',
  );
  static const VerificationMeta _taxAmountMinorMeta = const VerificationMeta(
    'taxAmountMinor',
  );
  late final GeneratedColumn<int> taxAmountMinor = GeneratedColumn<int>(
    'tax_amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (tax_amount_minor IS NULL OR tax_amount_minor BETWEEN 1 AND 1000000000000)',
  );
  static const VerificationMeta _deliveryMinorMeta = const VerificationMeta(
    'deliveryMinor',
  );
  late final GeneratedColumn<int> deliveryMinor = GeneratedColumn<int>(
    'delivery_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (delivery_minor IS NULL OR delivery_minor BETWEEN 0 AND 1000000000000)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    title,
    splitType,
    totalMinor,
    expenseDate,
    subtotalMinor,
    serviceBps,
    serviceMinor,
    taxBps,
    taxMinor,
    taxBase,
    adjustmentMinor,
    createdByUserId,
    createdAt,
    updatedAt,
    deletedAt,
    version,
    category,
    paidFromPool,
    discountBps,
    discountAmountMinor,
    discountMinor,
    serviceAmountMinor,
    taxAmountMinor,
    deliveryMinor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('split_type')) {
      context.handle(
        _splitTypeMeta,
        splitType.isAcceptableOrUnknown(data['split_type']!, _splitTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_splitTypeMeta);
    }
    if (data.containsKey('total_minor')) {
      context.handle(
        _totalMinorMeta,
        totalMinor.isAcceptableOrUnknown(data['total_minor']!, _totalMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMinorMeta);
    }
    if (data.containsKey('expense_date')) {
      context.handle(
        _expenseDateMeta,
        expenseDate.isAcceptableOrUnknown(
          data['expense_date']!,
          _expenseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expenseDateMeta);
    }
    if (data.containsKey('subtotal_minor')) {
      context.handle(
        _subtotalMinorMeta,
        subtotalMinor.isAcceptableOrUnknown(
          data['subtotal_minor']!,
          _subtotalMinorMeta,
        ),
      );
    }
    if (data.containsKey('service_bps')) {
      context.handle(
        _serviceBpsMeta,
        serviceBps.isAcceptableOrUnknown(data['service_bps']!, _serviceBpsMeta),
      );
    }
    if (data.containsKey('service_minor')) {
      context.handle(
        _serviceMinorMeta,
        serviceMinor.isAcceptableOrUnknown(
          data['service_minor']!,
          _serviceMinorMeta,
        ),
      );
    }
    if (data.containsKey('tax_bps')) {
      context.handle(
        _taxBpsMeta,
        taxBps.isAcceptableOrUnknown(data['tax_bps']!, _taxBpsMeta),
      );
    }
    if (data.containsKey('tax_minor')) {
      context.handle(
        _taxMinorMeta,
        taxMinor.isAcceptableOrUnknown(data['tax_minor']!, _taxMinorMeta),
      );
    }
    if (data.containsKey('tax_base')) {
      context.handle(
        _taxBaseMeta,
        taxBase.isAcceptableOrUnknown(data['tax_base']!, _taxBaseMeta),
      );
    }
    if (data.containsKey('adjustment_minor')) {
      context.handle(
        _adjustmentMinorMeta,
        adjustmentMinor.isAcceptableOrUnknown(
          data['adjustment_minor']!,
          _adjustmentMinorMeta,
        ),
      );
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
        _createdByUserIdMeta,
        createdByUserId.isAcceptableOrUnknown(
          data['created_by_user_id']!,
          _createdByUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdByUserIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('paid_from_pool')) {
      context.handle(
        _paidFromPoolMeta,
        paidFromPool.isAcceptableOrUnknown(
          data['paid_from_pool']!,
          _paidFromPoolMeta,
        ),
      );
    }
    if (data.containsKey('discount_bps')) {
      context.handle(
        _discountBpsMeta,
        discountBps.isAcceptableOrUnknown(
          data['discount_bps']!,
          _discountBpsMeta,
        ),
      );
    }
    if (data.containsKey('discount_amount_minor')) {
      context.handle(
        _discountAmountMinorMeta,
        discountAmountMinor.isAcceptableOrUnknown(
          data['discount_amount_minor']!,
          _discountAmountMinorMeta,
        ),
      );
    }
    if (data.containsKey('discount_minor')) {
      context.handle(
        _discountMinorMeta,
        discountMinor.isAcceptableOrUnknown(
          data['discount_minor']!,
          _discountMinorMeta,
        ),
      );
    }
    if (data.containsKey('service_amount_minor')) {
      context.handle(
        _serviceAmountMinorMeta,
        serviceAmountMinor.isAcceptableOrUnknown(
          data['service_amount_minor']!,
          _serviceAmountMinorMeta,
        ),
      );
    }
    if (data.containsKey('tax_amount_minor')) {
      context.handle(
        _taxAmountMinorMeta,
        taxAmountMinor.isAcceptableOrUnknown(
          data['tax_amount_minor']!,
          _taxAmountMinorMeta,
        ),
      );
    }
    if (data.containsKey('delivery_minor')) {
      context.handle(
        _deliveryMinorMeta,
        deliveryMinor.isAcceptableOrUnknown(
          data['delivery_minor']!,
          _deliveryMinorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      splitType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}split_type'],
      )!,
      totalMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_minor'],
      )!,
      expenseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_date'],
      )!,
      subtotalMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal_minor'],
      ),
      serviceBps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}service_bps'],
      ),
      serviceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}service_minor'],
      ),
      taxBps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_bps'],
      ),
      taxMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_minor'],
      ),
      taxBase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_base'],
      ),
      adjustmentMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}adjustment_minor'],
      ),
      createdByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_user_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      paidFromPool: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_from_pool'],
      )!,
      discountBps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_bps'],
      ),
      discountAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_amount_minor'],
      ),
      discountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_minor'],
      ),
      serviceAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}service_amount_minor'],
      ),
      taxAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_amount_minor'],
      ),
      deliveryMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delivery_minor'],
      ),
    );
  }

  @override
  Expenses createAlias(String alias) {
    return Expenses(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const [
    'CONSTRAINT ck_expenses_charge_one_form CHECK(NOT(discount_bps IS NOT NULL AND discount_amount_minor IS NOT NULL)AND NOT(service_bps IS NOT NULL AND service_amount_minor IS NOT NULL)AND NOT(tax_bps IS NOT NULL AND tax_amount_minor IS NOT NULL))',
    'CONSTRAINT ck_expenses_itemized_columns CHECK(split_type = \'ITEMIZED\' OR(subtotal_minor IS NULL AND service_bps IS NULL AND service_minor IS NULL AND tax_bps IS NULL AND tax_minor IS NULL AND tax_base IS NULL AND adjustment_minor IS NULL AND discount_bps IS NULL AND discount_amount_minor IS NULL AND discount_minor IS NULL AND service_amount_minor IS NULL AND tax_amount_minor IS NULL AND delivery_minor IS NULL))',
    'CONSTRAINT ck_expenses_itemized_charges CHECK(split_type <> \'ITEMIZED\' OR(subtotal_minor IS NOT NULL AND subtotal_minor > 0 AND discount_minor IS NOT NULL AND discount_minor >= 0 AND discount_minor < subtotal_minor AND service_minor IS NOT NULL AND service_minor >= 0 AND tax_minor IS NOT NULL AND tax_minor >= 0 AND delivery_minor IS NOT NULL AND delivery_minor >= 0 AND adjustment_minor IS NOT NULL AND total_minor = subtotal_minor - discount_minor + service_minor + tax_minor + delivery_minor + adjustment_minor AND((discount_bps IS NOT NULL OR discount_amount_minor IS NOT NULL)=(discount_minor > 0))AND(discount_amount_minor IS NULL OR discount_minor = discount_amount_minor)AND(service_bps IS NOT NULL OR service_amount_minor IS NOT NULL OR service_minor = 0)AND(service_amount_minor IS NULL OR service_minor = service_amount_minor)AND(tax_bps IS NOT NULL OR tax_amount_minor IS NOT NULL OR tax_minor = 0)AND(tax_amount_minor IS NULL OR tax_minor = tax_amount_minor)AND((tax_bps IS NULL AND tax_amount_minor IS NULL)=(tax_base IS NULL))))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ExpenseRow extends DataClass implements Insertable<ExpenseRow> {
  final String id;
  final String groupId;
  final String title;
  final String splitType;
  final int totalMinor;
  final String expenseDate;
  final int? subtotalMinor;
  final int? serviceBps;
  final int? serviceMinor;
  final int? taxBps;
  final int? taxMinor;
  final String? taxBase;
  final int? adjustmentMinor;
  final String createdByUserId;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final int version;
  final String category;

  /// Schema 5 (SA10, Java V20): a pool expense (its single payer is the treasurer: checked by the service).
  final int paidFromPool;

  /// Schema 8 (SA15, Java V21, A171-A177): one bill discount (percent or amount) and service/tax as amounts.
  /// *_bps / *_amount_minor are the request (which form); discount_minor is the computed total like service_minor.
  final int? discountBps;
  final int? discountAmountMinor;
  final int? discountMinor;
  final int? serviceAmountMinor;
  final int? taxAmountMinor;

  /// Schema 9 (Java V22, A180): the delivery amount (request and computed total are the same number). NULL on
  /// EQUAL/EXACT, 0 or more on ITEMIZED.
  final int? deliveryMinor;
  const ExpenseRow({
    required this.id,
    required this.groupId,
    required this.title,
    required this.splitType,
    required this.totalMinor,
    required this.expenseDate,
    this.subtotalMinor,
    this.serviceBps,
    this.serviceMinor,
    this.taxBps,
    this.taxMinor,
    this.taxBase,
    this.adjustmentMinor,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.version,
    required this.category,
    required this.paidFromPool,
    this.discountBps,
    this.discountAmountMinor,
    this.discountMinor,
    this.serviceAmountMinor,
    this.taxAmountMinor,
    this.deliveryMinor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['title'] = Variable<String>(title);
    map['split_type'] = Variable<String>(splitType);
    map['total_minor'] = Variable<int>(totalMinor);
    map['expense_date'] = Variable<String>(expenseDate);
    if (!nullToAbsent || subtotalMinor != null) {
      map['subtotal_minor'] = Variable<int>(subtotalMinor);
    }
    if (!nullToAbsent || serviceBps != null) {
      map['service_bps'] = Variable<int>(serviceBps);
    }
    if (!nullToAbsent || serviceMinor != null) {
      map['service_minor'] = Variable<int>(serviceMinor);
    }
    if (!nullToAbsent || taxBps != null) {
      map['tax_bps'] = Variable<int>(taxBps);
    }
    if (!nullToAbsent || taxMinor != null) {
      map['tax_minor'] = Variable<int>(taxMinor);
    }
    if (!nullToAbsent || taxBase != null) {
      map['tax_base'] = Variable<String>(taxBase);
    }
    if (!nullToAbsent || adjustmentMinor != null) {
      map['adjustment_minor'] = Variable<int>(adjustmentMinor);
    }
    map['created_by_user_id'] = Variable<String>(createdByUserId);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['version'] = Variable<int>(version);
    map['category'] = Variable<String>(category);
    map['paid_from_pool'] = Variable<int>(paidFromPool);
    if (!nullToAbsent || discountBps != null) {
      map['discount_bps'] = Variable<int>(discountBps);
    }
    if (!nullToAbsent || discountAmountMinor != null) {
      map['discount_amount_minor'] = Variable<int>(discountAmountMinor);
    }
    if (!nullToAbsent || discountMinor != null) {
      map['discount_minor'] = Variable<int>(discountMinor);
    }
    if (!nullToAbsent || serviceAmountMinor != null) {
      map['service_amount_minor'] = Variable<int>(serviceAmountMinor);
    }
    if (!nullToAbsent || taxAmountMinor != null) {
      map['tax_amount_minor'] = Variable<int>(taxAmountMinor);
    }
    if (!nullToAbsent || deliveryMinor != null) {
      map['delivery_minor'] = Variable<int>(deliveryMinor);
    }
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      title: Value(title),
      splitType: Value(splitType),
      totalMinor: Value(totalMinor),
      expenseDate: Value(expenseDate),
      subtotalMinor: subtotalMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(subtotalMinor),
      serviceBps: serviceBps == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceBps),
      serviceMinor: serviceMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceMinor),
      taxBps: taxBps == null && nullToAbsent
          ? const Value.absent()
          : Value(taxBps),
      taxMinor: taxMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(taxMinor),
      taxBase: taxBase == null && nullToAbsent
          ? const Value.absent()
          : Value(taxBase),
      adjustmentMinor: adjustmentMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(adjustmentMinor),
      createdByUserId: Value(createdByUserId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      version: Value(version),
      category: Value(category),
      paidFromPool: Value(paidFromPool),
      discountBps: discountBps == null && nullToAbsent
          ? const Value.absent()
          : Value(discountBps),
      discountAmountMinor: discountAmountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(discountAmountMinor),
      discountMinor: discountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(discountMinor),
      serviceAmountMinor: serviceAmountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceAmountMinor),
      taxAmountMinor: taxAmountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(taxAmountMinor),
      deliveryMinor: deliveryMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryMinor),
    );
  }

  factory ExpenseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['group_id']),
      title: serializer.fromJson<String>(json['title']),
      splitType: serializer.fromJson<String>(json['split_type']),
      totalMinor: serializer.fromJson<int>(json['total_minor']),
      expenseDate: serializer.fromJson<String>(json['expense_date']),
      subtotalMinor: serializer.fromJson<int?>(json['subtotal_minor']),
      serviceBps: serializer.fromJson<int?>(json['service_bps']),
      serviceMinor: serializer.fromJson<int?>(json['service_minor']),
      taxBps: serializer.fromJson<int?>(json['tax_bps']),
      taxMinor: serializer.fromJson<int?>(json['tax_minor']),
      taxBase: serializer.fromJson<String?>(json['tax_base']),
      adjustmentMinor: serializer.fromJson<int?>(json['adjustment_minor']),
      createdByUserId: serializer.fromJson<String>(json['created_by_user_id']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
      version: serializer.fromJson<int>(json['version']),
      category: serializer.fromJson<String>(json['category']),
      paidFromPool: serializer.fromJson<int>(json['paid_from_pool']),
      discountBps: serializer.fromJson<int?>(json['discount_bps']),
      discountAmountMinor: serializer.fromJson<int?>(
        json['discount_amount_minor'],
      ),
      discountMinor: serializer.fromJson<int?>(json['discount_minor']),
      serviceAmountMinor: serializer.fromJson<int?>(
        json['service_amount_minor'],
      ),
      taxAmountMinor: serializer.fromJson<int?>(json['tax_amount_minor']),
      deliveryMinor: serializer.fromJson<int?>(json['delivery_minor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'group_id': serializer.toJson<String>(groupId),
      'title': serializer.toJson<String>(title),
      'split_type': serializer.toJson<String>(splitType),
      'total_minor': serializer.toJson<int>(totalMinor),
      'expense_date': serializer.toJson<String>(expenseDate),
      'subtotal_minor': serializer.toJson<int?>(subtotalMinor),
      'service_bps': serializer.toJson<int?>(serviceBps),
      'service_minor': serializer.toJson<int?>(serviceMinor),
      'tax_bps': serializer.toJson<int?>(taxBps),
      'tax_minor': serializer.toJson<int?>(taxMinor),
      'tax_base': serializer.toJson<String?>(taxBase),
      'adjustment_minor': serializer.toJson<int?>(adjustmentMinor),
      'created_by_user_id': serializer.toJson<String>(createdByUserId),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
      'version': serializer.toJson<int>(version),
      'category': serializer.toJson<String>(category),
      'paid_from_pool': serializer.toJson<int>(paidFromPool),
      'discount_bps': serializer.toJson<int?>(discountBps),
      'discount_amount_minor': serializer.toJson<int?>(discountAmountMinor),
      'discount_minor': serializer.toJson<int?>(discountMinor),
      'service_amount_minor': serializer.toJson<int?>(serviceAmountMinor),
      'tax_amount_minor': serializer.toJson<int?>(taxAmountMinor),
      'delivery_minor': serializer.toJson<int?>(deliveryMinor),
    };
  }

  ExpenseRow copyWith({
    String? id,
    String? groupId,
    String? title,
    String? splitType,
    int? totalMinor,
    String? expenseDate,
    Value<int?> subtotalMinor = const Value.absent(),
    Value<int?> serviceBps = const Value.absent(),
    Value<int?> serviceMinor = const Value.absent(),
    Value<int?> taxBps = const Value.absent(),
    Value<int?> taxMinor = const Value.absent(),
    Value<String?> taxBase = const Value.absent(),
    Value<int?> adjustmentMinor = const Value.absent(),
    String? createdByUserId,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    int? version,
    String? category,
    int? paidFromPool,
    Value<int?> discountBps = const Value.absent(),
    Value<int?> discountAmountMinor = const Value.absent(),
    Value<int?> discountMinor = const Value.absent(),
    Value<int?> serviceAmountMinor = const Value.absent(),
    Value<int?> taxAmountMinor = const Value.absent(),
    Value<int?> deliveryMinor = const Value.absent(),
  }) => ExpenseRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    title: title ?? this.title,
    splitType: splitType ?? this.splitType,
    totalMinor: totalMinor ?? this.totalMinor,
    expenseDate: expenseDate ?? this.expenseDate,
    subtotalMinor: subtotalMinor.present
        ? subtotalMinor.value
        : this.subtotalMinor,
    serviceBps: serviceBps.present ? serviceBps.value : this.serviceBps,
    serviceMinor: serviceMinor.present ? serviceMinor.value : this.serviceMinor,
    taxBps: taxBps.present ? taxBps.value : this.taxBps,
    taxMinor: taxMinor.present ? taxMinor.value : this.taxMinor,
    taxBase: taxBase.present ? taxBase.value : this.taxBase,
    adjustmentMinor: adjustmentMinor.present
        ? adjustmentMinor.value
        : this.adjustmentMinor,
    createdByUserId: createdByUserId ?? this.createdByUserId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    version: version ?? this.version,
    category: category ?? this.category,
    paidFromPool: paidFromPool ?? this.paidFromPool,
    discountBps: discountBps.present ? discountBps.value : this.discountBps,
    discountAmountMinor: discountAmountMinor.present
        ? discountAmountMinor.value
        : this.discountAmountMinor,
    discountMinor: discountMinor.present
        ? discountMinor.value
        : this.discountMinor,
    serviceAmountMinor: serviceAmountMinor.present
        ? serviceAmountMinor.value
        : this.serviceAmountMinor,
    taxAmountMinor: taxAmountMinor.present
        ? taxAmountMinor.value
        : this.taxAmountMinor,
    deliveryMinor: deliveryMinor.present
        ? deliveryMinor.value
        : this.deliveryMinor,
  );
  ExpenseRow copyWithCompanion(ExpensesCompanion data) {
    return ExpenseRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      title: data.title.present ? data.title.value : this.title,
      splitType: data.splitType.present ? data.splitType.value : this.splitType,
      totalMinor: data.totalMinor.present
          ? data.totalMinor.value
          : this.totalMinor,
      expenseDate: data.expenseDate.present
          ? data.expenseDate.value
          : this.expenseDate,
      subtotalMinor: data.subtotalMinor.present
          ? data.subtotalMinor.value
          : this.subtotalMinor,
      serviceBps: data.serviceBps.present
          ? data.serviceBps.value
          : this.serviceBps,
      serviceMinor: data.serviceMinor.present
          ? data.serviceMinor.value
          : this.serviceMinor,
      taxBps: data.taxBps.present ? data.taxBps.value : this.taxBps,
      taxMinor: data.taxMinor.present ? data.taxMinor.value : this.taxMinor,
      taxBase: data.taxBase.present ? data.taxBase.value : this.taxBase,
      adjustmentMinor: data.adjustmentMinor.present
          ? data.adjustmentMinor.value
          : this.adjustmentMinor,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      version: data.version.present ? data.version.value : this.version,
      category: data.category.present ? data.category.value : this.category,
      paidFromPool: data.paidFromPool.present
          ? data.paidFromPool.value
          : this.paidFromPool,
      discountBps: data.discountBps.present
          ? data.discountBps.value
          : this.discountBps,
      discountAmountMinor: data.discountAmountMinor.present
          ? data.discountAmountMinor.value
          : this.discountAmountMinor,
      discountMinor: data.discountMinor.present
          ? data.discountMinor.value
          : this.discountMinor,
      serviceAmountMinor: data.serviceAmountMinor.present
          ? data.serviceAmountMinor.value
          : this.serviceAmountMinor,
      taxAmountMinor: data.taxAmountMinor.present
          ? data.taxAmountMinor.value
          : this.taxAmountMinor,
      deliveryMinor: data.deliveryMinor.present
          ? data.deliveryMinor.value
          : this.deliveryMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('title: $title, ')
          ..write('splitType: $splitType, ')
          ..write('totalMinor: $totalMinor, ')
          ..write('expenseDate: $expenseDate, ')
          ..write('subtotalMinor: $subtotalMinor, ')
          ..write('serviceBps: $serviceBps, ')
          ..write('serviceMinor: $serviceMinor, ')
          ..write('taxBps: $taxBps, ')
          ..write('taxMinor: $taxMinor, ')
          ..write('taxBase: $taxBase, ')
          ..write('adjustmentMinor: $adjustmentMinor, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('version: $version, ')
          ..write('category: $category, ')
          ..write('paidFromPool: $paidFromPool, ')
          ..write('discountBps: $discountBps, ')
          ..write('discountAmountMinor: $discountAmountMinor, ')
          ..write('discountMinor: $discountMinor, ')
          ..write('serviceAmountMinor: $serviceAmountMinor, ')
          ..write('taxAmountMinor: $taxAmountMinor, ')
          ..write('deliveryMinor: $deliveryMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    groupId,
    title,
    splitType,
    totalMinor,
    expenseDate,
    subtotalMinor,
    serviceBps,
    serviceMinor,
    taxBps,
    taxMinor,
    taxBase,
    adjustmentMinor,
    createdByUserId,
    createdAt,
    updatedAt,
    deletedAt,
    version,
    category,
    paidFromPool,
    discountBps,
    discountAmountMinor,
    discountMinor,
    serviceAmountMinor,
    taxAmountMinor,
    deliveryMinor,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.title == this.title &&
          other.splitType == this.splitType &&
          other.totalMinor == this.totalMinor &&
          other.expenseDate == this.expenseDate &&
          other.subtotalMinor == this.subtotalMinor &&
          other.serviceBps == this.serviceBps &&
          other.serviceMinor == this.serviceMinor &&
          other.taxBps == this.taxBps &&
          other.taxMinor == this.taxMinor &&
          other.taxBase == this.taxBase &&
          other.adjustmentMinor == this.adjustmentMinor &&
          other.createdByUserId == this.createdByUserId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.version == this.version &&
          other.category == this.category &&
          other.paidFromPool == this.paidFromPool &&
          other.discountBps == this.discountBps &&
          other.discountAmountMinor == this.discountAmountMinor &&
          other.discountMinor == this.discountMinor &&
          other.serviceAmountMinor == this.serviceAmountMinor &&
          other.taxAmountMinor == this.taxAmountMinor &&
          other.deliveryMinor == this.deliveryMinor);
}

class ExpensesCompanion extends UpdateCompanion<ExpenseRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> title;
  final Value<String> splitType;
  final Value<int> totalMinor;
  final Value<String> expenseDate;
  final Value<int?> subtotalMinor;
  final Value<int?> serviceBps;
  final Value<int?> serviceMinor;
  final Value<int?> taxBps;
  final Value<int?> taxMinor;
  final Value<String?> taxBase;
  final Value<int?> adjustmentMinor;
  final Value<String> createdByUserId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> version;
  final Value<String> category;
  final Value<int> paidFromPool;
  final Value<int?> discountBps;
  final Value<int?> discountAmountMinor;
  final Value<int?> discountMinor;
  final Value<int?> serviceAmountMinor;
  final Value<int?> taxAmountMinor;
  final Value<int?> deliveryMinor;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.title = const Value.absent(),
    this.splitType = const Value.absent(),
    this.totalMinor = const Value.absent(),
    this.expenseDate = const Value.absent(),
    this.subtotalMinor = const Value.absent(),
    this.serviceBps = const Value.absent(),
    this.serviceMinor = const Value.absent(),
    this.taxBps = const Value.absent(),
    this.taxMinor = const Value.absent(),
    this.taxBase = const Value.absent(),
    this.adjustmentMinor = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.category = const Value.absent(),
    this.paidFromPool = const Value.absent(),
    this.discountBps = const Value.absent(),
    this.discountAmountMinor = const Value.absent(),
    this.discountMinor = const Value.absent(),
    this.serviceAmountMinor = const Value.absent(),
    this.taxAmountMinor = const Value.absent(),
    this.deliveryMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required String groupId,
    required String title,
    required String splitType,
    required int totalMinor,
    required String expenseDate,
    this.subtotalMinor = const Value.absent(),
    this.serviceBps = const Value.absent(),
    this.serviceMinor = const Value.absent(),
    this.taxBps = const Value.absent(),
    this.taxMinor = const Value.absent(),
    this.taxBase = const Value.absent(),
    this.adjustmentMinor = const Value.absent(),
    required String createdByUserId,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.category = const Value.absent(),
    this.paidFromPool = const Value.absent(),
    this.discountBps = const Value.absent(),
    this.discountAmountMinor = const Value.absent(),
    this.discountMinor = const Value.absent(),
    this.serviceAmountMinor = const Value.absent(),
    this.taxAmountMinor = const Value.absent(),
    this.deliveryMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       title = Value(title),
       splitType = Value(splitType),
       totalMinor = Value(totalMinor),
       expenseDate = Value(expenseDate),
       createdByUserId = Value(createdByUserId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ExpenseRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? title,
    Expression<String>? splitType,
    Expression<int>? totalMinor,
    Expression<String>? expenseDate,
    Expression<int>? subtotalMinor,
    Expression<int>? serviceBps,
    Expression<int>? serviceMinor,
    Expression<int>? taxBps,
    Expression<int>? taxMinor,
    Expression<String>? taxBase,
    Expression<int>? adjustmentMinor,
    Expression<String>? createdByUserId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? version,
    Expression<String>? category,
    Expression<int>? paidFromPool,
    Expression<int>? discountBps,
    Expression<int>? discountAmountMinor,
    Expression<int>? discountMinor,
    Expression<int>? serviceAmountMinor,
    Expression<int>? taxAmountMinor,
    Expression<int>? deliveryMinor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (title != null) 'title': title,
      if (splitType != null) 'split_type': splitType,
      if (totalMinor != null) 'total_minor': totalMinor,
      if (expenseDate != null) 'expense_date': expenseDate,
      if (subtotalMinor != null) 'subtotal_minor': subtotalMinor,
      if (serviceBps != null) 'service_bps': serviceBps,
      if (serviceMinor != null) 'service_minor': serviceMinor,
      if (taxBps != null) 'tax_bps': taxBps,
      if (taxMinor != null) 'tax_minor': taxMinor,
      if (taxBase != null) 'tax_base': taxBase,
      if (adjustmentMinor != null) 'adjustment_minor': adjustmentMinor,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (version != null) 'version': version,
      if (category != null) 'category': category,
      if (paidFromPool != null) 'paid_from_pool': paidFromPool,
      if (discountBps != null) 'discount_bps': discountBps,
      if (discountAmountMinor != null)
        'discount_amount_minor': discountAmountMinor,
      if (discountMinor != null) 'discount_minor': discountMinor,
      if (serviceAmountMinor != null)
        'service_amount_minor': serviceAmountMinor,
      if (taxAmountMinor != null) 'tax_amount_minor': taxAmountMinor,
      if (deliveryMinor != null) 'delivery_minor': deliveryMinor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? title,
    Value<String>? splitType,
    Value<int>? totalMinor,
    Value<String>? expenseDate,
    Value<int?>? subtotalMinor,
    Value<int?>? serviceBps,
    Value<int?>? serviceMinor,
    Value<int?>? taxBps,
    Value<int?>? taxMinor,
    Value<String?>? taxBase,
    Value<int?>? adjustmentMinor,
    Value<String>? createdByUserId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? version,
    Value<String>? category,
    Value<int>? paidFromPool,
    Value<int?>? discountBps,
    Value<int?>? discountAmountMinor,
    Value<int?>? discountMinor,
    Value<int?>? serviceAmountMinor,
    Value<int?>? taxAmountMinor,
    Value<int?>? deliveryMinor,
    Value<int>? rowid,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      splitType: splitType ?? this.splitType,
      totalMinor: totalMinor ?? this.totalMinor,
      expenseDate: expenseDate ?? this.expenseDate,
      subtotalMinor: subtotalMinor ?? this.subtotalMinor,
      serviceBps: serviceBps ?? this.serviceBps,
      serviceMinor: serviceMinor ?? this.serviceMinor,
      taxBps: taxBps ?? this.taxBps,
      taxMinor: taxMinor ?? this.taxMinor,
      taxBase: taxBase ?? this.taxBase,
      adjustmentMinor: adjustmentMinor ?? this.adjustmentMinor,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      version: version ?? this.version,
      category: category ?? this.category,
      paidFromPool: paidFromPool ?? this.paidFromPool,
      discountBps: discountBps ?? this.discountBps,
      discountAmountMinor: discountAmountMinor ?? this.discountAmountMinor,
      discountMinor: discountMinor ?? this.discountMinor,
      serviceAmountMinor: serviceAmountMinor ?? this.serviceAmountMinor,
      taxAmountMinor: taxAmountMinor ?? this.taxAmountMinor,
      deliveryMinor: deliveryMinor ?? this.deliveryMinor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (splitType.present) {
      map['split_type'] = Variable<String>(splitType.value);
    }
    if (totalMinor.present) {
      map['total_minor'] = Variable<int>(totalMinor.value);
    }
    if (expenseDate.present) {
      map['expense_date'] = Variable<String>(expenseDate.value);
    }
    if (subtotalMinor.present) {
      map['subtotal_minor'] = Variable<int>(subtotalMinor.value);
    }
    if (serviceBps.present) {
      map['service_bps'] = Variable<int>(serviceBps.value);
    }
    if (serviceMinor.present) {
      map['service_minor'] = Variable<int>(serviceMinor.value);
    }
    if (taxBps.present) {
      map['tax_bps'] = Variable<int>(taxBps.value);
    }
    if (taxMinor.present) {
      map['tax_minor'] = Variable<int>(taxMinor.value);
    }
    if (taxBase.present) {
      map['tax_base'] = Variable<String>(taxBase.value);
    }
    if (adjustmentMinor.present) {
      map['adjustment_minor'] = Variable<int>(adjustmentMinor.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (paidFromPool.present) {
      map['paid_from_pool'] = Variable<int>(paidFromPool.value);
    }
    if (discountBps.present) {
      map['discount_bps'] = Variable<int>(discountBps.value);
    }
    if (discountAmountMinor.present) {
      map['discount_amount_minor'] = Variable<int>(discountAmountMinor.value);
    }
    if (discountMinor.present) {
      map['discount_minor'] = Variable<int>(discountMinor.value);
    }
    if (serviceAmountMinor.present) {
      map['service_amount_minor'] = Variable<int>(serviceAmountMinor.value);
    }
    if (taxAmountMinor.present) {
      map['tax_amount_minor'] = Variable<int>(taxAmountMinor.value);
    }
    if (deliveryMinor.present) {
      map['delivery_minor'] = Variable<int>(deliveryMinor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('title: $title, ')
          ..write('splitType: $splitType, ')
          ..write('totalMinor: $totalMinor, ')
          ..write('expenseDate: $expenseDate, ')
          ..write('subtotalMinor: $subtotalMinor, ')
          ..write('serviceBps: $serviceBps, ')
          ..write('serviceMinor: $serviceMinor, ')
          ..write('taxBps: $taxBps, ')
          ..write('taxMinor: $taxMinor, ')
          ..write('taxBase: $taxBase, ')
          ..write('adjustmentMinor: $adjustmentMinor, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('version: $version, ')
          ..write('category: $category, ')
          ..write('paidFromPool: $paidFromPool, ')
          ..write('discountBps: $discountBps, ')
          ..write('discountAmountMinor: $discountAmountMinor, ')
          ..write('discountMinor: $discountMinor, ')
          ..write('serviceAmountMinor: $serviceAmountMinor, ')
          ..write('taxAmountMinor: $taxAmountMinor, ')
          ..write('deliveryMinor: $deliveryMinor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ExpensePayers extends Table with TableInfo<ExpensePayers, PayerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ExpensePayers(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES expenses(id)',
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES members(id)',
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (amount_minor BETWEEN 1 AND 1000000000000)',
  );
  @override
  List<GeneratedColumn> get $columns => [expenseId, memberId, amountMinor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_payers';
  @override
  VerificationContext validateIntegrity(
    Insertable<PayerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {expenseId, memberId};
  @override
  PayerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PayerRow(
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
    );
  }

  @override
  ExpensePayers createAlias(String alias) {
    return ExpensePayers(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(expense_id, member_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class PayerRow extends DataClass implements Insertable<PayerRow> {
  final String expenseId;
  final String memberId;
  final int amountMinor;
  const PayerRow({
    required this.expenseId,
    required this.memberId,
    required this.amountMinor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['expense_id'] = Variable<String>(expenseId);
    map['member_id'] = Variable<String>(memberId);
    map['amount_minor'] = Variable<int>(amountMinor);
    return map;
  }

  ExpensePayersCompanion toCompanion(bool nullToAbsent) {
    return ExpensePayersCompanion(
      expenseId: Value(expenseId),
      memberId: Value(memberId),
      amountMinor: Value(amountMinor),
    );
  }

  factory PayerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PayerRow(
      expenseId: serializer.fromJson<String>(json['expense_id']),
      memberId: serializer.fromJson<String>(json['member_id']),
      amountMinor: serializer.fromJson<int>(json['amount_minor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'expense_id': serializer.toJson<String>(expenseId),
      'member_id': serializer.toJson<String>(memberId),
      'amount_minor': serializer.toJson<int>(amountMinor),
    };
  }

  PayerRow copyWith({String? expenseId, String? memberId, int? amountMinor}) =>
      PayerRow(
        expenseId: expenseId ?? this.expenseId,
        memberId: memberId ?? this.memberId,
        amountMinor: amountMinor ?? this.amountMinor,
      );
  PayerRow copyWithCompanion(ExpensePayersCompanion data) {
    return PayerRow(
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PayerRow(')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('amountMinor: $amountMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(expenseId, memberId, amountMinor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PayerRow &&
          other.expenseId == this.expenseId &&
          other.memberId == this.memberId &&
          other.amountMinor == this.amountMinor);
}

class ExpensePayersCompanion extends UpdateCompanion<PayerRow> {
  final Value<String> expenseId;
  final Value<String> memberId;
  final Value<int> amountMinor;
  final Value<int> rowid;
  const ExpensePayersCompanion({
    this.expenseId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensePayersCompanion.insert({
    required String expenseId,
    required String memberId,
    required int amountMinor,
    this.rowid = const Value.absent(),
  }) : expenseId = Value(expenseId),
       memberId = Value(memberId),
       amountMinor = Value(amountMinor);
  static Insertable<PayerRow> custom({
    Expression<String>? expenseId,
    Expression<String>? memberId,
    Expression<int>? amountMinor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (expenseId != null) 'expense_id': expenseId,
      if (memberId != null) 'member_id': memberId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensePayersCompanion copyWith({
    Value<String>? expenseId,
    Value<String>? memberId,
    Value<int>? amountMinor,
    Value<int>? rowid,
  }) {
    return ExpensePayersCompanion(
      expenseId: expenseId ?? this.expenseId,
      memberId: memberId ?? this.memberId,
      amountMinor: amountMinor ?? this.amountMinor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensePayersCompanion(')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ExpenseSplits extends Table with TableInfo<ExpenseSplits, SplitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ExpenseSplits(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES expenses(id)',
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES members(id)',
  );
  static const VerificationMeta _owedMinorMeta = const VerificationMeta(
    'owedMinor',
  );
  late final GeneratedColumn<int> owedMinor = GeneratedColumn<int>(
    'owed_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (owed_minor BETWEEN 0 AND 1000000000000)',
  );
  static const VerificationMeta _itemsMinorMeta = const VerificationMeta(
    'itemsMinor',
  );
  late final GeneratedColumn<int> itemsMinor = GeneratedColumn<int>(
    'items_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _serviceMinorMeta = const VerificationMeta(
    'serviceMinor',
  );
  late final GeneratedColumn<int> serviceMinor = GeneratedColumn<int>(
    'service_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _taxMinorMeta = const VerificationMeta(
    'taxMinor',
  );
  late final GeneratedColumn<int> taxMinor = GeneratedColumn<int>(
    'tax_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _adjustmentMinorMeta = const VerificationMeta(
    'adjustmentMinor',
  );
  late final GeneratedColumn<int> adjustmentMinor = GeneratedColumn<int>(
    'adjustment_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _discountMinorMeta = const VerificationMeta(
    'discountMinor',
  );
  late final GeneratedColumn<int> discountMinor = GeneratedColumn<int>(
    'discount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deliveryMinorMeta = const VerificationMeta(
    'deliveryMinor',
  );
  late final GeneratedColumn<int> deliveryMinor = GeneratedColumn<int>(
    'delivery_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    expenseId,
    memberId,
    owedMinor,
    itemsMinor,
    serviceMinor,
    taxMinor,
    adjustmentMinor,
    discountMinor,
    deliveryMinor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_splits';
  @override
  VerificationContext validateIntegrity(
    Insertable<SplitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('owed_minor')) {
      context.handle(
        _owedMinorMeta,
        owedMinor.isAcceptableOrUnknown(data['owed_minor']!, _owedMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_owedMinorMeta);
    }
    if (data.containsKey('items_minor')) {
      context.handle(
        _itemsMinorMeta,
        itemsMinor.isAcceptableOrUnknown(data['items_minor']!, _itemsMinorMeta),
      );
    }
    if (data.containsKey('service_minor')) {
      context.handle(
        _serviceMinorMeta,
        serviceMinor.isAcceptableOrUnknown(
          data['service_minor']!,
          _serviceMinorMeta,
        ),
      );
    }
    if (data.containsKey('tax_minor')) {
      context.handle(
        _taxMinorMeta,
        taxMinor.isAcceptableOrUnknown(data['tax_minor']!, _taxMinorMeta),
      );
    }
    if (data.containsKey('adjustment_minor')) {
      context.handle(
        _adjustmentMinorMeta,
        adjustmentMinor.isAcceptableOrUnknown(
          data['adjustment_minor']!,
          _adjustmentMinorMeta,
        ),
      );
    }
    if (data.containsKey('discount_minor')) {
      context.handle(
        _discountMinorMeta,
        discountMinor.isAcceptableOrUnknown(
          data['discount_minor']!,
          _discountMinorMeta,
        ),
      );
    }
    if (data.containsKey('delivery_minor')) {
      context.handle(
        _deliveryMinorMeta,
        deliveryMinor.isAcceptableOrUnknown(
          data['delivery_minor']!,
          _deliveryMinorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {expenseId, memberId};
  @override
  SplitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SplitRow(
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      owedMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}owed_minor'],
      )!,
      itemsMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}items_minor'],
      ),
      serviceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}service_minor'],
      ),
      taxMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_minor'],
      ),
      adjustmentMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}adjustment_minor'],
      ),
      discountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_minor'],
      ),
      deliveryMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delivery_minor'],
      ),
    );
  }

  @override
  ExpenseSplits createAlias(String alias) {
    return ExpenseSplits(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(expense_id, member_id)',
    'CONSTRAINT ck_expense_splits_breakdown CHECK((items_minor IS NULL AND discount_minor IS NULL AND service_minor IS NULL AND tax_minor IS NULL AND adjustment_minor IS NULL AND delivery_minor IS NULL)OR(items_minor IS NOT NULL AND items_minor >= 0 AND discount_minor IS NOT NULL AND discount_minor >= 0 AND discount_minor <= items_minor AND service_minor IS NOT NULL AND service_minor >= 0 AND tax_minor IS NOT NULL AND tax_minor >= 0 AND delivery_minor IS NOT NULL AND delivery_minor >= 0 AND adjustment_minor IS NOT NULL AND owed_minor = items_minor - discount_minor + service_minor + tax_minor + delivery_minor + adjustment_minor))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class SplitRow extends DataClass implements Insertable<SplitRow> {
  final String expenseId;
  final String memberId;
  final int owedMinor;
  final int? itemsMinor;
  final int? serviceMinor;
  final int? taxMinor;
  final int? adjustmentMinor;

  /// Schema 8 (SA15, Java V21): this member's part of the bill discount (ITEMIZED breakdown only).
  final int? discountMinor;

  /// Schema 9 (Java V22, A180): this member's part of the delivery (ITEMIZED breakdown only).
  final int? deliveryMinor;
  const SplitRow({
    required this.expenseId,
    required this.memberId,
    required this.owedMinor,
    this.itemsMinor,
    this.serviceMinor,
    this.taxMinor,
    this.adjustmentMinor,
    this.discountMinor,
    this.deliveryMinor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['expense_id'] = Variable<String>(expenseId);
    map['member_id'] = Variable<String>(memberId);
    map['owed_minor'] = Variable<int>(owedMinor);
    if (!nullToAbsent || itemsMinor != null) {
      map['items_minor'] = Variable<int>(itemsMinor);
    }
    if (!nullToAbsent || serviceMinor != null) {
      map['service_minor'] = Variable<int>(serviceMinor);
    }
    if (!nullToAbsent || taxMinor != null) {
      map['tax_minor'] = Variable<int>(taxMinor);
    }
    if (!nullToAbsent || adjustmentMinor != null) {
      map['adjustment_minor'] = Variable<int>(adjustmentMinor);
    }
    if (!nullToAbsent || discountMinor != null) {
      map['discount_minor'] = Variable<int>(discountMinor);
    }
    if (!nullToAbsent || deliveryMinor != null) {
      map['delivery_minor'] = Variable<int>(deliveryMinor);
    }
    return map;
  }

  ExpenseSplitsCompanion toCompanion(bool nullToAbsent) {
    return ExpenseSplitsCompanion(
      expenseId: Value(expenseId),
      memberId: Value(memberId),
      owedMinor: Value(owedMinor),
      itemsMinor: itemsMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(itemsMinor),
      serviceMinor: serviceMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceMinor),
      taxMinor: taxMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(taxMinor),
      adjustmentMinor: adjustmentMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(adjustmentMinor),
      discountMinor: discountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(discountMinor),
      deliveryMinor: deliveryMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryMinor),
    );
  }

  factory SplitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SplitRow(
      expenseId: serializer.fromJson<String>(json['expense_id']),
      memberId: serializer.fromJson<String>(json['member_id']),
      owedMinor: serializer.fromJson<int>(json['owed_minor']),
      itemsMinor: serializer.fromJson<int?>(json['items_minor']),
      serviceMinor: serializer.fromJson<int?>(json['service_minor']),
      taxMinor: serializer.fromJson<int?>(json['tax_minor']),
      adjustmentMinor: serializer.fromJson<int?>(json['adjustment_minor']),
      discountMinor: serializer.fromJson<int?>(json['discount_minor']),
      deliveryMinor: serializer.fromJson<int?>(json['delivery_minor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'expense_id': serializer.toJson<String>(expenseId),
      'member_id': serializer.toJson<String>(memberId),
      'owed_minor': serializer.toJson<int>(owedMinor),
      'items_minor': serializer.toJson<int?>(itemsMinor),
      'service_minor': serializer.toJson<int?>(serviceMinor),
      'tax_minor': serializer.toJson<int?>(taxMinor),
      'adjustment_minor': serializer.toJson<int?>(adjustmentMinor),
      'discount_minor': serializer.toJson<int?>(discountMinor),
      'delivery_minor': serializer.toJson<int?>(deliveryMinor),
    };
  }

  SplitRow copyWith({
    String? expenseId,
    String? memberId,
    int? owedMinor,
    Value<int?> itemsMinor = const Value.absent(),
    Value<int?> serviceMinor = const Value.absent(),
    Value<int?> taxMinor = const Value.absent(),
    Value<int?> adjustmentMinor = const Value.absent(),
    Value<int?> discountMinor = const Value.absent(),
    Value<int?> deliveryMinor = const Value.absent(),
  }) => SplitRow(
    expenseId: expenseId ?? this.expenseId,
    memberId: memberId ?? this.memberId,
    owedMinor: owedMinor ?? this.owedMinor,
    itemsMinor: itemsMinor.present ? itemsMinor.value : this.itemsMinor,
    serviceMinor: serviceMinor.present ? serviceMinor.value : this.serviceMinor,
    taxMinor: taxMinor.present ? taxMinor.value : this.taxMinor,
    adjustmentMinor: adjustmentMinor.present
        ? adjustmentMinor.value
        : this.adjustmentMinor,
    discountMinor: discountMinor.present
        ? discountMinor.value
        : this.discountMinor,
    deliveryMinor: deliveryMinor.present
        ? deliveryMinor.value
        : this.deliveryMinor,
  );
  SplitRow copyWithCompanion(ExpenseSplitsCompanion data) {
    return SplitRow(
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      owedMinor: data.owedMinor.present ? data.owedMinor.value : this.owedMinor,
      itemsMinor: data.itemsMinor.present
          ? data.itemsMinor.value
          : this.itemsMinor,
      serviceMinor: data.serviceMinor.present
          ? data.serviceMinor.value
          : this.serviceMinor,
      taxMinor: data.taxMinor.present ? data.taxMinor.value : this.taxMinor,
      adjustmentMinor: data.adjustmentMinor.present
          ? data.adjustmentMinor.value
          : this.adjustmentMinor,
      discountMinor: data.discountMinor.present
          ? data.discountMinor.value
          : this.discountMinor,
      deliveryMinor: data.deliveryMinor.present
          ? data.deliveryMinor.value
          : this.deliveryMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SplitRow(')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('owedMinor: $owedMinor, ')
          ..write('itemsMinor: $itemsMinor, ')
          ..write('serviceMinor: $serviceMinor, ')
          ..write('taxMinor: $taxMinor, ')
          ..write('adjustmentMinor: $adjustmentMinor, ')
          ..write('discountMinor: $discountMinor, ')
          ..write('deliveryMinor: $deliveryMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    expenseId,
    memberId,
    owedMinor,
    itemsMinor,
    serviceMinor,
    taxMinor,
    adjustmentMinor,
    discountMinor,
    deliveryMinor,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SplitRow &&
          other.expenseId == this.expenseId &&
          other.memberId == this.memberId &&
          other.owedMinor == this.owedMinor &&
          other.itemsMinor == this.itemsMinor &&
          other.serviceMinor == this.serviceMinor &&
          other.taxMinor == this.taxMinor &&
          other.adjustmentMinor == this.adjustmentMinor &&
          other.discountMinor == this.discountMinor &&
          other.deliveryMinor == this.deliveryMinor);
}

class ExpenseSplitsCompanion extends UpdateCompanion<SplitRow> {
  final Value<String> expenseId;
  final Value<String> memberId;
  final Value<int> owedMinor;
  final Value<int?> itemsMinor;
  final Value<int?> serviceMinor;
  final Value<int?> taxMinor;
  final Value<int?> adjustmentMinor;
  final Value<int?> discountMinor;
  final Value<int?> deliveryMinor;
  final Value<int> rowid;
  const ExpenseSplitsCompanion({
    this.expenseId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.owedMinor = const Value.absent(),
    this.itemsMinor = const Value.absent(),
    this.serviceMinor = const Value.absent(),
    this.taxMinor = const Value.absent(),
    this.adjustmentMinor = const Value.absent(),
    this.discountMinor = const Value.absent(),
    this.deliveryMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpenseSplitsCompanion.insert({
    required String expenseId,
    required String memberId,
    required int owedMinor,
    this.itemsMinor = const Value.absent(),
    this.serviceMinor = const Value.absent(),
    this.taxMinor = const Value.absent(),
    this.adjustmentMinor = const Value.absent(),
    this.discountMinor = const Value.absent(),
    this.deliveryMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : expenseId = Value(expenseId),
       memberId = Value(memberId),
       owedMinor = Value(owedMinor);
  static Insertable<SplitRow> custom({
    Expression<String>? expenseId,
    Expression<String>? memberId,
    Expression<int>? owedMinor,
    Expression<int>? itemsMinor,
    Expression<int>? serviceMinor,
    Expression<int>? taxMinor,
    Expression<int>? adjustmentMinor,
    Expression<int>? discountMinor,
    Expression<int>? deliveryMinor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (expenseId != null) 'expense_id': expenseId,
      if (memberId != null) 'member_id': memberId,
      if (owedMinor != null) 'owed_minor': owedMinor,
      if (itemsMinor != null) 'items_minor': itemsMinor,
      if (serviceMinor != null) 'service_minor': serviceMinor,
      if (taxMinor != null) 'tax_minor': taxMinor,
      if (adjustmentMinor != null) 'adjustment_minor': adjustmentMinor,
      if (discountMinor != null) 'discount_minor': discountMinor,
      if (deliveryMinor != null) 'delivery_minor': deliveryMinor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpenseSplitsCompanion copyWith({
    Value<String>? expenseId,
    Value<String>? memberId,
    Value<int>? owedMinor,
    Value<int?>? itemsMinor,
    Value<int?>? serviceMinor,
    Value<int?>? taxMinor,
    Value<int?>? adjustmentMinor,
    Value<int?>? discountMinor,
    Value<int?>? deliveryMinor,
    Value<int>? rowid,
  }) {
    return ExpenseSplitsCompanion(
      expenseId: expenseId ?? this.expenseId,
      memberId: memberId ?? this.memberId,
      owedMinor: owedMinor ?? this.owedMinor,
      itemsMinor: itemsMinor ?? this.itemsMinor,
      serviceMinor: serviceMinor ?? this.serviceMinor,
      taxMinor: taxMinor ?? this.taxMinor,
      adjustmentMinor: adjustmentMinor ?? this.adjustmentMinor,
      discountMinor: discountMinor ?? this.discountMinor,
      deliveryMinor: deliveryMinor ?? this.deliveryMinor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (owedMinor.present) {
      map['owed_minor'] = Variable<int>(owedMinor.value);
    }
    if (itemsMinor.present) {
      map['items_minor'] = Variable<int>(itemsMinor.value);
    }
    if (serviceMinor.present) {
      map['service_minor'] = Variable<int>(serviceMinor.value);
    }
    if (taxMinor.present) {
      map['tax_minor'] = Variable<int>(taxMinor.value);
    }
    if (adjustmentMinor.present) {
      map['adjustment_minor'] = Variable<int>(adjustmentMinor.value);
    }
    if (discountMinor.present) {
      map['discount_minor'] = Variable<int>(discountMinor.value);
    }
    if (deliveryMinor.present) {
      map['delivery_minor'] = Variable<int>(deliveryMinor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseSplitsCompanion(')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('owedMinor: $owedMinor, ')
          ..write('itemsMinor: $itemsMinor, ')
          ..write('serviceMinor: $serviceMinor, ')
          ..write('taxMinor: $taxMinor, ')
          ..write('adjustmentMinor: $adjustmentMinor, ')
          ..write('discountMinor: $discountMinor, ')
          ..write('deliveryMinor: $deliveryMinor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ExpenseItems extends Table with TableInfo<ExpenseItems, ItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ExpenseItems(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 36)',
  );
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES expenses(id)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 100)',
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (amount_minor BETWEEN 1 AND 1000000000000)',
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (sort_order >= 0)',
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (quantity BETWEEN 1 AND 999)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _unitAmountMinorMeta = const VerificationMeta(
    'unitAmountMinor',
  );
  late final GeneratedColumn<int> unitAmountMinor = GeneratedColumn<int>(
    'unit_amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (unit_amount_minor BETWEEN 1 AND 1000000000000)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    expenseId,
    name,
    amountMinor,
    sortOrder,
    quantity,
    unitAmountMinor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit_amount_minor')) {
      context.handle(
        _unitAmountMinorMeta,
        unitAmountMinor.isAcceptableOrUnknown(
          data['unit_amount_minor']!,
          _unitAmountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitAmountMinorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {expenseId, sortOrder},
  ];
  @override
  ItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unitAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_amount_minor'],
      )!,
    );
  }

  @override
  ExpenseItems createAlias(String alias) {
    return ExpenseItems(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const [
    'CONSTRAINT ux_expense_items_order UNIQUE(expense_id, sort_order)',
    'CONSTRAINT ck_expense_items_line CHECK(amount_minor = quantity * unit_amount_minor)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ItemRow extends DataClass implements Insertable<ItemRow> {
  final String id;
  final String expenseId;
  final String name;
  final int amountMinor;
  final int sortOrder;

  /// Schema 8 (SA15, Java V21, A172): quantity x unit price = the line amount (999 x 10^12 fits in 64 bits).
  final int quantity;
  final int unitAmountMinor;
  const ItemRow({
    required this.id,
    required this.expenseId,
    required this.name,
    required this.amountMinor,
    required this.sortOrder,
    required this.quantity,
    required this.unitAmountMinor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['expense_id'] = Variable<String>(expenseId);
    map['name'] = Variable<String>(name);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['sort_order'] = Variable<int>(sortOrder);
    map['quantity'] = Variable<int>(quantity);
    map['unit_amount_minor'] = Variable<int>(unitAmountMinor);
    return map;
  }

  ExpenseItemsCompanion toCompanion(bool nullToAbsent) {
    return ExpenseItemsCompanion(
      id: Value(id),
      expenseId: Value(expenseId),
      name: Value(name),
      amountMinor: Value(amountMinor),
      sortOrder: Value(sortOrder),
      quantity: Value(quantity),
      unitAmountMinor: Value(unitAmountMinor),
    );
  }

  factory ItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemRow(
      id: serializer.fromJson<String>(json['id']),
      expenseId: serializer.fromJson<String>(json['expense_id']),
      name: serializer.fromJson<String>(json['name']),
      amountMinor: serializer.fromJson<int>(json['amount_minor']),
      sortOrder: serializer.fromJson<int>(json['sort_order']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unitAmountMinor: serializer.fromJson<int>(json['unit_amount_minor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'expense_id': serializer.toJson<String>(expenseId),
      'name': serializer.toJson<String>(name),
      'amount_minor': serializer.toJson<int>(amountMinor),
      'sort_order': serializer.toJson<int>(sortOrder),
      'quantity': serializer.toJson<int>(quantity),
      'unit_amount_minor': serializer.toJson<int>(unitAmountMinor),
    };
  }

  ItemRow copyWith({
    String? id,
    String? expenseId,
    String? name,
    int? amountMinor,
    int? sortOrder,
    int? quantity,
    int? unitAmountMinor,
  }) => ItemRow(
    id: id ?? this.id,
    expenseId: expenseId ?? this.expenseId,
    name: name ?? this.name,
    amountMinor: amountMinor ?? this.amountMinor,
    sortOrder: sortOrder ?? this.sortOrder,
    quantity: quantity ?? this.quantity,
    unitAmountMinor: unitAmountMinor ?? this.unitAmountMinor,
  );
  ItemRow copyWithCompanion(ExpenseItemsCompanion data) {
    return ItemRow(
      id: data.id.present ? data.id.value : this.id,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      name: data.name.present ? data.name.value : this.name,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitAmountMinor: data.unitAmountMinor.present
          ? data.unitAmountMinor.value
          : this.unitAmountMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemRow(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('name: $name, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('quantity: $quantity, ')
          ..write('unitAmountMinor: $unitAmountMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    expenseId,
    name,
    amountMinor,
    sortOrder,
    quantity,
    unitAmountMinor,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemRow &&
          other.id == this.id &&
          other.expenseId == this.expenseId &&
          other.name == this.name &&
          other.amountMinor == this.amountMinor &&
          other.sortOrder == this.sortOrder &&
          other.quantity == this.quantity &&
          other.unitAmountMinor == this.unitAmountMinor);
}

class ExpenseItemsCompanion extends UpdateCompanion<ItemRow> {
  final Value<String> id;
  final Value<String> expenseId;
  final Value<String> name;
  final Value<int> amountMinor;
  final Value<int> sortOrder;
  final Value<int> quantity;
  final Value<int> unitAmountMinor;
  final Value<int> rowid;
  const ExpenseItemsCompanion({
    this.id = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.name = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitAmountMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpenseItemsCompanion.insert({
    required String id,
    required String expenseId,
    required String name,
    required int amountMinor,
    required int sortOrder,
    this.quantity = const Value.absent(),
    required int unitAmountMinor,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       expenseId = Value(expenseId),
       name = Value(name),
       amountMinor = Value(amountMinor),
       sortOrder = Value(sortOrder),
       unitAmountMinor = Value(unitAmountMinor);
  static Insertable<ItemRow> custom({
    Expression<String>? id,
    Expression<String>? expenseId,
    Expression<String>? name,
    Expression<int>? amountMinor,
    Expression<int>? sortOrder,
    Expression<int>? quantity,
    Expression<int>? unitAmountMinor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (expenseId != null) 'expense_id': expenseId,
      if (name != null) 'name': name,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (quantity != null) 'quantity': quantity,
      if (unitAmountMinor != null) 'unit_amount_minor': unitAmountMinor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpenseItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? expenseId,
    Value<String>? name,
    Value<int>? amountMinor,
    Value<int>? sortOrder,
    Value<int>? quantity,
    Value<int>? unitAmountMinor,
    Value<int>? rowid,
  }) {
    return ExpenseItemsCompanion(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      name: name ?? this.name,
      amountMinor: amountMinor ?? this.amountMinor,
      sortOrder: sortOrder ?? this.sortOrder,
      quantity: quantity ?? this.quantity,
      unitAmountMinor: unitAmountMinor ?? this.unitAmountMinor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitAmountMinor.present) {
      map['unit_amount_minor'] = Variable<int>(unitAmountMinor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseItemsCompanion(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('name: $name, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('quantity: $quantity, ')
          ..write('unitAmountMinor: $unitAmountMinor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ExpenseItemAssignees extends Table
    with TableInfo<ExpenseItemAssignees, AssigneeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ExpenseItemAssignees(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES expense_items(id)',
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES members(id)',
  );
  @override
  List<GeneratedColumn> get $columns => [itemId, memberId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_item_assignees';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssigneeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, memberId};
  @override
  AssigneeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssigneeRow(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
    );
  }

  @override
  ExpenseItemAssignees createAlias(String alias) {
    return ExpenseItemAssignees(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(item_id, member_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class AssigneeRow extends DataClass implements Insertable<AssigneeRow> {
  final String itemId;
  final String memberId;
  const AssigneeRow({required this.itemId, required this.memberId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['member_id'] = Variable<String>(memberId);
    return map;
  }

  ExpenseItemAssigneesCompanion toCompanion(bool nullToAbsent) {
    return ExpenseItemAssigneesCompanion(
      itemId: Value(itemId),
      memberId: Value(memberId),
    );
  }

  factory AssigneeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssigneeRow(
      itemId: serializer.fromJson<String>(json['item_id']),
      memberId: serializer.fromJson<String>(json['member_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'item_id': serializer.toJson<String>(itemId),
      'member_id': serializer.toJson<String>(memberId),
    };
  }

  AssigneeRow copyWith({String? itemId, String? memberId}) => AssigneeRow(
    itemId: itemId ?? this.itemId,
    memberId: memberId ?? this.memberId,
  );
  AssigneeRow copyWithCompanion(ExpenseItemAssigneesCompanion data) {
    return AssigneeRow(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssigneeRow(')
          ..write('itemId: $itemId, ')
          ..write('memberId: $memberId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, memberId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssigneeRow &&
          other.itemId == this.itemId &&
          other.memberId == this.memberId);
}

class ExpenseItemAssigneesCompanion extends UpdateCompanion<AssigneeRow> {
  final Value<String> itemId;
  final Value<String> memberId;
  final Value<int> rowid;
  const ExpenseItemAssigneesCompanion({
    this.itemId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpenseItemAssigneesCompanion.insert({
    required String itemId,
    required String memberId,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       memberId = Value(memberId);
  static Insertable<AssigneeRow> custom({
    Expression<String>? itemId,
    Expression<String>? memberId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (memberId != null) 'member_id': memberId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpenseItemAssigneesCompanion copyWith({
    Value<String>? itemId,
    Value<String>? memberId,
    Value<int>? rowid,
  }) {
    return ExpenseItemAssigneesCompanion(
      itemId: itemId ?? this.itemId,
      memberId: memberId ?? this.memberId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseItemAssigneesCompanion(')
          ..write('itemId: $itemId, ')
          ..write('memberId: $memberId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ExpenseRevisions extends Table
    with TableInfo<ExpenseRevisions, RevisionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ExpenseRevisions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 36)',
  );
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES expenses(id)',
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (version >= 1)',
  );
  static const VerificationMeta _changeTypeMeta = const VerificationMeta(
    'changeType',
  );
  late final GeneratedColumn<String> changeType = GeneratedColumn<String>(
    'change_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (change_type IN (\'CREATE\', \'UPDATE\', \'DELETE\'))',
  );
  static const VerificationMeta _snapshotMeta = const VerificationMeta(
    'snapshot',
  );
  late final GeneratedColumn<String> snapshot = GeneratedColumn<String>(
    'snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (json_valid(snapshot) AND json_type(snapshot) = \'object\')',
  );
  static const VerificationMeta _changedByUserIdMeta = const VerificationMeta(
    'changedByUserId',
  );
  late final GeneratedColumn<String> changedByUserId = GeneratedColumn<String>(
    'changed_by_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES local_profile(id)',
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  late final GeneratedColumn<int> changedAt = GeneratedColumn<int>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    expenseId,
    version,
    changeType,
    snapshot,
    changedByUserId,
    changedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RevisionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('change_type')) {
      context.handle(
        _changeTypeMeta,
        changeType.isAcceptableOrUnknown(data['change_type']!, _changeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_changeTypeMeta);
    }
    if (data.containsKey('snapshot')) {
      context.handle(
        _snapshotMeta,
        snapshot.isAcceptableOrUnknown(data['snapshot']!, _snapshotMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotMeta);
    }
    if (data.containsKey('changed_by_user_id')) {
      context.handle(
        _changedByUserIdMeta,
        changedByUserId.isAcceptableOrUnknown(
          data['changed_by_user_id']!,
          _changedByUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_changedByUserIdMeta);
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_changedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {expenseId, version},
  ];
  @override
  RevisionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RevisionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      changeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}change_type'],
      )!,
      snapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot'],
      )!,
      changedByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}changed_by_user_id'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}changed_at'],
      )!,
    );
  }

  @override
  ExpenseRevisions createAlias(String alias) {
    return ExpenseRevisions(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const [
    'CONSTRAINT ux_expense_revisions_version UNIQUE(expense_id, version)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class RevisionRow extends DataClass implements Insertable<RevisionRow> {
  final String id;
  final String expenseId;
  final int version;
  final String changeType;
  final String snapshot;
  final String changedByUserId;
  final int changedAt;
  const RevisionRow({
    required this.id,
    required this.expenseId,
    required this.version,
    required this.changeType,
    required this.snapshot,
    required this.changedByUserId,
    required this.changedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['expense_id'] = Variable<String>(expenseId);
    map['version'] = Variable<int>(version);
    map['change_type'] = Variable<String>(changeType);
    map['snapshot'] = Variable<String>(snapshot);
    map['changed_by_user_id'] = Variable<String>(changedByUserId);
    map['changed_at'] = Variable<int>(changedAt);
    return map;
  }

  ExpenseRevisionsCompanion toCompanion(bool nullToAbsent) {
    return ExpenseRevisionsCompanion(
      id: Value(id),
      expenseId: Value(expenseId),
      version: Value(version),
      changeType: Value(changeType),
      snapshot: Value(snapshot),
      changedByUserId: Value(changedByUserId),
      changedAt: Value(changedAt),
    );
  }

  factory RevisionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RevisionRow(
      id: serializer.fromJson<String>(json['id']),
      expenseId: serializer.fromJson<String>(json['expense_id']),
      version: serializer.fromJson<int>(json['version']),
      changeType: serializer.fromJson<String>(json['change_type']),
      snapshot: serializer.fromJson<String>(json['snapshot']),
      changedByUserId: serializer.fromJson<String>(json['changed_by_user_id']),
      changedAt: serializer.fromJson<int>(json['changed_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'expense_id': serializer.toJson<String>(expenseId),
      'version': serializer.toJson<int>(version),
      'change_type': serializer.toJson<String>(changeType),
      'snapshot': serializer.toJson<String>(snapshot),
      'changed_by_user_id': serializer.toJson<String>(changedByUserId),
      'changed_at': serializer.toJson<int>(changedAt),
    };
  }

  RevisionRow copyWith({
    String? id,
    String? expenseId,
    int? version,
    String? changeType,
    String? snapshot,
    String? changedByUserId,
    int? changedAt,
  }) => RevisionRow(
    id: id ?? this.id,
    expenseId: expenseId ?? this.expenseId,
    version: version ?? this.version,
    changeType: changeType ?? this.changeType,
    snapshot: snapshot ?? this.snapshot,
    changedByUserId: changedByUserId ?? this.changedByUserId,
    changedAt: changedAt ?? this.changedAt,
  );
  RevisionRow copyWithCompanion(ExpenseRevisionsCompanion data) {
    return RevisionRow(
      id: data.id.present ? data.id.value : this.id,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      version: data.version.present ? data.version.value : this.version,
      changeType: data.changeType.present
          ? data.changeType.value
          : this.changeType,
      snapshot: data.snapshot.present ? data.snapshot.value : this.snapshot,
      changedByUserId: data.changedByUserId.present
          ? data.changedByUserId.value
          : this.changedByUserId,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RevisionRow(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('version: $version, ')
          ..write('changeType: $changeType, ')
          ..write('snapshot: $snapshot, ')
          ..write('changedByUserId: $changedByUserId, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    expenseId,
    version,
    changeType,
    snapshot,
    changedByUserId,
    changedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RevisionRow &&
          other.id == this.id &&
          other.expenseId == this.expenseId &&
          other.version == this.version &&
          other.changeType == this.changeType &&
          other.snapshot == this.snapshot &&
          other.changedByUserId == this.changedByUserId &&
          other.changedAt == this.changedAt);
}

class ExpenseRevisionsCompanion extends UpdateCompanion<RevisionRow> {
  final Value<String> id;
  final Value<String> expenseId;
  final Value<int> version;
  final Value<String> changeType;
  final Value<String> snapshot;
  final Value<String> changedByUserId;
  final Value<int> changedAt;
  final Value<int> rowid;
  const ExpenseRevisionsCompanion({
    this.id = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.version = const Value.absent(),
    this.changeType = const Value.absent(),
    this.snapshot = const Value.absent(),
    this.changedByUserId = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpenseRevisionsCompanion.insert({
    required String id,
    required String expenseId,
    required int version,
    required String changeType,
    required String snapshot,
    required String changedByUserId,
    required int changedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       expenseId = Value(expenseId),
       version = Value(version),
       changeType = Value(changeType),
       snapshot = Value(snapshot),
       changedByUserId = Value(changedByUserId),
       changedAt = Value(changedAt);
  static Insertable<RevisionRow> custom({
    Expression<String>? id,
    Expression<String>? expenseId,
    Expression<int>? version,
    Expression<String>? changeType,
    Expression<String>? snapshot,
    Expression<String>? changedByUserId,
    Expression<int>? changedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (expenseId != null) 'expense_id': expenseId,
      if (version != null) 'version': version,
      if (changeType != null) 'change_type': changeType,
      if (snapshot != null) 'snapshot': snapshot,
      if (changedByUserId != null) 'changed_by_user_id': changedByUserId,
      if (changedAt != null) 'changed_at': changedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpenseRevisionsCompanion copyWith({
    Value<String>? id,
    Value<String>? expenseId,
    Value<int>? version,
    Value<String>? changeType,
    Value<String>? snapshot,
    Value<String>? changedByUserId,
    Value<int>? changedAt,
    Value<int>? rowid,
  }) {
    return ExpenseRevisionsCompanion(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      version: version ?? this.version,
      changeType: changeType ?? this.changeType,
      snapshot: snapshot ?? this.snapshot,
      changedByUserId: changedByUserId ?? this.changedByUserId,
      changedAt: changedAt ?? this.changedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (changeType.present) {
      map['change_type'] = Variable<String>(changeType.value);
    }
    if (snapshot.present) {
      map['snapshot'] = Variable<String>(snapshot.value);
    }
    if (changedByUserId.present) {
      map['changed_by_user_id'] = Variable<String>(changedByUserId.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<int>(changedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRevisionsCompanion(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('version: $version, ')
          ..write('changeType: $changeType, ')
          ..write('snapshot: $snapshot, ')
          ..write('changedByUserId: $changedByUserId, ')
          ..write('changedAt: $changedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Settlements extends Table with TableInfo<Settlements, SettlementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Settlements(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 36)',
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES expense_groups(id)',
  );
  static const VerificationMeta _fromMemberIdMeta = const VerificationMeta(
    'fromMemberId',
  );
  late final GeneratedColumn<String> fromMemberId = GeneratedColumn<String>(
    'from_member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES members(id)',
  );
  static const VerificationMeta _toMemberIdMeta = const VerificationMeta(
    'toMemberId',
  );
  late final GeneratedColumn<String> toMemberId = GeneratedColumn<String>(
    'to_member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES members(id)',
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (amount_minor BETWEEN 1 AND 1000000000000)',
  );
  static const VerificationMeta _settledOnMeta = const VerificationMeta(
    'settledOn',
  );
  late final GeneratedColumn<String> settledOn = GeneratedColumn<String>(
    'settled_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (date(settled_on) IS settled_on)',
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (note IS NULL OR length(trim(note)) BETWEEN 1 AND 200)',
  );
  static const VerificationMeta _createdByUserIdMeta = const VerificationMeta(
    'createdByUserId',
  );
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
    'created_by_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES local_profile(id)',
  );
  static const VerificationMeta _createdByMemberIdMeta = const VerificationMeta(
    'createdByMemberId',
  );
  late final GeneratedColumn<String> createdByMemberId =
      GeneratedColumn<String>(
        'created_by_member_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES members(id)',
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (status IN (\'PENDING\', \'CONFIRMED\', \'DISPUTED\', \'CANCELLED\'))',
  );
  static const VerificationMeta _declaredAtMeta = const VerificationMeta(
    'declaredAt',
  );
  late final GeneratedColumn<int> declaredAt = GeneratedColumn<int>(
    'declared_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  late final GeneratedColumn<int> confirmedAt = GeneratedColumn<int>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _disputedAtMeta = const VerificationMeta(
    'disputedAt',
  );
  late final GeneratedColumn<int> disputedAt = GeneratedColumn<int>(
    'disputed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _cancelledAtMeta = const VerificationMeta(
    'cancelledAt',
  );
  late final GeneratedColumn<int> cancelledAt = GeneratedColumn<int>(
    'cancelled_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _recordedByAdminMeta = const VerificationMeta(
    'recordedByAdmin',
  );
  late final GeneratedColumn<int> recordedByAdmin = GeneratedColumn<int>(
    'recorded_by_admin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT 0 CHECK (recorded_by_admin IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'PAYMENT\' CHECK (kind IN (\'PAYMENT\', \'POOL_DEPOSIT\'))',
    defaultValue: const CustomExpression('\'PAYMENT\''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    fromMemberId,
    toMemberId,
    amountMinor,
    settledOn,
    note,
    createdByUserId,
    createdByMemberId,
    createdAt,
    status,
    declaredAt,
    confirmedAt,
    disputedAt,
    cancelledAt,
    recordedByAdmin,
    kind,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settlements';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettlementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('from_member_id')) {
      context.handle(
        _fromMemberIdMeta,
        fromMemberId.isAcceptableOrUnknown(
          data['from_member_id']!,
          _fromMemberIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromMemberIdMeta);
    }
    if (data.containsKey('to_member_id')) {
      context.handle(
        _toMemberIdMeta,
        toMemberId.isAcceptableOrUnknown(
          data['to_member_id']!,
          _toMemberIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_toMemberIdMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('settled_on')) {
      context.handle(
        _settledOnMeta,
        settledOn.isAcceptableOrUnknown(data['settled_on']!, _settledOnMeta),
      );
    } else if (isInserting) {
      context.missing(_settledOnMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
        _createdByUserIdMeta,
        createdByUserId.isAcceptableOrUnknown(
          data['created_by_user_id']!,
          _createdByUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdByUserIdMeta);
    }
    if (data.containsKey('created_by_member_id')) {
      context.handle(
        _createdByMemberIdMeta,
        createdByMemberId.isAcceptableOrUnknown(
          data['created_by_member_id']!,
          _createdByMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('declared_at')) {
      context.handle(
        _declaredAtMeta,
        declaredAt.isAcceptableOrUnknown(data['declared_at']!, _declaredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_declaredAtMeta);
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    if (data.containsKey('disputed_at')) {
      context.handle(
        _disputedAtMeta,
        disputedAt.isAcceptableOrUnknown(data['disputed_at']!, _disputedAtMeta),
      );
    }
    if (data.containsKey('cancelled_at')) {
      context.handle(
        _cancelledAtMeta,
        cancelledAt.isAcceptableOrUnknown(
          data['cancelled_at']!,
          _cancelledAtMeta,
        ),
      );
    }
    if (data.containsKey('recorded_by_admin')) {
      context.handle(
        _recordedByAdminMeta,
        recordedByAdmin.isAcceptableOrUnknown(
          data['recorded_by_admin']!,
          _recordedByAdminMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettlementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettlementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      fromMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_member_id'],
      )!,
      toMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_member_id'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      settledOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settled_on'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_user_id'],
      )!,
      createdByMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_member_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      declaredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}declared_at'],
      )!,
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}confirmed_at'],
      ),
      disputedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disputed_at'],
      ),
      cancelledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cancelled_at'],
      ),
      recordedByAdmin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_by_admin'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
    );
  }

  @override
  Settlements createAlias(String alias) {
    return Settlements(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const [
    'CONSTRAINT ck_settlements_members CHECK(from_member_id <> to_member_id)',
    'CONSTRAINT ck_settlements_confirmed_at CHECK((status = \'CONFIRMED\')=(confirmed_at IS NOT NULL))',
    'CONSTRAINT ck_settlements_cancelled_at CHECK((status = \'CANCELLED\')=(cancelled_at IS NOT NULL))',
    'CONSTRAINT ck_settlements_disputed_at CHECK(status <> \'DISPUTED\' OR disputed_at IS NOT NULL)',
    'CONSTRAINT ck_settlements_pending_clean CHECK(status <> \'PENDING\' OR(disputed_at IS NULL AND confirmed_at IS NULL))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class SettlementRow extends DataClass implements Insertable<SettlementRow> {
  final String id;
  final String groupId;
  final String fromMemberId;
  final String toMemberId;
  final int amountMinor;
  final String settledOn;
  final String? note;
  final String createdByUserId;
  final String? createdByMemberId;
  final int createdAt;
  final String status;
  final int declaredAt;
  final int? confirmedAt;
  final int? disputedAt;
  final int? cancelledAt;
  final int recordedByAdmin;

  /// Schema 5 (SA10, Java V20): a pool deposit is a settlement to the treasurer of kind POOL_DEPOSIT.
  final String kind;
  const SettlementRow({
    required this.id,
    required this.groupId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountMinor,
    required this.settledOn,
    this.note,
    required this.createdByUserId,
    this.createdByMemberId,
    required this.createdAt,
    required this.status,
    required this.declaredAt,
    this.confirmedAt,
    this.disputedAt,
    this.cancelledAt,
    required this.recordedByAdmin,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['from_member_id'] = Variable<String>(fromMemberId);
    map['to_member_id'] = Variable<String>(toMemberId);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['settled_on'] = Variable<String>(settledOn);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_by_user_id'] = Variable<String>(createdByUserId);
    if (!nullToAbsent || createdByMemberId != null) {
      map['created_by_member_id'] = Variable<String>(createdByMemberId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['status'] = Variable<String>(status);
    map['declared_at'] = Variable<int>(declaredAt);
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<int>(confirmedAt);
    }
    if (!nullToAbsent || disputedAt != null) {
      map['disputed_at'] = Variable<int>(disputedAt);
    }
    if (!nullToAbsent || cancelledAt != null) {
      map['cancelled_at'] = Variable<int>(cancelledAt);
    }
    map['recorded_by_admin'] = Variable<int>(recordedByAdmin);
    map['kind'] = Variable<String>(kind);
    return map;
  }

  SettlementsCompanion toCompanion(bool nullToAbsent) {
    return SettlementsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      fromMemberId: Value(fromMemberId),
      toMemberId: Value(toMemberId),
      amountMinor: Value(amountMinor),
      settledOn: Value(settledOn),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdByUserId: Value(createdByUserId),
      createdByMemberId: createdByMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByMemberId),
      createdAt: Value(createdAt),
      status: Value(status),
      declaredAt: Value(declaredAt),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
      disputedAt: disputedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(disputedAt),
      cancelledAt: cancelledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelledAt),
      recordedByAdmin: Value(recordedByAdmin),
      kind: Value(kind),
    );
  }

  factory SettlementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettlementRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['group_id']),
      fromMemberId: serializer.fromJson<String>(json['from_member_id']),
      toMemberId: serializer.fromJson<String>(json['to_member_id']),
      amountMinor: serializer.fromJson<int>(json['amount_minor']),
      settledOn: serializer.fromJson<String>(json['settled_on']),
      note: serializer.fromJson<String?>(json['note']),
      createdByUserId: serializer.fromJson<String>(json['created_by_user_id']),
      createdByMemberId: serializer.fromJson<String?>(
        json['created_by_member_id'],
      ),
      createdAt: serializer.fromJson<int>(json['created_at']),
      status: serializer.fromJson<String>(json['status']),
      declaredAt: serializer.fromJson<int>(json['declared_at']),
      confirmedAt: serializer.fromJson<int?>(json['confirmed_at']),
      disputedAt: serializer.fromJson<int?>(json['disputed_at']),
      cancelledAt: serializer.fromJson<int?>(json['cancelled_at']),
      recordedByAdmin: serializer.fromJson<int>(json['recorded_by_admin']),
      kind: serializer.fromJson<String>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'group_id': serializer.toJson<String>(groupId),
      'from_member_id': serializer.toJson<String>(fromMemberId),
      'to_member_id': serializer.toJson<String>(toMemberId),
      'amount_minor': serializer.toJson<int>(amountMinor),
      'settled_on': serializer.toJson<String>(settledOn),
      'note': serializer.toJson<String?>(note),
      'created_by_user_id': serializer.toJson<String>(createdByUserId),
      'created_by_member_id': serializer.toJson<String?>(createdByMemberId),
      'created_at': serializer.toJson<int>(createdAt),
      'status': serializer.toJson<String>(status),
      'declared_at': serializer.toJson<int>(declaredAt),
      'confirmed_at': serializer.toJson<int?>(confirmedAt),
      'disputed_at': serializer.toJson<int?>(disputedAt),
      'cancelled_at': serializer.toJson<int?>(cancelledAt),
      'recorded_by_admin': serializer.toJson<int>(recordedByAdmin),
      'kind': serializer.toJson<String>(kind),
    };
  }

  SettlementRow copyWith({
    String? id,
    String? groupId,
    String? fromMemberId,
    String? toMemberId,
    int? amountMinor,
    String? settledOn,
    Value<String?> note = const Value.absent(),
    String? createdByUserId,
    Value<String?> createdByMemberId = const Value.absent(),
    int? createdAt,
    String? status,
    int? declaredAt,
    Value<int?> confirmedAt = const Value.absent(),
    Value<int?> disputedAt = const Value.absent(),
    Value<int?> cancelledAt = const Value.absent(),
    int? recordedByAdmin,
    String? kind,
  }) => SettlementRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    fromMemberId: fromMemberId ?? this.fromMemberId,
    toMemberId: toMemberId ?? this.toMemberId,
    amountMinor: amountMinor ?? this.amountMinor,
    settledOn: settledOn ?? this.settledOn,
    note: note.present ? note.value : this.note,
    createdByUserId: createdByUserId ?? this.createdByUserId,
    createdByMemberId: createdByMemberId.present
        ? createdByMemberId.value
        : this.createdByMemberId,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    declaredAt: declaredAt ?? this.declaredAt,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
    disputedAt: disputedAt.present ? disputedAt.value : this.disputedAt,
    cancelledAt: cancelledAt.present ? cancelledAt.value : this.cancelledAt,
    recordedByAdmin: recordedByAdmin ?? this.recordedByAdmin,
    kind: kind ?? this.kind,
  );
  SettlementRow copyWithCompanion(SettlementsCompanion data) {
    return SettlementRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      fromMemberId: data.fromMemberId.present
          ? data.fromMemberId.value
          : this.fromMemberId,
      toMemberId: data.toMemberId.present
          ? data.toMemberId.value
          : this.toMemberId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      settledOn: data.settledOn.present ? data.settledOn.value : this.settledOn,
      note: data.note.present ? data.note.value : this.note,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
      createdByMemberId: data.createdByMemberId.present
          ? data.createdByMemberId.value
          : this.createdByMemberId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      declaredAt: data.declaredAt.present
          ? data.declaredAt.value
          : this.declaredAt,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
      disputedAt: data.disputedAt.present
          ? data.disputedAt.value
          : this.disputedAt,
      cancelledAt: data.cancelledAt.present
          ? data.cancelledAt.value
          : this.cancelledAt,
      recordedByAdmin: data.recordedByAdmin.present
          ? data.recordedByAdmin.value
          : this.recordedByAdmin,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettlementRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('fromMemberId: $fromMemberId, ')
          ..write('toMemberId: $toMemberId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('settledOn: $settledOn, ')
          ..write('note: $note, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdByMemberId: $createdByMemberId, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('declaredAt: $declaredAt, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('disputedAt: $disputedAt, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('recordedByAdmin: $recordedByAdmin, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    fromMemberId,
    toMemberId,
    amountMinor,
    settledOn,
    note,
    createdByUserId,
    createdByMemberId,
    createdAt,
    status,
    declaredAt,
    confirmedAt,
    disputedAt,
    cancelledAt,
    recordedByAdmin,
    kind,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettlementRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.fromMemberId == this.fromMemberId &&
          other.toMemberId == this.toMemberId &&
          other.amountMinor == this.amountMinor &&
          other.settledOn == this.settledOn &&
          other.note == this.note &&
          other.createdByUserId == this.createdByUserId &&
          other.createdByMemberId == this.createdByMemberId &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.declaredAt == this.declaredAt &&
          other.confirmedAt == this.confirmedAt &&
          other.disputedAt == this.disputedAt &&
          other.cancelledAt == this.cancelledAt &&
          other.recordedByAdmin == this.recordedByAdmin &&
          other.kind == this.kind);
}

class SettlementsCompanion extends UpdateCompanion<SettlementRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> fromMemberId;
  final Value<String> toMemberId;
  final Value<int> amountMinor;
  final Value<String> settledOn;
  final Value<String?> note;
  final Value<String> createdByUserId;
  final Value<String?> createdByMemberId;
  final Value<int> createdAt;
  final Value<String> status;
  final Value<int> declaredAt;
  final Value<int?> confirmedAt;
  final Value<int?> disputedAt;
  final Value<int?> cancelledAt;
  final Value<int> recordedByAdmin;
  final Value<String> kind;
  final Value<int> rowid;
  const SettlementsCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.fromMemberId = const Value.absent(),
    this.toMemberId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.settledOn = const Value.absent(),
    this.note = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.createdByMemberId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.declaredAt = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.disputedAt = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.recordedByAdmin = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettlementsCompanion.insert({
    required String id,
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required int amountMinor,
    required String settledOn,
    this.note = const Value.absent(),
    required String createdByUserId,
    this.createdByMemberId = const Value.absent(),
    required int createdAt,
    required String status,
    required int declaredAt,
    this.confirmedAt = const Value.absent(),
    this.disputedAt = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.recordedByAdmin = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       fromMemberId = Value(fromMemberId),
       toMemberId = Value(toMemberId),
       amountMinor = Value(amountMinor),
       settledOn = Value(settledOn),
       createdByUserId = Value(createdByUserId),
       createdAt = Value(createdAt),
       status = Value(status),
       declaredAt = Value(declaredAt);
  static Insertable<SettlementRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? fromMemberId,
    Expression<String>? toMemberId,
    Expression<int>? amountMinor,
    Expression<String>? settledOn,
    Expression<String>? note,
    Expression<String>? createdByUserId,
    Expression<String>? createdByMemberId,
    Expression<int>? createdAt,
    Expression<String>? status,
    Expression<int>? declaredAt,
    Expression<int>? confirmedAt,
    Expression<int>? disputedAt,
    Expression<int>? cancelledAt,
    Expression<int>? recordedByAdmin,
    Expression<String>? kind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (fromMemberId != null) 'from_member_id': fromMemberId,
      if (toMemberId != null) 'to_member_id': toMemberId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (settledOn != null) 'settled_on': settledOn,
      if (note != null) 'note': note,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (createdByMemberId != null) 'created_by_member_id': createdByMemberId,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (declaredAt != null) 'declared_at': declaredAt,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (disputedAt != null) 'disputed_at': disputedAt,
      if (cancelledAt != null) 'cancelled_at': cancelledAt,
      if (recordedByAdmin != null) 'recorded_by_admin': recordedByAdmin,
      if (kind != null) 'kind': kind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettlementsCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? fromMemberId,
    Value<String>? toMemberId,
    Value<int>? amountMinor,
    Value<String>? settledOn,
    Value<String?>? note,
    Value<String>? createdByUserId,
    Value<String?>? createdByMemberId,
    Value<int>? createdAt,
    Value<String>? status,
    Value<int>? declaredAt,
    Value<int?>? confirmedAt,
    Value<int?>? disputedAt,
    Value<int?>? cancelledAt,
    Value<int>? recordedByAdmin,
    Value<String>? kind,
    Value<int>? rowid,
  }) {
    return SettlementsCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      fromMemberId: fromMemberId ?? this.fromMemberId,
      toMemberId: toMemberId ?? this.toMemberId,
      amountMinor: amountMinor ?? this.amountMinor,
      settledOn: settledOn ?? this.settledOn,
      note: note ?? this.note,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByMemberId: createdByMemberId ?? this.createdByMemberId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      declaredAt: declaredAt ?? this.declaredAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      disputedAt: disputedAt ?? this.disputedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      recordedByAdmin: recordedByAdmin ?? this.recordedByAdmin,
      kind: kind ?? this.kind,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (fromMemberId.present) {
      map['from_member_id'] = Variable<String>(fromMemberId.value);
    }
    if (toMemberId.present) {
      map['to_member_id'] = Variable<String>(toMemberId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (settledOn.present) {
      map['settled_on'] = Variable<String>(settledOn.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (createdByMemberId.present) {
      map['created_by_member_id'] = Variable<String>(createdByMemberId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (declaredAt.present) {
      map['declared_at'] = Variable<int>(declaredAt.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<int>(confirmedAt.value);
    }
    if (disputedAt.present) {
      map['disputed_at'] = Variable<int>(disputedAt.value);
    }
    if (cancelledAt.present) {
      map['cancelled_at'] = Variable<int>(cancelledAt.value);
    }
    if (recordedByAdmin.present) {
      map['recorded_by_admin'] = Variable<int>(recordedByAdmin.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettlementsCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('fromMemberId: $fromMemberId, ')
          ..write('toMemberId: $toMemberId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('settledOn: $settledOn, ')
          ..write('note: $note, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdByMemberId: $createdByMemberId, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('declaredAt: $declaredAt, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('disputedAt: $disputedAt, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('recordedByAdmin: $recordedByAdmin, ')
          ..write('kind: $kind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PaymentHandles extends Table
    with TableInfo<PaymentHandles, PaymentHandleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PaymentHandles(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 36)',
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES local_profile(id)',
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (type IN (\'INSTAPAY\', \'WALLET\'))',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    type,
    value,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payment_handles';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentHandleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {userId, type},
  ];
  @override
  PaymentHandleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentHandleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  PaymentHandles createAlias(String alias) {
    return PaymentHandles(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const [
    'CONSTRAINT uq_payment_handles_user_type UNIQUE(user_id, type)',
    'CONSTRAINT ck_payment_handles_wallet CHECK(type <> \'WALLET\' OR value GLOB \'01[0125][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]\')',
    'CONSTRAINT ck_payment_handles_instapay CHECK(type <> \'INSTAPAY\' OR((length(value) BETWEEN 3 AND 60 AND value GLOB \'?*@?*\' AND value NOT GLOB \'*@*@*\' AND value NOT GLOB \'*[^a-z0-9._@-]*\' AND value NOT GLOB \'*@*_*\')OR(length(value) BETWEEN 16 AND 200 AND value GLOB \'https://ipn.eg/?*\' AND value NOT GLOB \'*[^A-Za-z0-9._~:/?#@!\$&=%+-]*\')))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class PaymentHandleRow extends DataClass
    implements Insertable<PaymentHandleRow> {
  final String id;
  final String userId;
  final String type;
  final String value;
  final int createdAt;
  final int updatedAt;
  const PaymentHandleRow({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['type'] = Variable<String>(type);
    map['value'] = Variable<String>(value);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PaymentHandlesCompanion toCompanion(bool nullToAbsent) {
    return PaymentHandlesCompanion(
      id: Value(id),
      userId: Value(userId),
      type: Value(type),
      value: Value(value),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PaymentHandleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentHandleRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['user_id']),
      type: serializer.fromJson<String>(json['type']),
      value: serializer.fromJson<String>(json['value']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String>(userId),
      'type': serializer.toJson<String>(type),
      'value': serializer.toJson<String>(value),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
    };
  }

  PaymentHandleRow copyWith({
    String? id,
    String? userId,
    String? type,
    String? value,
    int? createdAt,
    int? updatedAt,
  }) => PaymentHandleRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    value: value ?? this.value,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PaymentHandleRow copyWithCompanion(PaymentHandlesCompanion data) {
    return PaymentHandleRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      type: data.type.present ? data.type.value : this.type,
      value: data.value.present ? data.value.value : this.value,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentHandleRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, type, value, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentHandleRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.value == this.value &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PaymentHandlesCompanion extends UpdateCompanion<PaymentHandleRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> type;
  final Value<String> value;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const PaymentHandlesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.value = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentHandlesCompanion.insert({
    required String id,
    required String userId,
    required String type,
    required String value,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       type = Value(type),
       value = Value(value),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PaymentHandleRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? type,
    Expression<String>? value,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (value != null) 'value': value,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentHandlesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? type,
    Value<String>? value,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return PaymentHandlesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentHandlesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class IdempotencyKeys extends Table
    with TableInfo<IdempotencyKeys, IdempotencyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  IdempotencyKeys(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length("key") = 36)',
  );
  static const VerificationMeta _endpointMeta = const VerificationMeta(
    'endpoint',
  );
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _requestHashMeta = const VerificationMeta(
    'requestHash',
  );
  late final GeneratedColumn<String> requestHash = GeneratedColumn<String>(
    'request_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _responseStatusMeta = const VerificationMeta(
    'responseStatus',
  );
  late final GeneratedColumn<int> responseStatus = GeneratedColumn<int>(
    'response_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (response_status BETWEEN 100 AND 599)',
  );
  static const VerificationMeta _responseBodyMeta = const VerificationMeta(
    'responseBody',
  );
  late final GeneratedColumn<String> responseBody = GeneratedColumn<String>(
    'response_body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (json_valid(response_body))',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    endpoint,
    requestHash,
    responseStatus,
    responseBody,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'idempotency_keys';
  @override
  VerificationContext validateIntegrity(
    Insertable<IdempotencyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(
        _endpointMeta,
        endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta),
      );
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('request_hash')) {
      context.handle(
        _requestHashMeta,
        requestHash.isAcceptableOrUnknown(
          data['request_hash']!,
          _requestHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestHashMeta);
    }
    if (data.containsKey('response_status')) {
      context.handle(
        _responseStatusMeta,
        responseStatus.isAcceptableOrUnknown(
          data['response_status']!,
          _responseStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responseStatusMeta);
    }
    if (data.containsKey('response_body')) {
      context.handle(
        _responseBodyMeta,
        responseBody.isAcceptableOrUnknown(
          data['response_body']!,
          _responseBodyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responseBodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  IdempotencyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IdempotencyRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      endpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint'],
      )!,
      requestHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_hash'],
      )!,
      responseStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_status'],
      )!,
      responseBody: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  IdempotencyKeys createAlias(String alias) {
    return IdempotencyKeys(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class IdempotencyRow extends DataClass implements Insertable<IdempotencyRow> {
  final String key;
  final String endpoint;
  final String requestHash;
  final int responseStatus;
  final String responseBody;
  final int createdAt;
  const IdempotencyRow({
    required this.key,
    required this.endpoint,
    required this.requestHash,
    required this.responseStatus,
    required this.responseBody,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['endpoint'] = Variable<String>(endpoint);
    map['request_hash'] = Variable<String>(requestHash);
    map['response_status'] = Variable<int>(responseStatus);
    map['response_body'] = Variable<String>(responseBody);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  IdempotencyKeysCompanion toCompanion(bool nullToAbsent) {
    return IdempotencyKeysCompanion(
      key: Value(key),
      endpoint: Value(endpoint),
      requestHash: Value(requestHash),
      responseStatus: Value(responseStatus),
      responseBody: Value(responseBody),
      createdAt: Value(createdAt),
    );
  }

  factory IdempotencyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IdempotencyRow(
      key: serializer.fromJson<String>(json['key']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      requestHash: serializer.fromJson<String>(json['request_hash']),
      responseStatus: serializer.fromJson<int>(json['response_status']),
      responseBody: serializer.fromJson<String>(json['response_body']),
      createdAt: serializer.fromJson<int>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'endpoint': serializer.toJson<String>(endpoint),
      'request_hash': serializer.toJson<String>(requestHash),
      'response_status': serializer.toJson<int>(responseStatus),
      'response_body': serializer.toJson<String>(responseBody),
      'created_at': serializer.toJson<int>(createdAt),
    };
  }

  IdempotencyRow copyWith({
    String? key,
    String? endpoint,
    String? requestHash,
    int? responseStatus,
    String? responseBody,
    int? createdAt,
  }) => IdempotencyRow(
    key: key ?? this.key,
    endpoint: endpoint ?? this.endpoint,
    requestHash: requestHash ?? this.requestHash,
    responseStatus: responseStatus ?? this.responseStatus,
    responseBody: responseBody ?? this.responseBody,
    createdAt: createdAt ?? this.createdAt,
  );
  IdempotencyRow copyWithCompanion(IdempotencyKeysCompanion data) {
    return IdempotencyRow(
      key: data.key.present ? data.key.value : this.key,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      requestHash: data.requestHash.present
          ? data.requestHash.value
          : this.requestHash,
      responseStatus: data.responseStatus.present
          ? data.responseStatus.value
          : this.responseStatus,
      responseBody: data.responseBody.present
          ? data.responseBody.value
          : this.responseBody,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IdempotencyRow(')
          ..write('key: $key, ')
          ..write('endpoint: $endpoint, ')
          ..write('requestHash: $requestHash, ')
          ..write('responseStatus: $responseStatus, ')
          ..write('responseBody: $responseBody, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    key,
    endpoint,
    requestHash,
    responseStatus,
    responseBody,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdempotencyRow &&
          other.key == this.key &&
          other.endpoint == this.endpoint &&
          other.requestHash == this.requestHash &&
          other.responseStatus == this.responseStatus &&
          other.responseBody == this.responseBody &&
          other.createdAt == this.createdAt);
}

class IdempotencyKeysCompanion extends UpdateCompanion<IdempotencyRow> {
  final Value<String> key;
  final Value<String> endpoint;
  final Value<String> requestHash;
  final Value<int> responseStatus;
  final Value<String> responseBody;
  final Value<int> createdAt;
  final Value<int> rowid;
  const IdempotencyKeysCompanion({
    this.key = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.requestHash = const Value.absent(),
    this.responseStatus = const Value.absent(),
    this.responseBody = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IdempotencyKeysCompanion.insert({
    required String key,
    required String endpoint,
    required String requestHash,
    required int responseStatus,
    required String responseBody,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       endpoint = Value(endpoint),
       requestHash = Value(requestHash),
       responseStatus = Value(responseStatus),
       responseBody = Value(responseBody),
       createdAt = Value(createdAt);
  static Insertable<IdempotencyRow> custom({
    Expression<String>? key,
    Expression<String>? endpoint,
    Expression<String>? requestHash,
    Expression<int>? responseStatus,
    Expression<String>? responseBody,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (endpoint != null) 'endpoint': endpoint,
      if (requestHash != null) 'request_hash': requestHash,
      if (responseStatus != null) 'response_status': responseStatus,
      if (responseBody != null) 'response_body': responseBody,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IdempotencyKeysCompanion copyWith({
    Value<String>? key,
    Value<String>? endpoint,
    Value<String>? requestHash,
    Value<int>? responseStatus,
    Value<String>? responseBody,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return IdempotencyKeysCompanion(
      key: key ?? this.key,
      endpoint: endpoint ?? this.endpoint,
      requestHash: requestHash ?? this.requestHash,
      responseStatus: responseStatus ?? this.responseStatus,
      responseBody: responseBody ?? this.responseBody,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (requestHash.present) {
      map['request_hash'] = Variable<String>(requestHash.value);
    }
    if (responseStatus.present) {
      map['response_status'] = Variable<int>(responseStatus.value);
    }
    if (responseBody.present) {
      map['response_body'] = Variable<String>(responseBody.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IdempotencyKeysCompanion(')
          ..write('key: $key, ')
          ..write('endpoint: $endpoint, ')
          ..write('requestHash: $requestHash, ')
          ..write('responseStatus: $responseStatus, ')
          ..write('responseBody: $responseBody, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class FuelPrices extends Table with TableInfo<FuelPrices, FuelPriceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  FuelPrices(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fuelTypeMeta = const VerificationMeta(
    'fuelType',
  );
  late final GeneratedColumn<String> fuelType = GeneratedColumn<String>(
    'fuel_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (fuel_type IN (\'GASOLINE_80\', \'GASOLINE_92\', \'GASOLINE_95\', \'DIESEL\'))',
  );
  static const VerificationMeta _pricePerLitreMinorMeta =
      const VerificationMeta('pricePerLitreMinor');
  late final GeneratedColumn<int> pricePerLitreMinor = GeneratedColumn<int>(
    'price_per_litre_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (price_per_litre_minor BETWEEN 1 AND 100000)',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    fuelType,
    pricePerLitreMinor,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fuel_prices';
  @override
  VerificationContext validateIntegrity(
    Insertable<FuelPriceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('fuel_type')) {
      context.handle(
        _fuelTypeMeta,
        fuelType.isAcceptableOrUnknown(data['fuel_type']!, _fuelTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fuelTypeMeta);
    }
    if (data.containsKey('price_per_litre_minor')) {
      context.handle(
        _pricePerLitreMinorMeta,
        pricePerLitreMinor.isAcceptableOrUnknown(
          data['price_per_litre_minor']!,
          _pricePerLitreMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricePerLitreMinorMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fuelType};
  @override
  FuelPriceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FuelPriceRow(
      fuelType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fuel_type'],
      )!,
      pricePerLitreMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_per_litre_minor'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  FuelPrices createAlias(String alias) {
    return FuelPrices(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class FuelPriceRow extends DataClass implements Insertable<FuelPriceRow> {
  final String fuelType;
  final int pricePerLitreMinor;
  final int updatedAt;
  const FuelPriceRow({
    required this.fuelType,
    required this.pricePerLitreMinor,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['fuel_type'] = Variable<String>(fuelType);
    map['price_per_litre_minor'] = Variable<int>(pricePerLitreMinor);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  FuelPricesCompanion toCompanion(bool nullToAbsent) {
    return FuelPricesCompanion(
      fuelType: Value(fuelType),
      pricePerLitreMinor: Value(pricePerLitreMinor),
      updatedAt: Value(updatedAt),
    );
  }

  factory FuelPriceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FuelPriceRow(
      fuelType: serializer.fromJson<String>(json['fuel_type']),
      pricePerLitreMinor: serializer.fromJson<int>(
        json['price_per_litre_minor'],
      ),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fuel_type': serializer.toJson<String>(fuelType),
      'price_per_litre_minor': serializer.toJson<int>(pricePerLitreMinor),
      'updated_at': serializer.toJson<int>(updatedAt),
    };
  }

  FuelPriceRow copyWith({
    String? fuelType,
    int? pricePerLitreMinor,
    int? updatedAt,
  }) => FuelPriceRow(
    fuelType: fuelType ?? this.fuelType,
    pricePerLitreMinor: pricePerLitreMinor ?? this.pricePerLitreMinor,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FuelPriceRow copyWithCompanion(FuelPricesCompanion data) {
    return FuelPriceRow(
      fuelType: data.fuelType.present ? data.fuelType.value : this.fuelType,
      pricePerLitreMinor: data.pricePerLitreMinor.present
          ? data.pricePerLitreMinor.value
          : this.pricePerLitreMinor,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FuelPriceRow(')
          ..write('fuelType: $fuelType, ')
          ..write('pricePerLitreMinor: $pricePerLitreMinor, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fuelType, pricePerLitreMinor, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FuelPriceRow &&
          other.fuelType == this.fuelType &&
          other.pricePerLitreMinor == this.pricePerLitreMinor &&
          other.updatedAt == this.updatedAt);
}

class FuelPricesCompanion extends UpdateCompanion<FuelPriceRow> {
  final Value<String> fuelType;
  final Value<int> pricePerLitreMinor;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const FuelPricesCompanion({
    this.fuelType = const Value.absent(),
    this.pricePerLitreMinor = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FuelPricesCompanion.insert({
    required String fuelType,
    required int pricePerLitreMinor,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : fuelType = Value(fuelType),
       pricePerLitreMinor = Value(pricePerLitreMinor),
       updatedAt = Value(updatedAt);
  static Insertable<FuelPriceRow> custom({
    Expression<String>? fuelType,
    Expression<int>? pricePerLitreMinor,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fuelType != null) 'fuel_type': fuelType,
      if (pricePerLitreMinor != null)
        'price_per_litre_minor': pricePerLitreMinor,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FuelPricesCompanion copyWith({
    Value<String>? fuelType,
    Value<int>? pricePerLitreMinor,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return FuelPricesCompanion(
      fuelType: fuelType ?? this.fuelType,
      pricePerLitreMinor: pricePerLitreMinor ?? this.pricePerLitreMinor,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fuelType.present) {
      map['fuel_type'] = Variable<String>(fuelType.value);
    }
    if (pricePerLitreMinor.present) {
      map['price_per_litre_minor'] = Variable<int>(pricePerLitreMinor.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FuelPricesCompanion(')
          ..write('fuelType: $fuelType, ')
          ..write('pricePerLitreMinor: $pricePerLitreMinor, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final LocalProfile localProfile = LocalProfile(this);
  late final LocalMeta localMeta = LocalMeta(this);
  late final Members members = Members(this);
  late final ExpenseGroups expenseGroups = ExpenseGroups(this);
  late final Index ixExpenseGroupsOwnerCreated = Index(
    'ix_expense_groups_owner_created',
    'CREATE INDEX ix_expense_groups_owner_created ON expense_groups (owner_user_id, created_at DESC, id DESC)',
  );
  late final Trigger expenseGroupsTreasurerInsert = Trigger(
    'CREATE TRIGGER expense_groups_treasurer_insert BEFORE INSERT ON expense_groups WHEN NEW.treasurer_member_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM members WHERE id = NEW.treasurer_member_id AND group_id = NEW.id) BEGIN SELECT RAISE (ABORT, \'the treasurer must be a member of the same group\');END',
    'expense_groups_treasurer_insert',
  );
  late final Trigger expenseGroupsTreasurerUpdate = Trigger(
    'CREATE TRIGGER expense_groups_treasurer_update BEFORE UPDATE OF treasurer_member_id ON expense_groups WHEN NEW.treasurer_member_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM members WHERE id = NEW.treasurer_member_id AND group_id = NEW.id) BEGIN SELECT RAISE (ABORT, \'the treasurer must be a member of the same group\');END',
    'expense_groups_treasurer_update',
  );
  late final Index uxMembersGroupUser = Index(
    'ux_members_group_user',
    'CREATE UNIQUE INDEX ux_members_group_user ON members (group_id, user_id) WHERE user_id IS NOT NULL',
  );
  late final Index uxMembersGroupOwner = Index(
    'ux_members_group_owner',
    'CREATE UNIQUE INDEX ux_members_group_owner ON members (group_id) WHERE role = \'OWNER\'',
  );
  late final Expenses expenses = Expenses(this);
  late final Index ixExpensesGroupList = Index(
    'ix_expenses_group_list',
    'CREATE INDEX ix_expenses_group_list ON expenses (group_id, expense_date DESC, created_at DESC, id DESC) WHERE deleted_at IS NULL',
  );
  late final Index ixExpensesGroupCategory = Index(
    'ix_expenses_group_category',
    'CREATE INDEX ix_expenses_group_category ON expenses (group_id, category) WHERE deleted_at IS NULL',
  );
  late final Index ixExpensesGroup = Index(
    'ix_expenses_group',
    'CREATE INDEX ix_expenses_group ON expenses (group_id)',
  );
  late final Index ixExpensesPool = Index(
    'ix_expenses_pool',
    'CREATE INDEX ix_expenses_pool ON expenses (group_id) WHERE paid_from_pool = 1',
  );
  late final ExpensePayers expensePayers = ExpensePayers(this);
  late final Index ixExpensePayersMember = Index(
    'ix_expense_payers_member',
    'CREATE INDEX ix_expense_payers_member ON expense_payers (member_id)',
  );
  late final ExpenseSplits expenseSplits = ExpenseSplits(this);
  late final Index ixExpenseSplitsMember = Index(
    'ix_expense_splits_member',
    'CREATE INDEX ix_expense_splits_member ON expense_splits (member_id)',
  );
  late final ExpenseItems expenseItems = ExpenseItems(this);
  late final ExpenseItemAssignees expenseItemAssignees = ExpenseItemAssignees(
    this,
  );
  late final Index ixExpenseItemAssigneesMember = Index(
    'ix_expense_item_assignees_member',
    'CREATE INDEX ix_expense_item_assignees_member ON expense_item_assignees (member_id)',
  );
  late final ExpenseRevisions expenseRevisions = ExpenseRevisions(this);
  late final Trigger expenseRevisionsAppendOnly = Trigger(
    'CREATE TRIGGER expense_revisions_append_only BEFORE UPDATE ON expense_revisions BEGIN SELECT RAISE (ABORT, \'expense_revisions are append-only\');END',
    'expense_revisions_append_only',
  );
  late final Settlements settlements = Settlements(this);
  late final Index ixSettlementsGroupList = Index(
    'ix_settlements_group_list',
    'CREATE INDEX ix_settlements_group_list ON settlements (group_id, settled_on DESC, created_at DESC, id DESC)',
  );
  late final Index ixSettlementsGroupConfirmed = Index(
    'ix_settlements_group_confirmed',
    'CREATE INDEX ix_settlements_group_confirmed ON settlements (group_id) WHERE status = \'CONFIRMED\'',
  );
  late final Index ixSettlementsFromMember = Index(
    'ix_settlements_from_member',
    'CREATE INDEX ix_settlements_from_member ON settlements (from_member_id)',
  );
  late final Index ixSettlementsToMember = Index(
    'ix_settlements_to_member',
    'CREATE INDEX ix_settlements_to_member ON settlements (to_member_id)',
  );
  late final Index ixSettlementsDeposits = Index(
    'ix_settlements_deposits',
    'CREATE INDEX ix_settlements_deposits ON settlements (group_id) WHERE kind = \'POOL_DEPOSIT\'',
  );
  late final PaymentHandles paymentHandles = PaymentHandles(this);
  late final IdempotencyKeys idempotencyKeys = IdempotencyKeys(this);
  late final Index ixIdempotencyKeysCreated = Index(
    'ix_idempotency_keys_created',
    'CREATE INDEX ix_idempotency_keys_created ON idempotency_keys (created_at)',
  );
  late final FuelPrices fuelPrices = FuelPrices(this);
  late final ProfileDao profileDao = ProfileDao(this as LocalDatabase);
  late final MetaDao metaDao = MetaDao(this as LocalDatabase);
  late final GroupsDao groupsDao = GroupsDao(this as LocalDatabase);
  late final MembersDao membersDao = MembersDao(this as LocalDatabase);
  late final ExpensesDao expensesDao = ExpensesDao(this as LocalDatabase);
  late final RevisionsDao revisionsDao = RevisionsDao(this as LocalDatabase);
  late final SettlementsDao settlementsDao = SettlementsDao(
    this as LocalDatabase,
  );
  late final PaymentHandlesDao paymentHandlesDao = PaymentHandlesDao(
    this as LocalDatabase,
  );
  late final IdempotencyDao idempotencyDao = IdempotencyDao(
    this as LocalDatabase,
  );
  late final FuelPricesDao fuelPricesDao = FuelPricesDao(this as LocalDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localProfile,
    localMeta,
    members,
    expenseGroups,
    ixExpenseGroupsOwnerCreated,
    expenseGroupsTreasurerInsert,
    expenseGroupsTreasurerUpdate,
    uxMembersGroupUser,
    uxMembersGroupOwner,
    expenses,
    ixExpensesGroupList,
    ixExpensesGroupCategory,
    ixExpensesGroup,
    ixExpensesPool,
    expensePayers,
    ixExpensePayersMember,
    expenseSplits,
    ixExpenseSplitsMember,
    expenseItems,
    expenseItemAssignees,
    ixExpenseItemAssigneesMember,
    expenseRevisions,
    expenseRevisionsAppendOnly,
    settlements,
    ixSettlementsGroupList,
    ixSettlementsGroupConfirmed,
    ixSettlementsFromMember,
    ixSettlementsToMember,
    ixSettlementsDeposits,
    paymentHandles,
    idempotencyKeys,
    ixIdempotencyKeysCreated,
    fuelPrices,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'expense_groups',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'expense_groups',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'expense_revisions',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
  ]);
}

typedef $LocalProfileCreateCompanionBuilder = LocalProfileCompanion Function({
  required String id,
  required String displayName,
  required int createdAt,
  required int updatedAt,
  Value<int> singleton,
  Value<int> rowid,
});
typedef $LocalProfileUpdateCompanionBuilder = LocalProfileCompanion Function({
  Value<String> id,
  Value<String> displayName,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> singleton,
  Value<int> rowid,
});

final class $LocalProfileReferences
    extends BaseReferences<_$LocalDatabase, LocalProfile, LocalProfileRow> {
  $LocalProfileReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<Members, List<MemberRow>> _membersRefsTable(
    _$LocalDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.members,
    aliasName: 'local_profile__id__members__user_id',
  );

  $MembersProcessedTableManager get membersRefs {
    final manager = $MembersTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_membersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ExpenseGroups, List<GroupRow>>
  _expenseGroupsRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.expenseGroups,
    aliasName: 'local_profile__id__expense_groups__owner_user_id',
  );

  $ExpenseGroupsProcessedTableManager get expenseGroupsRefs {
    final manager = $ExpenseGroupsTableManager(
      $_db,
      $_db.expenseGroups,
    ).filter((f) => f.ownerUserId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expenseGroupsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Expenses, List<ExpenseRow>> _expensesRefsTable(
    _$LocalDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: 'local_profile__id__expenses__created_by_user_id',
  );

  $ExpensesProcessedTableManager get expensesRefs {
    final manager = $ExpensesTableManager($_db, $_db.expenses).filter(
      (f) => f.createdByUserId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ExpenseRevisions, List<RevisionRow>>
  _expenseRevisionsRefsTable(_$LocalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.expenseRevisions,
        aliasName: 'local_profile__id__expense_revisions__changed_by_user_id',
      );

  $ExpenseRevisionsProcessedTableManager get expenseRevisionsRefs {
    final manager = $ExpenseRevisionsTableManager($_db, $_db.expenseRevisions)
        .filter(
          (f) => f.changedByUserId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _expenseRevisionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Settlements, List<SettlementRow>>
  _settlementsRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.settlements,
    aliasName: 'local_profile__id__settlements__created_by_user_id',
  );

  $SettlementsProcessedTableManager get settlementsRefs {
    final manager = $SettlementsTableManager($_db, $_db.settlements).filter(
      (f) => f.createdByUserId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_settlementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<PaymentHandles, List<PaymentHandleRow>>
  _paymentHandlesRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.paymentHandles,
    aliasName: 'local_profile__id__payment_handles__user_id',
  );

  $PaymentHandlesProcessedTableManager get paymentHandlesRefs {
    final manager = $PaymentHandlesTableManager(
      $_db,
      $_db.paymentHandles,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentHandlesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $LocalProfileFilterComposer
    extends Composer<_$LocalDatabase, LocalProfile> {
  $LocalProfileFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get singleton => $composableBuilder(
    column: $table.singleton,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> membersRefs(
    Expression<bool> Function($MembersFilterComposer f) f,
  ) {
    final $MembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expenseGroupsRefs(
    Expression<bool> Function($ExpenseGroupsFilterComposer f) f,
  ) {
    final $ExpenseGroupsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseGroups,
      getReferencedColumn: (t) => t.ownerUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseGroupsFilterComposer(
            $db: $db,
            $table: $db.expenseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($ExpensesFilterComposer f) f,
  ) {
    final $ExpensesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.createdByUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensesFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expenseRevisionsRefs(
    Expression<bool> Function($ExpenseRevisionsFilterComposer f) f,
  ) {
    final $ExpenseRevisionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseRevisions,
      getReferencedColumn: (t) => t.changedByUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseRevisionsFilterComposer(
            $db: $db,
            $table: $db.expenseRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> settlementsRefs(
    Expression<bool> Function($SettlementsFilterComposer f) f,
  ) {
    final $SettlementsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.settlements,
      getReferencedColumn: (t) => t.createdByUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SettlementsFilterComposer(
            $db: $db,
            $table: $db.settlements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> paymentHandlesRefs(
    Expression<bool> Function($PaymentHandlesFilterComposer f) f,
  ) {
    final $PaymentHandlesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.paymentHandles,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PaymentHandlesFilterComposer(
            $db: $db,
            $table: $db.paymentHandles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $LocalProfileOrderingComposer
    extends Composer<_$LocalDatabase, LocalProfile> {
  $LocalProfileOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get singleton => $composableBuilder(
    column: $table.singleton,
    builder: (column) => ColumnOrderings(column),
  );
}

class $LocalProfileAnnotationComposer
    extends Composer<_$LocalDatabase, LocalProfile> {
  $LocalProfileAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get singleton =>
      $composableBuilder(column: $table.singleton, builder: (column) => column);

  Expression<T> membersRefs<T extends Object>(
    Expression<T> Function($MembersAnnotationComposer a) f,
  ) {
    final $MembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expenseGroupsRefs<T extends Object>(
    Expression<T> Function($ExpenseGroupsAnnotationComposer a) f,
  ) {
    final $ExpenseGroupsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseGroups,
      getReferencedColumn: (t) => t.ownerUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseGroupsAnnotationComposer(
            $db: $db,
            $table: $db.expenseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($ExpensesAnnotationComposer a) f,
  ) {
    final $ExpensesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.createdByUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensesAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expenseRevisionsRefs<T extends Object>(
    Expression<T> Function($ExpenseRevisionsAnnotationComposer a) f,
  ) {
    final $ExpenseRevisionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseRevisions,
      getReferencedColumn: (t) => t.changedByUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseRevisionsAnnotationComposer(
            $db: $db,
            $table: $db.expenseRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> settlementsRefs<T extends Object>(
    Expression<T> Function($SettlementsAnnotationComposer a) f,
  ) {
    final $SettlementsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.settlements,
      getReferencedColumn: (t) => t.createdByUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SettlementsAnnotationComposer(
            $db: $db,
            $table: $db.settlements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> paymentHandlesRefs<T extends Object>(
    Expression<T> Function($PaymentHandlesAnnotationComposer a) f,
  ) {
    final $PaymentHandlesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.paymentHandles,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PaymentHandlesAnnotationComposer(
            $db: $db,
            $table: $db.paymentHandles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $LocalProfileTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          LocalProfile,
          LocalProfileRow,
          $LocalProfileFilterComposer,
          $LocalProfileOrderingComposer,
          $LocalProfileAnnotationComposer,
          $LocalProfileCreateCompanionBuilder,
          $LocalProfileUpdateCompanionBuilder,
          (LocalProfileRow, $LocalProfileReferences),
          LocalProfileRow,
          PrefetchHooks Function({
            bool membersRefs,
            bool expenseGroupsRefs,
            bool expensesRefs,
            bool expenseRevisionsRefs,
            bool settlementsRefs,
            bool paymentHandlesRefs,
          })
        > {
  $LocalProfileTableManager(_$LocalDatabase db, LocalProfile table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LocalProfileFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LocalProfileOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LocalProfileAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> singleton = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProfileCompanion(
                id: id,
                displayName: displayName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                singleton: singleton,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required int createdAt,
                required int updatedAt,
                Value<int> singleton = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProfileCompanion.insert(
                id: id,
                displayName: displayName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                singleton: singleton,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<LocalProfile, LocalProfileRow>(table),
                  $LocalProfileReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                membersRefs = false,
                expenseGroupsRefs = false,
                expensesRefs = false,
                expenseRevisionsRefs = false,
                settlementsRefs = false,
                paymentHandlesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (membersRefs) db.members,
                    if (expenseGroupsRefs) db.expenseGroups,
                    if (expensesRefs) db.expenses,
                    if (expenseRevisionsRefs) db.expenseRevisions,
                    if (settlementsRefs) db.settlements,
                    if (paymentHandlesRefs) db.paymentHandles,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (membersRefs)
                        await $_getPrefetchedDataByColumns<
                          LocalProfileRow,
                          LocalProfile,
                          MemberRow,
                          Members
                        >(
                          currentTable: table,
                          referencedTable: $LocalProfileReferences
                              ._membersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $LocalProfileReferences(
                                db,
                                table,
                                p0,
                              ).membersRefs,
                          currentColumn: 'id',
                          referencedColumn: 'user_id',
                          typedResults: items,
                        ),
                      if (expenseGroupsRefs)
                        await $_getPrefetchedDataByColumns<
                          LocalProfileRow,
                          LocalProfile,
                          GroupRow,
                          ExpenseGroups
                        >(
                          currentTable: table,
                          referencedTable: $LocalProfileReferences
                              ._expenseGroupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $LocalProfileReferences(
                                db,
                                table,
                                p0,
                              ).expenseGroupsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'owner_user_id',
                          typedResults: items,
                        ),
                      if (expensesRefs)
                        await $_getPrefetchedDataByColumns<
                          LocalProfileRow,
                          LocalProfile,
                          ExpenseRow,
                          Expenses
                        >(
                          currentTable: table,
                          referencedTable: $LocalProfileReferences
                              ._expensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $LocalProfileReferences(
                                db,
                                table,
                                p0,
                              ).expensesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'created_by_user_id',
                          typedResults: items,
                        ),
                      if (expenseRevisionsRefs)
                        await $_getPrefetchedDataByColumns<
                          LocalProfileRow,
                          LocalProfile,
                          RevisionRow,
                          ExpenseRevisions
                        >(
                          currentTable: table,
                          referencedTable: $LocalProfileReferences
                              ._expenseRevisionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $LocalProfileReferences(
                                db,
                                table,
                                p0,
                              ).expenseRevisionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'changed_by_user_id',
                          typedResults: items,
                        ),
                      if (settlementsRefs)
                        await $_getPrefetchedDataByColumns<
                          LocalProfileRow,
                          LocalProfile,
                          SettlementRow,
                          Settlements
                        >(
                          currentTable: table,
                          referencedTable: $LocalProfileReferences
                              ._settlementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $LocalProfileReferences(
                                db,
                                table,
                                p0,
                              ).settlementsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'created_by_user_id',
                          typedResults: items,
                        ),
                      if (paymentHandlesRefs)
                        await $_getPrefetchedDataByColumns<
                          LocalProfileRow,
                          LocalProfile,
                          PaymentHandleRow,
                          PaymentHandles
                        >(
                          currentTable: table,
                          referencedTable: $LocalProfileReferences
                              ._paymentHandlesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $LocalProfileReferences(
                                db,
                                table,
                                p0,
                              ).paymentHandlesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'user_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $LocalProfileProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      LocalProfile,
      LocalProfileRow,
      $LocalProfileFilterComposer,
      $LocalProfileOrderingComposer,
      $LocalProfileAnnotationComposer,
      $LocalProfileCreateCompanionBuilder,
      $LocalProfileUpdateCompanionBuilder,
      (LocalProfileRow, $LocalProfileReferences),
      LocalProfileRow,
      PrefetchHooks Function({
        bool membersRefs,
        bool expenseGroupsRefs,
        bool expensesRefs,
        bool expenseRevisionsRefs,
        bool settlementsRefs,
        bool paymentHandlesRefs,
      })
    >;
typedef $LocalMetaCreateCompanionBuilder = LocalMetaCompanion Function({
  Value<int> id,
  required int createdSchemaVersion,
  required int createdAt,
  Value<int?> lastExportAt,
  Value<int?> lastExportFormatVersion,
  Value<int?> backupReminderSnoozedUntil,
  Value<String?> lastReminderTone,
  Value<int?> ocrConsentAt,
  Value<String?> ocrScanDay,
  Value<int> ocrScanCount,
  Value<int> ocrPermissionErrors,
  Value<int?> ocrHiddenUntil,
  Value<int> archiveRetentionDays,
});
typedef $LocalMetaUpdateCompanionBuilder = LocalMetaCompanion Function({
  Value<int> id,
  Value<int> createdSchemaVersion,
  Value<int> createdAt,
  Value<int?> lastExportAt,
  Value<int?> lastExportFormatVersion,
  Value<int?> backupReminderSnoozedUntil,
  Value<String?> lastReminderTone,
  Value<int?> ocrConsentAt,
  Value<String?> ocrScanDay,
  Value<int> ocrScanCount,
  Value<int> ocrPermissionErrors,
  Value<int?> ocrHiddenUntil,
  Value<int> archiveRetentionDays,
});

class $LocalMetaFilterComposer extends Composer<_$LocalDatabase, LocalMeta> {
  $LocalMetaFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdSchemaVersion => $composableBuilder(
    column: $table.createdSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastExportAt => $composableBuilder(
    column: $table.lastExportAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastExportFormatVersion => $composableBuilder(
    column: $table.lastExportFormatVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get backupReminderSnoozedUntil => $composableBuilder(
    column: $table.backupReminderSnoozedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastReminderTone => $composableBuilder(
    column: $table.lastReminderTone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ocrConsentAt => $composableBuilder(
    column: $table.ocrConsentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrScanDay => $composableBuilder(
    column: $table.ocrScanDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ocrScanCount => $composableBuilder(
    column: $table.ocrScanCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ocrPermissionErrors => $composableBuilder(
    column: $table.ocrPermissionErrors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ocrHiddenUntil => $composableBuilder(
    column: $table.ocrHiddenUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archiveRetentionDays => $composableBuilder(
    column: $table.archiveRetentionDays,
    builder: (column) => ColumnFilters(column),
  );
}

class $LocalMetaOrderingComposer extends Composer<_$LocalDatabase, LocalMeta> {
  $LocalMetaOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdSchemaVersion => $composableBuilder(
    column: $table.createdSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastExportAt => $composableBuilder(
    column: $table.lastExportAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastExportFormatVersion => $composableBuilder(
    column: $table.lastExportFormatVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get backupReminderSnoozedUntil => $composableBuilder(
    column: $table.backupReminderSnoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastReminderTone => $composableBuilder(
    column: $table.lastReminderTone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ocrConsentAt => $composableBuilder(
    column: $table.ocrConsentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrScanDay => $composableBuilder(
    column: $table.ocrScanDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ocrScanCount => $composableBuilder(
    column: $table.ocrScanCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ocrPermissionErrors => $composableBuilder(
    column: $table.ocrPermissionErrors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ocrHiddenUntil => $composableBuilder(
    column: $table.ocrHiddenUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archiveRetentionDays => $composableBuilder(
    column: $table.archiveRetentionDays,
    builder: (column) => ColumnOrderings(column),
  );
}

class $LocalMetaAnnotationComposer
    extends Composer<_$LocalDatabase, LocalMeta> {
  $LocalMetaAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdSchemaVersion => $composableBuilder(
    column: $table.createdSchemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastExportAt => $composableBuilder(
    column: $table.lastExportAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastExportFormatVersion => $composableBuilder(
    column: $table.lastExportFormatVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get backupReminderSnoozedUntil => $composableBuilder(
    column: $table.backupReminderSnoozedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastReminderTone => $composableBuilder(
    column: $table.lastReminderTone,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ocrConsentAt => $composableBuilder(
    column: $table.ocrConsentAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ocrScanDay => $composableBuilder(
    column: $table.ocrScanDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ocrScanCount => $composableBuilder(
    column: $table.ocrScanCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ocrPermissionErrors => $composableBuilder(
    column: $table.ocrPermissionErrors,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ocrHiddenUntil => $composableBuilder(
    column: $table.ocrHiddenUntil,
    builder: (column) => column,
  );

  GeneratedColumn<int> get archiveRetentionDays => $composableBuilder(
    column: $table.archiveRetentionDays,
    builder: (column) => column,
  );
}

class $LocalMetaTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          LocalMeta,
          LocalMetaRow,
          $LocalMetaFilterComposer,
          $LocalMetaOrderingComposer,
          $LocalMetaAnnotationComposer,
          $LocalMetaCreateCompanionBuilder,
          $LocalMetaUpdateCompanionBuilder,
          (
            LocalMetaRow,
            BaseReferences<_$LocalDatabase, LocalMeta, LocalMetaRow>,
          ),
          LocalMetaRow,
          PrefetchHooks Function()
        > {
  $LocalMetaTableManager(_$LocalDatabase db, LocalMeta table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LocalMetaFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LocalMetaOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LocalMetaAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> createdSchemaVersion = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> lastExportAt = const Value.absent(),
                Value<int?> lastExportFormatVersion = const Value.absent(),
                Value<int?> backupReminderSnoozedUntil = const Value.absent(),
                Value<String?> lastReminderTone = const Value.absent(),
                Value<int?> ocrConsentAt = const Value.absent(),
                Value<String?> ocrScanDay = const Value.absent(),
                Value<int> ocrScanCount = const Value.absent(),
                Value<int> ocrPermissionErrors = const Value.absent(),
                Value<int?> ocrHiddenUntil = const Value.absent(),
                Value<int> archiveRetentionDays = const Value.absent(),
              }) => LocalMetaCompanion(
                id: id,
                createdSchemaVersion: createdSchemaVersion,
                createdAt: createdAt,
                lastExportAt: lastExportAt,
                lastExportFormatVersion: lastExportFormatVersion,
                backupReminderSnoozedUntil: backupReminderSnoozedUntil,
                lastReminderTone: lastReminderTone,
                ocrConsentAt: ocrConsentAt,
                ocrScanDay: ocrScanDay,
                ocrScanCount: ocrScanCount,
                ocrPermissionErrors: ocrPermissionErrors,
                ocrHiddenUntil: ocrHiddenUntil,
                archiveRetentionDays: archiveRetentionDays,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int createdSchemaVersion,
                required int createdAt,
                Value<int?> lastExportAt = const Value.absent(),
                Value<int?> lastExportFormatVersion = const Value.absent(),
                Value<int?> backupReminderSnoozedUntil = const Value.absent(),
                Value<String?> lastReminderTone = const Value.absent(),
                Value<int?> ocrConsentAt = const Value.absent(),
                Value<String?> ocrScanDay = const Value.absent(),
                Value<int> ocrScanCount = const Value.absent(),
                Value<int> ocrPermissionErrors = const Value.absent(),
                Value<int?> ocrHiddenUntil = const Value.absent(),
                Value<int> archiveRetentionDays = const Value.absent(),
              }) => LocalMetaCompanion.insert(
                id: id,
                createdSchemaVersion: createdSchemaVersion,
                createdAt: createdAt,
                lastExportAt: lastExportAt,
                lastExportFormatVersion: lastExportFormatVersion,
                backupReminderSnoozedUntil: backupReminderSnoozedUntil,
                lastReminderTone: lastReminderTone,
                ocrConsentAt: ocrConsentAt,
                ocrScanDay: ocrScanDay,
                ocrScanCount: ocrScanCount,
                ocrPermissionErrors: ocrPermissionErrors,
                ocrHiddenUntil: ocrHiddenUntil,
                archiveRetentionDays: archiveRetentionDays,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<LocalMeta, LocalMetaRow>(table),
                  BaseReferences<_$LocalDatabase, LocalMeta, LocalMetaRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $LocalMetaProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      LocalMeta,
      LocalMetaRow,
      $LocalMetaFilterComposer,
      $LocalMetaOrderingComposer,
      $LocalMetaAnnotationComposer,
      $LocalMetaCreateCompanionBuilder,
      $LocalMetaUpdateCompanionBuilder,
      (LocalMetaRow, BaseReferences<_$LocalDatabase, LocalMeta, LocalMetaRow>),
      LocalMetaRow,
      PrefetchHooks Function()
    >;
typedef $MembersCreateCompanionBuilder = MembersCompanion Function({
  required String id,
  required String groupId,
  required String displayName,
  required String nameKey,
  Value<String?> userId,
  required int sortOrder,
  Value<String> role,
  Value<String> status,
  Value<int?> joinedAt,
  Value<int?> leftAt,
  required int createdAt,
  Value<int> rowid,
});
typedef $MembersUpdateCompanionBuilder = MembersCompanion Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> displayName,
  Value<String> nameKey,
  Value<String?> userId,
  Value<int> sortOrder,
  Value<String> role,
  Value<String> status,
  Value<int?> joinedAt,
  Value<int?> leftAt,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $MembersReferences
    extends BaseReferences<_$LocalDatabase, Members, MemberRow> {
  $MembersReferences(super.$_db, super.$_table, super.$_typedResult);

  static ExpenseGroups _groupIdTable(_$LocalDatabase db) =>
      db.expenseGroups.createAlias('members__group_id__expense_groups__id');

  $ExpenseGroupsProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $ExpenseGroupsTableManager(
      $_db,
      $_db.expenseGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static LocalProfile _userIdTable(_$LocalDatabase db) =>
      db.localProfile.createAlias('members__user_id__local_profile__id');

  $LocalProfileProcessedTableManager? get userId {
    final $_column = $_itemColumn<String>('user_id');
    if ($_column == null) return null;
    final manager = $LocalProfileTableManager(
      $_db,
      $_db.localProfile,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<ExpenseGroups, List<GroupRow>>
  _expenseGroupsRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.expenseGroups,
    aliasName: 'members__id__expense_groups__treasurer_member_id',
  );

  $ExpenseGroupsProcessedTableManager get expenseGroupsRefs {
    final manager = $ExpenseGroupsTableManager($_db, $_db.expenseGroups).filter(
      (f) => f.treasurerMemberId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_expenseGroupsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ExpensePayers, List<PayerRow>>
  _expensePayersRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.expensePayers,
    aliasName: 'members__id__expense_payers__member_id',
  );

  $ExpensePayersProcessedTableManager get expensePayersRefs {
    final manager = $ExpensePayersTableManager(
      $_db,
      $_db.expensePayers,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensePayersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ExpenseSplits, List<SplitRow>>
  _expenseSplitsRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.expenseSplits,
    aliasName: 'members__id__expense_splits__member_id',
  );

  $ExpenseSplitsProcessedTableManager get expenseSplitsRefs {
    final manager = $ExpenseSplitsTableManager(
      $_db,
      $_db.expenseSplits,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expenseSplitsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ExpenseItemAssignees, List<AssigneeRow>>
  _expenseItemAssigneesRefsTable(_$LocalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.expenseItemAssignees,
        aliasName: 'members__id__expense_item_assignees__member_id',
      );

  $ExpenseItemAssigneesProcessedTableManager get expenseItemAssigneesRefs {
    final manager = $ExpenseItemAssigneesTableManager(
      $_db,
      $_db.expenseItemAssignees,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _expenseItemAssigneesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $MembersFilterComposer extends Composer<_$LocalDatabase, Members> {
  $MembersFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leftAt => $composableBuilder(
    column: $table.leftAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $ExpenseGroupsFilterComposer get groupId {
    final $ExpenseGroupsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.expenseGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseGroupsFilterComposer(
            $db: $db,
            $table: $db.expenseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $LocalProfileFilterComposer get userId {
    final $LocalProfileFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileFilterComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> expenseGroupsRefs(
    Expression<bool> Function($ExpenseGroupsFilterComposer f) f,
  ) {
    final $ExpenseGroupsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseGroups,
      getReferencedColumn: (t) => t.treasurerMemberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseGroupsFilterComposer(
            $db: $db,
            $table: $db.expenseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expensePayersRefs(
    Expression<bool> Function($ExpensePayersFilterComposer f) f,
  ) {
    final $ExpensePayersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expensePayers,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensePayersFilterComposer(
            $db: $db,
            $table: $db.expensePayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expenseSplitsRefs(
    Expression<bool> Function($ExpenseSplitsFilterComposer f) f,
  ) {
    final $ExpenseSplitsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseSplits,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseSplitsFilterComposer(
            $db: $db,
            $table: $db.expenseSplits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expenseItemAssigneesRefs(
    Expression<bool> Function($ExpenseItemAssigneesFilterComposer f) f,
  ) {
    final $ExpenseItemAssigneesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseItemAssignees,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseItemAssigneesFilterComposer(
            $db: $db,
            $table: $db.expenseItemAssignees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $MembersOrderingComposer extends Composer<_$LocalDatabase, Members> {
  $MembersOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leftAt => $composableBuilder(
    column: $table.leftAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $ExpenseGroupsOrderingComposer get groupId {
    final $ExpenseGroupsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.expenseGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseGroupsOrderingComposer(
            $db: $db,
            $table: $db.expenseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $LocalProfileOrderingComposer get userId {
    final $LocalProfileOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileOrderingComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MembersAnnotationComposer extends Composer<_$LocalDatabase, Members> {
  $MembersAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nameKey =>
      $composableBuilder(column: $table.nameKey, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<int> get leftAt =>
      $composableBuilder(column: $table.leftAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $ExpenseGroupsAnnotationComposer get groupId {
    final $ExpenseGroupsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.expenseGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseGroupsAnnotationComposer(
            $db: $db,
            $table: $db.expenseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $LocalProfileAnnotationComposer get userId {
    final $LocalProfileAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileAnnotationComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> expenseGroupsRefs<T extends Object>(
    Expression<T> Function($ExpenseGroupsAnnotationComposer a) f,
  ) {
    final $ExpenseGroupsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseGroups,
      getReferencedColumn: (t) => t.treasurerMemberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseGroupsAnnotationComposer(
            $db: $db,
            $table: $db.expenseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expensePayersRefs<T extends Object>(
    Expression<T> Function($ExpensePayersAnnotationComposer a) f,
  ) {
    final $ExpensePayersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expensePayers,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensePayersAnnotationComposer(
            $db: $db,
            $table: $db.expensePayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expenseSplitsRefs<T extends Object>(
    Expression<T> Function($ExpenseSplitsAnnotationComposer a) f,
  ) {
    final $ExpenseSplitsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseSplits,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseSplitsAnnotationComposer(
            $db: $db,
            $table: $db.expenseSplits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expenseItemAssigneesRefs<T extends Object>(
    Expression<T> Function($ExpenseItemAssigneesAnnotationComposer a) f,
  ) {
    final $ExpenseItemAssigneesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseItemAssignees,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseItemAssigneesAnnotationComposer(
            $db: $db,
            $table: $db.expenseItemAssignees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $MembersTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          Members,
          MemberRow,
          $MembersFilterComposer,
          $MembersOrderingComposer,
          $MembersAnnotationComposer,
          $MembersCreateCompanionBuilder,
          $MembersUpdateCompanionBuilder,
          (MemberRow, $MembersReferences),
          MemberRow,
          PrefetchHooks Function({
            bool groupId,
            bool userId,
            bool expenseGroupsRefs,
            bool expensePayersRefs,
            bool expenseSplitsRefs,
            bool expenseItemAssigneesRefs,
          })
        > {
  $MembersTableManager(_$LocalDatabase db, Members table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MembersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MembersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MembersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> nameKey = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> joinedAt = const Value.absent(),
                Value<int?> leftAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion(
                id: id,
                groupId: groupId,
                displayName: displayName,
                nameKey: nameKey,
                userId: userId,
                sortOrder: sortOrder,
                role: role,
                status: status,
                joinedAt: joinedAt,
                leftAt: leftAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String displayName,
                required String nameKey,
                Value<String?> userId = const Value.absent(),
                required int sortOrder,
                Value<String> role = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> joinedAt = const Value.absent(),
                Value<int?> leftAt = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion.insert(
                id: id,
                groupId: groupId,
                displayName: displayName,
                nameKey: nameKey,
                userId: userId,
                sortOrder: sortOrder,
                role: role,
                status: status,
                joinedAt: joinedAt,
                leftAt: leftAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Members, MemberRow>(table),
                  $MembersReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                groupId = false,
                userId = false,
                expenseGroupsRefs = false,
                expensePayersRefs = false,
                expenseSplitsRefs = false,
                expenseItemAssigneesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (expenseGroupsRefs) db.expenseGroups,
                    if (expensePayersRefs) db.expensePayers,
                    if (expenseSplitsRefs) db.expenseSplits,
                    if (expenseItemAssigneesRefs) db.expenseItemAssignees,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.groupId,
                            referencedTable: $MembersReferences._groupIdTable(
                              db,
                            ),
                            referencedColumn: $MembersReferences
                                ._groupIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (userId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.userId,
                            referencedTable: $MembersReferences._userIdTable(
                              db,
                            ),
                            referencedColumn: $MembersReferences
                                ._userIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (expenseGroupsRefs)
                        await $_getPrefetchedDataByColumns<
                          MemberRow,
                          Members,
                          GroupRow,
                          ExpenseGroups
                        >(
                          currentTable: table,
                          referencedTable: $MembersReferences
                              ._expenseGroupsRefsTable(db),
                          managerFromTypedResult: (p0) => $MembersReferences(
                            db,
                            table,
                            p0,
                          ).expenseGroupsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'treasurer_member_id',
                          typedResults: items,
                        ),
                      if (expensePayersRefs)
                        await $_getPrefetchedDataByColumns<
                          MemberRow,
                          Members,
                          PayerRow,
                          ExpensePayers
                        >(
                          currentTable: table,
                          referencedTable: $MembersReferences
                              ._expensePayersRefsTable(db),
                          managerFromTypedResult: (p0) => $MembersReferences(
                            db,
                            table,
                            p0,
                          ).expensePayersRefs,
                          currentColumn: 'id',
                          referencedColumn: 'member_id',
                          typedResults: items,
                        ),
                      if (expenseSplitsRefs)
                        await $_getPrefetchedDataByColumns<
                          MemberRow,
                          Members,
                          SplitRow,
                          ExpenseSplits
                        >(
                          currentTable: table,
                          referencedTable: $MembersReferences
                              ._expenseSplitsRefsTable(db),
                          managerFromTypedResult: (p0) => $MembersReferences(
                            db,
                            table,
                            p0,
                          ).expenseSplitsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'member_id',
                          typedResults: items,
                        ),
                      if (expenseItemAssigneesRefs)
                        await $_getPrefetchedDataByColumns<
                          MemberRow,
                          Members,
                          AssigneeRow,
                          ExpenseItemAssignees
                        >(
                          currentTable: table,
                          referencedTable: $MembersReferences
                              ._expenseItemAssigneesRefsTable(db),
                          managerFromTypedResult: (p0) => $MembersReferences(
                            db,
                            table,
                            p0,
                          ).expenseItemAssigneesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'member_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $MembersProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      Members,
      MemberRow,
      $MembersFilterComposer,
      $MembersOrderingComposer,
      $MembersAnnotationComposer,
      $MembersCreateCompanionBuilder,
      $MembersUpdateCompanionBuilder,
      (MemberRow, $MembersReferences),
      MemberRow,
      PrefetchHooks Function({
        bool groupId,
        bool userId,
        bool expenseGroupsRefs,
        bool expensePayersRefs,
        bool expenseSplitsRefs,
        bool expenseItemAssigneesRefs,
      })
    >;
typedef $ExpenseGroupsCreateCompanionBuilder = ExpenseGroupsCompanion Function({
  required String id,
  required String ownerUserId,
  required String name,
  required String type,
  Value<String> currencyCode,
  required int createdAt,
  required int updatedAt,
  Value<int> version,
  Value<int> memberSeq,
  Value<String?> treasurerMemberId,
  Value<int?> archivedAt,
  Value<int> rowid,
});
typedef $ExpenseGroupsUpdateCompanionBuilder = ExpenseGroupsCompanion Function({
  Value<String> id,
  Value<String> ownerUserId,
  Value<String> name,
  Value<String> type,
  Value<String> currencyCode,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> version,
  Value<int> memberSeq,
  Value<String?> treasurerMemberId,
  Value<int?> archivedAt,
  Value<int> rowid,
});

final class $ExpenseGroupsReferences
    extends BaseReferences<_$LocalDatabase, ExpenseGroups, GroupRow> {
  $ExpenseGroupsReferences(super.$_db, super.$_table, super.$_typedResult);

  static LocalProfile _ownerUserIdTable(_$LocalDatabase db) => db.localProfile
      .createAlias('expense_groups__owner_user_id__local_profile__id');

  $LocalProfileProcessedTableManager get ownerUserId {
    final $_column = $_itemColumn<String>('owner_user_id')!;

    final manager = $LocalProfileTableManager(
      $_db,
      $_db.localProfile,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Members _treasurerMemberIdTable(_$LocalDatabase db) => db.members
      .createAlias('expense_groups__treasurer_member_id__members__id');

  $MembersProcessedTableManager? get treasurerMemberId {
    final $_column = $_itemColumn<String>('treasurer_member_id');
    if ($_column == null) return null;
    final manager = $MembersTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_treasurerMemberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<Members, List<MemberRow>> _membersRefsTable(
    _$LocalDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.members,
    aliasName: 'expense_groups__id__members__group_id',
  );

  $MembersProcessedTableManager get membersRefs {
    final manager = $MembersTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_membersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Expenses, List<ExpenseRow>> _expensesRefsTable(
    _$LocalDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: 'expense_groups__id__expenses__group_id',
  );

  $ExpensesProcessedTableManager get expensesRefs {
    final manager = $ExpensesTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Settlements, List<SettlementRow>>
  _settlementsRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.settlements,
    aliasName: 'expense_groups__id__settlements__group_id',
  );

  $SettlementsProcessedTableManager get settlementsRefs {
    final manager = $SettlementsTableManager(
      $_db,
      $_db.settlements,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_settlementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ExpenseGroupsFilterComposer
    extends Composer<_$LocalDatabase, ExpenseGroups> {
  $ExpenseGroupsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get memberSeq => $composableBuilder(
    column: $table.memberSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  $LocalProfileFilterComposer get ownerUserId {
    final $LocalProfileFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUserId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileFilterComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersFilterComposer get treasurerMemberId {
    final $MembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.treasurerMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> membersRefs(
    Expression<bool> Function($MembersFilterComposer f) f,
  ) {
    final $MembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($ExpensesFilterComposer f) f,
  ) {
    final $ExpensesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensesFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> settlementsRefs(
    Expression<bool> Function($SettlementsFilterComposer f) f,
  ) {
    final $SettlementsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.settlements,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SettlementsFilterComposer(
            $db: $db,
            $table: $db.settlements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ExpenseGroupsOrderingComposer
    extends Composer<_$LocalDatabase, ExpenseGroups> {
  $ExpenseGroupsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get memberSeq => $composableBuilder(
    column: $table.memberSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $LocalProfileOrderingComposer get ownerUserId {
    final $LocalProfileOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUserId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileOrderingComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersOrderingComposer get treasurerMemberId {
    final $MembersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.treasurerMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExpenseGroupsAnnotationComposer
    extends Composer<_$LocalDatabase, ExpenseGroups> {
  $ExpenseGroupsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get memberSeq =>
      $composableBuilder(column: $table.memberSeq, builder: (column) => column);

  GeneratedColumn<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  $LocalProfileAnnotationComposer get ownerUserId {
    final $LocalProfileAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerUserId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileAnnotationComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersAnnotationComposer get treasurerMemberId {
    final $MembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.treasurerMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> membersRefs<T extends Object>(
    Expression<T> Function($MembersAnnotationComposer a) f,
  ) {
    final $MembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($ExpensesAnnotationComposer a) f,
  ) {
    final $ExpensesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensesAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> settlementsRefs<T extends Object>(
    Expression<T> Function($SettlementsAnnotationComposer a) f,
  ) {
    final $SettlementsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.settlements,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SettlementsAnnotationComposer(
            $db: $db,
            $table: $db.settlements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ExpenseGroupsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          ExpenseGroups,
          GroupRow,
          $ExpenseGroupsFilterComposer,
          $ExpenseGroupsOrderingComposer,
          $ExpenseGroupsAnnotationComposer,
          $ExpenseGroupsCreateCompanionBuilder,
          $ExpenseGroupsUpdateCompanionBuilder,
          (GroupRow, $ExpenseGroupsReferences),
          GroupRow,
          PrefetchHooks Function({
            bool ownerUserId,
            bool treasurerMemberId,
            bool membersRefs,
            bool expensesRefs,
            bool settlementsRefs,
          })
        > {
  $ExpenseGroupsTableManager(_$LocalDatabase db, ExpenseGroups table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ExpenseGroupsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ExpenseGroupsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ExpenseGroupsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerUserId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> memberSeq = const Value.absent(),
                Value<String?> treasurerMemberId = const Value.absent(),
                Value<int?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseGroupsCompanion(
                id: id,
                ownerUserId: ownerUserId,
                name: name,
                type: type,
                currencyCode: currencyCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                memberSeq: memberSeq,
                treasurerMemberId: treasurerMemberId,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerUserId,
                required String name,
                required String type,
                Value<String> currencyCode = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> version = const Value.absent(),
                Value<int> memberSeq = const Value.absent(),
                Value<String?> treasurerMemberId = const Value.absent(),
                Value<int?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseGroupsCompanion.insert(
                id: id,
                ownerUserId: ownerUserId,
                name: name,
                type: type,
                currencyCode: currencyCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                memberSeq: memberSeq,
                treasurerMemberId: treasurerMemberId,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ExpenseGroups, GroupRow>(table),
                  $ExpenseGroupsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ownerUserId = false,
                treasurerMemberId = false,
                membersRefs = false,
                expensesRefs = false,
                settlementsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (membersRefs) db.members,
                    if (expensesRefs) db.expenses,
                    if (settlementsRefs) db.settlements,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (ownerUserId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.ownerUserId,
                            referencedTable: $ExpenseGroupsReferences
                                ._ownerUserIdTable(db),
                            referencedColumn: $ExpenseGroupsReferences
                                ._ownerUserIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (treasurerMemberId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.treasurerMemberId,
                            referencedTable: $ExpenseGroupsReferences
                                ._treasurerMemberIdTable(db),
                            referencedColumn: $ExpenseGroupsReferences
                                ._treasurerMemberIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (membersRefs)
                        await $_getPrefetchedDataByColumns<
                          GroupRow,
                          ExpenseGroups,
                          MemberRow,
                          Members
                        >(
                          currentTable: table,
                          referencedTable: $ExpenseGroupsReferences
                              ._membersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ExpenseGroupsReferences(
                                db,
                                table,
                                p0,
                              ).membersRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                      if (expensesRefs)
                        await $_getPrefetchedDataByColumns<
                          GroupRow,
                          ExpenseGroups,
                          ExpenseRow,
                          Expenses
                        >(
                          currentTable: table,
                          referencedTable: $ExpenseGroupsReferences
                              ._expensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ExpenseGroupsReferences(
                                db,
                                table,
                                p0,
                              ).expensesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                      if (settlementsRefs)
                        await $_getPrefetchedDataByColumns<
                          GroupRow,
                          ExpenseGroups,
                          SettlementRow,
                          Settlements
                        >(
                          currentTable: table,
                          referencedTable: $ExpenseGroupsReferences
                              ._settlementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ExpenseGroupsReferences(
                                db,
                                table,
                                p0,
                              ).settlementsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $ExpenseGroupsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      ExpenseGroups,
      GroupRow,
      $ExpenseGroupsFilterComposer,
      $ExpenseGroupsOrderingComposer,
      $ExpenseGroupsAnnotationComposer,
      $ExpenseGroupsCreateCompanionBuilder,
      $ExpenseGroupsUpdateCompanionBuilder,
      (GroupRow, $ExpenseGroupsReferences),
      GroupRow,
      PrefetchHooks Function({
        bool ownerUserId,
        bool treasurerMemberId,
        bool membersRefs,
        bool expensesRefs,
        bool settlementsRefs,
      })
    >;
typedef $ExpensesCreateCompanionBuilder = ExpensesCompanion Function({
  required String id,
  required String groupId,
  required String title,
  required String splitType,
  required int totalMinor,
  required String expenseDate,
  Value<int?> subtotalMinor,
  Value<int?> serviceBps,
  Value<int?> serviceMinor,
  Value<int?> taxBps,
  Value<int?> taxMinor,
  Value<String?> taxBase,
  Value<int?> adjustmentMinor,
  required String createdByUserId,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> version,
  Value<String> category,
  Value<int> paidFromPool,
  Value<int?> discountBps,
  Value<int?> discountAmountMinor,
  Value<int?> discountMinor,
  Value<int?> serviceAmountMinor,
  Value<int?> taxAmountMinor,
  Value<int?> deliveryMinor,
  Value<int> rowid,
});
typedef $ExpensesUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> title,
  Value<String> splitType,
  Value<int> totalMinor,
  Value<String> expenseDate,
  Value<int?> subtotalMinor,
  Value<int?> serviceBps,
  Value<int?> serviceMinor,
  Value<int?> taxBps,
  Value<int?> taxMinor,
  Value<String?> taxBase,
  Value<int?> adjustmentMinor,
  Value<String> createdByUserId,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> version,
  Value<String> category,
  Value<int> paidFromPool,
  Value<int?> discountBps,
  Value<int?> discountAmountMinor,
  Value<int?> discountMinor,
  Value<int?> serviceAmountMinor,
  Value<int?> taxAmountMinor,
  Value<int?> deliveryMinor,
  Value<int> rowid,
});

final class $ExpensesReferences
    extends BaseReferences<_$LocalDatabase, Expenses, ExpenseRow> {
  $ExpensesReferences(super.$_db, super.$_table, super.$_typedResult);

  static ExpenseGroups _groupIdTable(_$LocalDatabase db) =>
      db.expenseGroups.createAlias('expenses__group_id__expense_groups__id');

  $ExpenseGroupsProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $ExpenseGroupsTableManager(
      $_db,
      $_db.expenseGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static LocalProfile _createdByUserIdTable(_$LocalDatabase db) => db
      .localProfile
      .createAlias('expenses__created_by_user_id__local_profile__id');

  $LocalProfileProcessedTableManager get createdByUserId {
    final $_column = $_itemColumn<String>('created_by_user_id')!;

    final manager = $LocalProfileTableManager(
      $_db,
      $_db.localProfile,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<ExpensePayers, List<PayerRow>>
  _expensePayersRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.expensePayers,
    aliasName: 'expenses__id__expense_payers__expense_id',
  );

  $ExpensePayersProcessedTableManager get expensePayersRefs {
    final manager = $ExpensePayersTableManager(
      $_db,
      $_db.expensePayers,
    ).filter((f) => f.expenseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensePayersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ExpenseSplits, List<SplitRow>>
  _expenseSplitsRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.expenseSplits,
    aliasName: 'expenses__id__expense_splits__expense_id',
  );

  $ExpenseSplitsProcessedTableManager get expenseSplitsRefs {
    final manager = $ExpenseSplitsTableManager(
      $_db,
      $_db.expenseSplits,
    ).filter((f) => f.expenseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expenseSplitsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ExpenseItems, List<ItemRow>>
  _expenseItemsRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.expenseItems,
    aliasName: 'expenses__id__expense_items__expense_id',
  );

  $ExpenseItemsProcessedTableManager get expenseItemsRefs {
    final manager = $ExpenseItemsTableManager(
      $_db,
      $_db.expenseItems,
    ).filter((f) => f.expenseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expenseItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ExpenseRevisions, List<RevisionRow>>
  _expenseRevisionsRefsTable(_$LocalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.expenseRevisions,
        aliasName: 'expenses__id__expense_revisions__expense_id',
      );

  $ExpenseRevisionsProcessedTableManager get expenseRevisionsRefs {
    final manager = $ExpenseRevisionsTableManager(
      $_db,
      $_db.expenseRevisions,
    ).filter((f) => f.expenseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _expenseRevisionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ExpensesFilterComposer extends Composer<_$LocalDatabase, Expenses> {
  $ExpensesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get splitType => $composableBuilder(
    column: $table.splitType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalMinor => $composableBuilder(
    column: $table.totalMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expenseDate => $composableBuilder(
    column: $table.expenseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotalMinor => $composableBuilder(
    column: $table.subtotalMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serviceBps => $composableBuilder(
    column: $table.serviceBps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serviceMinor => $composableBuilder(
    column: $table.serviceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxBps => $composableBuilder(
    column: $table.taxBps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxMinor => $composableBuilder(
    column: $table.taxMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxBase => $composableBuilder(
    column: $table.taxBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get adjustmentMinor => $composableBuilder(
    column: $table.adjustmentMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidFromPool => $composableBuilder(
    column: $table.paidFromPool,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountBps => $composableBuilder(
    column: $table.discountBps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountAmountMinor => $composableBuilder(
    column: $table.discountAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountMinor => $composableBuilder(
    column: $table.discountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serviceAmountMinor => $composableBuilder(
    column: $table.serviceAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxAmountMinor => $composableBuilder(
    column: $table.taxAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deliveryMinor => $composableBuilder(
    column: $table.deliveryMinor,
    builder: (column) => ColumnFilters(column),
  );

  $ExpenseGroupsFilterComposer get groupId {
    final $ExpenseGroupsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.expenseGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseGroupsFilterComposer(
            $db: $db,
            $table: $db.expenseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $LocalProfileFilterComposer get createdByUserId {
    final $LocalProfileFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileFilterComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> expensePayersRefs(
    Expression<bool> Function($ExpensePayersFilterComposer f) f,
  ) {
    final $ExpensePayersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expensePayers,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensePayersFilterComposer(
            $db: $db,
            $table: $db.expensePayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expenseSplitsRefs(
    Expression<bool> Function($ExpenseSplitsFilterComposer f) f,
  ) {
    final $ExpenseSplitsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseSplits,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseSplitsFilterComposer(
            $db: $db,
            $table: $db.expenseSplits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expenseItemsRefs(
    Expression<bool> Function($ExpenseItemsFilterComposer f) f,
  ) {
    final $ExpenseItemsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseItems,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseItemsFilterComposer(
            $db: $db,
            $table: $db.expenseItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expenseRevisionsRefs(
    Expression<bool> Function($ExpenseRevisionsFilterComposer f) f,
  ) {
    final $ExpenseRevisionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseRevisions,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseRevisionsFilterComposer(
            $db: $db,
            $table: $db.expenseRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ExpensesOrderingComposer extends Composer<_$LocalDatabase, Expenses> {
  $ExpensesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get splitType => $composableBuilder(
    column: $table.splitType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMinor => $composableBuilder(
    column: $table.totalMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expenseDate => $composableBuilder(
    column: $table.expenseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotalMinor => $composableBuilder(
    column: $table.subtotalMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serviceBps => $composableBuilder(
    column: $table.serviceBps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serviceMinor => $composableBuilder(
    column: $table.serviceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxBps => $composableBuilder(
    column: $table.taxBps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxMinor => $composableBuilder(
    column: $table.taxMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxBase => $composableBuilder(
    column: $table.taxBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get adjustmentMinor => $composableBuilder(
    column: $table.adjustmentMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidFromPool => $composableBuilder(
    column: $table.paidFromPool,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountBps => $composableBuilder(
    column: $table.discountBps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountAmountMinor => $composableBuilder(
    column: $table.discountAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountMinor => $composableBuilder(
    column: $table.discountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serviceAmountMinor => $composableBuilder(
    column: $table.serviceAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxAmountMinor => $composableBuilder(
    column: $table.taxAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deliveryMinor => $composableBuilder(
    column: $table.deliveryMinor,
    builder: (column) => ColumnOrderings(column),
  );

  $ExpenseGroupsOrderingComposer get groupId {
    final $ExpenseGroupsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.expenseGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseGroupsOrderingComposer(
            $db: $db,
            $table: $db.expenseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $LocalProfileOrderingComposer get createdByUserId {
    final $LocalProfileOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileOrderingComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExpensesAnnotationComposer extends Composer<_$LocalDatabase, Expenses> {
  $ExpensesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get splitType =>
      $composableBuilder(column: $table.splitType, builder: (column) => column);

  GeneratedColumn<int> get totalMinor => $composableBuilder(
    column: $table.totalMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expenseDate => $composableBuilder(
    column: $table.expenseDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subtotalMinor => $composableBuilder(
    column: $table.subtotalMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serviceBps => $composableBuilder(
    column: $table.serviceBps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serviceMinor => $composableBuilder(
    column: $table.serviceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxBps =>
      $composableBuilder(column: $table.taxBps, builder: (column) => column);

  GeneratedColumn<int> get taxMinor =>
      $composableBuilder(column: $table.taxMinor, builder: (column) => column);

  GeneratedColumn<String> get taxBase =>
      $composableBuilder(column: $table.taxBase, builder: (column) => column);

  GeneratedColumn<int> get adjustmentMinor => $composableBuilder(
    column: $table.adjustmentMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get paidFromPool => $composableBuilder(
    column: $table.paidFromPool,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountBps => $composableBuilder(
    column: $table.discountBps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountAmountMinor => $composableBuilder(
    column: $table.discountAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountMinor => $composableBuilder(
    column: $table.discountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serviceAmountMinor => $composableBuilder(
    column: $table.serviceAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxAmountMinor => $composableBuilder(
    column: $table.taxAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deliveryMinor => $composableBuilder(
    column: $table.deliveryMinor,
    builder: (column) => column,
  );

  $ExpenseGroupsAnnotationComposer get groupId {
    final $ExpenseGroupsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.expenseGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseGroupsAnnotationComposer(
            $db: $db,
            $table: $db.expenseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $LocalProfileAnnotationComposer get createdByUserId {
    final $LocalProfileAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileAnnotationComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> expensePayersRefs<T extends Object>(
    Expression<T> Function($ExpensePayersAnnotationComposer a) f,
  ) {
    final $ExpensePayersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expensePayers,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensePayersAnnotationComposer(
            $db: $db,
            $table: $db.expensePayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expenseSplitsRefs<T extends Object>(
    Expression<T> Function($ExpenseSplitsAnnotationComposer a) f,
  ) {
    final $ExpenseSplitsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseSplits,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseSplitsAnnotationComposer(
            $db: $db,
            $table: $db.expenseSplits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expenseItemsRefs<T extends Object>(
    Expression<T> Function($ExpenseItemsAnnotationComposer a) f,
  ) {
    final $ExpenseItemsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseItems,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseItemsAnnotationComposer(
            $db: $db,
            $table: $db.expenseItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expenseRevisionsRefs<T extends Object>(
    Expression<T> Function($ExpenseRevisionsAnnotationComposer a) f,
  ) {
    final $ExpenseRevisionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseRevisions,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseRevisionsAnnotationComposer(
            $db: $db,
            $table: $db.expenseRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ExpensesTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          Expenses,
          ExpenseRow,
          $ExpensesFilterComposer,
          $ExpensesOrderingComposer,
          $ExpensesAnnotationComposer,
          $ExpensesCreateCompanionBuilder,
          $ExpensesUpdateCompanionBuilder,
          (ExpenseRow, $ExpensesReferences),
          ExpenseRow,
          PrefetchHooks Function({
            bool groupId,
            bool createdByUserId,
            bool expensePayersRefs,
            bool expenseSplitsRefs,
            bool expenseItemsRefs,
            bool expenseRevisionsRefs,
          })
        > {
  $ExpensesTableManager(_$LocalDatabase db, Expenses table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ExpensesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ExpensesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ExpensesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> splitType = const Value.absent(),
                Value<int> totalMinor = const Value.absent(),
                Value<String> expenseDate = const Value.absent(),
                Value<int?> subtotalMinor = const Value.absent(),
                Value<int?> serviceBps = const Value.absent(),
                Value<int?> serviceMinor = const Value.absent(),
                Value<int?> taxBps = const Value.absent(),
                Value<int?> taxMinor = const Value.absent(),
                Value<String?> taxBase = const Value.absent(),
                Value<int?> adjustmentMinor = const Value.absent(),
                Value<String> createdByUserId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> paidFromPool = const Value.absent(),
                Value<int?> discountBps = const Value.absent(),
                Value<int?> discountAmountMinor = const Value.absent(),
                Value<int?> discountMinor = const Value.absent(),
                Value<int?> serviceAmountMinor = const Value.absent(),
                Value<int?> taxAmountMinor = const Value.absent(),
                Value<int?> deliveryMinor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                groupId: groupId,
                title: title,
                splitType: splitType,
                totalMinor: totalMinor,
                expenseDate: expenseDate,
                subtotalMinor: subtotalMinor,
                serviceBps: serviceBps,
                serviceMinor: serviceMinor,
                taxBps: taxBps,
                taxMinor: taxMinor,
                taxBase: taxBase,
                adjustmentMinor: adjustmentMinor,
                createdByUserId: createdByUserId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                version: version,
                category: category,
                paidFromPool: paidFromPool,
                discountBps: discountBps,
                discountAmountMinor: discountAmountMinor,
                discountMinor: discountMinor,
                serviceAmountMinor: serviceAmountMinor,
                taxAmountMinor: taxAmountMinor,
                deliveryMinor: deliveryMinor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String title,
                required String splitType,
                required int totalMinor,
                required String expenseDate,
                Value<int?> subtotalMinor = const Value.absent(),
                Value<int?> serviceBps = const Value.absent(),
                Value<int?> serviceMinor = const Value.absent(),
                Value<int?> taxBps = const Value.absent(),
                Value<int?> taxMinor = const Value.absent(),
                Value<String?> taxBase = const Value.absent(),
                Value<int?> adjustmentMinor = const Value.absent(),
                required String createdByUserId,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> paidFromPool = const Value.absent(),
                Value<int?> discountBps = const Value.absent(),
                Value<int?> discountAmountMinor = const Value.absent(),
                Value<int?> discountMinor = const Value.absent(),
                Value<int?> serviceAmountMinor = const Value.absent(),
                Value<int?> taxAmountMinor = const Value.absent(),
                Value<int?> deliveryMinor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                groupId: groupId,
                title: title,
                splitType: splitType,
                totalMinor: totalMinor,
                expenseDate: expenseDate,
                subtotalMinor: subtotalMinor,
                serviceBps: serviceBps,
                serviceMinor: serviceMinor,
                taxBps: taxBps,
                taxMinor: taxMinor,
                taxBase: taxBase,
                adjustmentMinor: adjustmentMinor,
                createdByUserId: createdByUserId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                version: version,
                category: category,
                paidFromPool: paidFromPool,
                discountBps: discountBps,
                discountAmountMinor: discountAmountMinor,
                discountMinor: discountMinor,
                serviceAmountMinor: serviceAmountMinor,
                taxAmountMinor: taxAmountMinor,
                deliveryMinor: deliveryMinor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Expenses, ExpenseRow>(table),
                  $ExpensesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                groupId = false,
                createdByUserId = false,
                expensePayersRefs = false,
                expenseSplitsRefs = false,
                expenseItemsRefs = false,
                expenseRevisionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (expensePayersRefs) db.expensePayers,
                    if (expenseSplitsRefs) db.expenseSplits,
                    if (expenseItemsRefs) db.expenseItems,
                    if (expenseRevisionsRefs) db.expenseRevisions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.groupId,
                            referencedTable: $ExpensesReferences._groupIdTable(
                              db,
                            ),
                            referencedColumn: $ExpensesReferences
                                ._groupIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (createdByUserId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.createdByUserId,
                            referencedTable: $ExpensesReferences
                                ._createdByUserIdTable(db),
                            referencedColumn: $ExpensesReferences
                                ._createdByUserIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (expensePayersRefs)
                        await $_getPrefetchedDataByColumns<
                          ExpenseRow,
                          Expenses,
                          PayerRow,
                          ExpensePayers
                        >(
                          currentTable: table,
                          referencedTable: $ExpensesReferences
                              ._expensePayersRefsTable(db),
                          managerFromTypedResult: (p0) => $ExpensesReferences(
                            db,
                            table,
                            p0,
                          ).expensePayersRefs,
                          currentColumn: 'id',
                          referencedColumn: 'expense_id',
                          typedResults: items,
                        ),
                      if (expenseSplitsRefs)
                        await $_getPrefetchedDataByColumns<
                          ExpenseRow,
                          Expenses,
                          SplitRow,
                          ExpenseSplits
                        >(
                          currentTable: table,
                          referencedTable: $ExpensesReferences
                              ._expenseSplitsRefsTable(db),
                          managerFromTypedResult: (p0) => $ExpensesReferences(
                            db,
                            table,
                            p0,
                          ).expenseSplitsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'expense_id',
                          typedResults: items,
                        ),
                      if (expenseItemsRefs)
                        await $_getPrefetchedDataByColumns<
                          ExpenseRow,
                          Expenses,
                          ItemRow,
                          ExpenseItems
                        >(
                          currentTable: table,
                          referencedTable: $ExpensesReferences
                              ._expenseItemsRefsTable(db),
                          managerFromTypedResult: (p0) => $ExpensesReferences(
                            db,
                            table,
                            p0,
                          ).expenseItemsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'expense_id',
                          typedResults: items,
                        ),
                      if (expenseRevisionsRefs)
                        await $_getPrefetchedDataByColumns<
                          ExpenseRow,
                          Expenses,
                          RevisionRow,
                          ExpenseRevisions
                        >(
                          currentTable: table,
                          referencedTable: $ExpensesReferences
                              ._expenseRevisionsRefsTable(db),
                          managerFromTypedResult: (p0) => $ExpensesReferences(
                            db,
                            table,
                            p0,
                          ).expenseRevisionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'expense_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $ExpensesProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      Expenses,
      ExpenseRow,
      $ExpensesFilterComposer,
      $ExpensesOrderingComposer,
      $ExpensesAnnotationComposer,
      $ExpensesCreateCompanionBuilder,
      $ExpensesUpdateCompanionBuilder,
      (ExpenseRow, $ExpensesReferences),
      ExpenseRow,
      PrefetchHooks Function({
        bool groupId,
        bool createdByUserId,
        bool expensePayersRefs,
        bool expenseSplitsRefs,
        bool expenseItemsRefs,
        bool expenseRevisionsRefs,
      })
    >;
typedef $ExpensePayersCreateCompanionBuilder = ExpensePayersCompanion Function({
  required String expenseId,
  required String memberId,
  required int amountMinor,
  Value<int> rowid,
});
typedef $ExpensePayersUpdateCompanionBuilder = ExpensePayersCompanion Function({
  Value<String> expenseId,
  Value<String> memberId,
  Value<int> amountMinor,
  Value<int> rowid,
});

final class $ExpensePayersReferences
    extends BaseReferences<_$LocalDatabase, ExpensePayers, PayerRow> {
  $ExpensePayersReferences(super.$_db, super.$_table, super.$_typedResult);

  static Expenses _expenseIdTable(_$LocalDatabase db) =>
      db.expenses.createAlias('expense_payers__expense_id__expenses__id');

  $ExpensesProcessedTableManager get expenseId {
    final $_column = $_itemColumn<String>('expense_id')!;

    final manager = $ExpensesTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Members _memberIdTable(_$LocalDatabase db) =>
      db.members.createAlias('expense_payers__member_id__members__id');

  $MembersProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $MembersTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $ExpensePayersFilterComposer
    extends Composer<_$LocalDatabase, ExpensePayers> {
  $ExpensePayersFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  $ExpensesFilterComposer get expenseId {
    final $ExpensesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensesFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersFilterComposer get memberId {
    final $MembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExpensePayersOrderingComposer
    extends Composer<_$LocalDatabase, ExpensePayers> {
  $ExpensePayersOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  $ExpensesOrderingComposer get expenseId {
    final $ExpensesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensesOrderingComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersOrderingComposer get memberId {
    final $MembersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExpensePayersAnnotationComposer
    extends Composer<_$LocalDatabase, ExpensePayers> {
  $ExpensePayersAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  $ExpensesAnnotationComposer get expenseId {
    final $ExpensesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensesAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersAnnotationComposer get memberId {
    final $MembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExpensePayersTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          ExpensePayers,
          PayerRow,
          $ExpensePayersFilterComposer,
          $ExpensePayersOrderingComposer,
          $ExpensePayersAnnotationComposer,
          $ExpensePayersCreateCompanionBuilder,
          $ExpensePayersUpdateCompanionBuilder,
          (PayerRow, $ExpensePayersReferences),
          PayerRow,
          PrefetchHooks Function({bool expenseId, bool memberId})
        > {
  $ExpensePayersTableManager(_$LocalDatabase db, ExpensePayers table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ExpensePayersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ExpensePayersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ExpensePayersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> expenseId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensePayersCompanion(
                expenseId: expenseId,
                memberId: memberId,
                amountMinor: amountMinor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String expenseId,
                required String memberId,
                required int amountMinor,
                Value<int> rowid = const Value.absent(),
              }) => ExpensePayersCompanion.insert(
                expenseId: expenseId,
                memberId: memberId,
                amountMinor: amountMinor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ExpensePayers, PayerRow>(table),
                  $ExpensePayersReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({expenseId = false, memberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (expenseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.expenseId,
                        referencedTable: $ExpensePayersReferences
                            ._expenseIdTable(db),
                        referencedColumn: $ExpensePayersReferences
                            ._expenseIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (memberId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.memberId,
                        referencedTable: $ExpensePayersReferences
                            ._memberIdTable(db),
                        referencedColumn: $ExpensePayersReferences
                            ._memberIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $ExpensePayersProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      ExpensePayers,
      PayerRow,
      $ExpensePayersFilterComposer,
      $ExpensePayersOrderingComposer,
      $ExpensePayersAnnotationComposer,
      $ExpensePayersCreateCompanionBuilder,
      $ExpensePayersUpdateCompanionBuilder,
      (PayerRow, $ExpensePayersReferences),
      PayerRow,
      PrefetchHooks Function({bool expenseId, bool memberId})
    >;
typedef $ExpenseSplitsCreateCompanionBuilder = ExpenseSplitsCompanion Function({
  required String expenseId,
  required String memberId,
  required int owedMinor,
  Value<int?> itemsMinor,
  Value<int?> serviceMinor,
  Value<int?> taxMinor,
  Value<int?> adjustmentMinor,
  Value<int?> discountMinor,
  Value<int?> deliveryMinor,
  Value<int> rowid,
});
typedef $ExpenseSplitsUpdateCompanionBuilder = ExpenseSplitsCompanion Function({
  Value<String> expenseId,
  Value<String> memberId,
  Value<int> owedMinor,
  Value<int?> itemsMinor,
  Value<int?> serviceMinor,
  Value<int?> taxMinor,
  Value<int?> adjustmentMinor,
  Value<int?> discountMinor,
  Value<int?> deliveryMinor,
  Value<int> rowid,
});

final class $ExpenseSplitsReferences
    extends BaseReferences<_$LocalDatabase, ExpenseSplits, SplitRow> {
  $ExpenseSplitsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Expenses _expenseIdTable(_$LocalDatabase db) =>
      db.expenses.createAlias('expense_splits__expense_id__expenses__id');

  $ExpensesProcessedTableManager get expenseId {
    final $_column = $_itemColumn<String>('expense_id')!;

    final manager = $ExpensesTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Members _memberIdTable(_$LocalDatabase db) =>
      db.members.createAlias('expense_splits__member_id__members__id');

  $MembersProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $MembersTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $ExpenseSplitsFilterComposer
    extends Composer<_$LocalDatabase, ExpenseSplits> {
  $ExpenseSplitsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get owedMinor => $composableBuilder(
    column: $table.owedMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemsMinor => $composableBuilder(
    column: $table.itemsMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serviceMinor => $composableBuilder(
    column: $table.serviceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxMinor => $composableBuilder(
    column: $table.taxMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get adjustmentMinor => $composableBuilder(
    column: $table.adjustmentMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountMinor => $composableBuilder(
    column: $table.discountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deliveryMinor => $composableBuilder(
    column: $table.deliveryMinor,
    builder: (column) => ColumnFilters(column),
  );

  $ExpensesFilterComposer get expenseId {
    final $ExpensesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensesFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersFilterComposer get memberId {
    final $MembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExpenseSplitsOrderingComposer
    extends Composer<_$LocalDatabase, ExpenseSplits> {
  $ExpenseSplitsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get owedMinor => $composableBuilder(
    column: $table.owedMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemsMinor => $composableBuilder(
    column: $table.itemsMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serviceMinor => $composableBuilder(
    column: $table.serviceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxMinor => $composableBuilder(
    column: $table.taxMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get adjustmentMinor => $composableBuilder(
    column: $table.adjustmentMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountMinor => $composableBuilder(
    column: $table.discountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deliveryMinor => $composableBuilder(
    column: $table.deliveryMinor,
    builder: (column) => ColumnOrderings(column),
  );

  $ExpensesOrderingComposer get expenseId {
    final $ExpensesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensesOrderingComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersOrderingComposer get memberId {
    final $MembersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExpenseSplitsAnnotationComposer
    extends Composer<_$LocalDatabase, ExpenseSplits> {
  $ExpenseSplitsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get owedMinor =>
      $composableBuilder(column: $table.owedMinor, builder: (column) => column);

  GeneratedColumn<int> get itemsMinor => $composableBuilder(
    column: $table.itemsMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serviceMinor => $composableBuilder(
    column: $table.serviceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxMinor =>
      $composableBuilder(column: $table.taxMinor, builder: (column) => column);

  GeneratedColumn<int> get adjustmentMinor => $composableBuilder(
    column: $table.adjustmentMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountMinor => $composableBuilder(
    column: $table.discountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deliveryMinor => $composableBuilder(
    column: $table.deliveryMinor,
    builder: (column) => column,
  );

  $ExpensesAnnotationComposer get expenseId {
    final $ExpensesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensesAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersAnnotationComposer get memberId {
    final $MembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExpenseSplitsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          ExpenseSplits,
          SplitRow,
          $ExpenseSplitsFilterComposer,
          $ExpenseSplitsOrderingComposer,
          $ExpenseSplitsAnnotationComposer,
          $ExpenseSplitsCreateCompanionBuilder,
          $ExpenseSplitsUpdateCompanionBuilder,
          (SplitRow, $ExpenseSplitsReferences),
          SplitRow,
          PrefetchHooks Function({bool expenseId, bool memberId})
        > {
  $ExpenseSplitsTableManager(_$LocalDatabase db, ExpenseSplits table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ExpenseSplitsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ExpenseSplitsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ExpenseSplitsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> expenseId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> owedMinor = const Value.absent(),
                Value<int?> itemsMinor = const Value.absent(),
                Value<int?> serviceMinor = const Value.absent(),
                Value<int?> taxMinor = const Value.absent(),
                Value<int?> adjustmentMinor = const Value.absent(),
                Value<int?> discountMinor = const Value.absent(),
                Value<int?> deliveryMinor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseSplitsCompanion(
                expenseId: expenseId,
                memberId: memberId,
                owedMinor: owedMinor,
                itemsMinor: itemsMinor,
                serviceMinor: serviceMinor,
                taxMinor: taxMinor,
                adjustmentMinor: adjustmentMinor,
                discountMinor: discountMinor,
                deliveryMinor: deliveryMinor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String expenseId,
                required String memberId,
                required int owedMinor,
                Value<int?> itemsMinor = const Value.absent(),
                Value<int?> serviceMinor = const Value.absent(),
                Value<int?> taxMinor = const Value.absent(),
                Value<int?> adjustmentMinor = const Value.absent(),
                Value<int?> discountMinor = const Value.absent(),
                Value<int?> deliveryMinor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseSplitsCompanion.insert(
                expenseId: expenseId,
                memberId: memberId,
                owedMinor: owedMinor,
                itemsMinor: itemsMinor,
                serviceMinor: serviceMinor,
                taxMinor: taxMinor,
                adjustmentMinor: adjustmentMinor,
                discountMinor: discountMinor,
                deliveryMinor: deliveryMinor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ExpenseSplits, SplitRow>(table),
                  $ExpenseSplitsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({expenseId = false, memberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (expenseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.expenseId,
                        referencedTable: $ExpenseSplitsReferences
                            ._expenseIdTable(db),
                        referencedColumn: $ExpenseSplitsReferences
                            ._expenseIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (memberId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.memberId,
                        referencedTable: $ExpenseSplitsReferences
                            ._memberIdTable(db),
                        referencedColumn: $ExpenseSplitsReferences
                            ._memberIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $ExpenseSplitsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      ExpenseSplits,
      SplitRow,
      $ExpenseSplitsFilterComposer,
      $ExpenseSplitsOrderingComposer,
      $ExpenseSplitsAnnotationComposer,
      $ExpenseSplitsCreateCompanionBuilder,
      $ExpenseSplitsUpdateCompanionBuilder,
      (SplitRow, $ExpenseSplitsReferences),
      SplitRow,
      PrefetchHooks Function({bool expenseId, bool memberId})
    >;
typedef $ExpenseItemsCreateCompanionBuilder = ExpenseItemsCompanion Function({
  required String id,
  required String expenseId,
  required String name,
  required int amountMinor,
  required int sortOrder,
  Value<int> quantity,
  required int unitAmountMinor,
  Value<int> rowid,
});
typedef $ExpenseItemsUpdateCompanionBuilder = ExpenseItemsCompanion Function({
  Value<String> id,
  Value<String> expenseId,
  Value<String> name,
  Value<int> amountMinor,
  Value<int> sortOrder,
  Value<int> quantity,
  Value<int> unitAmountMinor,
  Value<int> rowid,
});

final class $ExpenseItemsReferences
    extends BaseReferences<_$LocalDatabase, ExpenseItems, ItemRow> {
  $ExpenseItemsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Expenses _expenseIdTable(_$LocalDatabase db) =>
      db.expenses.createAlias('expense_items__expense_id__expenses__id');

  $ExpensesProcessedTableManager get expenseId {
    final $_column = $_itemColumn<String>('expense_id')!;

    final manager = $ExpensesTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<ExpenseItemAssignees, List<AssigneeRow>>
  _expenseItemAssigneesRefsTable(_$LocalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.expenseItemAssignees,
        aliasName: 'expense_items__id__expense_item_assignees__item_id',
      );

  $ExpenseItemAssigneesProcessedTableManager get expenseItemAssigneesRefs {
    final manager = $ExpenseItemAssigneesTableManager(
      $_db,
      $_db.expenseItemAssignees,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _expenseItemAssigneesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ExpenseItemsFilterComposer
    extends Composer<_$LocalDatabase, ExpenseItems> {
  $ExpenseItemsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitAmountMinor => $composableBuilder(
    column: $table.unitAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  $ExpensesFilterComposer get expenseId {
    final $ExpensesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensesFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> expenseItemAssigneesRefs(
    Expression<bool> Function($ExpenseItemAssigneesFilterComposer f) f,
  ) {
    final $ExpenseItemAssigneesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseItemAssignees,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseItemAssigneesFilterComposer(
            $db: $db,
            $table: $db.expenseItemAssignees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ExpenseItemsOrderingComposer
    extends Composer<_$LocalDatabase, ExpenseItems> {
  $ExpenseItemsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitAmountMinor => $composableBuilder(
    column: $table.unitAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  $ExpensesOrderingComposer get expenseId {
    final $ExpensesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensesOrderingComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExpenseItemsAnnotationComposer
    extends Composer<_$LocalDatabase, ExpenseItems> {
  $ExpenseItemsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get unitAmountMinor => $composableBuilder(
    column: $table.unitAmountMinor,
    builder: (column) => column,
  );

  $ExpensesAnnotationComposer get expenseId {
    final $ExpensesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensesAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> expenseItemAssigneesRefs<T extends Object>(
    Expression<T> Function($ExpenseItemAssigneesAnnotationComposer a) f,
  ) {
    final $ExpenseItemAssigneesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseItemAssignees,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseItemAssigneesAnnotationComposer(
            $db: $db,
            $table: $db.expenseItemAssignees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ExpenseItemsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          ExpenseItems,
          ItemRow,
          $ExpenseItemsFilterComposer,
          $ExpenseItemsOrderingComposer,
          $ExpenseItemsAnnotationComposer,
          $ExpenseItemsCreateCompanionBuilder,
          $ExpenseItemsUpdateCompanionBuilder,
          (ItemRow, $ExpenseItemsReferences),
          ItemRow,
          PrefetchHooks Function({
            bool expenseId,
            bool expenseItemAssigneesRefs,
          })
        > {
  $ExpenseItemsTableManager(_$LocalDatabase db, ExpenseItems table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ExpenseItemsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ExpenseItemsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ExpenseItemsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> expenseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> unitAmountMinor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseItemsCompanion(
                id: id,
                expenseId: expenseId,
                name: name,
                amountMinor: amountMinor,
                sortOrder: sortOrder,
                quantity: quantity,
                unitAmountMinor: unitAmountMinor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String expenseId,
                required String name,
                required int amountMinor,
                required int sortOrder,
                Value<int> quantity = const Value.absent(),
                required int unitAmountMinor,
                Value<int> rowid = const Value.absent(),
              }) => ExpenseItemsCompanion.insert(
                id: id,
                expenseId: expenseId,
                name: name,
                amountMinor: amountMinor,
                sortOrder: sortOrder,
                quantity: quantity,
                unitAmountMinor: unitAmountMinor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ExpenseItems, ItemRow>(table),
                  $ExpenseItemsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({expenseId = false, expenseItemAssigneesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (expenseItemAssigneesRefs) db.expenseItemAssignees,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (expenseId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.expenseId,
                            referencedTable: $ExpenseItemsReferences
                                ._expenseIdTable(db),
                            referencedColumn: $ExpenseItemsReferences
                                ._expenseIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (expenseItemAssigneesRefs)
                        await $_getPrefetchedDataByColumns<
                          ItemRow,
                          ExpenseItems,
                          AssigneeRow,
                          ExpenseItemAssignees
                        >(
                          currentTable: table,
                          referencedTable: $ExpenseItemsReferences
                              ._expenseItemAssigneesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ExpenseItemsReferences(
                                db,
                                table,
                                p0,
                              ).expenseItemAssigneesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'item_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $ExpenseItemsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      ExpenseItems,
      ItemRow,
      $ExpenseItemsFilterComposer,
      $ExpenseItemsOrderingComposer,
      $ExpenseItemsAnnotationComposer,
      $ExpenseItemsCreateCompanionBuilder,
      $ExpenseItemsUpdateCompanionBuilder,
      (ItemRow, $ExpenseItemsReferences),
      ItemRow,
      PrefetchHooks Function({bool expenseId, bool expenseItemAssigneesRefs})
    >;
typedef $ExpenseItemAssigneesCreateCompanionBuilder =
    ExpenseItemAssigneesCompanion Function({
      required String itemId,
      required String memberId,
      Value<int> rowid,
    });
typedef $ExpenseItemAssigneesUpdateCompanionBuilder =
    ExpenseItemAssigneesCompanion Function({
      Value<String> itemId,
      Value<String> memberId,
      Value<int> rowid,
    });

final class $ExpenseItemAssigneesReferences
    extends BaseReferences<_$LocalDatabase, ExpenseItemAssignees, AssigneeRow> {
  $ExpenseItemAssigneesReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static ExpenseItems _itemIdTable(_$LocalDatabase db) => db.expenseItems
      .createAlias('expense_item_assignees__item_id__expense_items__id');

  $ExpenseItemsProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $ExpenseItemsTableManager(
      $_db,
      $_db.expenseItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Members _memberIdTable(_$LocalDatabase db) =>
      db.members.createAlias('expense_item_assignees__member_id__members__id');

  $MembersProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $MembersTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $ExpenseItemAssigneesFilterComposer
    extends Composer<_$LocalDatabase, ExpenseItemAssignees> {
  $ExpenseItemAssigneesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $ExpenseItemsFilterComposer get itemId {
    final $ExpenseItemsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.expenseItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseItemsFilterComposer(
            $db: $db,
            $table: $db.expenseItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersFilterComposer get memberId {
    final $MembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExpenseItemAssigneesOrderingComposer
    extends Composer<_$LocalDatabase, ExpenseItemAssignees> {
  $ExpenseItemAssigneesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $ExpenseItemsOrderingComposer get itemId {
    final $ExpenseItemsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.expenseItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseItemsOrderingComposer(
            $db: $db,
            $table: $db.expenseItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersOrderingComposer get memberId {
    final $MembersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExpenseItemAssigneesAnnotationComposer
    extends Composer<_$LocalDatabase, ExpenseItemAssignees> {
  $ExpenseItemAssigneesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $ExpenseItemsAnnotationComposer get itemId {
    final $ExpenseItemsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.expenseItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseItemsAnnotationComposer(
            $db: $db,
            $table: $db.expenseItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersAnnotationComposer get memberId {
    final $MembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExpenseItemAssigneesTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          ExpenseItemAssignees,
          AssigneeRow,
          $ExpenseItemAssigneesFilterComposer,
          $ExpenseItemAssigneesOrderingComposer,
          $ExpenseItemAssigneesAnnotationComposer,
          $ExpenseItemAssigneesCreateCompanionBuilder,
          $ExpenseItemAssigneesUpdateCompanionBuilder,
          (AssigneeRow, $ExpenseItemAssigneesReferences),
          AssigneeRow,
          PrefetchHooks Function({bool itemId, bool memberId})
        > {
  $ExpenseItemAssigneesTableManager(
    _$LocalDatabase db,
    ExpenseItemAssignees table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ExpenseItemAssigneesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ExpenseItemAssigneesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ExpenseItemAssigneesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseItemAssigneesCompanion(
                itemId: itemId,
                memberId: memberId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required String memberId,
                Value<int> rowid = const Value.absent(),
              }) => ExpenseItemAssigneesCompanion.insert(
                itemId: itemId,
                memberId: memberId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ExpenseItemAssignees, AssigneeRow>(table),
                  $ExpenseItemAssigneesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false, memberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $ExpenseItemAssigneesReferences
                            ._itemIdTable(db),
                        referencedColumn: $ExpenseItemAssigneesReferences
                            ._itemIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (memberId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.memberId,
                        referencedTable: $ExpenseItemAssigneesReferences
                            ._memberIdTable(db),
                        referencedColumn: $ExpenseItemAssigneesReferences
                            ._memberIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $ExpenseItemAssigneesProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      ExpenseItemAssignees,
      AssigneeRow,
      $ExpenseItemAssigneesFilterComposer,
      $ExpenseItemAssigneesOrderingComposer,
      $ExpenseItemAssigneesAnnotationComposer,
      $ExpenseItemAssigneesCreateCompanionBuilder,
      $ExpenseItemAssigneesUpdateCompanionBuilder,
      (AssigneeRow, $ExpenseItemAssigneesReferences),
      AssigneeRow,
      PrefetchHooks Function({bool itemId, bool memberId})
    >;
typedef $ExpenseRevisionsCreateCompanionBuilder =
    ExpenseRevisionsCompanion Function({
      required String id,
      required String expenseId,
      required int version,
      required String changeType,
      required String snapshot,
      required String changedByUserId,
      required int changedAt,
      Value<int> rowid,
    });
typedef $ExpenseRevisionsUpdateCompanionBuilder =
    ExpenseRevisionsCompanion Function({
      Value<String> id,
      Value<String> expenseId,
      Value<int> version,
      Value<String> changeType,
      Value<String> snapshot,
      Value<String> changedByUserId,
      Value<int> changedAt,
      Value<int> rowid,
    });

final class $ExpenseRevisionsReferences
    extends BaseReferences<_$LocalDatabase, ExpenseRevisions, RevisionRow> {
  $ExpenseRevisionsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Expenses _expenseIdTable(_$LocalDatabase db) =>
      db.expenses.createAlias('expense_revisions__expense_id__expenses__id');

  $ExpensesProcessedTableManager get expenseId {
    final $_column = $_itemColumn<String>('expense_id')!;

    final manager = $ExpensesTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static LocalProfile _changedByUserIdTable(_$LocalDatabase db) => db
      .localProfile
      .createAlias('expense_revisions__changed_by_user_id__local_profile__id');

  $LocalProfileProcessedTableManager get changedByUserId {
    final $_column = $_itemColumn<String>('changed_by_user_id')!;

    final manager = $LocalProfileTableManager(
      $_db,
      $_db.localProfile,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_changedByUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $ExpenseRevisionsFilterComposer
    extends Composer<_$LocalDatabase, ExpenseRevisions> {
  $ExpenseRevisionsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  $ExpensesFilterComposer get expenseId {
    final $ExpensesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensesFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $LocalProfileFilterComposer get changedByUserId {
    final $LocalProfileFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.changedByUserId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileFilterComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExpenseRevisionsOrderingComposer
    extends Composer<_$LocalDatabase, ExpenseRevisions> {
  $ExpenseRevisionsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $ExpensesOrderingComposer get expenseId {
    final $ExpensesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensesOrderingComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $LocalProfileOrderingComposer get changedByUserId {
    final $LocalProfileOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.changedByUserId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileOrderingComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExpenseRevisionsAnnotationComposer
    extends Composer<_$LocalDatabase, ExpenseRevisions> {
  $ExpenseRevisionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get snapshot =>
      $composableBuilder(column: $table.snapshot, builder: (column) => column);

  GeneratedColumn<int> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  $ExpensesAnnotationComposer get expenseId {
    final $ExpensesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpensesAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $LocalProfileAnnotationComposer get changedByUserId {
    final $LocalProfileAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.changedByUserId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileAnnotationComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExpenseRevisionsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          ExpenseRevisions,
          RevisionRow,
          $ExpenseRevisionsFilterComposer,
          $ExpenseRevisionsOrderingComposer,
          $ExpenseRevisionsAnnotationComposer,
          $ExpenseRevisionsCreateCompanionBuilder,
          $ExpenseRevisionsUpdateCompanionBuilder,
          (RevisionRow, $ExpenseRevisionsReferences),
          RevisionRow,
          PrefetchHooks Function({bool expenseId, bool changedByUserId})
        > {
  $ExpenseRevisionsTableManager(_$LocalDatabase db, ExpenseRevisions table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ExpenseRevisionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ExpenseRevisionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ExpenseRevisionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> expenseId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> changeType = const Value.absent(),
                Value<String> snapshot = const Value.absent(),
                Value<String> changedByUserId = const Value.absent(),
                Value<int> changedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseRevisionsCompanion(
                id: id,
                expenseId: expenseId,
                version: version,
                changeType: changeType,
                snapshot: snapshot,
                changedByUserId: changedByUserId,
                changedAt: changedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String expenseId,
                required int version,
                required String changeType,
                required String snapshot,
                required String changedByUserId,
                required int changedAt,
                Value<int> rowid = const Value.absent(),
              }) => ExpenseRevisionsCompanion.insert(
                id: id,
                expenseId: expenseId,
                version: version,
                changeType: changeType,
                snapshot: snapshot,
                changedByUserId: changedByUserId,
                changedAt: changedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ExpenseRevisions, RevisionRow>(table),
                  $ExpenseRevisionsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({expenseId = false, changedByUserId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (expenseId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.expenseId,
                            referencedTable: $ExpenseRevisionsReferences
                                ._expenseIdTable(db),
                            referencedColumn: $ExpenseRevisionsReferences
                                ._expenseIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (changedByUserId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.changedByUserId,
                            referencedTable: $ExpenseRevisionsReferences
                                ._changedByUserIdTable(db),
                            referencedColumn: $ExpenseRevisionsReferences
                                ._changedByUserIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $ExpenseRevisionsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      ExpenseRevisions,
      RevisionRow,
      $ExpenseRevisionsFilterComposer,
      $ExpenseRevisionsOrderingComposer,
      $ExpenseRevisionsAnnotationComposer,
      $ExpenseRevisionsCreateCompanionBuilder,
      $ExpenseRevisionsUpdateCompanionBuilder,
      (RevisionRow, $ExpenseRevisionsReferences),
      RevisionRow,
      PrefetchHooks Function({bool expenseId, bool changedByUserId})
    >;
typedef $SettlementsCreateCompanionBuilder = SettlementsCompanion Function({
  required String id,
  required String groupId,
  required String fromMemberId,
  required String toMemberId,
  required int amountMinor,
  required String settledOn,
  Value<String?> note,
  required String createdByUserId,
  Value<String?> createdByMemberId,
  required int createdAt,
  required String status,
  required int declaredAt,
  Value<int?> confirmedAt,
  Value<int?> disputedAt,
  Value<int?> cancelledAt,
  Value<int> recordedByAdmin,
  Value<String> kind,
  Value<int> rowid,
});
typedef $SettlementsUpdateCompanionBuilder = SettlementsCompanion Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> fromMemberId,
  Value<String> toMemberId,
  Value<int> amountMinor,
  Value<String> settledOn,
  Value<String?> note,
  Value<String> createdByUserId,
  Value<String?> createdByMemberId,
  Value<int> createdAt,
  Value<String> status,
  Value<int> declaredAt,
  Value<int?> confirmedAt,
  Value<int?> disputedAt,
  Value<int?> cancelledAt,
  Value<int> recordedByAdmin,
  Value<String> kind,
  Value<int> rowid,
});

final class $SettlementsReferences
    extends BaseReferences<_$LocalDatabase, Settlements, SettlementRow> {
  $SettlementsReferences(super.$_db, super.$_table, super.$_typedResult);

  static ExpenseGroups _groupIdTable(_$LocalDatabase db) =>
      db.expenseGroups.createAlias('settlements__group_id__expense_groups__id');

  $ExpenseGroupsProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $ExpenseGroupsTableManager(
      $_db,
      $_db.expenseGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Members _fromMemberIdTable(_$LocalDatabase db) =>
      db.members.createAlias('settlements__from_member_id__members__id');

  $MembersProcessedTableManager get fromMemberId {
    final $_column = $_itemColumn<String>('from_member_id')!;

    final manager = $MembersTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromMemberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Members _toMemberIdTable(_$LocalDatabase db) =>
      db.members.createAlias('settlements__to_member_id__members__id');

  $MembersProcessedTableManager get toMemberId {
    final $_column = $_itemColumn<String>('to_member_id')!;

    final manager = $MembersTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toMemberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static LocalProfile _createdByUserIdTable(_$LocalDatabase db) => db
      .localProfile
      .createAlias('settlements__created_by_user_id__local_profile__id');

  $LocalProfileProcessedTableManager get createdByUserId {
    final $_column = $_itemColumn<String>('created_by_user_id')!;

    final manager = $LocalProfileTableManager(
      $_db,
      $_db.localProfile,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Members _createdByMemberIdTable(_$LocalDatabase db) =>
      db.members.createAlias('settlements__created_by_member_id__members__id');

  $MembersProcessedTableManager? get createdByMemberId {
    final $_column = $_itemColumn<String>('created_by_member_id');
    if ($_column == null) return null;
    final manager = $MembersTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByMemberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $SettlementsFilterComposer
    extends Composer<_$LocalDatabase, Settlements> {
  $SettlementsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settledOn => $composableBuilder(
    column: $table.settledOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get declaredAt => $composableBuilder(
    column: $table.declaredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get disputedAt => $composableBuilder(
    column: $table.disputedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordedByAdmin => $composableBuilder(
    column: $table.recordedByAdmin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  $ExpenseGroupsFilterComposer get groupId {
    final $ExpenseGroupsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.expenseGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseGroupsFilterComposer(
            $db: $db,
            $table: $db.expenseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersFilterComposer get fromMemberId {
    final $MembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersFilterComposer get toMemberId {
    final $MembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $LocalProfileFilterComposer get createdByUserId {
    final $LocalProfileFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileFilterComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersFilterComposer get createdByMemberId {
    final $MembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SettlementsOrderingComposer
    extends Composer<_$LocalDatabase, Settlements> {
  $SettlementsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settledOn => $composableBuilder(
    column: $table.settledOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get declaredAt => $composableBuilder(
    column: $table.declaredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get disputedAt => $composableBuilder(
    column: $table.disputedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedByAdmin => $composableBuilder(
    column: $table.recordedByAdmin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  $ExpenseGroupsOrderingComposer get groupId {
    final $ExpenseGroupsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.expenseGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseGroupsOrderingComposer(
            $db: $db,
            $table: $db.expenseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersOrderingComposer get fromMemberId {
    final $MembersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersOrderingComposer get toMemberId {
    final $MembersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $LocalProfileOrderingComposer get createdByUserId {
    final $LocalProfileOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileOrderingComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersOrderingComposer get createdByMemberId {
    final $MembersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SettlementsAnnotationComposer
    extends Composer<_$LocalDatabase, Settlements> {
  $SettlementsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settledOn =>
      $composableBuilder(column: $table.settledOn, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get declaredAt => $composableBuilder(
    column: $table.declaredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get disputedAt => $composableBuilder(
    column: $table.disputedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cancelledAt => $composableBuilder(
    column: $table.cancelledAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordedByAdmin => $composableBuilder(
    column: $table.recordedByAdmin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  $ExpenseGroupsAnnotationComposer get groupId {
    final $ExpenseGroupsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.expenseGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExpenseGroupsAnnotationComposer(
            $db: $db,
            $table: $db.expenseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersAnnotationComposer get fromMemberId {
    final $MembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersAnnotationComposer get toMemberId {
    final $MembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $LocalProfileAnnotationComposer get createdByUserId {
    final $LocalProfileAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileAnnotationComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $MembersAnnotationComposer get createdByMemberId {
    final $MembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MembersAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SettlementsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          Settlements,
          SettlementRow,
          $SettlementsFilterComposer,
          $SettlementsOrderingComposer,
          $SettlementsAnnotationComposer,
          $SettlementsCreateCompanionBuilder,
          $SettlementsUpdateCompanionBuilder,
          (SettlementRow, $SettlementsReferences),
          SettlementRow,
          PrefetchHooks Function({
            bool groupId,
            bool fromMemberId,
            bool toMemberId,
            bool createdByUserId,
            bool createdByMemberId,
          })
        > {
  $SettlementsTableManager(_$LocalDatabase db, Settlements table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SettlementsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SettlementsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SettlementsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> fromMemberId = const Value.absent(),
                Value<String> toMemberId = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> settledOn = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> createdByUserId = const Value.absent(),
                Value<String?> createdByMemberId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> declaredAt = const Value.absent(),
                Value<int?> confirmedAt = const Value.absent(),
                Value<int?> disputedAt = const Value.absent(),
                Value<int?> cancelledAt = const Value.absent(),
                Value<int> recordedByAdmin = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettlementsCompanion(
                id: id,
                groupId: groupId,
                fromMemberId: fromMemberId,
                toMemberId: toMemberId,
                amountMinor: amountMinor,
                settledOn: settledOn,
                note: note,
                createdByUserId: createdByUserId,
                createdByMemberId: createdByMemberId,
                createdAt: createdAt,
                status: status,
                declaredAt: declaredAt,
                confirmedAt: confirmedAt,
                disputedAt: disputedAt,
                cancelledAt: cancelledAt,
                recordedByAdmin: recordedByAdmin,
                kind: kind,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String fromMemberId,
                required String toMemberId,
                required int amountMinor,
                required String settledOn,
                Value<String?> note = const Value.absent(),
                required String createdByUserId,
                Value<String?> createdByMemberId = const Value.absent(),
                required int createdAt,
                required String status,
                required int declaredAt,
                Value<int?> confirmedAt = const Value.absent(),
                Value<int?> disputedAt = const Value.absent(),
                Value<int?> cancelledAt = const Value.absent(),
                Value<int> recordedByAdmin = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettlementsCompanion.insert(
                id: id,
                groupId: groupId,
                fromMemberId: fromMemberId,
                toMemberId: toMemberId,
                amountMinor: amountMinor,
                settledOn: settledOn,
                note: note,
                createdByUserId: createdByUserId,
                createdByMemberId: createdByMemberId,
                createdAt: createdAt,
                status: status,
                declaredAt: declaredAt,
                confirmedAt: confirmedAt,
                disputedAt: disputedAt,
                cancelledAt: cancelledAt,
                recordedByAdmin: recordedByAdmin,
                kind: kind,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Settlements, SettlementRow>(table),
                  $SettlementsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                groupId = false,
                fromMemberId = false,
                toMemberId = false,
                createdByUserId = false,
                createdByMemberId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.groupId,
                            referencedTable: $SettlementsReferences
                                ._groupIdTable(db),
                            referencedColumn: $SettlementsReferences
                                ._groupIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (fromMemberId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.fromMemberId,
                            referencedTable: $SettlementsReferences
                                ._fromMemberIdTable(db),
                            referencedColumn: $SettlementsReferences
                                ._fromMemberIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (toMemberId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.toMemberId,
                            referencedTable: $SettlementsReferences
                                ._toMemberIdTable(db),
                            referencedColumn: $SettlementsReferences
                                ._toMemberIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (createdByUserId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.createdByUserId,
                            referencedTable: $SettlementsReferences
                                ._createdByUserIdTable(db),
                            referencedColumn: $SettlementsReferences
                                ._createdByUserIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (createdByMemberId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.createdByMemberId,
                            referencedTable: $SettlementsReferences
                                ._createdByMemberIdTable(db),
                            referencedColumn: $SettlementsReferences
                                ._createdByMemberIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $SettlementsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      Settlements,
      SettlementRow,
      $SettlementsFilterComposer,
      $SettlementsOrderingComposer,
      $SettlementsAnnotationComposer,
      $SettlementsCreateCompanionBuilder,
      $SettlementsUpdateCompanionBuilder,
      (SettlementRow, $SettlementsReferences),
      SettlementRow,
      PrefetchHooks Function({
        bool groupId,
        bool fromMemberId,
        bool toMemberId,
        bool createdByUserId,
        bool createdByMemberId,
      })
    >;
typedef $PaymentHandlesCreateCompanionBuilder =
    PaymentHandlesCompanion Function({
      required String id,
      required String userId,
      required String type,
      required String value,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $PaymentHandlesUpdateCompanionBuilder =
    PaymentHandlesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> type,
      Value<String> value,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $PaymentHandlesReferences
    extends BaseReferences<_$LocalDatabase, PaymentHandles, PaymentHandleRow> {
  $PaymentHandlesReferences(super.$_db, super.$_table, super.$_typedResult);

  static LocalProfile _userIdTable(_$LocalDatabase db) => db.localProfile
      .createAlias('payment_handles__user_id__local_profile__id');

  $LocalProfileProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $LocalProfileTableManager(
      $_db,
      $_db.localProfile,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $PaymentHandlesFilterComposer
    extends Composer<_$LocalDatabase, PaymentHandles> {
  $PaymentHandlesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $LocalProfileFilterComposer get userId {
    final $LocalProfileFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileFilterComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PaymentHandlesOrderingComposer
    extends Composer<_$LocalDatabase, PaymentHandles> {
  $PaymentHandlesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $LocalProfileOrderingComposer get userId {
    final $LocalProfileOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileOrderingComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PaymentHandlesAnnotationComposer
    extends Composer<_$LocalDatabase, PaymentHandles> {
  $PaymentHandlesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $LocalProfileAnnotationComposer get userId {
    final $LocalProfileAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.localProfile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LocalProfileAnnotationComposer(
            $db: $db,
            $table: $db.localProfile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PaymentHandlesTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          PaymentHandles,
          PaymentHandleRow,
          $PaymentHandlesFilterComposer,
          $PaymentHandlesOrderingComposer,
          $PaymentHandlesAnnotationComposer,
          $PaymentHandlesCreateCompanionBuilder,
          $PaymentHandlesUpdateCompanionBuilder,
          (PaymentHandleRow, $PaymentHandlesReferences),
          PaymentHandleRow,
          PrefetchHooks Function({bool userId})
        > {
  $PaymentHandlesTableManager(_$LocalDatabase db, PaymentHandles table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PaymentHandlesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PaymentHandlesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PaymentHandlesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentHandlesCompanion(
                id: id,
                userId: userId,
                type: type,
                value: value,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String type,
                required String value,
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PaymentHandlesCompanion.insert(
                id: id,
                userId: userId,
                type: type,
                value: value,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<PaymentHandles, PaymentHandleRow>(table),
                  $PaymentHandlesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.userId,
                        referencedTable: $PaymentHandlesReferences._userIdTable(
                          db,
                        ),
                        referencedColumn: $PaymentHandlesReferences
                            ._userIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $PaymentHandlesProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      PaymentHandles,
      PaymentHandleRow,
      $PaymentHandlesFilterComposer,
      $PaymentHandlesOrderingComposer,
      $PaymentHandlesAnnotationComposer,
      $PaymentHandlesCreateCompanionBuilder,
      $PaymentHandlesUpdateCompanionBuilder,
      (PaymentHandleRow, $PaymentHandlesReferences),
      PaymentHandleRow,
      PrefetchHooks Function({bool userId})
    >;
typedef $IdempotencyKeysCreateCompanionBuilder =
    IdempotencyKeysCompanion Function({
      required String key,
      required String endpoint,
      required String requestHash,
      required int responseStatus,
      required String responseBody,
      required int createdAt,
      Value<int> rowid,
    });
typedef $IdempotencyKeysUpdateCompanionBuilder =
    IdempotencyKeysCompanion Function({
      Value<String> key,
      Value<String> endpoint,
      Value<String> requestHash,
      Value<int> responseStatus,
      Value<String> responseBody,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $IdempotencyKeysFilterComposer
    extends Composer<_$LocalDatabase, IdempotencyKeys> {
  $IdempotencyKeysFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestHash => $composableBuilder(
    column: $table.requestHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get responseStatus => $composableBuilder(
    column: $table.responseStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseBody => $composableBuilder(
    column: $table.responseBody,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $IdempotencyKeysOrderingComposer
    extends Composer<_$LocalDatabase, IdempotencyKeys> {
  $IdempotencyKeysOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestHash => $composableBuilder(
    column: $table.requestHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get responseStatus => $composableBuilder(
    column: $table.responseStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseBody => $composableBuilder(
    column: $table.responseBody,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $IdempotencyKeysAnnotationComposer
    extends Composer<_$LocalDatabase, IdempotencyKeys> {
  $IdempotencyKeysAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get requestHash => $composableBuilder(
    column: $table.requestHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get responseStatus => $composableBuilder(
    column: $table.responseStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get responseBody => $composableBuilder(
    column: $table.responseBody,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $IdempotencyKeysTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          IdempotencyKeys,
          IdempotencyRow,
          $IdempotencyKeysFilterComposer,
          $IdempotencyKeysOrderingComposer,
          $IdempotencyKeysAnnotationComposer,
          $IdempotencyKeysCreateCompanionBuilder,
          $IdempotencyKeysUpdateCompanionBuilder,
          (
            IdempotencyRow,
            BaseReferences<_$LocalDatabase, IdempotencyKeys, IdempotencyRow>,
          ),
          IdempotencyRow,
          PrefetchHooks Function()
        > {
  $IdempotencyKeysTableManager(_$LocalDatabase db, IdempotencyKeys table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $IdempotencyKeysFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $IdempotencyKeysOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $IdempotencyKeysAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> endpoint = const Value.absent(),
                Value<String> requestHash = const Value.absent(),
                Value<int> responseStatus = const Value.absent(),
                Value<String> responseBody = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IdempotencyKeysCompanion(
                key: key,
                endpoint: endpoint,
                requestHash: requestHash,
                responseStatus: responseStatus,
                responseBody: responseBody,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String endpoint,
                required String requestHash,
                required int responseStatus,
                required String responseBody,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => IdempotencyKeysCompanion.insert(
                key: key,
                endpoint: endpoint,
                requestHash: requestHash,
                responseStatus: responseStatus,
                responseBody: responseBody,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<IdempotencyKeys, IdempotencyRow>(table),
                  BaseReferences<
                    _$LocalDatabase,
                    IdempotencyKeys,
                    IdempotencyRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $IdempotencyKeysProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      IdempotencyKeys,
      IdempotencyRow,
      $IdempotencyKeysFilterComposer,
      $IdempotencyKeysOrderingComposer,
      $IdempotencyKeysAnnotationComposer,
      $IdempotencyKeysCreateCompanionBuilder,
      $IdempotencyKeysUpdateCompanionBuilder,
      (
        IdempotencyRow,
        BaseReferences<_$LocalDatabase, IdempotencyKeys, IdempotencyRow>,
      ),
      IdempotencyRow,
      PrefetchHooks Function()
    >;
typedef $FuelPricesCreateCompanionBuilder = FuelPricesCompanion Function({
  required String fuelType,
  required int pricePerLitreMinor,
  required int updatedAt,
  Value<int> rowid,
});
typedef $FuelPricesUpdateCompanionBuilder = FuelPricesCompanion Function({
  Value<String> fuelType,
  Value<int> pricePerLitreMinor,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $FuelPricesFilterComposer extends Composer<_$LocalDatabase, FuelPrices> {
  $FuelPricesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pricePerLitreMinor => $composableBuilder(
    column: $table.pricePerLitreMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $FuelPricesOrderingComposer
    extends Composer<_$LocalDatabase, FuelPrices> {
  $FuelPricesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pricePerLitreMinor => $composableBuilder(
    column: $table.pricePerLitreMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $FuelPricesAnnotationComposer
    extends Composer<_$LocalDatabase, FuelPrices> {
  $FuelPricesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fuelType =>
      $composableBuilder(column: $table.fuelType, builder: (column) => column);

  GeneratedColumn<int> get pricePerLitreMinor => $composableBuilder(
    column: $table.pricePerLitreMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $FuelPricesTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          FuelPrices,
          FuelPriceRow,
          $FuelPricesFilterComposer,
          $FuelPricesOrderingComposer,
          $FuelPricesAnnotationComposer,
          $FuelPricesCreateCompanionBuilder,
          $FuelPricesUpdateCompanionBuilder,
          (
            FuelPriceRow,
            BaseReferences<_$LocalDatabase, FuelPrices, FuelPriceRow>,
          ),
          FuelPriceRow,
          PrefetchHooks Function()
        > {
  $FuelPricesTableManager(_$LocalDatabase db, FuelPrices table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $FuelPricesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $FuelPricesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $FuelPricesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fuelType = const Value.absent(),
                Value<int> pricePerLitreMinor = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FuelPricesCompanion(
                fuelType: fuelType,
                pricePerLitreMinor: pricePerLitreMinor,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fuelType,
                required int pricePerLitreMinor,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FuelPricesCompanion.insert(
                fuelType: fuelType,
                pricePerLitreMinor: pricePerLitreMinor,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<FuelPrices, FuelPriceRow>(table),
                  BaseReferences<_$LocalDatabase, FuelPrices, FuelPriceRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $FuelPricesProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      FuelPrices,
      FuelPriceRow,
      $FuelPricesFilterComposer,
      $FuelPricesOrderingComposer,
      $FuelPricesAnnotationComposer,
      $FuelPricesCreateCompanionBuilder,
      $FuelPricesUpdateCompanionBuilder,
      (FuelPriceRow, BaseReferences<_$LocalDatabase, FuelPrices, FuelPriceRow>),
      FuelPriceRow,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $LocalProfileTableManager get localProfile =>
      $LocalProfileTableManager(_db, _db.localProfile);
  $LocalMetaTableManager get localMeta =>
      $LocalMetaTableManager(_db, _db.localMeta);
  $MembersTableManager get members => $MembersTableManager(_db, _db.members);
  $ExpenseGroupsTableManager get expenseGroups =>
      $ExpenseGroupsTableManager(_db, _db.expenseGroups);
  $ExpensesTableManager get expenses =>
      $ExpensesTableManager(_db, _db.expenses);
  $ExpensePayersTableManager get expensePayers =>
      $ExpensePayersTableManager(_db, _db.expensePayers);
  $ExpenseSplitsTableManager get expenseSplits =>
      $ExpenseSplitsTableManager(_db, _db.expenseSplits);
  $ExpenseItemsTableManager get expenseItems =>
      $ExpenseItemsTableManager(_db, _db.expenseItems);
  $ExpenseItemAssigneesTableManager get expenseItemAssignees =>
      $ExpenseItemAssigneesTableManager(_db, _db.expenseItemAssignees);
  $ExpenseRevisionsTableManager get expenseRevisions =>
      $ExpenseRevisionsTableManager(_db, _db.expenseRevisions);
  $SettlementsTableManager get settlements =>
      $SettlementsTableManager(_db, _db.settlements);
  $PaymentHandlesTableManager get paymentHandles =>
      $PaymentHandlesTableManager(_db, _db.paymentHandles);
  $IdempotencyKeysTableManager get idempotencyKeys =>
      $IdempotencyKeysTableManager(_db, _db.idempotencyKeys);
  $FuelPricesTableManager get fuelPrices =>
      $FuelPricesTableManager(_db, _db.fuelPrices);
}
