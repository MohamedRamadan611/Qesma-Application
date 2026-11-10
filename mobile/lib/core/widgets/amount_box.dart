import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Digits (Western or Arabic-Indic) and the separators `Money.parse` understands. Anything else
/// the user types or pastes is dropped.
final TextInputFormatter amountInputFormatter = FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩۰-۹.,٫٬]'));

/// The same plus a minus sign, for an amount that may be negative (the bill adjustment).
final TextInputFormatter signedAmountInputFormatter = FilteringTextInputFormatter.allow(RegExp('[-0-9٠-٩۰-۹.,٫٬]'));

/// A compact amount field for a member row, an item price or a percentage. [text] is the
/// model's value: when it changes from outside (a server prefill, "clear amounts", a stepper) the
/// box shows it, and while the user types the two are equal so the cursor never jumps. The value
/// reads left-to-right in both languages; a screen reader hears [semanticLabel] ("Asem's share").
class AmountBox extends StatefulWidget {
  const AmountBox({
    super.key,
    required this.text,
    required this.semanticLabel,
    required this.onChanged,
    this.enabled = true,
    this.width = 120,
    this.expand = false,
    this.hint = '0.00',
    this.signed = false,
    this.hasError = false,
  });

  final String text;
  final String semanticLabel;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final double width;

  /// Fill the available width (a stacked row at large text sizes) instead of [width].
  final bool expand;

  /// Shown while the box is empty.
  final String hint;

  /// Accept a leading minus sign.
  final bool signed;

  /// Draw the error border (the message itself is the caller's, next to the box).
  final bool hasError;

  @override
  State<AmountBox> createState() => _AmountBoxState();
}

class _AmountBoxState extends State<AmountBox> {
  late final TextEditingController _controller = TextEditingController(text: widget.text);

  @override
  void didUpdateWidget(AmountBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.text) {
      _controller.value = TextEditingValue(text: widget.text, selection: TextSelection.collapsed(offset: widget.text.length));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorBorder = widget.hasError
        ? OutlineInputBorder(borderRadius: BorderRadius.circular(QesmaRadii.control), borderSide: const BorderSide(color: QesmaColors.error, width: 1.5))
        : null;
    return SizedBox(
      width: widget.expand ? double.infinity : widget.width,
      child: Semantics(
        label: widget.semanticLabel,
        textField: true,
        child: TextField(
          controller: _controller,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          keyboardType: TextInputType.numberWithOptions(decimal: true, signed: widget.signed),
          inputFormatters: [widget.signed ? signedAmountInputFormatter : amountInputFormatter],
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.titleMedium,
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hint,
            contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: QesmaSpacing.sm + 4, vertical: QesmaSpacing.md - 2),
            enabledBorder: errorBorder,
            focusedBorder: errorBorder,
          ),
        ),
      ),
    );
  }
}
