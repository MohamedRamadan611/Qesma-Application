import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// White card: 16 px radius, hairline border, level-1 shadow. Tappable cards get an ink
/// ripple and a 48 px minimum height.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(QesmaSpacing.md),
    this.color = QesmaColors.card,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;

  /// Replaces the combined text of the children for screen readers (e.g. a full sentence
  /// describing a group row).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(QesmaRadii.card);
    final body = Padding(padding: padding, child: child);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: Border.all(color: QesmaColors.hairline),
        boxShadow: QesmaShadows.card,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: onTap == null
            ? body
            : InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: ConstrainedBox(constraints: const BoxConstraints(minHeight: kMinTouch), child: body),
              ),
      ),
    );
    if (semanticLabel == null) return card;
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      onTap: onTap,
      child: ExcludeSemantics(child: card),
    );
  }
}
