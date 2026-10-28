import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.topSpacing = AppSpacing.sectionGap,
    this.bottomSpacing = AppSpacing.sm,
  });

  final String title;
  final Widget? trailing;
  final double topSpacing;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: topSpacing, bottom: bottomSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
