import 'package:drift/drift.dart';

import '../local_database.dart';

part 'payment_handles_dao.g.dart';

/// The local profile's own payment handles (one per type).
@DriftAccessor(include: {'../schema.drift'})
class PaymentHandlesDao extends DatabaseAccessor<LocalDatabase> with _$PaymentHandlesDaoMixin {
  PaymentHandlesDao(super.db);

  Future<List<PaymentHandleRow>> listForUser(String userId) => (select(paymentHandles)
        ..where((h) => h.userId.equals(userId))
        ..orderBy([(h) => OrderingTerm.asc(h.type)]))
      .get();

  /// Inserts, or replaces the value of the existing handle of the same type (keeps its id and createdAt).
  Future<void> upsert(PaymentHandleRow row) => into(paymentHandles).insert(
        row,
        onConflict: DoUpdate(
          (_) => PaymentHandlesCompanion(value: Value(row.value), updatedAt: Value(row.updatedAt)),
          target: [paymentHandles.userId, paymentHandles.type],
        ),
      );

  Future<int> deleteType(String userId, String type) =>
      (delete(paymentHandles)..where((h) => h.userId.equals(userId) & h.type.equals(type))).go();
}
