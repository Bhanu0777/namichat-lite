import 'package:flutter/material.dart';

import 'package:namichat_lite/design_system/flow_spacing.dart';

/// A soft, rounded surface used to group related content.
///
/// Theme-aware: uses the [ColorScheme.surface] and the Flow card shape by
/// default. Optionally tappable via [onTap] and supports an [elevation]
/// override and custom [padding].
class FlowCard extends StatelessWidget {
  const FlowCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = FlowSpacing.cardPadding,
    this.margin,
    this.elevation,
    this.color,
    this.borderRadius,
    this.clip = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? color;
  final double? borderRadius;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? FlowSpacing.radiusLg;

    final content = Padding(padding: padding, child: child);

    final card = Card(
      margin: margin,
      color: color ?? scheme.surface,
      elevation: elevation ?? 1,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: scheme.outlineVariant, width: 1),
      ),
      child: content,
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: card,
    );
  }
}
