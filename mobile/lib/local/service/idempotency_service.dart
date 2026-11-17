import 'dart:convert';

import '../db/local_database.dart';
import '../errors.dart';
import 'local_context.dart';

/// A stored or fresh create response: status and JSON body text; [replayed] when it came from the key store.
final class Outcome {
  const Outcome(this.status, this.body, {this.replayed = false});
  final int status;
  final String body;
  final bool replayed;
}

/// Idempotency-Key handling of spec 8.3 (STANDALONE_SPEC 3.4). Callers run [findReplay] and [store] inside the same
/// drift transaction as the business write, so the key row exists exactly when the write committed.
///
/// The request fingerprint is the canonical JSON text itself (Java hashes the same text with SHA-256); comparing the
/// full text is exact and needs no hashing package at runtime. One local user: the key scope is `(key)`.
final class IdempotencyService {
  IdempotencyService(this._ctx);

  final LocalContext _ctx;

  static const int retentionMillis = 24 * 60 * 60 * 1000;

  /// Canonical text of a normalized request: [canonical] must already have a fixed key order and sorted lists.
  static String fingerprint(Map<String, Object?> canonical) => jsonEncode(canonical);

  /// The stored response for [key], or null when the key is new (or older than the retention, which counts as new).
  /// The same key with a different endpoint or request is 422 IDEMPOTENCY_KEY_REUSED.
  Future<Outcome?> findReplay(String key, String endpoint, String requestFingerprint) async {
    final dao = _ctx.db.idempotencyDao;
    final row = await dao.find(key);
    if (row == null) return null;
    if (row.createdAt < _ctx.clock() - retentionMillis) {
      await dao.deleteCreatedBefore(_ctx.clock() - retentionMillis);
      return null;
    }
    if (row.endpoint != endpoint || row.requestHash != requestFingerprint) {
      throw LocalApiException.unprocessable(
        'IDEMPOTENCY_KEY_REUSED',
        'This Idempotency-Key was already used for a different request',
      );
    }
    return Outcome(row.responseStatus, row.responseBody, replayed: true);
  }

  /// Records a successful response (only successes are stored).
  Future<void> store(String key, String endpoint, String requestFingerprint, Outcome outcome) =>
      _ctx.db.idempotencyDao.insertKey(IdempotencyRow(
        key: key,
        endpoint: endpoint,
        requestHash: requestFingerprint,
        responseStatus: outcome.status,
        responseBody: outcome.body,
        createdAt: _ctx.clock(),
      ));

  /// Retention purge at app start: deletes keys older than 24 hours. Returns the number removed.
  Future<int> purgeExpired() => _ctx.db.idempotencyDao.deleteCreatedBefore(_ctx.clock() - retentionMillis);
}
