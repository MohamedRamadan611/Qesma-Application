import 'package:flutter/foundation.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/money/money.dart';
import '../../../core/widgets/code_point_limit.dart';

final Date kFirstPaymentDate = Date(2000, 1, 1);
final Date kLastPaymentDate = Date(2100, 12, 31);

/// The longest note the server accepts (A44), in code points.
const int kPaymentNoteMax = 200;

/// SA10: the settlement kind of a pool deposit (a plain payment leaves `kind` out: the server default is PAYMENT).
const String kPoolDepositKind = 'POOL_DEPOSIT';

/// What the Record payment sheet is opened with: a tapped transfer (from, to and the server's
/// amount, a copy) or nothing for a payment the user describes themselves.
@immutable
class PaymentSeed {
  const PaymentSeed({this.fromId, this.toId, this.amountMinor, this.poolDeposit = false});

  final String? fromId;
  final String? toId;
  final int? amountMinor;

  /// SA10: a deposit to the pool: [toId] is the treasurer and the settlement kind is POOL_DEPOSIT.
  final bool poolDeposit;

  @override
  bool operator ==(Object other) =>
      other is PaymentSeed && other.fromId == fromId && other.toId == toId && other.amountMinor == amountMinor && other.poolDeposit == poolDeposit;

  @override
  int get hashCode => Object.hash(fromId, toId, amountMinor, poolDeposit);
}

/// Why a field is not acceptable yet (the sheet shows the matching message once the field was touched).
enum PaymentFieldError { amount, date, note, sameMember, missingMember }

/// The sheet's inputs, as typed. Immutable; replaced as a whole. Pure: validation and the request
/// body, and nothing about balances.
@immutable
class PaymentForm {
  const PaymentForm({
    this.fromId,
    this.toId,
    this.amountText = '',
    required this.date,
    this.note = '',
    this.suggestedMinor,
    this.poolDeposit = false,
  });

  final String? fromId;
  final String? toId;
  final String amountText;
  final Date date;
  final String note;

  /// The tapped transfer's amount as the server sent it, for the "full amount" chip. Null for a manual entry.
  final int? suggestedMinor;

  /// SA10: a pool deposit (kind POOL_DEPOSIT, receiver fixed to the treasurer); a plain payment otherwise.
  final bool poolDeposit;

  /// 1..10^12 piasters, or null while the text is not a valid amount.
  int? get amountMinor => Money.parse(amountText);

  bool get dateValid => date.compareTo(kFirstPaymentDate) >= 0 && date.compareTo(kLastPaymentDate) <= 0;

  String get trimmedNote => note.trim();

  bool get noteValid => codePointCount(trimmedNote) <= kPaymentNoteMax;

  /// The first thing wrong, in the order the sheet is read; null when the payment can be sent.
  PaymentFieldError? get firstError {
    if (fromId == null || toId == null) return PaymentFieldError.missingMember;
    if (fromId == toId) return PaymentFieldError.sameMember;
    if (amountMinor == null) return PaymentFieldError.amount;
    if (!dateValid) return PaymentFieldError.date;
    if (!noteValid) return PaymentFieldError.note;
    return null;
  }

  bool get canSend => firstError == null;

  PaymentForm copyWith({String? fromId, String? toId, String? amountText, Date? date, String? note}) => PaymentForm(
        fromId: fromId ?? this.fromId,
        toId: toId ?? this.toId,
        amountText: amountText ?? this.amountText,
        date: date ?? this.date,
        note: note ?? this.note,
        suggestedMinor: suggestedMinor,
        poolDeposit: poolDeposit,
      );

  /// The inputs differ from how the sheet opened (decides the discard question).
  bool differsFrom(PaymentForm other) =>
      fromId != other.fromId || toId != other.toId || amountText != other.amountText || date.compareTo(other.date) != 0 || note != other.note;
}

/// The request for a valid form, or null. The only place a [SettlementCommand] is built:
/// a blank note is left out, a note is trimmed, the amount is an integer.
SettlementCommand? buildSettlementCommand(PaymentForm form) {
  if (!form.canSend) return null;
  final note = form.trimmedNote;
  return SettlementCommand((b) => b
    ..fromMemberId = form.fromId
    ..toMemberId = form.toId
    ..amountMinor = form.amountMinor
    ..settledOn = form.date
    ..note = note.isEmpty ? null : note
    ..kind = form.poolDeposit ? kPoolDepositKind : null);
}

/// The body as JSON-encodable values: what the idempotency key is bound to (same body, same key).
Map<String, Object?> settlementBodyJson(SettlementCommand command) => {
      'fromMemberId': command.fromMemberId,
      'toMemberId': command.toMemberId,
      'amountMinor': command.amountMinor,
      'settledOn': command.settledOn.toString(),
      if (command.note != null) 'note': command.note,
      if (command.kind != null) 'kind': command.kind,
    };
