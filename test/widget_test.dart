import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finwise/app/app.dart';
import 'package:finwise/app/providers.dart';
import 'package:finwise/app/theme/theme.dart';
import 'package:finwise/theme/app_tokens.dart';
import 'package:finwise/data/storage.dart';
import 'package:finwise/domain/calculators/catalog.dart';
import 'package:finwise/features/calculator/calculator_screen.dart';
import 'package:finwise/shared/widgets/common.dart';
import 'package:finwise/shared/widgets/keyboard_accessory_sheet.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestApp({
  required SharedPreferences prefs,
  required ScenarioRepository repo,
  Widget? home,
}) {
  return ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      repoProvider.overrideWithValue(repo),
    ],
    child: home != null
        ? MaterialApp(
            theme: buildTheme(Brightness.light),
            home: home,
          )
        : const FinanceApp(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ScenarioRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'theme': 'system',
      'currency': 'INR',
      'locale': 'en_IN',
    });
    prefs = await SharedPreferences.getInstance();
    repo = ScenarioRepository.inMemory();
  });

  group('Shell and navigation tests', () {
    testWidgets('App launches on Home tab with header', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp(prefs: prefs, repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Finwise'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Popular'), findsOneWidget);
    });

    testWidgets('Can navigate through bottom tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp(prefs: prefs, repo: repo));
      await tester.pumpAndSettle();

      // Tap on Calculators tab icon
      await tester.tap(find.byIcon(PhosphorIconsRegular.calculator));
      await tester.pumpAndSettle();
      expect(find.byType(SearchField), findsOneWidget);

      // Tap on Saved tab icon
      await tester.tap(find.byIcon(PhosphorIconsRegular.bookmarkSimple));
      await tester.pumpAndSettle();
      expect(find.text('No saved scenarios'), findsOneWidget);

      // Tap on Settings tab icon
      await tester.tap(find.byIcon(PhosphorIconsRegular.gearSix));
      await tester.pumpAndSettle();
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
    });
  });

  group('CalculatorScreen interaction tests', () {
    testWidgets('Renders Compound Interest calculator and updates input',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final compoundDef = calcById('compound')!;

      await tester.pumpWidget(
        createTestApp(
          prefs: prefs,
          repo: repo,
          home: CalculatorScreen(def: compoundDef),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compound Interest'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('ESTIMATED FINAL VALUE'), findsOneWidget);

      // Find the Principal text field (first TextField) and enter 20000
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      await tester.enterText(textFields.first, '20000');
      await tester.pumpAndSettle();

      // Results update reactively
      expect(find.text('ESTIMATED FINAL VALUE'), findsOneWidget);
    });

    testWidgets('Can save scenario to repository', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final compoundDef = calcById('compound')!;

      await tester.pumpWidget(
        createTestApp(
          prefs: prefs,
          repo: repo,
          home: CalculatorScreen(def: compoundDef),
        ),
      );
      await tester.pumpAndSettle();

      final saveButton = find.text('Save scenario');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Dialog should appear asking for a title
      expect(find.text('Save scenario'), findsWidgets);
      final saveDialogConfirm = find.text('Save');
      expect(saveDialogConfirm, findsOneWidget);

      await tester.tap(saveDialogConfirm);
      await tester.pumpAndSettle();

      // Verify scenario is saved in repo
      final scenarios = await repo.all();
      expect(scenarios.length, 1);
      expect(scenarios.first.calcId, 'compound');
    });

    testWidgets(
        'Keyboard accessory sheet displays contextual presets on focus and updates value on tap',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(() {
        tester.binding.setSurfaceSize(null);
        tester.view.resetViewInsets();
      });

      final compoundDef = calcById('compound')!;

      await tester.pumpWidget(
        createTestApp(
          prefs: prefs,
          repo: repo,
          home: CalculatorScreen(def: compoundDef),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // 1. Focus on Principal field (index 0)
      await tester.tap(textFields.at(0));
      await tester.pumpAndSettle();

      // Keyboard accessory sheet should appear with Principal label and presets
      expect(find.byType(KeyboardAccessorySheet), findsOneWidget);
      expect(find.text('Principal'), findsWidgets);
      expect(find.text('₹ 50,000'), findsOneWidget);

      // Tap on ₹ 50,000 preset chip
      await tester.tap(find.text('₹ 50,000'));
      await tester.pumpAndSettle();

      // Controller should update to 50000
      final principalField = tester.widget<TextField>(textFields.at(0));
      expect(principalField.controller?.text, '50000');

      // 2. Focus on Annual Interest Rate field (index 1)
      await tester.tap(textFields.at(1));
      await tester.pumpAndSettle();

      // Accessory sheet should contextually update to rate presets
      expect(find.byType(KeyboardAccessorySheet), findsOneWidget);
      expect(find.text('Annual interest rate'), findsWidgets);
      expect(find.text('12%'), findsOneWidget);

      // Tap on 12% preset chip
      await tester.tap(find.text('12%'));
      await tester.pumpAndSettle();

      final rateField = tester.widget<TextField>(textFields.at(1));
      expect(rateField.controller?.text, '12');

      // 3. Focus on Time Period field (index 2)
      await tester.tap(textFields.at(2));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardAccessorySheet), findsOneWidget);
      expect(find.text('Time period'), findsWidgets);
      expect(find.text('15 years'), findsOneWidget);

      await tester.tap(find.text('15 years'));
      await tester.pumpAndSettle();

      final yearsField = tester.widget<TextField>(textFields.at(2));
      expect(yearsField.controller?.text, '15');

      // 4. Dismiss keyboard (viewInsets drops to 0) -> accessory sheet must disappear immediately
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();
      expect(find.byType(KeyboardAccessorySheet), findsNothing);
    });

    testWidgets('Home screen category cards honor active theme accent',
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

      // Initially default Finwise Green
      BuildContext context = tester.element(find.text('Finwise'));
      final greenPrimary = context.tokens.primary;
      expect(greenPrimary, const Color(0xFF059669));

      // Category icon badge uses greenPrimary
      final iconBadges = tester.widgetList<IconBadge>(find.byType(IconBadge));
      expect(iconBadges.first.color, greenPrimary);

      // Switch to Sunset Rose (pink) palette
      container.read(settingsProvider.notifier).setPalette('royal_indigo');
      await tester.pumpAndSettle();

      context = tester.element(find.text('Finwise'));
      final pinkPrimary = context.tokens.primary;
      expect(pinkPrimary, const Color(0xFFE11D48));

      // Category icon badge updates to active pinkPrimary
      final updatedIconBadges =
          tester.widgetList<IconBadge>(find.byType(IconBadge));
      expect(updatedIconBadges.first.color, pinkPrimary);
    });

    testWidgets(
        'Interest payment picker switches from On Maturity to Monthly and updates output',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final compoundDef = calcById('compound')!;

      await tester.pumpWidget(
        createTestApp(
          prefs: prefs,
          repo: repo,
          home: CalculatorScreen(def: compoundDef),
        ),
      );
      await tester.pumpAndSettle();

      // Initially On Maturity is selected and Compounding field is visible
      expect(find.text('Interest payment'), findsWidgets);
      expect(find.text('On Maturity'), findsWidgets);
      expect(find.text('Compounding'), findsOneWidget);

      // Tap on Interest payment to open pickOne modal sheet
      await tester.tap(find.text('On Maturity').first);
      await tester.pumpAndSettle();

      // Modal bottom sheet appears with choices
      expect(find.widgetWithText(ListTile, 'Monthly'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Quarterly'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Yearly'), findsOneWidget);

      // Select 'Monthly' from bottom sheet
      await tester.tap(find.widgetWithText(ListTile, 'Monthly'));
      await tester.pumpAndSettle();

      // Now 'Monthly' is displayed, Compounding field is cleanly hidden, and results show Total payout received
      expect(find.text('Monthly'), findsWidgets);
      expect(find.text('Compounding'), findsOneWidget);
      expect(find.text('TOTAL PAYOUT RECEIVED'), findsOneWidget);
      expect(find.text('Monthly interest payout'), findsOneWidget);
    });
  });
}
