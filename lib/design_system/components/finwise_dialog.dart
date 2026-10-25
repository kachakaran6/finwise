import 'package:flutter/material.dart';
import '../theme/finwise_shapes.dart';
import '../theme/finwise_spacing.dart';
import '../theme/finwise_tokens.dart';

class FinwiseDialog extends StatelessWidget {
  const FinwiseDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
  });

  final String title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: FinwiseShapes.xl,
        side: BorderSide(color: tokens.outline),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: FinwiseSpacing.xl,
        vertical: FinwiseSpacing.xxl,
      ),
      child: Padding(
        padding: const EdgeInsets.all(FinwiseSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: FinwiseSpacing.md),
            content,
            if (actions.isNotEmpty) ...[
              const SizedBox(height: FinwiseSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: FinwiseSpacing.sm),
                    actions[i],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<bool> showFinwiseConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String action = 'Confirm',
  bool isDestructive = false,
}) async {
  final tokens = context.tokens;
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: FinwiseShapes.xl,
        side: BorderSide(color: tokens.outline),
      ),
      title: Text(
        title,
        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
      content: Text(
        message,
        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
              height: 1.4,
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel', style: TextStyle(color: tokens.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isDestructive ? tokens.danger : tokens.primary,
            foregroundColor: isDestructive ? Colors.white : tokens.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: FinwiseShapes.md),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return res ?? false;
}

Future<String?> showFinwiseTextInput(
  BuildContext context, {
  required String title,
  String? initial,
  String? hint,
  String confirmLabel = 'Save',
}) {
  final ctrl = TextEditingController(text: initial);
  final tokens = context.tokens;

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: FinwiseShapes.xl,
        side: BorderSide(color: tokens.outline),
      ),
      title: Text(
        title,
        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: TextStyle(color: tokens.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: tokens.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: FinwiseShapes.md,
            borderSide: BorderSide(color: tokens.outline),
          ),
        ),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim());
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: TextStyle(color: tokens.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: tokens.primary,
            foregroundColor: tokens.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: FinwiseShapes.md),
          ),
          onPressed: () {
            final t = ctrl.text.trim();
            if (t.isNotEmpty) Navigator.pop(ctx, t);
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

void showFinwiseToast(
  BuildContext context,
  String message, {
  String? action,
  VoidCallback? onAction,
}) {
  final tokens = context.tokens;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: tokens.textPrimary,
      shape: RoundedRectangleBorder(borderRadius: FinwiseShapes.md),
      content: Text(
        message,
        style: TextStyle(color: tokens.background, fontWeight: FontWeight.w500),
      ),
      action: action != null && onAction != null
          ? SnackBarAction(
              label: action,
              textColor: tokens.primary,
              onPressed: onAction,
            )
          : null,
    ),
  );
}
