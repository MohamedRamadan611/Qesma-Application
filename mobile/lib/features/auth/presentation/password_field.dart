import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/widgets.dart';

/// A password field: hidden by default with a show/hide button (48 px, named for screen readers), no
/// suggestions, and the autofill hint the phone's password manager needs.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.hint,
    this.newPassword = false,
    this.enabled = true,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final String? hint;

  /// A password being chosen (registration, change) rather than typed to sign in.
  final bool newPassword;
  final bool enabled;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      errorText: widget.errorText,
      enabled: widget.enabled,
      obscureText: !_visible,
      showClear: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: [widget.newPassword ? AutofillHints.newPassword : AutofillHints.password],
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffix: IconButton(
        icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
        tooltip: _visible ? l10n.fieldPasswordHide : l10n.fieldPasswordShow,
        onPressed: () => setState(() => _visible = !_visible),
      ),
    );
  }
}
