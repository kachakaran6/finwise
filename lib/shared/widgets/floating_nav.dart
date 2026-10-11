import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

class NavItemData {
  const NavItemData(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon, activeIcon;
}

/// Floating, inset pill navigation bar.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key, required this.items, required this.index, required this.onChanged});
  final List<NavItemData> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(Sp.xl, 0, Sp.xl, bottom + Sp.md),
      child: Container(
        height: 68,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: p.navBg,
          borderRadius: Rd.r(Rd.xl + 6),
          boxShadow: [BoxShadow(color: p.shadow, blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Row(children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                label: items[i].label,
                child: InkWell(
                  borderRadius: Rd.r(Rd.xl),
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      color: i == index ? const Color(0x26FFFFFF) : Colors.transparent,
                      borderRadius: Rd.r(Rd.xl),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(i == index ? items[i].activeIcon : items[i].icon, size: 22, color: i == index ? const Color(0xFFE6C77A) : const Color(0xFFA9BBB0)),
                      const SizedBox(height: 3),
                      Text(
                        items[i].label,
                        style: TextStyle(fontFamily: AppType.sans, fontSize: 11, fontWeight: i == index ? FontWeight.w600 : FontWeight.w500, color: i == index ? const Color(0xFFF1F5F2) : const Color(0xFFA9BBB0)),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
