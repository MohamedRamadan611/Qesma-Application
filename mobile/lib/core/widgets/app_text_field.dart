import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';
import 'code_point_limit.dart';
import '../theme/palette.dart';

/// Text field with the label above it (as in the mock-ups), an error line, an optional
/// counter ("8/60", Western digits, counted in code points like the backend) and a clear button.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters = const [],
    this.prefixIcon,
    this.enabled = true,
    this.autofocus = false,
    this.showClear = true,
    this.focusNode,
    this.obscureText = false,
    this.autocorrect = true,
    this.autofillHints,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;

  /// Already localized. Shown below the field in the error colour; the field border turns red too.
  final String? errorText;

  /// Maximum length in code points. Also drives the counter.
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter> inputFormatters;
  final IconData? prefixIcon;
  final bool enabled;
  final bool autofocus;
  final bool showClear;
  final FocusNode? focusNode;

  /// Turn off for identifiers (usernames): the keyboard must not add a space after a dot or "fix" the spelling.
  final bool autocorrect;

  /// Hide the text (passwords): no suggestions, no clear button, and the field is not remembered by the keyboard.
  final bool obscureText;

  /// Lets the phone's password manager fill the field (`AutofillHints.email`, `.password`, `.newPassword`).
  final Iterable<String>? autofillHints;

  /// Replaces the clear button (the show/hide button of a password).
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: QesmaSpacing.sm),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final length = codePointCount(controller.text);
            return TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              autofocus: autofocus,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              obscureText: obscureText,
              enableSuggestions: autocorrect && !obscureText,
              autocorrect: autocorrect && !obscureText,
              autofillHints: autofillHints,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: theme.textTheme.bodyLarge,
              inputFormatters: [if (maxLength != null) CodePointLimitFormatter(maxLength!), ...inputFormatters],
              decoration: InputDecoration(
                hintText: hint,
                errorText: errorText,
                errorMaxLines: 3,
                prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, color: context.colors.textHelper),
                suffixIcon: suffix ??
                    (showClear && enabled && length > 0 && !obscureText
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: l10n.fieldClear,
                        onPressed: () {
                          controller.clear();
                          onChanged?.call('');
                        },
                      )
                    : null),
                counter: maxLength == null
                    ? null
                    : Text(
                        l10n.fieldCounter('$length', '$maxLength'),
                        style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}
