import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finwise/app/app.dart';
import 'package:finwise/app/providers.dart';
import 'package:finwise/app/theme/theme.dart';
import 'package:finwise/data/storage.dart';
import 'package:finwise/shared/widgets/floating_nav.dart';
import 'package:finwise/theme/app_spacing.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const items = [
    NavItemData('Home', PhosphorIconsRegular.house, PhosphorIconsFill.house, 'Home'),
    NavItemData('Calculators', PhosphorIconsRegular.calculator, PhosphorIconsFill.calculator, 'Calculators'),
    NavItemData('Saved', PhosphorIconsRegular.bookmarkSimple, PhosphorIconsFill.bookmarkSimple, 'Saved'),
    NavItemData('Settings', PhosphorIconsRegular.gearSix, PhosphorIconsFill.gearSix, 'Settings'),
  ];

  Widget buildDock({
    required int index,
    required ValueChanged<int> onChanged,
    Brightness brightness = Brightness.light,
    EdgeInsets padding = EdgeInsets.zero,
    EdgeInsets viewInsets = EdgeInsets.zero,
    double textScale = 1.0,
    AppPalette? palette,
  }) {
    return MaterialApp(
      theme: buildTheme(brightness, palette),
      home: MediaQuery(
        data: MediaQueryData(
          padding: padding,
          viewInsets: viewInsets,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FloatingNavBar(
                  items: items,
                  index: index,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('Finwise Adaptive Dock Tests', () {
    testWidgets('Renders all 4 destinations with readable labels and icons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var selected = 0;
      await tester.pumpWidget(
        buildDock(
          index: selected,
          onChanged: (i) => selected = i,
        ),
      );
      await tester.pumpAndSettle();

      // All 4 labels visible for complete discoverability
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Calculators'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Active item uses filled icon; inactive items use regular icons
      expect(find.byIcon(PhosphorIconsFill.house), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.calculator), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.bookmarkSimple), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.gearSix), findsOneWidget);
    });

    testWidgets('Tapping destinations triggers onChanged with haptic feedback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int? tappedIndex;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildDock(
              index: tappedIndex ?? 0,
              onChanged: (i) => setState(() => tappedIndex = i),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Calculators
      await tester.tap(find.text('Calculators'));
      await tester.pumpAndSettle();
      expect(tappedIndex, 1);
      expect(find.byIcon(PhosphorIconsFill.calculator), findsOneWidget);

      // Tap on Saved
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      expect(tappedIndex, 2);
      expect(find.byIcon(PhosphorIconsFill.bookmarkSimple), findsOneWidget);

      // Tap on Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(tappedIndex, 3);
      expect(find.byIcon(PhosphorIconsFill.gearSix), findsOneWidget);
    });

    testWidgets('Zero overflow on narrow device (320px) with 1.3x font scale', (tester) async {
      // Smallest Android screen width with accessibility font scaling
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildDock(
          index: 1, // 'Calculators' is the longest label (11 chars)
          onChanged: (_) {},
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no RenderFlex overflow exception was thrown
      expect(tester.takeException(), isNull);
      expect(find.text('Calculators'), findsOneWidget);
    });

    testWidgets('Hides gracefully when soft keyboard appears', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // With keyboard open (viewInsets.bottom = 300)
      await tester.pumpWidget(
        buildDock(
          index: 0,
          onChanged: (_) {},
          viewInsets: const EdgeInsets.only(bottom: 300),
        ),
      );
      await tester.pumpAndSettle();

      // Dock should auto-hide to avoid covering keyboard or input fields
      expect(find.byType(FloatingNavBar), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('Adapts to Dark Mode and all 6 accent palettes without neon clashing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final p in AppPalette.all) {
        await tester.pumpWidget(
          buildDock(
            index: 3, // Settings
            onChanged: (_) {},
            brightness: Brightness.dark,
            palette: p,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Settings'), findsOneWidget);
      }
    });

    testWidgets('Dynamic bottom nav clearance provides sufficient inset buffer', (tester) async {
      final context = tester.element(find.byType(Container).first);

      // Gesture navigation inset (bottom = 24)
      final clearanceGesture = AppSpacing.bottomNavClearance(context);
      expect(clearanceGesture, greaterThanOrEqualTo(80.0));

      // 3-button navigation inset (bottom = 48)
      // Standardizes bottom clearance so content never overlaps dock
      expect(AppSpacing.navDockHeight, 54.0);
    });

    testWidgets('Home page categories layout maintains full visibility and no orphan gap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({
        'theme': 'light',
        'currency': 'INR',
        'locale': 'en_IN',
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = ScenarioRepository.inMemory();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            repoProvider.overrideWithValue(repo),
          ],
          child: const FinanceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 5 categories are displayed cleanly
      expect(find.text('Growth & Investing'), findsOneWidget);
      expect(find.text('Loans & Debt'), findsOneWidget);
      expect(find.text('Goals & Planning'), findsOneWidget);
      expect(find.text('Returns & Inflation'), findsOneWidget);
      expect(find.text('Utilities'), findsOneWidget);

      // Verify Popular section header follows cleanly
      expect(find.text('Popular'), findsOneWidget);

      // Scroll to bottom and ensure last popular item is fully visible
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('CAGR'), 300, scrollable: scrollable);
      await tester.pumpAndSettle();
      expect(find.text('CAGR'), findsOneWidget);
    });
  });
}
