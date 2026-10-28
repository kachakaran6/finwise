import 'package:finwise/app/providers.dart';
import 'package:finwise/core/format.dart';
import 'package:finwise/data/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_calc_definition.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_input_def.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_output_def.dart';
import 'package:finwise/features/custom_studio/runtime/custom_calculator_runtime.dart';
import 'package:finwise/features/custom_studio/runtime/custom_calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomCalculatorRuntime', () {
    final freelanceCalc = CustomCalcDefinition(
      id: 'freelance_income',
      name: 'Freelance Take-Home',
      description: 'Calculates net income after platform fees and estimated taxes.',
      category: 'Income',
      inputs: const [
        CustomInputDef(
          id: 'revenue',
          label: 'Monthly Revenue',
          type: CustomInputType.currency,
          defaultValue: 5000,
        ),
        CustomInputDef(
          id: 'platform_fee_pct',
          label: 'Platform Fee %',
          type: CustomInputType.percentage,
          defaultValue: 10,
        ),
        CustomInputDef(
          id: 'expenses',
          label: 'Monthly Expenses',
          type: CustomInputType.currency,
          defaultValue: 500,
        ),
        CustomInputDef(
          id: 'tax_rate_pct',
          label: 'Tax Rate %',
          type: CustomInputType.percentage,
          defaultValue: 20,
        ),
      ],
      outputs: const [
        CustomOutputDef(
          id: 'fee_amount',
          label: 'Platform Fees',
          formula: 'revenue * (platform_fee_pct / 100)',
          kind: CustomOutputKind.currency,
        ),
        CustomOutputDef(
          id: 'gross_profit',
          label: 'Profit Before Tax',
          formula: 'revenue - fee_amount - expenses',
          kind: CustomOutputKind.currency,
        ),
        CustomOutputDef(
          id: 'tax_amount',
          label: 'Estimated Tax',
          formula: 'max(0, gross_profit * (tax_rate_pct / 100))',
          kind: CustomOutputKind.currency,
        ),
        CustomOutputDef(
          id: 'take_home',
          label: 'Net Take-Home',
          formula: 'gross_profit - tax_amount',
          kind: CustomOutputKind.currency,
          isPrimary: true,
        ),
      ],
    );

    test('evaluates all outputs in dependency order', () {
      final inputs = {
        'revenue': 5000.0,
        'platform_fee_pct': 10.0,
        'expenses': 500.0,
        'tax_rate_pct': 20.0,
      };

      final result = CustomCalculatorRuntime.compute(
        definition: freelanceCalc,
        rawInputs: inputs,
      );

      expect(result.hasErrors, isFalse);
      // fee_amount = 5000 * 0.10 = 500
      expect(result.values['fee_amount'], 500.0);
      // gross_profit = 5000 - 500 - 500 = 4000
      expect(result.values['gross_profit'], 4000.0);
      // tax_amount = 4000 * 0.20 = 800
      expect(result.values['tax_amount'], 800.0);
      // take_home = 4000 - 800 = 3200
      expect(result.values['take_home'], 3200.0);
      expect(result.primaryValue, 3200.0);
      expect(result.primaryOutput?.id, 'take_home');
    });

    test('handles division by zero gracefully without crashing', () {
      final divZeroCalc = CustomCalcDefinition(
        id: 'div_zero',
        name: 'Division Test',
        inputs: const [
          CustomInputDef(id: 'val', label: 'Value', type: CustomInputType.number, defaultValue: 100),
          CustomInputDef(id: 'zero', label: 'Zero', type: CustomInputType.number, defaultValue: 0),
        ],
        outputs: const [
          CustomOutputDef(
            id: 'res',
            label: 'Result',
            formula: 'val / zero',
            kind: CustomOutputKind.number,
            isPrimary: true,
          ),
        ],
      );

      final result = CustomCalculatorRuntime.compute(
        definition: divZeroCalc,
        rawInputs: {'val': 100, 'zero': 0},
      );

      expect(result.hasErrors, isTrue);
      expect(result.errors['res'], contains('Division by zero'));
    });

    test('detects circular dependencies between outputs', () {
      final cycleCalc = CustomCalcDefinition(
        id: 'cycle',
        name: 'Cycle Test',
        inputs: const [
          CustomInputDef(id: 'a', label: 'A', type: CustomInputType.number, defaultValue: 1),
        ],
        outputs: const [
          CustomOutputDef(id: 'out1', label: 'Out 1', formula: 'out2 + a'),
          CustomOutputDef(id: 'out2', label: 'Out 2', formula: 'out1 * 2'),
        ],
      );

      final result = CustomCalculatorRuntime.compute(
        definition: cycleCalc,
        rawInputs: {'a': 1},
      );

      expect(result.hasErrors, isTrue);
      expect(result.errors['out1'], contains('Circular dependency'));
    });
  });

  group('CustomCalculatorScreen Widget Tests', () {
    testWidgets('renders custom calculator inputs and computes live results', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final simpleCalc = CustomCalcDefinition(
        id: 'profit_calc',
        name: 'Profit Margin Calculator',
        description: 'Computes gross profit from price and cost.',
        inputs: const [
          CustomInputDef(
            id: 'price',
            label: 'Selling Price',
            type: CustomInputType.currency,
            defaultValue: 100,
          ),
          CustomInputDef(
            id: 'cost',
            label: 'Direct Cost',
            type: CustomInputType.currency,
            defaultValue: 40,
          ),
        ],
        outputs: const [
          CustomOutputDef(
            id: 'profit',
            label: 'Gross Profit',
            formula: 'price - cost',
            kind: CustomOutputKind.currency,
            isPrimary: true,
          ),
        ],
      );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = ScenarioRepository.inMemory();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            repoProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: CustomCalculatorScreen(definition: simpleCalc),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title and description
      expect(find.text('Profit Margin Calculator'), findsOneWidget);
      expect(find.text('Selling Price'), findsOneWidget);
      expect(find.text('Direct Cost'), findsOneWidget);
      expect(find.text('GROSS PROFIT'), findsOneWidget);

      // Selling price: 100, cost: 40 => Gross profit: 60.00 (shown in hero banner & output list)
      expect(find.textContaining('60.00'), findsNWidgets(2));

      // Change Selling Price to 200
      final priceField = find.widgetWithText(TextField, 'Selling Price');
      await tester.enterText(priceField, '200');
      await tester.pumpAndSettle();

      // 200 - 40 => 160.00
      expect(find.textContaining('160.00'), findsNWidgets(2));
    });
  });
}
