/// Unicode bidirectional isolates, built from code points (a literal control character in
/// source is invisible to reviewers and flagged by the analyzer).
const String _lri = '\u2066'; // left-to-right isolate
const String _pdi = '\u2069'; // pop directional isolate

/// Non-breaking space (between a number and its currency).
const String nbsp = '\u00A0';

/// Keeps [text] (numbers, ids, codes) in left-to-right order inside a right-to-left
/// sentence without disturbing the sentence's own order.
String ltrIsolate(String text) => '$_lri$text$_pdi';
