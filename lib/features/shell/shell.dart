import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../shared/widgets/floating_nav.dart';
import '../catalog/catalog_page.dart';
import '../home/home_page.dart';
import '../saved/saved_page.dart';
import '../settings/settings_page.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  static const _items = [
    NavItemData('Home', PhosphorIconsRegular.house, PhosphorIconsFill.house),
    NavItemData('Calculators', PhosphorIconsRegular.calculator, PhosphorIconsFill.calculator),
    NavItemData('Saved', PhosphorIconsRegular.bookmarkSimple, PhosphorIconsFill.bookmarkSimple),
    NavItemData('Settings', PhosphorIconsRegular.gearSix, PhosphorIconsFill.gearSix),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(children: [
        IndexedStack(index: _index, children: const [HomePage(), CatalogPage(), SavedPage(), SettingsPage()]),
        Positioned(left: 0, right: 0, bottom: 0, child: FloatingNavBar(items: _items, index: _index, onChanged: (i) => setState(() => _index = i))),
      ]),
    );
  }
}
