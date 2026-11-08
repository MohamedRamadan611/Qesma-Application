import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/theme/tokens.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

double _luminance(Color c) {
  double channel(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

typedef _Pair = (String, Color, Color);

void main() {
  const white = QesmaColors.card;
  const canvas = QesmaColors.canvas;

  // Every foreground/background pair the design system uses for TEXT or ICONS that carry
  // meaning. Needs 4.5:1 (WCAG 1.4.3). When a widget starts using a new pair, add it here.
  final text = <_Pair>[
    ('primary text on white', QesmaColors.primary, white),
    ('white on primary button', white, QesmaColors.primary),
    ('white on primary pressed', white, QesmaColors.primaryPressed),
    ('text primary on canvas', QesmaColors.textPrimary, canvas),
    ('text primary on white', QesmaColors.textPrimary, white),
    ('text secondary on canvas', QesmaColors.textSecondary, canvas),
    ('text secondary on white', QesmaColors.textSecondary, white),
    ('helper text on white', QesmaColors.textHelper, white),
    ('helper text on canvas', QesmaColors.textHelper, canvas),
    ('primary container text', QesmaColors.onPrimaryContainer, QesmaColors.primaryContainer),
    ('primary on tint card', QesmaColors.primary, QesmaColors.tint),
    ('text primary on tint card', QesmaColors.textPrimary, QesmaColors.tint),
    ('error text on white', QesmaColors.error, white),
    ('error text on canvas', QesmaColors.error, canvas),
    ('error text on error container', QesmaColors.error, QesmaColors.errorContainer),
    ('white on error (destructive button)', white, QesmaColors.error),
    ('warning text on its container', QesmaColors.warning, QesmaColors.warningContainer),
    ('warning text on white', QesmaColors.warning, white),
    ('info tag', QesmaColors.info, QesmaColors.infoContainer),
    ('success tag', QesmaColors.success, QesmaColors.successContainer),
    ('owed chip', QesmaColors.owed, QesmaColors.owedBg),
    ('owed amount on white', QesmaColors.owed, white),
    ('owes chip', QesmaColors.owes, QesmaColors.owesBg),
    ('owes amount on white', QesmaColors.owes, white),
    ('settled chip', QesmaColors.settled, QesmaColors.settledBg),
    ('snackbar text', QesmaColors.onInverseSurface, QesmaColors.inverseSurface),
    ('snackbar action', QesmaColors.primaryContainer, QesmaColors.inverseSurface),
    for (var i = 0; i < QesmaColors.avatarTints.length; i++)
      ('avatar tint $i initial', QesmaColors.avatarTints[i].$2, QesmaColors.avatarTints[i].$1),
  ];

  // Boundaries and focus indicators need 3:1 (WCAG 1.4.11).
  final nonText = <_Pair>[
    ('input outline on white', QesmaColors.outline, white),
    ('input outline on canvas', QesmaColors.outline, canvas),
    ('focus ring on canvas', QesmaColors.primary, canvas),
    ('focus ring on white', QesmaColors.primary, white),
    ('error outline on white', QesmaColors.error, white),
  ];

  group('text and icon pairs reach WCAG AA (4.5:1)', () {
    for (final (name, fg, bg) in text) {
      test(name, () {
        final ratio = contrast(fg, bg);
        expect(ratio, greaterThanOrEqualTo(4.5), reason: '$name: ${ratio.toStringAsFixed(2)}:1 (needs 4.5:1)');
      });
    }
  });

  group('boundaries and focus indicators reach 3:1', () {
    for (final (name, fg, bg) in nonText) {
      test(name, () {
        final ratio = contrast(fg, bg);
        expect(ratio, greaterThanOrEqualTo(3.0), reason: '$name: ${ratio.toStringAsFixed(2)}:1 (needs 3:1)');
      });
    }
  });

  test('pairs that must NOT be used for information stay documented as failing', () {
    // If these ever pass, the comments in tokens.dart are stale; if a widget uses them for text, it is a bug.
    expect(contrast(QesmaColors.textDisabled, white), lessThan(4.5));
    expect(contrast(QesmaColors.buttonBorder, white), lessThan(3.0));
    expect(contrast(QesmaColors.textHelper, QesmaColors.surfaceLow), lessThan(4.5));
    expect(contrast(QesmaColors.warningDecor, QesmaColors.warningContainer), lessThan(4.5));
  });

  test('prints the full table (run with --reporter expanded to read it)', () {
    final lines = [for (final (name, fg, bg) in [...text, ...nonText]) '${contrast(fg, bg).toStringAsFixed(2).padLeft(6)}  $name'];
    // ignore: avoid_print
    print(lines.join('\n'));
  });
}
