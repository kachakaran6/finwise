import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_elevation.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';

class NavItemData {
  const NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.semanticLabel,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String? semanticLabel;
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItemData> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).padding.bottom;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 10;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 200);

    if (keyboardVisible) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        bottom + AppSpacing.md,
      ),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: tokens.outline,
            width: 1.0,
          ),
          boxShadow: isDark ? AppElevation.e2Dark : AppElevation.e2Light,
        ),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == currentIndex,
                  label: items[i].semanticLabel ?? items[i].label,
                  child: _NavBarItem(
                    data: items[i],
                    isSelected: i == currentIndex,
                    duration: duration,
                    tokens: tokens,
                    onTap: () {
                      if (i != currentIndex) {
                        HapticFeedback.selectionClick();
                        onTap(i);
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.data,
    required this.isSelected,
    required this.duration,
    required this.tokens,
    required this.onTap,
  });

  final NavItemData data;
  final bool isSelected;
  final Duration duration;
  final AppTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = isSelected ? tokens.primary : tokens.textTertiary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? tokens.primaryContainer.withValues(alpha: 0.65)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? data.activeIcon : data.icon,
                  size: 20,
                  color: color,
                ),
                if (isSelected) ...[
                  const SizedBox(width: AppSpacing.xs + 2),
                  Text(
                    data.label,
                    style: textTheme.labelSmall?.copyWith(
                      color: tokens.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
