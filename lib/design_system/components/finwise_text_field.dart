import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/finwise_shapes.dart';
import '../theme/finwise_tokens.dart';

class FinwiseTextField extends StatelessWidget {
  const FinwiseTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixText,
    this.suffixText,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixStyle,
    this.suffixStyle,
    this.style,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.readOnly = false,
    this.helperText,
    this.errorText,
    this.helperMaxLines = 3,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? prefixText;
  final String? suffixText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextStyle? prefixStyle;
  final TextStyle? suffixStyle;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final String? helperText;
  final String? errorText;
  final int helperMaxLines;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: tokens.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          readOnly: readOnly,
          style: style ??
              textTheme.bodyLarge?.copyWith(
                color: tokens.textPrimary,
              ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: tokens.textTertiary,
            ),
            prefixText: prefixText,
            prefixStyle: prefixStyle ??
                textTheme.bodyLarge?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
            suffixText: suffixText,
            suffixStyle: suffixStyle ??
                textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            helperText: helperText,
            helperMaxLines: helperMaxLines,
            errorText: errorText,
            filled: true,
            fillColor: tokens.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: FinwiseShapes.md,
              borderSide: BorderSide(color: tokens.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: FinwiseShapes.md,
              borderSide: BorderSide(color: tokens.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: FinwiseShapes.md,
              borderSide: BorderSide(color: tokens.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: FinwiseShapes.md,
              borderSide: BorderSide(color: tokens.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: FinwiseShapes.md,
              borderSide: BorderSide(color: tokens.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
