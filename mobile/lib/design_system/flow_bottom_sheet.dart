import 'package:flutter/material.dart';

import 'package:namichat_lite/design_system/flow_spacing.dart';

/// Ocean-styled bottom sheet helper with a rounded top (wave-like) shape.
class FlowBottomSheet {
  const FlowBottomSheet._();

  /// Shows a modal bottom sheet. [builder] builds the sheet content; [title]
  /// optionally renders a header row. The sheet is scrollable and padded.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    String? title,
    bool isScrollControlled = false,
    bool useSafeArea = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(FlowSpacing.radiusXl),
        ),
      ),
      builder: (ctx) => _SheetScaffold(title: title, builder: builder),
    );
  }

  /// Shows a bottom sheet from a simple list of [FlowSheetItem]s.
  static Future<T?> showActions<T>({
    required BuildContext context,
    String? title,
    required List<FlowSheetItem<T>> items,
  }) {
    return show<T>(
      context: context,
      title: title,
      builder: (ctx) => ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: FlowSpacing.sm),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final item = items[index];
          return ListTile(
            leading:
                item.icon != null ? Icon(item.icon, color: Theme.of(ctx).colorScheme.primary) : null,
            title: Text(item.label),
            onTap: () => Navigator.of(ctx).pop(item.value),
          );
        },
      ),
    );
  }
}

class FlowSheetItem<T> {
  const FlowSheetItem({required this.label, this.value, this.icon});
  final String label;
  final T? value;
  final IconData? icon;
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({this.title, required this.builder});
  final String? title;
  final Widget Function(BuildContext) builder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: FlowSpacing.lg,
          right: FlowSpacing.lg,
          top: FlowSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + FlowSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: FlowSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(FlowSpacing.radiusFull),
                ),
              ),
            ),
            if (title != null) ...[
              Text(
                title!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: FlowSpacing.md),
            ],
            Flexible(child: builder(context)),
          ],
        ),
      ),
    );
  }
}