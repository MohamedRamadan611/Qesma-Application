import 'package:qesma_api/qesma_api.dart';

/// The four states of a settlement (B13). The wire value is a plain string; an unknown one (a newer
/// backend) is [unknown] and gets no actions and a neutral chip.
enum SettlementStatus {
  pending('PENDING'),
  confirmed('CONFIRMED'),
  disputed('DISPUTED'),
  cancelled('CANCELLED'),
  unknown('');

  const SettlementStatus(this.wire);

  final String wire;

  static SettlementStatus fromWire(String? value) {
    for (final s in values) {
      if (s != unknown && s.wire == value) return s;
    }
    return unknown;
  }

  /// Balances count CONFIRMED only; these two are informational (A83).
  bool get isOpen => this == pending || this == disputed;
}

extension SettlementViewStatus on SettlementView {
  SettlementStatus get statusKind => SettlementStatus.fromWire(status);
}

/// What a person can do to a settlement from where it is.
enum SettlementAction { confirm, dispute, cancel }

/// Who may do what (the table of PHASE2_SPEC section 6 and decision A84), as a pure function.
///
/// This only decides which buttons to **show**: the server is the authority and every action still handles
/// `403 FORBIDDEN`, `404` and `409 INVALID_STATE_TRANSITION`.
///
/// * confirm: the receiver, or an Owner/Admin who is not the payer (the payer never confirms their own payment).
/// * dispute: the receiver only, and only while PENDING.
/// * cancel: the payer, or an Owner/Admin.
/// * CONFIRMED and CANCELLED are final: nothing.
Set<SettlementAction> settlementActionsFor({
  required SettlementStatus status,
  required String? yourMemberId,
  required String fromMemberId,
  required String toMemberId,
  required bool isAdminOrOwner,
}) {
  if (!status.isOpen || yourMemberId == null) return const {};
  final isPayer = yourMemberId == fromMemberId;
  final isReceiver = yourMemberId == toMemberId;
  return {
    if (isReceiver || (isAdminOrOwner && !isPayer)) SettlementAction.confirm,
    if (isReceiver && status == SettlementStatus.pending) SettlementAction.dispute,
    if (isPayer || isAdminOrOwner) SettlementAction.cancel,
  };
}

/// What the sheet can say **before** sending about the state the server will give a new payment (A85). It is a hint
/// for the wording and for not offering what would be a certain 403; the state shown afterwards is always the
/// server's.
enum InitialOutcome {
  /// The payer declares to a member with an account: waits for the receiver.
  pending,

  /// The receiver records it, or an Owner/Admin records on behalf: counted at once.
  confirmed,

  /// A plain Member naming a payer or a receiver that is not themselves, or paying a member without an account: the server refuses.
  notAllowed,
}

InitialOutcome expectedInitialOutcome({
  required String? yourMemberId,
  required String? fromMemberId,
  required String? toMemberId,
  required bool receiverHasAccount,
  required bool isAdminOrOwner,
}) {
  if (yourMemberId == null || fromMemberId == null || toMemberId == null) return InitialOutcome.notAllowed;
  if (yourMemberId == fromMemberId) {
    if (receiverHasAccount) return InitialOutcome.pending;
    return isAdminOrOwner ? InitialOutcome.confirmed : InitialOutcome.notAllowed;
  }
  if (yourMemberId == toMemberId) return InitialOutcome.confirmed;
  return isAdminOrOwner ? InitialOutcome.confirmed : InitialOutcome.notAllowed;
}
