import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';
import 'app_card.dart';

/// A flat placeholder block (P11-03). No shimmer: a slow fade that stops completely when
/// the system "remove animations" setting is on.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({super.key, this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: QesmaColors.skeleton, borderRadius: BorderRadius.circular(radius)),
      );
}

/// Fades its child between full and 55% opacity. Static when animations are disabled.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: QesmaDurations.pulse);
  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldRun = !MediaQuery.disableAnimationsOf(context);
    if (shouldRun && !_running) {
      _controller.repeat(reverse: true);
    } else if (!shouldRun && _running) {
      _controller.stop();
      _controller.value = 0;
    }
    _running = shouldRun;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.55).animate(_controller),
        child: widget.child,
      );
}

/// Placeholder shaped like a feed row: avatar/icon block, two text lines, an amount block.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) => const AppCard(
        child: Row(
          children: [
            SkeletonBlock(width: 44, height: 44, radius: 12),
            SizedBox(width: QesmaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(height: 16),
                  SizedBox(height: QesmaSpacing.sm),
                  FractionallySizedBox(widthFactor: 0.6, child: SkeletonBlock(height: 12)),
                ],
              ),
            ),
            SizedBox(width: QesmaSpacing.md),
            SkeletonBlock(width: 64, height: 24, radius: 12),
          ],
        ),
      );
}

/// A list of [SkeletonCard]s announced once to screen readers as "loading".
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.commonLoading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: SkeletonPulse(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(QesmaSpacing.margin),
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(height: QesmaSpacing.md - 4),
            itemBuilder: (_, _) => const SkeletonCard(),
          ),
        ),
      ),
    );
  }
}
