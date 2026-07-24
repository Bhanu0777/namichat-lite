import 'package:flutter/material.dart';

import 'package:namichat_lite/design_system/flow_colors.dart';
import 'package:namichat_lite/design_system/flow_spacing.dart';

/// Semantic type for [FlowSnackBar] and other status surfaces.
enum FlowStatus { info, success, warning, danger }

/// Ocean-styled snackbar helper.
class FlowSnackBar {
  const FlowSnackBar._();

  /// Displays a floating, theme-aware snackbar.
  static void show(
    BuildContext context, {
    required String message,
    FlowStatus type = FlowStatus.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final colors = _resolve(type, scheme);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(colors.icon, color: colors.foreground, size: 20),
            const SizedBox(width: FlowSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.foreground),
              ),
            ),
          ],
        ),
        backgroundColor: colors.background,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FlowSpacing.radiusMd),
        ),
        margin: const EdgeInsets.all(FlowSpacing.md),
        action: action,
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: FlowStatus.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: FlowStatus.danger);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: FlowStatus.warning);

  static _SnackStyle _resolve(FlowStatus type, ColorScheme scheme) {
    switch (type) {
      case FlowStatus.success:
        return const _SnackStyle(
          background: FlowColors.success,
          foreground: Colors.white,
          icon: Icons.check_circle_outline,
        );
      case FlowStatus.warning:
        return const _SnackStyle(
          background: FlowColors.warning,
          foreground: Colors.white,
          icon: Icons.warning_amber_outlined,
        );
      case FlowStatus.danger:
        return _SnackStyle(
          background: scheme.error,
          foreground: scheme.onError,
          icon: Icons.error_outline,
        );
      case FlowStatus.info:
        return _SnackStyle(
          background: scheme.primary,
          foreground: scheme.onPrimary,
          icon: Icons.info_outline,
        );
    }
  }
}

class _SnackStyle {
  const _SnackStyle({
    required this.background,
    required this.foreground,
    required this.icon,
  });
  final Color background;
  final Color foreground;
  final IconData icon;
}
