import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tokens.dart';

class NavItemData {
  const NavItemData(this.label, this.icon, this.activeIcon, this.semanticLabel);
  final String label;
  final IconData icon, activeIcon;
  final String semanticLabel;
}

/// Floating, frosted-glass navigation bar featuring sleek icon-only tabs with glow.
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
    final duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 200);

    if (keyboardVisible) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(Sp.page, 0, Sp.page, bottom + Sp.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: p.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: p.outline.withValues(alpha: 0.9), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: p.shadow,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
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
          height: 46,
          constraints: const BoxConstraints(minWidth: 50, maxWidth: 66),
          decoration: BoxDecoration(
            color: selected ? p.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(23),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: p.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: duration,
              curve: Curves.easeOutCubic,
              child: Icon(
                selected ? data.activeIcon : data.icon,
                size: 22,
                color: selected ? p.onPrimary : p.inkMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
