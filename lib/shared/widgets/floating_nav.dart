import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tokens.dart';

class NavItemData {
  const NavItemData(this.label, this.icon, this.activeIcon, this.semanticLabel);
  final String label;
  final IconData icon, activeIcon;
  final String semanticLabel;
}

/// Floating, inset, animated pill navigation bar.
///
/// Design:
/// - ~60 dp high, 16 dp inset from sides, fully rounded.
/// - Neutral surface + 1px outline + soft shadow. No gold icons.
/// - Selected item: pill expands to show icon + label side-by-side (200ms ease-out).
/// - Unselected: icon only.
/// - Icon size 22, label 13 sp medium.
/// - 48dp minimum touch target per item.
/// - Hides when keyboard is open.
/// - Haptic feedback on tab change.
/// - Respects reduced-motion via MediaQuery.disableAnimations.
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
      padding: EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, bottom + Sp.md),
      child: Container(
        height: 60,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: p.navBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: p.outline.withValues(alpha: 0.6)),
          boxShadow: [BoxShadow(color: p.shadow, blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                flex: i == index ? 3 : 2,
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

    return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(2),
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: selected ? p.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: AnimatedSwitcher(
            duration: duration,
            child: selected
                ? ClipRect(
                    key: const ValueKey('selected'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(data.activeIcon, size: 22, color: p.onPrimary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            data.label,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                            style: TextStyle(
                              fontFamily: AppType.sans,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: p.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    key: const ValueKey('unselected'),
                    child: Icon(data.icon, size: 22, color: p.inkMuted),
                  ),
          ),
        ),
      );
  }
}
