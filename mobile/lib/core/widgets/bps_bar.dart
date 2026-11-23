import 'package:flutter/material.dart';

import '../money/money.dart';

/// A thin progress bar filled to [fillBps] basis points (0..10000), RTL-aware. The caller passes an already capped
/// value (trip budget: `barFillBps`); the figure it stands for is always written next to the bar, so the bar itself is
/// decoration and hidden from screen readers.
class BpsBar extends StatelessWidget {
  const BpsBar({super.key, required this.fillBps, required this.color, this.height = 8});

  final int fillBps;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final factor = fillBps.clamp(0, Bps.max) / Bps.max;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Container(
          height: height,
          width: double.infinity,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(widthFactor: factor, child: Container(color: color)),
          ),
        ),
      ),
    );
  }
}
