import 'package:flutter/material.dart';

import 'package:namichat_lite/design_system/flow_colors.dart';
import 'package:namichat_lite/design_system/flow_spacing.dart';

/// Themed circular progress indicator using the Flow primary color.
class FlowLoadingIndicator extends StatelessWidget {
  const FlowLoadingIndicator({super.key, this.size = 24, this.strokeWidth = 3});

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: FlowColors.ocean,
      ),
    );
  }
}

/// Small indicator shown inside buttons while an action is in flight.
class FlowButtonLoader extends StatelessWidget {
  const FlowButtonLoader({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? FlowColors.foam;
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: c,
      ),
    );
  }
}

/// Full-screen centered loader with an optional label.
class FlowPageLoader extends StatelessWidget {
  const FlowPageLoader({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FlowLoadingIndicator(size: 36, strokeWidth: 4),
          if (label != null) ...[
            const SizedBox(height: FlowSpacing.md),
            Text(label!, style: const TextStyle(fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

/// A shimmering placeholder block for loading skeletons.
class FlowSkeleton extends StatelessWidget {
  const FlowSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = FlowSpacing.radiusSm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
