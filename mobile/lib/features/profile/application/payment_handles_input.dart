/// Client-side convenience checks for payment handles (PHASE2_SPEC section 7, A90). The server is
/// authoritative; these only normalise what a person typed and catch obvious mistakes early.
/// Pure string logic: no I/O, no arithmetic, and the values are never logged.
library;

import 'package:qesma/core/format/western_digits.dart';

enum HandleIssue { wallet, instapay }

/// Outcome of normalising one field. [value] is the canonical text to send, or null to remove the
/// handle. [issue] is set when the text cannot be a valid handle.
class HandleInput {
  const HandleInput.value(String this.value) : issue = null;
  const HandleInput.removed() : value = null, issue = null;
  const HandleInput.invalid(HandleIssue this.issue) : value = null;

  final String? value;
  final HandleIssue? issue;

  bool get isValid => issue == null;
}

bool _isInvisible(int r) => (r >= 0x200B && r <= 0x200F) || (r >= 0x202A && r <= 0x202E) || (r >= 0x2066 && r <= 0x2069) || r == 0xFEFF;

bool _isWalletSeparator(int r) => r == 0x20 || r == 0x09 || r == 0xA0 || r == 0x2D || r == 0x2010 || r == 0x2011 || r == 0x2012 || r == 0x2013 || r == 0x2014 || r == 0x5F;

final RegExp _walletPattern = RegExp(r'^01[0125][0-9]{8}$');
final RegExp _instapayPattern = RegExp(r'^[a-z0-9._-]+@[a-z0-9.-]+$');

/// `01012345678` for what people write as `٠١٠ ١٢٣ ٤٥٦٧٨`, `010-1234-5678` or `+20 10 1234 5678`.
/// A blank field means "remove"; a non-blank field that is empty once stripped (`---`) is invalid.
HandleInput normaliseWallet(String? input) {
  final raw = (input ?? '').trim();
  if (raw.isEmpty) return const HandleInput.removed();
  var digits = westernDigits(raw).runes.where((r) => !_isInvisible(r) && !_isWalletSeparator(r)).map(String.fromCharCode).join();
  if (digits.startsWith('+20')) {
    digits = '0${digits.substring(3)}';
  } else if (digits.startsWith('0020')) {
    digits = '0${digits.substring(4)}';
  }
  if (!_walletPattern.hasMatch(digits)) return const HandleInput.invalid(HandleIssue.wallet);
  return HandleInput.value(digits);
}

/// `name@bank`, 3..60 ASCII characters, exactly one `@`, stored lower case. Blank means "remove".
HandleInput normaliseInstapay(String? input) {
  final raw = (input ?? '').trim();
  if (raw.isEmpty) return const HandleInput.removed();
  final text = raw.toLowerCase();
  final ascii = text.runes.every((r) => r > 0x20 && r < 0x7F);
  if (!ascii || text.length < 3 || text.length > 60) return const HandleInput.invalid(HandleIssue.instapay);
  if ('@'.allMatches(text).length != 1) return const HandleInput.invalid(HandleIssue.instapay);
  if (!_instapayPattern.hasMatch(text)) return const HandleInput.invalid(HandleIssue.instapay);
  return HandleInput.value(text);
}

/// What the two fields say right now, normalised.
class HandlesDraft {
  const HandlesDraft({required this.instapay, required this.wallet});

  final HandleInput instapay;
  final HandleInput wallet;

  bool get isValid => instapay.isValid && wallet.isValid;
}

HandlesDraft evaluateHandles({String? instapay, String? wallet}) => HandlesDraft(instapay: normaliseInstapay(instapay), wallet: normaliseWallet(wallet));

/// The handles as stored on the server (null = not set).
typedef StoredHandles = ({String? instapay, String? wallet});

/// The draft differs from what is stored (decides whether saving makes sense and the discard question).
bool handlesChanged(HandlesDraft draft, StoredHandles stored) =>
    draft.isValid && (draft.instapay.value != _blankToNull(stored.instapay) || draft.wallet.value != _blankToNull(stored.wallet));

/// The handles this save would delete: stored today, empty in the draft.
Set<HandleIssue> handlesRemoved(HandlesDraft draft, StoredHandles stored) => {
      if (draft.instapay.isValid && draft.instapay.value == null && _blankToNull(stored.instapay) != null) HandleIssue.instapay,
      if (draft.wallet.isValid && draft.wallet.value == null && _blankToNull(stored.wallet) != null) HandleIssue.wallet,
    };

String? _blankToNull(String? v) => v == null || v.trim().isEmpty ? null : v;
