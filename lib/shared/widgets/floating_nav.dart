import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_elevation.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_tokens.dart';

class NavItemData {
  const NavItemData(this.label, this.icon, this.activeIcon, this.semanticLabel);
  final String label;
  final IconData icon, activeIcon;
  final String semanticLabel;
}

/// Floating navigation bar adhering to Finwise design system contract.
/// Height 64, radius pill, surface + e2 elevation, active item = icon + label in primary (no oversized blob).
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  });

  final List<NavItemData> items;
  final int index;
  final ValueChanged<int> onChanged;

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
            for (var i = 0; i < items.length; i++)
              Expanded(
                flex: i == index ? 2 : 1,
                child: Semantics(
                  button: true,
                  selected: i == index,
                  label: items[i].semanticLabel,
                  child: _NavItem(
                    data: items[i],
                    selected: i == index,
                    duration: duration,
                    tokens: tokens,
                    onTap: () {
                      if (i != index) {
                        HapticFeedback.selectionClick();
                        onChanged(i);
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.duration,
    required this.tokens,
    required this.onTap,
  });

  final NavItemData data;
  final bool selected;
  final Duration duration;
  final AppTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = selected ? tokens.primary : tokens.textTertiary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: selected ? AppSpacing.sm + 2 : AppSpacing.xs,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? tokens.primaryContainer.withValues(alpha: 0.65)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? data.activeIcon : data.icon,
                  size: 20,
                  color: color,
                ),
                if (selected) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      data.label,
                      style: textTheme.labelSmall?.copyWith(
                        color: tokens.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
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
