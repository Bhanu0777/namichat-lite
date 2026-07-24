import 'package:flutter/material.dart';

import 'package:namichat_lite/design_system/flow_buttons.dart';
import 'package:namichat_lite/design_system/flow_spacing.dart';

/// A friendly empty-state surface for lists/screens with no data.
class FlowEmptyState extends StatelessWidget {
  const FlowEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: FlowSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(FlowSpacing.xl),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: FlowSpacing.lg),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: FlowSpacing.sm),
              Text(
                description!,
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: FlowSpacing.xl),
              FlowButton(
                onPressed: onAction!,
                label: actionLabel!,
                icon: const Icon(Icons.add),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
