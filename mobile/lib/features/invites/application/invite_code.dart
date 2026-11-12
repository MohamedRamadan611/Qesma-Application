/// The invite code: 8 characters from an unambiguous 32-symbol alphabet, typed as `XXXX-XXXX`
/// (PHASE2_SPEC section 4). Pure functions, no I/O.
library;

const String inviteAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const int inviteCodeLength = 8;

const String _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
const String _easternArabicIndic = '۰۱۲۳۴۵۶۷۸۹';

String _westernDigits(String input) {
  final out = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final a = _arabicIndic.indexOf(char);
    final e = _easternArabicIndic.indexOf(char);
    out.write(a >= 0 ? '$a' : e >= 0 ? '$e' : char);
  }
  return out.toString();
}

/// Zero-width and direction marks that a paste may carry (U+200B..200F, U+202A..202E, U+2066..2069, U+FEFF).
bool _isInvisible(int r) => (r >= 0x200B && r <= 0x200F) || (r >= 0x202A && r <= 0x202E) || (r >= 0x2066 && r <= 0x2069) || r == 0xFEFF;

/// Spaces, dashes and underscores people put in the middle of a code.
bool _isSeparator(int r) => r == 0x20 || r == 0x2D || r == 0x5F || r == 0xA0 || r == 0x09 || r == 0x2010 || r == 0x2011 || r == 0x2013 || r == 0x2014;

/// Turns what a person typed or pasted into the canonical 8 characters, or null when it cannot be a code.
/// Accepts lower case, dashes, spaces, zero-width marks, Arabic-Indic digits and a whole link
/// (`https://host/join/ABCD-2345`).
String? normaliseInviteCode(String? input) {
  if (input == null) return null;
  var text = input.trim();
  final slash = text.lastIndexOf('/');
  if (slash >= 0) text = text.substring(slash + 1);
  final question = text.indexOf(RegExp(r'[?#]'));
  if (question >= 0) text = text.substring(0, question);
  final cleaned = _westernDigits(text).toUpperCase().runes.where((r) => !_isInvisible(r) && !_isSeparator(r)).map(String.fromCharCode).join();
  if (cleaned.length != inviteCodeLength) return null;
  for (final rune in cleaned.runes) {
    if (!inviteAlphabet.contains(String.fromCharCode(rune))) return null;
  }
  return cleaned;
}

/// `ABCD2345` -> `ABCD-2345` (display only; the wire form has no dash).
String formatInviteCode(String? code) {
  final text = code ?? '';
  if (text.length != inviteCodeLength) return text;
  return '${text.substring(0, 4)}-${text.substring(4)}';
}

/// The code of an App Link path `/join/<code>`, or null.
String? codeFromJoinPath(String path) {
  const prefix = '/join/';
  if (!path.startsWith(prefix)) return null;
  return normaliseInviteCode(Uri.decodeComponent(path.substring(prefix.length)));
}
