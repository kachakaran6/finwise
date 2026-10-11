import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finwise/app/app.dart';
import 'package:finwise/app/providers.dart';
import 'package:finwise/app/theme/theme.dart';
import 'package:finwise/data/storage.dart';
import 'package:finwise/domain/calculators/catalog.dart';
import 'package:finwise/features/calculator/calculator_screen.dart';
import 'package:finwise/shared/widgets/common.dart';
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
      expect(find.text('Offline'), findsOneWidget);
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
      expect(find.text('Currency symbol'), findsOneWidget);
    });
  });

  group('CalculatorScreen interaction tests', () {
    testWidgets('Renders Compound Interest calculator and updates input', (tester) async {
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
  });
}
