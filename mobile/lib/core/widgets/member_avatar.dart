import 'package:flutter/material.dart';

import '../theme/qesma_text.dart';
import '../theme/palette.dart';

/// Deterministic tint for a member: the same id always gets the same colour. Integer
/// hash only (no money, no randomness) so it is stable across launches and devices.
int avatarTintIndex(String memberId) {
  var hash = 17;
  for (final unit in memberId.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash % QesmaPalette.light.avatarTints.length; // both palettes have the same number of tints
}

/// First letter of a name, upper-cased for Latin scripts; '?' for an empty name.
String avatarInitial(String name) {
  for (final rune in name.trim().runes) {
    final ch = String.fromCharCode(rune);
    if (RegExp(r'\p{L}|\p{N}', unicode: true).hasMatch(ch)) return ch.toUpperCase();
  }
  return '?';
}

/// Round avatar with the member's initial. Initials only: no photos in Phase 1.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.memberId, required this.name, this.size = 40, this.semanticLabel});

  final String memberId;
  final String name;
  final double size;

  /// Set only when the name is not shown next to the avatar; otherwise it is decoration.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = context.colors.avatarTints[avatarTintIndex(memberId)];
    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        avatarInitial(name),
        style: QesmaText.amountSmall().copyWith(color: fg, fontSize: size * 0.42, height: 1),
        textScaler: TextScaler.noScaling,
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: avatar)
        : Semantics(label: semanticLabel, image: true, child: ExcludeSemantics(child: avatar));
  }
}
