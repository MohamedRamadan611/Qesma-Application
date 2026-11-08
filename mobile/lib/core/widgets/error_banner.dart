import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Inline error under a field or button: icon + text on the error container, announced to
/// screen readers when it appears. Colour is never the only signal (icon and words).
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(color: QesmaColors.errorContainer, borderRadius: BorderRadius.circular(QesmaRadii.control)),
          child: Padding(
            padding: const EdgeInsets.all(QesmaSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(child: Icon(Icons.error_outline, color: QesmaColors.error, size: 20)),
                const SizedBox(width: QesmaSpacing.sm),
                Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: QesmaColors.error))),
              ],
            ),
          ),
        ),
      );
}
