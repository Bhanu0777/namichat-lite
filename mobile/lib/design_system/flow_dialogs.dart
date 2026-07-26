import 'package:flutter/material.dart';

import 'package:namichat_lite/design_system/flow_buttons.dart';
import 'package:namichat_lite/design_system/flow_spacing.dart';

/// Ocean-styled modal dialog helpers built on [AlertDialog].
class FlowDialogs {
  const FlowDialogs._();

  /// Shows a confirmation dialog with confirm/dismiss actions.
  ///
  /// Returns `true` if the user confirmed. [confirmLabel]/[dismissLabel]
  /// default to "OK"/"Cancel" and the confirm button uses the given [variant].
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'OK',
    String dismissLabel = 'Cancel',
    FlowButtonVariant confirmVariant = FlowButtonVariant.primary,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FlowSpacing.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(dismissLabel),
          ),
          FlowButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            label: confirmLabel,
            variant: confirmVariant,
            size: FlowButtonSize.small,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  /// Shows an informational dialog with a single dismiss button.
  static Future<void> info({
    required BuildContext context,
    required String title,
    required String message,
    String buttonLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FlowSpacing.radiusLg),
        ),
        actions: [
          FlowButton(
            onPressed: () => Navigator.of(ctx).pop(),
            label: buttonLabel,
            size: FlowButtonSize.small,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  /// Shows a fully custom dialog. [builder] receives the dialog context.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }
}