import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/palette.dart';

/// White card: 16 px radius, hairline border, level-1 shadow. Tappable cards get an ink
/// ripple and a 48 px minimum height.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(QesmaSpacing.md),
    this.color,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Secondary actions (for example the groups list menu); used together with [onTap].
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  /// Fill; the theme's card colour when null.
  final Color? color;

  /// Replaces the combined text of the children for screen readers (e.g. a full sentence
  /// describing a group row).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(QesmaRadii.card);
    final body = Padding(padding: padding, child: child);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? context.colors.card,
        borderRadius: radius,
        border: Border.all(color: context.colors.hairline),
        boxShadow: QesmaShadows.card,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: onTap == null
            ? body
            : InkWell(
                borderRadius: radius,
                onTap: onTap,
                onLongPress: onLongPress,
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
      onLongPress: onLongPress,
      child: ExcludeSemantics(child: card),
    );
  }
}
