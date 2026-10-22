import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_tokens.dart';

enum AppButtonVariant { primary, outlined, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isFullWidth = true,
    this.height = 52.0,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isFullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: variant == AppButtonVariant.primary
                ? tokens.onPrimary
                : tokens.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    Widget button;
    final borderRadius = BorderRadius.circular(AppRadius.md);

    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: tokens.primary,
            foregroundColor: tokens.onPrimary,
            minimumSize: Size(isFullWidth ? double.infinity : 48, height),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            elevation: 0,
          ),
          child: child,
        );
        break;
      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: tokens.primary,
            side: BorderSide(color: tokens.outline, width: 1.2),
            minimumSize: Size(isFullWidth ? double.infinity : 48, height),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
          ),
          child: child,
        );
        break;
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: tokens.primary,
            minimumSize: Size(isFullWidth ? double.infinity : 48, height),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
          ),
          child: child,
        );
        break;
    }

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
