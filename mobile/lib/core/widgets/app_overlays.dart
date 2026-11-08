import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';
import 'app_button.dart';

/// Content of a bottom sheet: drag handle, close button, title, optional subtitle, scrolling
/// body and a sticky action area. Use [showAppBottomSheet] to open one.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({super.key, required this.title, required this.child, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget child;

  /// Sticky area under the body (usually the primary button).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: QesmaSpacing.sm + 4),
          ExcludeSemantics(
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: QesmaColors.buttonBorder,
                  borderRadius: BorderRadius.circular(QesmaRadii.pill),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.sm, QesmaSpacing.sm, QesmaSpacing.md, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.commonClose,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(top: QesmaSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(header: true, child: Text(title, style: theme.textTheme.headlineMedium)),
                        if (subtitle != null)
                          Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: QesmaColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.md, QesmaSpacing.md, QesmaSpacing.md, QesmaSpacing.md),
              child: child,
            ),
          ),
          if (action != null)
            DecoratedBox(
              decoration: const BoxDecoration(
                color: QesmaColors.card,
                border: Border(top: BorderSide(color: QesmaColors.hairline)),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.md, QesmaSpacing.sm, QesmaSpacing.md, QesmaSpacing.md),
                child: action,
              ),
            ),
        ],
      ),
    );
  }
}

/// Opens an [AppBottomSheet]: keyboard-aware, at most 90% of the screen height.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
  String? subtitle,
  Widget? action,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: AppBottomSheet(title: title, subtitle: subtitle, action: action, child: child),
    ),
  );
}

/// Yes/no question. Returns true only when the user confirms. [destructive] paints the
/// confirm button in the error colour (deletes).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsOverflowButtonSpacing: QesmaSpacing.sm,
      actions: [
        AppButton(
          label: cancelLabel ?? l10n.commonCancel,
          variant: AppButtonVariant.text,
          expand: false,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        AppButton(
          label: confirmLabel,
          variant: destructive ? AppButtonVariant.destructive : AppButtonVariant.primary,
          expand: false,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// "You can't do that" notice with a single acknowledgement button (blocked deletes, conflicts).
Future<void> showBlockedDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? okLabel,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const ExcludeSemantics(child: Icon(Icons.info_outline, color: QesmaColors.warning, size: 32)),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actions: [
        AppButton(
          label: okLabel ?? l10n.commonOk,
          expand: false,
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}

/// Floating snackbar. Replaces any snackbar already showing; announced by screen readers.
void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
      ),
    );
}
