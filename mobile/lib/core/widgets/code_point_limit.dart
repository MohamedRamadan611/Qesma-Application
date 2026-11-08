import 'package:flutter/services.dart';

/// Counts Unicode code points, the way the backend measures name and title limits
/// ("60 code points"), not UTF-16 units and not grapheme clusters.
int codePointCount(String text) => text.runes.length;

/// Limits input to [max] code points (never splits a surrogate pair).
class CodePointLimitFormatter extends TextInputFormatter {
  const CodePointLimitFormatter(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (codePointCount(newValue.text) <= max) return newValue;
    // The user typed or pasted too much: keep what was there before when it already fits,
    // otherwise cut the new text at the limit.
    final kept = String.fromCharCodes(newValue.text.runes.take(max));
    final end = kept.length;
    return TextEditingValue(
      text: kept,
      selection: TextSelection.collapsed(offset: newValue.selection.baseOffset.clamp(0, end)),
    );
  }
}
