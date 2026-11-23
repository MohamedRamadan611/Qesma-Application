import 'package:flutter/widgets.dart';

/// Lays [child] out at least [minHeight] tall and clips what does not fit yet. For a `NestedScrollView` body: its
/// first layout gets only what the scroll-away header leaves, which at large text sizes can be a few pixels; the body
/// keeps a usable layout (no overflow) and grows to its real size as the header scrolls away.
class MinHeightBody extends StatelessWidget {
  const MinHeightBody({super.key, required this.child, this.minHeight = 360});

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) {
          if (box.maxHeight >= minHeight) return child;
          return ClipRect(
            child: OverflowBox(
              alignment: AlignmentDirectional.topStart,
              minHeight: minHeight,
              maxHeight: minHeight,
              child: child,
            ),
          );
        },
      );
}
