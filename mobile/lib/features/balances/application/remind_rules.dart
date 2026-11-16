/// Who sees the Remind button on a suggested transfer, and whether it is enabled (PHASE2_SPEC section 8, A107-A109).
/// A pure function: no I/O, no money, no clock of its own.
library;

enum RemindKind {
  /// No button and no caption (not the creditor, no rights, or the debtor has left).
  hidden,

  /// The debtor has no account: nothing to send a reminder to. No button, a caption says why.
  noAccount,

  /// The button is there and works.
  enabled,

  /// The button is there and disabled ("sent today"); [RemindState.until] is the server's time when it may be used again.
  disabled,
}

class RemindState {
  const RemindState(this.kind, [this.until]);

  final RemindKind kind;
  final DateTime? until;

  bool get showsButton => kind == RemindKind.enabled || kind == RemindKind.disabled;

  @override
  bool operator ==(Object other) => other is RemindState && other.kind == kind && other.until == until;

  @override
  int get hashCode => Object.hash(kind, until);

  @override
  String toString() => 'RemindState($kind, $until)';
}

/// The state of the Remind control of one transfer.
///
/// * never shown to the debtor themself (the server answers 422);
/// * visible only to the creditor (the receiver of the transfer) or to an Owner/Admin ([canRemindAny]);
/// * hidden when the debtor has left; a caption instead of a button when the debtor has no account;
/// * disabled while the server says it is too early: [canRemindAt] (from the transfers view) or [lockedUntil] (what the
///   server answered to a send or a 429 in this session). Both are the server's timestamps; the later one wins. The client
///   never works out a window of its own, it only compares those timestamps with [now].
///
/// This decides what is shown. The server still checks everything (403, 422, 429).
RemindState remindStateFor({
  required bool isCreditor,
  bool isDebtor = false,
  required bool canRemindAny,
  required bool debtorHasAccount,
  required String debtorStatus,
  required DateTime? canRemindAt,
  required DateTime now,
  DateTime? lockedUntil,
}) {
  if (isDebtor) return const RemindState(RemindKind.hidden);
  if (!isCreditor && !canRemindAny) return const RemindState(RemindKind.hidden);
  if (debtorStatus != 'ACTIVE') return const RemindState(RemindKind.hidden);
  if (!debtorHasAccount) return const RemindState(RemindKind.noAccount);
  DateTime? until = canRemindAt;
  if (lockedUntil != null && (until == null || lockedUntil.isAfter(until))) until = lockedUntil;
  if (until != null && until.isAfter(now)) return RemindState(RemindKind.disabled, until);
  return const RemindState(RemindKind.enabled);
}
