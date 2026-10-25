import 'package:flutter/material.dart';
import '../theme/finwise_shapes.dart';
import '../theme/finwise_tokens.dart';

enum FinwiseButtonVariant { primary, outlined, text }

class FinwiseButton extends StatelessWidget {
  const FinwiseButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = FinwiseButtonVariant.primary,
    this.icon,
    this.isFullWidth = true,
    this.height = 52.0,
  });

  final String label;
  final VoidCallback? onPressed;
  final FinwiseButtonVariant variant;
  final IconData? icon;
  final bool isFullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    Widget content = Row(
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
            color: variant == FinwiseButtonVariant.primary
                ? tokens.onPrimary
                : tokens.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    Widget button;
    final borderRadius = FinwiseShapes.md;

    switch (variant) {
      case FinwiseButtonVariant.primary:
        button = FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: tokens.primary,
            foregroundColor: tokens.onPrimary,
            minimumSize: Size(isFullWidth ? double.infinity : 48, height),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            elevation: 0,
          ),
          child: content,
        );
        break;
      case FinwiseButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: tokens.primary,
            side: BorderSide(color: tokens.outline, width: 1.2),
            minimumSize: Size(isFullWidth ? double.infinity : 48, height),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
          ),
          child: content,
        );
        break;
      case FinwiseButtonVariant.text:
        button = TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: tokens.primary,
            minimumSize: Size(isFullWidth ? double.infinity : 48, height),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
          ),
          child: content,
        );
        break;
    }

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
