import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../local/db/local_database.dart';
import '../../../local/db/local_database_provider.dart';

/// The receipt-scan limits (A145) and the hiding rule (SA12 decision Q1).
const int kDailyScanCap = 20;
const int kPermissionErrorsToHide = 3;
const Duration kHiddenFor = Duration(days: 7);

/// Consent and counters of the receipt scan, kept on this phone only (A148: the drift DB; never in the backup).
final class OcrSettings {
  const OcrSettings({this.consentAt, this.scanDay, this.scanCount = 0, this.permissionErrors = 0, this.hiddenUntil});

  /// UTC epoch ms of the consent, or null when not given (or revoked).
  final int? consentAt;

  /// Cairo calendar day (`YYYY-MM-DD`) of [scanCount].
  final String? scanDay;
  final int scanCount;

  /// Consecutive permission / App Check errors.
  final int permissionErrors;

  /// UTC epoch ms until which the feature hides itself after repeated permission errors.
  final int? hiddenUntil;

  bool get consented => consentAt != null;

  bool isHidden(int nowMs) => hiddenUntil != null && nowMs < hiddenUntil!;

  /// Scans already sent on [today] (0 when the stored day is another one).
  int scansOn(String today) => scanDay == today ? scanCount : 0;

  OcrSettings copyWith({
    int? consentAt,
    bool clearConsent = false,
    String? scanDay,
    int? scanCount,
    int? permissionErrors,
    int? hiddenUntil,
    bool clearHidden = false,
  }) =>
      OcrSettings(
        consentAt: clearConsent ? null : (consentAt ?? this.consentAt),
        scanDay: scanDay ?? this.scanDay,
        scanCount: scanCount ?? this.scanCount,
        permissionErrors: permissionErrors ?? this.permissionErrors,
        hiddenUntil: clearHidden ? null : (hiddenUntil ?? this.hiddenUntil),
      );
}

abstract interface class OcrSettingsStore {
  Future<OcrSettings> read();
  Future<void> write(OcrSettings settings);
}

final class LocalOcrSettingsStore implements OcrSettingsStore {
  const LocalOcrSettingsStore(this._db);

  final LocalDatabase _db;

  @override
  Future<OcrSettings> read() async {
    final meta = await _db.metaDao.get();
    return OcrSettings(
      consentAt: meta.ocrConsentAt,
      scanDay: meta.ocrScanDay,
      scanCount: meta.ocrScanCount,
      permissionErrors: meta.ocrPermissionErrors,
      hiddenUntil: meta.ocrHiddenUntil,
    );
  }

  @override
  Future<void> write(OcrSettings s) => _db.metaDao.writeOcr(
        consentAt: s.consentAt,
        scanDay: s.scanDay,
        scanCount: s.scanCount,
        permissionErrors: s.permissionErrors,
        hiddenUntil: s.hiddenUntil,
      );
}

final ocrSettingsStoreProvider = Provider<OcrSettingsStore>((ref) => LocalOcrSettingsStore(ref.watch(localDatabaseProvider)));
