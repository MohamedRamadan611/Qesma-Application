import 'json_fields.dart';

/// Request bodies as the server's Java records receive them: every field nullable, read by [JsonFields]
/// (wrong JSON types are already a 400 here; missing values are left to the validators, which answer 422).

final class PayerIn {
  const PayerIn(this.memberId, this.amountMinor);
  final String? memberId;
  final int? amountMinor;

  static PayerIn? read(Object? v) {
    final f = JsonFields.object(v);
    return f == null ? null : PayerIn(f.uuid('memberId'), f.integer('amountMinor'));
  }
}

final class ItemIn {
  const ItemIn(this.name, this.amountMinor, this.assigneeMemberIds);
  final String? name;
  final int? amountMinor;
  final List<String?>? assigneeMemberIds;

  static ItemIn? read(Object? v) {
    final f = JsonFields.object(v);
    return f == null ? null : ItemIn(f.str('name'), f.integer('amountMinor'), f.uuidList('assigneeMemberIds'));
  }
}

final class TaxIn {
  const TaxIn(this.bps, this.base);
  final int? bps;
  final String? base;
}

/// `ExpenseCommand` (create, preview and update share it).
final class ExpenseIn {
  const ExpenseIn({
    this.title,
    this.expenseDate,
    this.splitType,
    this.totalMinor,
    this.payers,
    this.participantMemberIds,
    this.shares,
    this.items,
    this.serviceBps,
    this.hasService = false,
    this.tax,
    this.adjustmentMinor,
    this.category,
  });

  final String? title;
  final String? expenseDate;
  final String? splitType;
  final int? totalMinor;
  final List<PayerIn?>? payers;
  final List<String?>? participantMemberIds;

  /// EXACT shares have the payer shape: `{memberId, amountMinor}`.
  final List<PayerIn?>? shares;
  final List<ItemIn?>? items;

  /// `service` was sent (an object) and its `bps`, which may itself be missing.
  final bool hasService;
  final int? serviceBps;
  final TaxIn? tax;
  final int? adjustmentMinor;
  final String? category;

  static ExpenseIn read(JsonFields f) {
    final service = f.obj('service');
    final tax = f.obj('tax');
    return ExpenseIn(
      title: f.str('title'),
      expenseDate: f.date('expenseDate'),
      splitType: f.str('splitType'),
      totalMinor: f.integer('totalMinor'),
      payers: f.list('payers')?.map(PayerIn.read).toList(),
      participantMemberIds: f.uuidList('participantMemberIds'),
      shares: f.list('shares')?.map(PayerIn.read).toList(),
      items: f.list('items')?.map(ItemIn.read).toList(),
      hasService: service != null,
      serviceBps: service?.integer('bps'),
      tax: tax == null ? null : TaxIn(tax.integer('bps'), tax.str('base')),
      adjustmentMinor: f.integer('adjustmentMinor'),
      category: f.str('category'),
    );
  }
}

/// `SettlementCommand`.
final class SettlementIn {
  const SettlementIn(this.fromMemberId, this.toMemberId, this.amountMinor, this.settledOn, this.note);
  final String? fromMemberId;
  final String? toMemberId;
  final int? amountMinor;
  final String? settledOn;
  final String? note;

  static SettlementIn read(JsonFields f) => SettlementIn(
        f.uuid('fromMemberId'),
        f.uuid('toMemberId'),
        f.integer('amountMinor'),
        f.date('settledOn'),
        f.str('note'),
      );
}
