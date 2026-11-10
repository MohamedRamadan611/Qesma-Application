import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/palette.dart';

enum BannerTone { neutral, success, warning, error }

/// A one-line status (icon + words) announced to screen readers when it changes. Colour only
/// reinforces the icon and the words.
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.icon, required this.text, required this.tone});

  final IconData icon;
  final String text;
  final BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (tone) {
      BannerTone.success => (context.colors.success, context.colors.successContainer),
      BannerTone.warning => (context.colors.warning, context.colors.warningContainer),
      BannerTone.error => (context.colors.error, context.colors.errorContainer),
      BannerTone.neutral => (context.colors.textSecondary, context.colors.tint),
    };
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(QesmaRadii.control)),
        child: Padding(
          padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
          child: Row(
            children: [
              ExcludeSemantics(child: Icon(icon, color: fg, size: 20)),
              const SizedBox(width: QesmaSpacing.sm),
              Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg))),
            ],
          ),
        ),
      ),
    );
  }
}
