import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

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
      BannerTone.success => (QesmaColors.success, QesmaColors.successContainer),
      BannerTone.warning => (QesmaColors.warning, QesmaColors.warningContainer),
      BannerTone.error => (QesmaColors.error, QesmaColors.errorContainer),
      BannerTone.neutral => (QesmaColors.textSecondary, QesmaColors.tint),
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
