import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/theme/palette.dart';

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

typedef ContrastPair = (String, Color, Color);

/// Every foreground/background pair the design system uses for TEXT or ICONS that carry meaning
/// needs 4.5:1 (WCAG 1.4.3). When a widget starts using a new pair, add it here. The same table
/// is held against BOTH palettes.
List<ContrastPair> textPairs(QesmaPalette p) => [
      ('primary text on card', p.primary, p.card),
      ('primary text on canvas', p.primary, p.canvas),
      ('onPrimary on primary (button, status card, FAB)', p.onPrimary, p.primary),
      ('onPrimary on primary pressed', p.onPrimary, p.primaryPressed),
      ('text primary on canvas', p.textPrimary, p.canvas),
      ('text primary on card', p.textPrimary, p.card),
      ('text primary on surfaceLow', p.textPrimary, p.surfaceLow),
      ('text secondary on canvas', p.textSecondary, p.canvas),
      ('text secondary on card', p.textSecondary, p.card),
      ('text secondary on surfaceLow (nav bar)', p.textSecondary, p.surfaceLow),
      ('helper text on card', p.textHelper, p.card),
      ('helper text on canvas', p.textHelper, p.canvas),
      ('primary container text', p.onPrimaryContainer, p.primaryContainer),
      ('primary on tint card', p.primary, p.tint),
      ('text primary on tint card', p.textPrimary, p.tint),
      ('text secondary on tint card', p.textSecondary, p.tint),
      ('error text on card', p.error, p.card),
      ('error text on canvas', p.error, p.canvas),
      ('error text on error container', p.error, p.errorContainer),
      ('onError on error fill (destructive button)', p.onError, p.errorFill),
      ('warning text on its container', p.warning, p.warningContainer),
      ('warning text on card', p.warning, p.card),
      ('info tag', p.info, p.infoContainer),
      ('success tag', p.success, p.successContainer),
      ('success text on card', p.success, p.card),
      ('owed chip', p.owed, p.owedBg),
      ('owed amount on card', p.owed, p.card),
      ('owed on tint card (profile / groups header)', p.owed, p.tint),
      ('owes chip', p.owes, p.owesBg),
      ('owes amount on card', p.owes, p.card),
      ('settled chip', p.settled, p.settledBg),
      ('snackbar text', p.onInverseSurface, p.inverseSurface),
      ('snackbar action', p.snackbarAction, p.inverseSurface),
      for (var i = 0; i < p.avatarTints.length; i++) ('avatar tint $i initial', p.avatarTints[i].$2, p.avatarTints[i].$1),
    ];

/// Boundaries and focus indicators need 3:1 (WCAG 1.4.11).
List<ContrastPair> nonTextPairs(QesmaPalette p) => [
      ('input outline on card', p.outline, p.card),
      ('input outline on canvas', p.outline, p.canvas),
      ('focus ring on canvas', p.primary, p.canvas),
      ('focus ring on card', p.primary, p.card),
      ('error outline on card', p.error, p.card),
      ('selected check on card', p.primary, p.card),
    ];

void main() {
  for (final (label, p) in [('light', QesmaPalette.light), ('dark', QesmaPalette.dark)]) {
    group('$label palette: text and icon pairs reach WCAG AA (4.5:1)', () {
      for (final (name, fg, bg) in textPairs(p)) {
        test(name, () {
          final ratio = contrast(fg, bg);
          expect(ratio, greaterThanOrEqualTo(4.5), reason: '$label / $name: ${ratio.toStringAsFixed(2)}:1 (needs 4.5:1)');
        });
      }
    });

    group('$label palette: boundaries and focus indicators reach 3:1', () {
      for (final (name, fg, bg) in nonTextPairs(p)) {
        test(name, () {
          final ratio = contrast(fg, bg);
          expect(ratio, greaterThanOrEqualTo(3.0), reason: '$label / $name: ${ratio.toStringAsFixed(2)}:1 (needs 3:1)');
        });
      }
    });

    test('$label palette: disabled and decorative colours never carry information', () {
      // textDisabled is below AA by design (decorative only); the skeleton must stay visible but quiet.
      expect(contrast(p.textDisabled, p.card), lessThan(4.5));
      expect(contrast(p.skeleton, p.canvas), lessThan(3.0));
    });

    test('$label palette: the light and dark palettes have the same number of avatar tints', () {
      expect(p.avatarTints.length, QesmaPalette.light.avatarTints.length);
    });
  }

  test('light palette: pairs that must NOT be used for information stay documented as failing', () {
    const p = QesmaPalette.light;
    expect(contrast(p.buttonBorder, p.card), lessThan(3.0));
    expect(contrast(p.textHelper, p.surfaceLow), lessThan(4.5));
    expect(contrast(p.warningDecor, p.warningContainer), lessThan(4.5));
  });

  test('prints the full table for both palettes (run with --reporter expanded to read it)', () {
    final lines = [
      for (final (label, p) in [('light', QesmaPalette.light), ('dark', QesmaPalette.dark)])
        for (final (name, fg, bg) in [...textPairs(p), ...nonTextPairs(p)]) '${contrast(fg, bg).toStringAsFixed(2).padLeft(6)}  $label  $name',
    ];
    // ignore: avoid_print
    print(lines.join('\n'));
  });
}
