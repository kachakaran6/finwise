import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/finwise_elevation.dart';
import '../theme/finwise_shapes.dart';
import '../theme/finwise_spacing.dart';
import '../theme/finwise_tokens.dart';

class FinwiseNavItem {
  const FinwiseNavItem({
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

/// Premium liquid-glass floating navigation bar.
///
/// Adheres strictly to the Finwise design identity:
/// - Single controlled liquid glass surface
/// - Brand emerald active indicator (no arbitrary purple or yellow underlines)
/// - Height 64dp, radius pill, safe-area aware
/// - No content overlap or text clipping
class FinwiseNavBar extends StatelessWidget {
  const FinwiseNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<FinwiseNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = tokens.isDark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 10;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 200);

    if (keyboardVisible) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        FinwiseSpacing.screen,
        0,
        FinwiseSpacing.screen,
        bottomInset + FinwiseSpacing.md,
      ),
      child: Container(
        height: FinwiseSpacing.navBarHeight,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151C28) : Colors.white,
          borderRadius: FinwiseShapes.pill,
          border: Border.all(
            color: isDark ? const Color(0xFF2A3340) : tokens.outline,
            width: 1.0,
          ),
          boxShadow: isDark
              ? FinwiseElevation.navShadowDark
              : FinwiseElevation.navShadowLight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: FinwiseSpacing.sm, vertical: 6),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++)
              Expanded(
                flex: i == currentIndex ? 2 : 1,
                child: Semantics(
                  button: true,
                  selected: i == currentIndex,
                  label: items[i].semanticLabel ?? items[i].label,
                  child: _NavBarTab(
                    item: items[i],
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

class _NavBarTab extends StatelessWidget {
  const _NavBarTab({
    required this.item,
    required this.isSelected,
    required this.duration,
    required this.tokens,
    required this.onTap,
  });

  final FinwiseNavItem item;
  final bool isSelected;
  final Duration duration;
  final FinwiseTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final iconColor = isSelected ? tokens.primary : tokens.textTertiary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: FinwiseShapes.pill,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? FinwiseSpacing.sm + 2 : FinwiseSpacing.xs,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? tokens.primaryContainer.withValues(alpha: 0.65)
                  : Colors.transparent,
              borderRadius: FinwiseShapes.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 20,
                  color: iconColor,
                ),
                if (isSelected) ...[
                  const SizedBox(width: FinwiseSpacing.xs + 2),
                  Flexible(
                    child: Text(
                      item.label,
                      style: textTheme.labelSmall?.copyWith(
                        color: tokens.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
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
