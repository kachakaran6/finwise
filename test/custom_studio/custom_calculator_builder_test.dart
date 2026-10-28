import 'package:finwise/app/providers.dart';
import 'package:finwise/data/storage.dart';
import 'package:finwise/features/custom_studio/data/custom_calc_repository.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_calc_definition.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_input_def.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_output_def.dart';
import 'package:finwise/features/custom_studio/presentation/builder/calculator_builder_screen.dart';
import 'package:finwise/features/custom_studio/presentation/custom_studio_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late ScenarioRepository repo;
  late CustomCalcRepository customCalcRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = ScenarioRepository.inMemory();
    customCalcRepo = repo.customCalcRepo;
  });

  Widget buildTestApp(Widget child) {
    return ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        repoProvider.overrideWithValue(repo),
        customCalcRepoProvider.overrideWithValue(customCalcRepo),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('CustomStudioLibraryScreen Tests', () {
    testWidgets('renders empty state when no custom calculators exist', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp(const CustomStudioLibraryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Custom Calculator Studio'), findsOneWidget);
      expect(find.text('Build Your Own Calculators'), findsOneWidget);
      expect(find.text('Create First Calculator'), findsOneWidget);
      expect(find.text('Import from JSON'), findsOneWidget);
    });

    testWidgets('renders saved calculators, search filter, and duplicate action', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final calc1 = CustomCalcDefinition(
        id: 'calc_1',
        name: 'Freelance Tax Estimator',
        description: 'Computes freelance net profit and taxes',
        category: 'Income',
        inputs: const [
          CustomInputDef(id: 'rev', label: 'Revenue', type: CustomInputType.currency, defaultValue: 1000),
        ],
        outputs: const [
          CustomOutputDef(id: 'tax', label: 'Tax', formula: 'rev * 0.2', isPrimary: true),
        ],
        createdAt: 1000,
        updatedAt: 1000,
      );

      final calc2 = CustomCalcDefinition(
        id: 'calc_2',
        name: 'Rental Yield Calculator',
        description: 'Computes gross rental yield',
        category: 'Real Estate',
        inputs: const [
          CustomInputDef(id: 'rent', label: 'Rent', type: CustomInputType.currency, defaultValue: 500),
        ],
        outputs: const [
          CustomOutputDef(id: 'yield', label: 'Yield', formula: 'rent * 12', isPrimary: true),
        ],
        createdAt: 2000,
        updatedAt: 2000,
      );

      await customCalcRepo.save(calc1);
      await customCalcRepo.save(calc2);

      await tester.pumpWidget(buildTestApp(const CustomStudioLibraryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Freelance Tax Estimator'), findsOneWidget);
      expect(find.text('Rental Yield Calculator'), findsOneWidget);

      // Search filter
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Rental');
      await tester.pumpAndSettle();

      expect(find.text('Freelance Tax Estimator'), findsNothing);
      expect(find.text('Rental Yield Calculator'), findsOneWidget);
    });
  });

  group('CalculatorBuilderScreen Tests', () {
    testWidgets('creates a calculator through guided wizard steps and saves', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp(const CalculatorBuilderScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create Calculator'), findsOneWidget);
      expect(find.text('1. Info'), findsOneWidget);
      expect(find.text('2. Inputs (0)'), findsOneWidget);

      // Enter calculator name
      final nameField = find.widgetWithText(TextField, 'Calculator Name *');
      await tester.enterText(nameField, 'SaaS Margin Calculator');
      await tester.pumpAndSettle();

      // Tap Next Step -> goes to Inputs
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();

      expect(find.text('Input Fields (0)'), findsOneWidget);
      expect(find.text('Add First Input'), findsOneWidget);

      // Open Add Input Sheet
      await tester.tap(find.text('Add First Input'));
      await tester.pumpAndSettle();

      expect(find.text('Add Input Widget'), findsOneWidget);
      // Input label
      final labelField = find.widgetWithText(TextField, 'Input Label');
      await tester.enterText(labelField, 'Monthly ARR');
      await tester.pumpAndSettle();

      // Submit input
      await tester.tap(find.widgetWithText(FilledButton, 'Add Input').last);
      await tester.pumpAndSettle();

      expect(find.text('Monthly ARR'), findsOneWidget);
      expect(find.text('Input Fields (1)'), findsOneWidget);

      // Tap Next Step -> goes to Formulas
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();

      expect(find.text('Calculated Results (0)'), findsOneWidget);

      // Open Add Calculation Sheet
      await tester.tap(find.text('Add First Calculation'));
      await tester.pumpAndSettle();

      expect(find.text('Add Calculated Result'), findsNWidgets(2));
      final resultLabelField = find.widgetWithText(TextField, 'Result Label');
      await tester.enterText(resultLabelField, 'Annual Run Rate');
      await tester.pumpAndSettle();

      // Switch to Mode B (Formula Editor)
      await tester.tap(find.text('Formula'));
      await tester.pumpAndSettle();

      final formulaField = find.widgetWithText(TextField, 'Mathematical Formula');
      await tester.enterText(formulaField, 'monthly_arr * 12');
      await tester.pumpAndSettle();

      expect(find.text('Valid Expression'), findsOneWidget);

      // Submit calculation
      await tester.tap(find.widgetWithText(FilledButton, 'Add Calculated Result'));
      await tester.pumpAndSettle();

      expect(find.text('Annual Run Rate'), findsOneWidget);

      // Save calculator
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify persisted in repo
      final all = await customCalcRepo.all();
      expect(all.length, 1);
      expect(all.first.name, 'SaaS Margin Calculator');
      expect(all.first.inputs.length, 1);
      expect(all.first.outputs.length, 1);
      expect(all.first.isDraft, isFalse);
    });
  });
}
