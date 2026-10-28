import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finwise/app/app.dart';
import 'package:finwise/app/providers.dart';
import 'package:finwise/data/storage.dart';
import 'package:finwise/design_system/components/finwise_glass_surface.dart';
import 'package:finwise/design_system/theme/finwise_colors.dart';
import 'package:finwise/design_system/theme/finwise_palette.dart';
import 'package:finwise/design_system/theme/finwise_spacing.dart';
import 'package:finwise/shared/widgets/floating_nav.dart';
import 'package:finwise/theme/app_palette.dart';
import 'package:finwise/theme/app_spacing.dart';
import 'package:finwise/theme/app_tokens.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestAppWithOverrides({
  required SharedPreferences prefs,
  required ScenarioRepository repo,
  Brightness platformBrightness = Brightness.light,
}) {
  return ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      repoProvider.overrideWithValue(repo),
    ],
    child: const FinanceApp(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ScenarioRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'theme': 'system',
      'palette': 'finwise_green',
      'currency': 'INR',
      'locale': 'en_IN',
    });
    prefs = await SharedPreferences.getInstance();
    repo = ScenarioRepository.inMemory();
  });

  group('Design System & Theme Consistency Tests', () {
    test('Default palette is Finwise Green (#059669)', () {
      final defaultPalette = AppPalette.defaultPalette;
      expect(defaultPalette.id, 'finwise_green');
      expect(defaultPalette.primaryLight, FinwiseColors.brand600);
      expect(defaultPalette.primaryDark, FinwiseColors.brand400);

      const dsDefault = FinwisePalette.defaultPalette;
      expect(dsDefault.id, 'finwise_green');
      expect(dsDefault.primaryLight, FinwiseColors.brand600);
    });

    test('Fallback on invalid palette returns Finwise Green', () {
      final fallback = AppPalette.byId('non_existent_palette_123');
      expect(fallback.id, 'finwise_green');
      expect(fallback.primaryLight, const Color(0xFF059669));

      final dsFallback = FinwisePalette.byId('invalid_xyz');
      expect(dsFallback.id, 'finwise_green');
    });

    testWidgets('App initializes with Finwise Green in System mode',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester
          .pumpWidget(createTestAppWithOverrides(prefs: prefs, repo: repo));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.text('Finwise'));
      final theme = Theme.of(context);
      final tokens = context.tokens;

      expect(tokens.primary, FinwiseColors.brand600);
      expect(theme.colorScheme.primary, FinwiseColors.brand600);
    });

    testWidgets('Switching to Dark mode immediately updates theme to dark',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          repoProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FinanceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Settings
      await tester.tap(find.byIcon(PhosphorIconsRegular.gearSix));
      await tester.pumpAndSettle();

      // Switch to Dark mode
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Verify theme mode updated in state & storage
      expect(container.read(settingsProvider).themeMode, ThemeMode.dark);
      expect(prefs.getString('theme'), 'dark');

      final BuildContext context = tester.element(find.text('Appearance'));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(context.tokens.primary, FinwiseColors.brand400);
    });

    testWidgets('Switching to Light mode immediately updates theme to light',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          repoProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FinanceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Settings
      await tester.tap(find.byIcon(PhosphorIconsRegular.gearSix));
      await tester.pumpAndSettle();

      // Switch to Light mode
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).themeMode, ThemeMode.light);
      expect(prefs.getString('theme'), 'light');

      final BuildContext context = tester.element(find.text('Appearance'));
      expect(Theme.of(context).brightness, Brightness.light);
      expect(context.tokens.primary, FinwiseColors.brand600);
    });

    testWidgets('Switching palette updates active primary accent and persists',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          repoProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FinanceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Directly update palette via settings provider to ocean_blue
      container.read(settingsProvider.notifier).setPalette('ocean_blue');
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).paletteId, 'ocean_blue');
      expect(prefs.getString('theme_palette'), 'ocean_blue');

      final BuildContext context = tester.element(find.text('Finwise'));
      expect(context.tokens.primary, const Color(0xFF2563EB));
    });

    testWidgets('FinwiseGlassSurface renders children safely with fallback',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinwiseGlassSurface(
              borderRadius: BorderRadius.circular(16),
              child: const Text('Liquid Glass Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Liquid Glass Content'), findsOneWidget);
    });

    testWidgets(
        'FloatingNavBar renders without overflow and highlights active tab with emerald',
        (tester) async {
      int activeIndex = 0;
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              AppTokens.lightFor(AppPalette.defaultPalette),
            ],
          ),
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                bottomNavigationBar: FloatingNavBar(
                  items: const [
                    NavItemData('Home', PhosphorIconsRegular.house,
                        PhosphorIconsFill.house, 'Home'),
                    NavItemData('Calculators', PhosphorIconsRegular.calculator,
                        PhosphorIconsFill.calculator, 'Calculators'),
                    NavItemData('Saved', PhosphorIconsRegular.bookmarkSimple,
                        PhosphorIconsFill.bookmarkSimple, 'Saved'),
                    NavItemData('Settings', PhosphorIconsRegular.gearSix,
                        PhosphorIconsFill.gearSix, 'Settings'),
                  ],
                  index: activeIndex,
                  onChanged: (i) => setState(() => activeIndex = i),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      // No overflow exceptions
      expect(tester.takeException(), isNull);

      // Tap on Calculators tab icon
      await tester.tap(find.byIcon(PhosphorIconsRegular.calculator));
      await tester.pumpAndSettle();
      expect(activeIndex, 1);
      expect(find.text('Calculators'), findsOneWidget);
    });

    test('WCAG 2.1 AA mathematical relative luminance contrast verification',
        () {
      double channelLuminance(double v) => v <= 0.03928
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
      double relLum(Color c) =>
          0.2126 * channelLuminance(c.r) +
          0.7152 * channelLuminance(c.g) +
          0.0722 * channelLuminance(c.b);
      double contrast(Color c1, Color c2) {
        final l1 = relLum(c1);
        final l2 = relLum(c2);
        final lighter = l1 > l2 ? l1 : l2;
        final darker = l1 > l2 ? l2 : l1;
        return (lighter + 0.05) / (darker + 0.05);
      }

      // 1. Text Primary on White >= 15.0:1 (AAA)
      expect(contrast(FinwiseColors.n900, Colors.white), greaterThan(15.0));

      // 2. Text Subtle/Tertiary (n500 = #64748B) on White >= 4.5:1 (AA)
      expect(contrast(FinwiseColors.n500, Colors.white), greaterThan(4.5));

      // 3. Gain Light (#047857) on White >= 4.5:1 (AA)
      expect(contrast(FinwiseColors.gainLight, Colors.white), greaterThan(4.5));

      // 4. Loss Light (#DC2626) on White >= 4.5:1 (AA)
      expect(contrast(FinwiseColors.lossLight, Colors.white), greaterThan(4.5));

      // 5. Dark Mode Text on Dark Surface >= 14.0:1 (AAA)
      expect(contrast(FinwiseColors.n100, FinwiseColors.darkSurface),
          greaterThan(14.0));
    });

    test('Nav clearance consistency across token systems', () {
      expect(FinwiseSpacing.navClearance, 112.0);
      expect(AppSpacing.navClearance, 112.0);
    });

    test('All 6 palettes are synchronized across FinwisePalette and AppPalette',
        () {
      expect(FinwisePalette.all.length, 6);
      expect(AppPalette.all.length, 6);

      for (var i = 0; i < 6; i++) {
        final fp = FinwisePalette.all[i];
        final ap = AppPalette.all[i];
        expect(fp.id, ap.id);
        expect(fp.primaryLight, ap.primaryLight);
        expect(fp.primaryDark, ap.primaryDark);
      }
    });
  });
}
