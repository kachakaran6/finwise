import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/play_service.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PlayService.checkForUpdate(context);
    });
  }

  static const _items = [
    NavItemData('Home', PhosphorIconsRegular.house, PhosphorIconsFill.house, 'Home'),
    NavItemData('Calculators', PhosphorIconsRegular.calculator, PhosphorIconsFill.calculator, 'Calculators'),
    NavItemData('Saved', PhosphorIconsRegular.bookmarkSimple, PhosphorIconsFill.bookmarkSimple, 'Saved'),
    NavItemData('Settings', PhosphorIconsRegular.gearSix, PhosphorIconsFill.gearSix, 'Settings'),
  ];

  /// Tab-level back: non-Home tabs navigate back to Home.
  /// Home tab exits the app.
  Future<bool> _onTabBack() async {
    if (_index != 0) {
      setState(() => _index = 0);
      return false; // consumed — do not pop
    }
    return true; // let Home's PopScope handle exit
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Forward the back event to our handler
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _onTabBack();
        if (shouldExit && context.mounted) {
          // Home tab — exit the app
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(children: [
          IndexedStack(
            index: _index,
            children: const [HomePage(), CatalogPage(), SavedPage(), SettingsPage()],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavBar(
              items: _items,
              index: _index,
              onChanged: (i) => setState(() => _index = i),
            ),
          ),
        ]),
      ),
    );
  }
}
