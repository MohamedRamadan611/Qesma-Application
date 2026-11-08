import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';
import 'app_button.dart';
import 'app_overlays.dart';
import 'bidi.dart';

/// Tinted circle with an icon in place of the mock-ups' illustrations (no artwork exists yet).
class _StateIcon extends StatelessWidget {
  const _StateIcon(this.icon, {this.background = QesmaColors.primaryContainer, this.foreground = QesmaColors.onPrimaryContainer});

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, size: 48, color: foreground),
        ),
      );
}

/// Centered, scrollable column so the state still fits at 2x text scale.
class _StateLayout extends StatelessWidget {
  const _StateLayout({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(QesmaSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      );
}

/// Nothing to show yet (empty list). The caller supplies copy that fits the screen.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.actionLabel, this.onAction});

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StateLayout(
      children: [
        Center(child: _StateIcon(icon)),
        const SizedBox(height: QesmaSpacing.lg),
        Semantics(header: true, child: Text(title, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center)),
        if (message != null) ...[
          const SizedBox(height: QesmaSpacing.sm),
          Text(message!, style: theme.textTheme.bodyLarge?.copyWith(color: QesmaColors.textSecondary), textAlign: TextAlign.center),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: QesmaSpacing.lg),
          AppButton(label: actionLabel!, onPressed: onAction),
        ],
      ],
    );
  }
}

/// Generic failure with a retry button and, when the server sent one, the request id so
/// support can find the failure (select or copy it). Defaults to the generic copy.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.onRetry, this.title, this.message, this.requestId});

  final VoidCallback onRetry;
  final String? title;
  final String? message;
  final String? requestId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _StateLayout(
      children: [
        const Center(
          child: _StateIcon(Icons.error_outline, background: QesmaColors.errorContainer, foreground: QesmaColors.error),
        ),
        const SizedBox(height: QesmaSpacing.lg),
        Semantics(
          header: true,
          child: Text(title ?? l10n.stateErrorTitle, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
        ),
        const SizedBox(height: QesmaSpacing.sm),
        Text(
          message ?? l10n.stateErrorMessage,
          style: theme.textTheme.bodyLarge?.copyWith(color: QesmaColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        if (requestId != null) ...[
          const SizedBox(height: QesmaSpacing.md),
          _RequestIdRow(requestId: requestId!),
        ],
        const SizedBox(height: QesmaSpacing.lg),
        AppButton(label: l10n.commonRetry, icon: Icons.refresh, onPressed: onRetry),
      ],
    );
  }
}

class _RequestIdRow extends StatelessWidget {
  const _RequestIdRow({required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QesmaColors.tint,
        borderRadius: BorderRadius.circular(QesmaRadii.control),
        border: Border.all(color: QesmaColors.tintBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: QesmaSpacing.md, vertical: QesmaSpacing.sm),
              child: SelectableText(
                l10n.stateErrorRequestId(ltrIsolate(requestId)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            tooltip: l10n.commonCopy,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: requestId));
              if (context.mounted) showAppSnackBar(context, l10n.commonCopied);
            },
          ),
        ],
      ),
    );
  }
}

/// Offline screen (P11-01). Only says what is true: the app is online-only and what was
/// recorded before is already saved on the server.
class NoInternetState extends StatelessWidget {
  const NoInternetState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _StateLayout(
      children: [
        const Center(child: _StateIcon(Icons.wifi_off)),
        const SizedBox(height: QesmaSpacing.lg),
        Semantics(
          header: true,
          child: Text(l10n.stateNoInternetTitle, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
        ),
        const SizedBox(height: QesmaSpacing.sm),
        Text(
          l10n.stateNoInternetMessage,
          style: theme.textTheme.bodyLarge?.copyWith(color: QesmaColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: QesmaSpacing.lg),
        AppButton(label: l10n.commonRetry, icon: Icons.refresh, onPressed: onRetry),
        const SizedBox(height: QesmaSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: QesmaColors.tint,
            borderRadius: BorderRadius.circular(QesmaRadii.card),
            border: Border.all(color: QesmaColors.tintBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(QesmaSpacing.md),
            child: Row(
              children: [
                const ExcludeSemantics(child: Icon(Icons.verified_user_outlined, color: QesmaColors.primary)),
                const SizedBox(width: QesmaSpacing.md),
                Expanded(child: Text(l10n.stateNoInternetReassure, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Thin banner for the top of a screen while offline. Wired to real connectivity in FL8.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      child: ColoredBox(
        color: QesmaColors.errorContainer,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: QesmaSpacing.md, vertical: QesmaSpacing.sm),
          child: Row(
            children: [
              const ExcludeSemantics(child: Icon(Icons.wifi_off, size: 18, color: QesmaColors.error)),
              const SizedBox(width: QesmaSpacing.sm),
              Expanded(
                child: Text(
                  l10n.stateOfflineBanner,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: QesmaColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
