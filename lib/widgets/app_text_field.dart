import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_tokens.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixText,
    this.suffixText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
    this.helperText,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? prefixText;
  final String? suffixText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final String? helperText;
  final String? errorText;

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
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          readOnly: readOnly,
          style: textTheme.bodyLarge?.copyWith(
            color: tokens.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: tokens.textTertiary,
            ),
            prefixText: prefixText,
            prefixStyle: textTheme.bodyLarge?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            suffixText: suffixText,
            suffixStyle: textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            helperText: helperText,
            errorText: errorText,
            filled: true,
            fillColor: tokens.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: tokens.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: tokens.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: tokens.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
