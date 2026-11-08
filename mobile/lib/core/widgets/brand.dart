import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';

/// Placeholder brand mark: a teal disc with a white pie-slice glyph, drawn in code because
/// no logo asset exists yet. Replace with the real logo when it is supplied.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(color: QesmaColors.primary, shape: BoxShape.circle, boxShadow: QesmaShadows.raised),
          child: CustomPaint(painter: _PiePainter()),
        ),
      );
}

class _PiePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.27;
    final gap = size.width * 0.045;
    canvas.drawCircle(center, radius, Paint()..color = QesmaColors.onPrimary);
    final cut = Paint()
      ..color = QesmaColors.primary
      ..strokeWidth = gap;
    canvas.drawLine(center - Offset(0, radius), center + Offset(0, radius), cut); // left | right
    canvas.drawLine(center, center + Offset(radius, 0), cut); // right: top / bottom
  }

  @override
  bool shouldRepaint(_PiePainter oldDelegate) => false;
}

/// Logo, wordmark and a line of text under it (splash, welcome and sign-in).
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.tagline, this.logoSize = 96});

  final String tagline;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandLogo(size: logoSize),
        const SizedBox(height: QesmaSpacing.md),
        Semantics(
          header: true,
          child: Text(
            l10n.brandWordmark,
            style: theme.textTheme.displayMedium?.copyWith(color: QesmaColors.primaryPressed),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: QesmaSpacing.sm),
        Text(
          tagline,
          style: theme.textTheme.titleMedium?.copyWith(color: QesmaColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
