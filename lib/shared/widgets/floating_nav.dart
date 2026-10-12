import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tokens.dart';

class NavItemData {
  const NavItemData(this.label, this.icon, this.activeIcon, this.semanticLabel);
  final String label;
  final IconData icon, activeIcon;
  final String semanticLabel;
}

/// Floating, inset navigation bar featuring clean icon-only tabs.
///
/// Design:
/// - ~58 dp high, fully rounded floating bar.
/// - Matches theme surface (pure white in light mode, dark graphite in dark mode).
/// - 1px outline + soft shadow.
/// - Active tab: soft pill highlight with active icon. No labels.
/// - Equal width for all tabs — zero layout jumps, zero overflow.
/// - 48dp minimum touch target per item.
/// - Hides smoothly when keyboard is open.
/// - Light haptic feedback on tab change.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key, required this.items, required this.index, required this.onChanged});
  final List<NavItemData> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final bottom = MediaQuery.of(context).padding.bottom;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 10;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 180);

    if (keyboardVisible) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, bottom + Sp.md),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: p.navBg,
          borderRadius: BorderRadius.circular(29),
          border: Border.all(color: p.outline.withValues(alpha: 0.8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: p.shadow,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == index,
                  label: items[i].semanticLabel,
                  child: _NavItem(
                    data: items[i],
                    selected: i == index,
                    duration: duration,
                    palette: p,
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
    required this.palette,
    required this.onTap,
  });

  final NavItemData data;
  final bool selected;
  final Duration duration;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          height: 44,
          constraints: const BoxConstraints(minWidth: 48, maxWidth: 64),
          decoration: BoxDecoration(
            color: selected ? p.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Icon(
              selected ? data.activeIcon : data.icon,
              size: 23,
              color: selected ? p.onPrimary : p.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
