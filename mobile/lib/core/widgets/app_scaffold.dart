import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';

/// Screen frame: header (back arrow, title, optional tag and subtitle, trailing actions),
/// body, optional floating button and sticky bottom bar.
///
/// The header is not a Material `AppBar`: its height grows with the text, so a long
/// Arabic title at 2x text scale wraps instead of overflowing. The back arrow points
/// right in right-to-left layouts (the framework mirrors `Icons.arrow_back`).
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.titleTag,
    this.actions = const [],
    this.showBack,
    this.onBack,
    this.floatingActionButton,
    this.bottomBar,
  });

  final String title;
  final String? subtitle;

  /// Small pill next to the title (e.g. the group type).
  final Widget? titleTag;
  final List<Widget> actions;

  /// Defaults to "show when there is a page to go back to".
  final bool? showBack;
  final VoidCallback? onBack;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canPop = Navigator.maybeOf(context)?.canPop() ?? false;
    final back = showBack ?? canPop;

    final header = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.sm, QesmaSpacing.sm, QesmaSpacing.md, QesmaSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (back)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: l10n.commonBack,
              onPressed: onBack ?? () => Navigator.maybeOf(context)?.maybePop(),
            )
          else
            const SizedBox(width: QesmaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Wrap(
                    spacing: QesmaSpacing.sm,
                    runSpacing: QesmaSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(title, style: theme.textTheme.headlineMedium),
                      ?titleTag,
                    ],
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: QesmaColors.textHelper)),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );

    return Scaffold(
      backgroundColor: QesmaColors.canvas,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: bottomBar,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [header, Expanded(child: body)],
        ),
      ),
    );
  }
}
