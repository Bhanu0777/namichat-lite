import 'package:flutter/material.dart';

import 'package:namichat_lite/design_system/flow_buttons.dart';
import 'package:namichat_lite/design_system/flow_spacing.dart';

/// A recoverable error surface with an optional retry action.
class FlowErrorState extends StatelessWidget {
  const FlowErrorState({
    super.key,
    this.icon = Icons.cloud_off_outlined,
    this.title = 'Something went wrong',
    required this.message,
    this.retryLabel = 'Try again',
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: FlowSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: scheme.error.withValues(alpha: 0.85),
            ),
            const SizedBox(height: FlowSpacing.lg),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FlowSpacing.sm),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: FlowSpacing.xl),
              FlowButton(
                onPressed: onRetry!,
                label: retryLabel,
                variant: FlowButtonVariant.outline,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A lightweight inline error banner (e.g. atop a form or list).
class FlowErrorBanner extends StatelessWidget {
  const FlowErrorBanner({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(FlowSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: FlowSpacing.md,
        vertical: FlowSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(FlowSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.error, size: 20),
          const SizedBox(width: FlowSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 14),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, color: scheme.onErrorContainer, size: 18),
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
