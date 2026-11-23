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

/// `ItemInput`: legacy [amountMinor] (quantity 1) or [unitAmountMinor] with an optional [quantity] (A172, BSA2).
final class ItemIn {
  const ItemIn(this.name, this.amountMinor, this.assigneeMemberIds, {this.unitAmountMinor, this.quantity});
  final String? name;
  final int? amountMinor;
  final int? unitAmountMinor;
  final int? quantity;
  final List<String?>? assigneeMemberIds;

  static ItemIn? read(Object? v) {
    final f = JsonFields.object(v);
    return f == null
        ? null
        : ItemIn(f.str('name'), f.integer('amountMinor'), f.uuidList('assigneeMemberIds'),
            unitAmountMinor: f.integer('unitAmountMinor'), quantity: f.integer('quantity'));
  }
}

/// `DiscountInput` / `ServiceInput`: `{bps}` or `{amountMinor}` (A171, A173). An object that was sent is present even
/// when both fields are missing (`{}`), so the validator can refuse it like Java does.
final class ChargeIn {
  const ChargeIn(this.bps, this.amountMinor);
  final int? bps;
  final int? amountMinor;

  static ChargeIn? read(JsonFields? f) => f == null ? null : ChargeIn(f.integer('bps'), f.integer('amountMinor'));
}

/// `TaxInput`: `{bps, base}` or `{amountMinor, base}`.
final class TaxIn {
  const TaxIn(this.bps, this.base, [this.amountMinor]);
  final int? bps;
  final String? base;
  final int? amountMinor;
}

/// `ShareParticipantInput` (BSA3, A195): one SHARES participant; presence only with a period (validator).
final class ShareParticipantIn {
  const ShareParticipantIn(this.memberId, this.shareUnits, {this.presentFrom, this.presentTo});
  final String? memberId;
  final int? shareUnits;
  final String? presentFrom;
  final String? presentTo;

  static ShareParticipantIn? read(Object? v) {
    final f = JsonFields.object(v);
    return f == null
        ? null
        : ShareParticipantIn(f.uuid('memberId'), f.integer('shareUnits'),
            presentFrom: f.date('presentFrom'), presentTo: f.date('presentTo'));
  }
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
    this.discount,
    this.service,
    this.tax,
    this.adjustmentMinor,
    this.deliveryMinor,
    this.category,
    this.paidFromPool,
    this.shareParticipants,
    this.periodFrom,
    this.periodTo,
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

  /// BSA2: one bill discount, null = none.
  final ChargeIn? discount;

  /// null = no service; present (possibly `{}`) when the client sent the object.
  final ChargeIn? service;
  final TaxIn? tax;
  final int? adjustmentMinor;

  /// A180: the delivery amount (ITEMIZED only), null = none.
  final int? deliveryMinor;
  final String? category;

  /// BSA1: optional; true only for a pool expense (single payer = the treasurer).
  final bool? paidFromPool;

  /// BSA3 (A185-A187): SHARES only; the period is optional (both bounds or neither).
  final List<ShareParticipantIn?>? shareParticipants;
  final String? periodFrom;
  final String? periodTo;

  static ExpenseIn read(JsonFields f) {
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
      discount: ChargeIn.read(f.obj('discount')),
      service: ChargeIn.read(f.obj('service')),
      tax: tax == null ? null : TaxIn(tax.integer('bps'), tax.str('base'), tax.integer('amountMinor')),
      adjustmentMinor: f.integer('adjustmentMinor'),
      deliveryMinor: f.integer('deliveryMinor'),
      category: f.str('category'),
      paidFromPool: f.boolean('paidFromPool'),
      shareParticipants: f.list('shareParticipants')?.map(ShareParticipantIn.read).toList(),
      periodFrom: f.date('periodFrom'),
      periodTo: f.date('periodTo'),
    );
  }
}
/// `SettlementCommand`.
final class SettlementIn {
  const SettlementIn(this.fromMemberId, this.toMemberId, this.amountMinor, this.settledOn, this.note, [this.kind]);
  final String? fromMemberId;
  final String? toMemberId;
  final int? amountMinor;
  final String? settledOn;
  final String? note;

  /// BSA1: PAYMENT (default when missing or blank) or POOL_DEPOSIT.
  final String? kind;

  static SettlementIn read(JsonFields f) => SettlementIn(
        f.uuid('fromMemberId'),
        f.uuid('toMemberId'),
        f.integer('amountMinor'),
        f.date('settledOn'),
        f.str('note'),
        f.str('kind'),
      );
}
