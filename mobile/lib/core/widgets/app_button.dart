import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';
import '../theme/palette.dart';

enum AppButtonVariant { primary, secondary, destructive, text }

/// The app's button: 48 px minimum, 12 px radius, optional leading icon and a loading state.
///
/// While [loading] the button ignores taps, keeps its colours and announces "loading" to
/// screen readers (no double submit, SCREEN_MAP rule 6). [onPressed] null = disabled.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;

  /// Fill the available width (default) or size to the content.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final callback = loading ? () {} : onPressed;

    final foreground = switch (variant) {
      AppButtonVariant.primary => context.colors.onPrimary,
      AppButtonVariant.destructive => context.colors.onError,
      AppButtonVariant.secondary => context.colors.textPrimary,
      AppButtonVariant.text => scheme.primary,
    };

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        else if (icon != null)
          Icon(icon, size: 20),
        if (loading || icon != null) const SizedBox(width: QesmaSpacing.sm),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: callback,
          style: loading ? FilledButton.styleFrom(backgroundColor: scheme.primary, disabledBackgroundColor: scheme.primary) : null,
          child: content,
        ),
      AppButtonVariant.destructive => FilledButton(
          onPressed: callback,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: context.colors.onError,
            disabledBackgroundColor: loading ? scheme.error : context.colors.hairline,
          ),
          child: content,
        ),
      AppButtonVariant.secondary => OutlinedButton(onPressed: callback, child: content),
      AppButtonVariant.text => TextButton(onPressed: callback, child: content),
    };

    final sized = expand ? SizedBox(width: double.infinity, child: button) : button;
    if (!loading) return sized;
    // One node: "<label>, loading". The child's own semantics are replaced so the busy
    // state is announced together with the button's name.
    return Semantics(
      button: true,
      enabled: false,
      label: '$label, ${l10n.commonLoading}',
      excludeSemantics: true,
      child: sized,
    );
  }
}
