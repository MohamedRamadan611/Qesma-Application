/// Unicode bidirectional isolates, built from code points (a literal control character in
/// source is invisible to reviewers and flagged by the analyzer).
const String _lri = '\u2066'; // left-to-right isolate
const String _pdi = '\u2069'; // pop directional isolate

/// Non-breaking space (between a number and its currency).
const String nbsp = '\u00A0';

/// Keeps [text] (numbers, ids, codes) in left-to-right order inside a right-to-left
/// sentence without disturbing the sentence's own order.
String ltrIsolate(String text) => '$_lri$text$_pdi';

/// First-strong isolate: [text] takes the direction of its own first letter (an Arabic name
/// reads right-to-left, a Latin one left-to-right) without disturbing the sentence around it.
/// Used for list items that mix names in either script with numbers and separators.
String fsIsolate(String text) => '${String.fromCharCode(0x2068)}$text${String.fromCharCode(0x2069)}';

/// [text] without the direction isolates [ltrIsolate] and [fsIsolate] add: for screen-reader
/// labels, where they are noise.
String stripIsolates(String text) => String.fromCharCodes(text.runes.where((r) => r < 0x2066 || r > 0x2069));
