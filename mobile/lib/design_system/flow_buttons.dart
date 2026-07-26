import 'package:flutter/material.dart';

import 'package:namichat_lite/design_system/flow_loading.dart';
import 'package:namichat_lite/design_system/flow_spacing.dart';

/// Visual style of a [FlowButton].
enum FlowButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  danger,
}

/// Size variant controlling height and padding.
enum FlowButtonSize {
  small,
  medium,
  large,
}

/// Flow's primary actionable surface — a theme-aware, ocean-styled button.
///
/// Supports `primary`, `secondary`, `outline`, `ghost`, and `danger` variants,
/// a loading state, leading/trailing icons, and full-width layout.
class FlowButton extends StatelessWidget {
  const FlowButton({
    super.key,
    required this.onPressed,
    this.label,
    this.child,
    this.variant = FlowButtonVariant.primary,
    this.size = FlowButtonSize.large,
    this.fullWidth = true,
    this.loading = false,
    this.icon,
    this.trailingIcon,
  });

  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final FlowButtonVariant variant;
  final FlowButtonSize size;
  final bool fullWidth;
  final bool loading;
  final Widget? icon;
  final Widget? trailingIcon;

  double get _height {
    switch (size) {
      case FlowButtonSize.small:
        return 36;
      case FlowButtonSize.medium:
        return 42;
      case FlowButtonSize.large:
        return FlowSpacing.buttonHeight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = loading
        ? FlowButtonLoader(color: _contentColor(scheme))
        : _content();

    final style = _style(context);

    Widget button;
    switch (variant) {
      case FlowButtonVariant.primary:
        button = FilledButton(
          onPressed: loading ? null : onPressed,
          style: style,
          child: content,
        );
      case FlowButtonVariant.danger:
        button = FilledButton(
          onPressed: loading ? null : onPressed,
          style: style,
          child: content,
        );
      case FlowButtonVariant.secondary:
        button = FilledButton.tonal(
          onPressed: loading ? null : onPressed,
          style: style,
          child: content,
        );
      case FlowButtonVariant.outline:
        button = OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: style,
          child: content,
        );
      case FlowButtonVariant.ghost:
        button = TextButton(
          onPressed: loading ? null : onPressed,
          style: style,
          child: content,
        );
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Widget _content() {
    final text = child ?? (label != null ? Text(label!) : null);
    if (icon == null && trailingIcon == null) {
      return text ?? const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: FlowSpacing.sm)],
        if (text != null) Flexible(child: text),
        if (trailingIcon != null) ...[
          const SizedBox(width: FlowSpacing.sm),
          trailingIcon!,
        ],
      ],
    );
  }

  ButtonStyle _style(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(FlowSpacing.radiusMd);
    final base = ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size.fromHeight(_height)),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: radius)),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: FlowSpacing.lg),
      ),
      textStyle: WidgetStateProperty.all(
        TextStyle(
          fontSize: size == FlowButtonSize.small ? 13 : 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    switch (variant) {
      case FlowButtonVariant.danger:
        return base.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.errorContainer;
            }
            if (states.contains(WidgetState.pressed)) {
              return scheme.error.withValues(alpha: 0.8);
            }
            return scheme.error;
          }),
          foregroundColor: WidgetStateProperty.all(scheme.onError),
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.08),
          ),
        );
      case FlowButtonVariant.outline:
        return base.copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: scheme.outlineVariant);
            }
            if (states.contains(WidgetState.pressed)) {
              return BorderSide(color: scheme.primary.withValues(alpha: 0.6));
            }
            return BorderSide(color: scheme.primary);
          }),
          foregroundColor: WidgetStateProperty.all(scheme.primary),
          overlayColor: WidgetStateProperty.all(
            scheme.primary.withValues(alpha: 0.08),
          ),
        );
      case FlowButtonVariant.ghost:
        return base.copyWith(
          foregroundColor: WidgetStateProperty.all(scheme.primary),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return scheme.primary.withValues(alpha: 0.16);
            }
            if (states.contains(WidgetState.hovered)) {
              return scheme.primary.withValues(alpha: 0.12);
            }
            return scheme.primary.withValues(alpha: 0.0);
          }),
        );
      case FlowButtonVariant.secondary:
        return base.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.secondaryContainer.withValues(alpha: 0.6);
            }
            if (states.contains(WidgetState.pressed)) {
              return scheme.secondaryContainer.withValues(alpha: 0.7);
            }
            return scheme.secondaryContainer;
          }),
          foregroundColor: WidgetStateProperty.all(scheme.onSecondaryContainer),
          overlayColor: WidgetStateProperty.all(
            scheme.onSecondaryContainer.withValues(alpha: 0.08),
          ),
        );
      case FlowButtonVariant.primary:
        return base.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.primary.withValues(alpha: 0.38);
            }
            if (states.contains(WidgetState.pressed)) {
              return scheme.primary.withValues(alpha: 0.9);
            }
            return scheme.primary;
          }),
          foregroundColor: WidgetStateProperty.all(scheme.onPrimary),
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.08),
          ),
        );
    }
  }

  Color _contentColor(ColorScheme scheme) {
    switch (variant) {
      case FlowButtonVariant.outline:
      case FlowButtonVariant.ghost:
        return scheme.primary;
      case FlowButtonVariant.secondary:
        return scheme.onSecondaryContainer;
      case FlowButtonVariant.danger:
        return scheme.onError;
      case FlowButtonVariant.primary:
        return scheme.onPrimary;
    }
  }
}
