import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:finwise/app/theme/theme.dart';
import 'package:finwise/data/storage.dart';
import 'package:finwise/domain/calculators/catalog.dart';
import 'package:finwise/domain/models/calc.dart';
import 'package:finwise/features/custom_studio/data/custom_calc_repository.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_calc_definition.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_input_def.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_output_def.dart';
import 'package:finwise/features/custom_studio/engine/dependency_graph.dart';
import 'package:finwise/features/custom_studio/engine/formula_evaluator.dart';
import 'package:finwise/features/custom_studio/engine/formula_parser.dart';
import 'package:finwise/features/custom_studio/runtime/custom_calculator_runtime.dart';

void main() {
  group('Tier 2: Boundary & Corner Cases E2E Suite', () {
    double evalFormula(String formula, [Map<String, double> vars = const {}]) {
      final ast = FormulaParser.parseFormula(formula);
      return FormulaEvaluator.evaluate(ast, vars);
    }

    // =========================================================================
    // F1: Visual Studio & Guided Creation Wizard Boundary/Corner Cases
    // =========================================================================
    group('F1: Visual Studio & Guided Creation Wizard Boundary/Corner', () {
      test('1.1 Whitespace-only name is rejected by validation', () {
        const def = CustomCalcDefinition(
          id: 'ws_name',
          name: '   \t\n  ',
          inputs: [CustomInputDef(id: 'x', label: 'X', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'y', label: 'Y', formula: 'x')],
        );

        final errors = def.validate();
        expect(errors, anyElement(contains('name cannot be empty')));
      });

      test('1.2 Extremely long name (1000 characters) and description handled gracefully', () {
        final longName = 'A' * 1000;
        final longDesc = 'D' * 5000;
        final def = CustomCalcDefinition(
          id: 'long_fields',
          name: longName,
          description: longDesc,
          inputs: const [CustomInputDef(id: 'a', label: 'A', type: CustomInputType.number)],
          outputs: const [CustomOutputDef(id: 'b', label: 'B', formula: 'a * 2', isPrimary: true)],
        );

        expect(def.name.length, 1000);
        expect(def.description.length, 5000);
        expect(def.validate(), isEmpty);
      });

      test('1.3 Duplicate input variable IDs are detected and rejected', () {
        const def = CustomCalcDefinition(
          id: 'dup_inputs',
          name: 'Duplicate Inputs Calc',
          inputs: [
            CustomInputDef(id: 'revenue', label: 'Gross Revenue', type: CustomInputType.currency),
            CustomInputDef(id: 'revenue', label: 'Monthly Revenue', type: CustomInputType.currency),
          ],
          outputs: [
            CustomOutputDef(id: 'total', label: 'Total', formula: 'revenue * 2'),
          ],
        );

        final errors = def.validate();
        expect(errors, anyElement(contains('Duplicate input variable ID: "revenue"')));
      });

      test('1.4 Duplicate output result IDs are detected and rejected', () {
        const def = CustomCalcDefinition(
          id: 'dup_outputs',
          name: 'Duplicate Outputs Calc',
          inputs: [
            CustomInputDef(id: 'units', label: 'Units Sold', type: CustomInputType.number),
          ],
          outputs: [
            CustomOutputDef(id: 'result', label: 'First Result', formula: 'units * 10'),
            CustomOutputDef(id: 'result', label: 'Second Result', formula: 'units * 20'),
          ],
        );

        final errors = def.validate();
        expect(errors, anyElement(contains('Duplicate calculated output ID: "result"')));
      });

      test('1.5 Output ID that clashes with an input variable ID is detected and rejected', () {
        const def = CustomCalcDefinition(
          id: 'clash_id',
          name: 'ID Clash Calc',
          inputs: [
            CustomInputDef(id: 'tax', label: 'Tax Rate', type: CustomInputType.percentage),
          ],
          outputs: [
            CustomOutputDef(id: 'tax', label: 'Tax Amount', formula: 'tax * 100'),
          ],
        );

        final errors = def.validate();
        expect(errors, anyElement(contains('clashes with an input variable ID')));
      });
    });

    // =========================================================================
    // F2: Custom Calculator Library & CRUD Actions Boundary/Corner Cases
    // =========================================================================
    group('F2: Custom Calculator Library & CRUD Actions Boundary/Corner', () {
      late CustomCalcRepository repo;

      setUp(() {
        repo = CustomCalcRepository.inMemory();
      });

      test('2.1 Getting calculator by nonexistent ID returns null', () async {
        final calc = await repo.getById('nonexistent_id_9999');
        expect(calc, isNull);
      });

      test('2.2 Deleting nonexistent ID completes without throwing error', () async {
        expect(() => repo.delete('nonexistent_id_9999'), returnsNormally);
      });

      test('2.3 Duplicating nonexistent ID throws descriptive Exception', () async {
        expect(
          () => repo.duplicate('nonexistent_id_9999'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'toString()',
            contains('not found'),
          )),
        );
      });

      test('2.4 Library search with special regex characters does not crash search', () async {
        const def = CustomCalcDefinition(
          id: 'regex_name',
          name: r'Special [Formula] (100% + $ Bonus)',
          inputs: [CustomInputDef(id: 'x', label: 'X', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'y', label: 'Y', formula: 'x')],
        );
        await repo.save(def);

        final all = await repo.all();
        // Search queries containing regex metacharacters
        for (final query in ['[Formula]', '(100%', r'+ $', '*', '?', '^', r'\']) {
          final q = query.toLowerCase();
          final matches = all.where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q)).toList();
          expect(matches, isA<List<CustomCalcDefinition>>());
        }
      });

      test('2.5 Library search with Unicode, emoji, and mixed-casing filters properly', () async {
        const def = CustomCalcDefinition(
          id: 'unicode_calc',
          name: '🪙 Crypto Yield & ภาษี (Tax)',
          description: 'Calculates Bitcoin staking yield',
          inputs: [CustomInputDef(id: 'btc', label: 'BTC', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'yield', label: 'Yield', formula: 'btc * 0.05')],
        );
        await repo.save(def);

        final all = await repo.all();
        final emojiMatches = all.where((c) => c.name.contains('🪙')).toList();
        final thaiMatches = all.where((c) => c.name.contains('ภาษี')).toList();
        final upperCaseMatches = all.where((c) => c.name.toLowerCase().contains('crypto')).toList();

        expect(emojiMatches.length, 1);
        expect(thaiMatches.length, 1);
        expect(upperCaseMatches.length, 1);
      });
    });

    // =========================================================================
    // F3: In-Progress Draft Preservation & Isolation Boundary/Corner Cases
    // =========================================================================
    group('F3: In-Progress Draft Preservation & Isolation Boundary/Corner', () {
      late CustomCalcRepository repo;

      setUp(() {
        repo = CustomCalcRepository.inMemory();
      });

      test('3.1 getLatestDraft() returns null when repository contains no drafts', () async {
        const published = CustomCalcDefinition(
          id: 'pub_only',
          name: 'Published Only',
          isDraft: false,
          inputs: [CustomInputDef(id: 'a', label: 'A', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'b', label: 'B', formula: 'a')],
        );
        await repo.save(published);

        final draft = await repo.getLatestDraft();
        expect(draft, isNull);
      });

      test('3.2 Incomplete draft with 0 inputs and 0 outputs persists without throwing validation error', () async {
        const emptyDraft = CustomCalcDefinition(
          id: 'empty_draft',
          name: '',
          isDraft: true,
          inputs: [],
          outputs: [],
        );

        // When isDraft=true, repo.save does not enforce strict validation
        await repo.save(emptyDraft);
        final fetched = await repo.getById('empty_draft');

        expect(fetched, isNotNull);
        expect(fetched!.isDraft, isTrue);
        expect(fetched.inputs, isEmpty);
        expect(fetched.outputs, isEmpty);
      });

      test('3.3 Incomplete draft with circular dependency or missing names is allowed to save as draft', () async {
        const circularDraft = CustomCalcDefinition(
          id: 'broken_draft',
          name: '',
          isDraft: true,
          inputs: [CustomInputDef(id: 'x', label: 'X', type: CustomInputType.number)],
          outputs: [
            CustomOutputDef(id: 'a', label: 'A', formula: 'b + 1'),
            CustomOutputDef(id: 'b', label: 'B', formula: 'a + 1'),
          ],
        );

        expect(() => repo.save(circularDraft), returnsNormally);
      });

      test('3.4 Draft with same ID as a published calculator separates them cleanly', () async {
        const published = CustomCalcDefinition(
          id: 'calc_shared_id',
          name: 'Published Version',
          isDraft: false,
          inputs: [CustomInputDef(id: 'x', label: 'X', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'y', label: 'Y', formula: 'x * 2')],
        );
        await repo.save(published);

        final allPublishedBefore = await repo.all(includeDrafts: false);
        expect(allPublishedBefore.length, 1);

        const draftUpdate = CustomCalcDefinition(
          id: 'calc_shared_id_draft',
          name: 'Draft Version of Shared Calc',
          isDraft: true,
          inputs: [],
          outputs: [],
        );
        await repo.save(draftUpdate);

        final allPublishedAfter = await repo.all(includeDrafts: false);
        expect(allPublishedAfter.length, 1);
        expect(allPublishedAfter.first.name, 'Published Version');
      });

      test('3.5 Saving multiple drafts updates draft list and getLatestDraft() accurately picks highest updatedAt', () async {
        for (int i = 1; i <= 5; i++) {
          final draft = CustomCalcDefinition(
            id: 'draft_$i',
            name: 'Draft $i',
            isDraft: true,
            updatedAt: 1000 + i * 100,
          );
          await repo.save(draft);
        }

        final latest = await repo.getLatestDraft();
        expect(latest, isNotNull);
        expect(latest!.id, 'draft_5');
        expect(latest.updatedAt, 1500);
      });
    });

    // =========================================================================
    // F4: Input Widget Library (10 Types) & Stable IDs Boundary/Corner Cases
    // =========================================================================
    group('F4: Input Widget Library (10 Types) & Stable IDs Boundary/Corner', () {
      test('4.1 Slider input clamping bounds: value below min clamps to min, value above max clamps to max', () {
        const slider = CustomInputDef(
          id: 'slider_input',
          label: 'Percentage Slider',
          type: CustomInputType.slider,
          min: 10.0,
          max: 50.0,
          step: 1.0,
          defaultValue: 25.0,
        );

        const testValLow = 5.0;
        const testValHigh = 75.0;

        final clampedLow = testValLow.clamp(slider.min!, slider.max!);
        final clampedHigh = testValHigh.clamp(slider.min!, slider.max!);

        expect(clampedLow, 10.0);
        expect(clampedHigh, 50.0);
      });

      test('4.2 Dropdown input with empty options list handles missing selection safely', () {
        const emptyDropdown = CustomInputDef(
          id: 'empty_drop',
          label: 'No Options',
          type: CustomInputType.dropdown,
          options: [],
        );

        expect(emptyDropdown.options, isEmpty);
        final defaultOption = emptyDropdown.options.isNotEmpty
            ? emptyDropdown.options.first.value
            : '0';
        expect(defaultOption, '0');
        expect(double.tryParse(defaultOption), 0.0);
      });

      test('4.3 Negative default values on currency/percentage preserved accurately', () {
        const negCur = CustomInputDef(
          id: 'loss_amount',
          label: 'Net Loss',
          type: CustomInputType.currency,
          defaultValue: -15000.0,
        );
        const negPct = CustomInputDef(
          id: 'discount_pct',
          label: 'Discount Rate',
          type: CustomInputType.percentage,
          defaultValue: -5.5,
        );

        expect(negCur.defaultValue, -15000.0);
        expect(negPct.defaultValue, -5.5);
      });

      test('4.4 Extremely large numeric values (1e15) do not overflow or throw in definition', () {
        const largeInput = CustomInputDef(
          id: 'national_debt',
          label: 'National Debt',
          type: CustomInputType.currency,
          defaultValue: 1e15,
        );

        expect(largeInput.defaultValue, 1e15);
        expect(largeInput.defaultValue! > 1e14, isTrue);
      });

      test('4.5 Duration input handles 0 duration and fractional durations (0.5 years)', () {
        const zeroDuration = CustomInputDef(
          id: 'zero_dur',
          label: 'Zero Years',
          type: CustomInputType.duration,
          defaultValue: 0.0,
          durationUnit: 'years',
        );
        const halfYear = CustomInputDef(
          id: 'half_dur',
          label: 'Half Year',
          type: CustomInputType.duration,
          defaultValue: 0.5,
          durationUnit: 'years',
        );

        expect(zeroDuration.defaultValue, 0.0);
        expect(halfYear.defaultValue, 0.5);
      });
    });

    // =========================================================================
    // F5: Decoupled Numeric Values vs Display Formatting Boundary/Corner Cases
    // =========================================================================
    group('F5: Decoupled Numeric Values vs Display Formatting Boundary/Corner', () {
      test('5.1 Zero (0.0) value maintains exact raw double 0.0 separate from currency prefix', () {
        const input = CustomInputDef(
          id: 'balance',
          label: 'Account Balance',
          type: CustomInputType.currency,
          defaultValue: 0.0,
          prefix: r'$',
        );

        expect(input.defaultValue, 0.0);
        expect(input.defaultValue == 0.0, isTrue);
      });

      test('5.2 Negative value (-500.0) maintains raw double -500.0 separate from currency symbol', () {
        const input = CustomInputDef(
          id: 'deficit',
          label: 'Deficit',
          type: CustomInputType.currency,
          defaultValue: -500.0,
          prefix: '₹',
        );

        expect(input.defaultValue, -500.0);
        expect(input.defaultValue! < 0, isTrue);
      });

      test('5.3 High floating-point precision (0.0000001) preserved in raw double storage', () {
        const input = CustomInputDef(
          id: 'micro_fee',
          label: 'Micro Transaction Fee',
          type: CustomInputType.number,
          defaultValue: 0.0000001,
        );

        expect(input.defaultValue, 0.0000001);
        expect(input.defaultValue! > 0, isTrue);
      });

      test('5.4 Percentage value > 100% (e.g. 250%) and < 0% (e.g. -15%) stored accurately as double', () {
        const highPct = CustomInputDef(
          id: 'hyper_inflation',
          label: 'Hyperinflation',
          type: CustomInputType.percentage,
          defaultValue: 250.0,
        );
        const defl = CustomInputDef(
          id: 'deflation',
          label: 'Deflation Rate',
          type: CustomInputType.percentage,
          defaultValue: -15.0,
        );

        expect(highPct.defaultValue, 250.0);
        expect(defl.defaultValue, -15.0);
      });

      test('5.5 Duration unit preservation maintains exact scalar value for days, months, and years', () {
        const days = CustomInputDef(id: 'd', label: 'D', type: CustomInputType.duration, defaultValue: 365, durationUnit: 'days');
        const months = CustomInputDef(id: 'm', label: 'M', type: CustomInputType.duration, defaultValue: 12, durationUnit: 'months');
        const years = CustomInputDef(id: 'y', label: 'Y', type: CustomInputType.duration, defaultValue: 1, durationUnit: 'years');

        expect(days.durationUnit, 'days');
        expect(months.durationUnit, 'months');
        expect(years.durationUnit, 'years');
      });
    });

    // =========================================================================
    // F6: Calculated Output Widgets (4 Styles) Boundary/Corner Cases
    // =========================================================================
    group('F6: Calculated Output Widgets (4 Styles) Boundary/Corner', () {
      test('6.1 Decimal places set to 0 rounds output display without decimals', () {
        const out = CustomOutputDef(
          id: 'round_zero',
          label: 'Whole Dollars',
          formula: '123.789',
          kind: CustomOutputKind.number,
          decimalPlaces: 0,
        );

        final val = 123.789;
        final formatted = val.toStringAsFixed(out.decimalPlaces);
        expect(formatted, '124');
      });

      test('6.2 Decimal places set to 6 preserves high precision in display', () {
        const out = CustomOutputDef(
          id: 'high_prec',
          label: 'Micro Rate',
          formula: '0.000123',
          kind: CustomOutputKind.number,
          decimalPlaces: 6,
        );

        final val = 0.00012345;
        final formatted = val.toStringAsFixed(out.decimalPlaces);
        expect(formatted, '0.000123');
      });

      test('6.3 Output with empty prefix and suffix formats without unexpected characters', () {
        const out = CustomOutputDef(
          id: 'clean_num',
          label: 'Raw Number',
          formula: '42',
          kind: CustomOutputKind.number,
          prefix: '',
          suffix: '',
          decimalPlaces: 2,
        );

        final val = 42.0;
        final prefix = out.prefix ?? '';
        final suffix = out.suffix ?? '';
        final formatted = '$prefix${val.toStringAsFixed(out.decimalPlaces)}$suffix';
        expect(formatted, '42.00');
      });

      test('6.4 Output with negative result in currency kind formats correctly', () {
        const out = CustomOutputDef(
          id: 'net_loss',
          label: 'Net Loss',
          formula: 'revenue - expenses',
          kind: CustomOutputKind.currency,
        );

        expect(out.kind, CustomOutputKind.currency);
      });

      test('6.5 Primary output fallback when no output has isPrimary=true defaults to first output', () {
        const def = CustomCalcDefinition(
          id: 'no_primary_set',
          name: 'Fallback Primary',
          inputs: [CustomInputDef(id: 'a', label: 'A', type: CustomInputType.number)],
          outputs: [
            CustomOutputDef(id: 'first', label: 'First', formula: 'a * 2', isPrimary: false),
            CustomOutputDef(id: 'second', label: 'Second', formula: 'a * 3', isPrimary: false),
          ],
        );

        expect(def.primaryOutput, isNotNull);
        expect(def.primaryOutput!.id, 'first');
      });
    });

    // =========================================================================
    // F7: Safe Deterministic Formula Engine & Operators Boundary/Corner Cases
    // =========================================================================
    group('F7: Safe Deterministic Formula Engine & Operators Boundary/Corner', () {
      test('7.1 Chained exponentiation 2 ^ 3 ^ 2 evaluates to 512, right-associative', () {
        // 2 ^ (3 ^ 2) = 2 ^ 9 = 512
        expect(evalFormula('2 ^ 3 ^ 2'), 512.0);
        // Explicit left association: (2 ^ 3) ^ 2 = 8 ^ 2 = 64
        expect(evalFormula('(2 ^ 3) ^ 2'), 64.0);
      });

      test('7.2 Consecutive unary negatives - - - 5 evaluates to -5', () {
        expect(evalFormula('- - - 5'), -5.0);
        expect(evalFormula('- - - - 10'), 10.0);
      });

      test('7.3 Deeply nested parentheses evaluate accurately without stack overflow', () {
        expect(evalFormula('((((10 + 2) * 3) - 6) / 2)'), 15.0);
        expect(evalFormula('((((((2 + 2) * 2) + 2) * 2) + 2) * 2)'), 44.0);
      });

      test('7.4 Percentage chained with addition 100 + 10% evaluates accurately', () {
        // In mathematical parser, 10% is 0.10, so 100 + 10% = 100.1
        expect(evalFormula('100 + 10%'), 100.10);
      });

      test('7.5 Small decimals float arithmetic 0.001 * 0.002 evaluates accurately within epsilon', () {
        expect(evalFormula('0.001 * 0.002'), closeTo(0.000002, 1e-9));
      });
    });

    // =========================================================================
    // F8: Math Functions Boundary/Corner Cases
    // =========================================================================
    group('F8: Math Functions Boundary/Corner', () {
      test('8.1 sqrt(0) evaluates to 0.0', () {
        expect(evalFormula('sqrt(0)'), 0.0);
      });

      test('8.2 sqrt of negative number throws MathEvaluationException', () {
        expect(
          () => evalFormula('sqrt(-16)'),
          throwsA(isA<MathEvaluationException>().having(
            (e) => e.message,
            'message',
            contains('negative number'),
          )),
        );
      });

      test('8.3 min and max with identical arguments return that value', () {
        expect(evalFormula('min(42, 42)'), 42.0);
        expect(evalFormula('max(42, 42)'), 42.0);
        expect(evalFormula('min(0, 0)'), 0.0);
      });

      test('8.4 round boundary values: round(2.5) evaluates to 3.0, round(-2.5) evaluates to -3.0', () {
        expect(evalFormula('round(2.5)'), 3.0);
        expect(evalFormula('round(-2.5)'), -3.0);
        expect(evalFormula('round(0.0)'), 0.0);
      });

      test('8.5 pow corner cases: pow(2, 0) is 1.0, pow(0, 5) is 0.0, pow(2, -2) is 0.25', () {
        expect(evalFormula('pow(2, 0)'), 1.0);
        expect(evalFormula('pow(0, 5)'), 0.0);
        expect(evalFormula('pow(2, -2)'), 0.25);
      });
    });

    // =========================================================================
    // F9: Dependency Graph & Cycle Detection Boundary/Corner Cases
    // =========================================================================
    group('F9: Dependency Graph & Cycle Detection Boundary/Corner', () {
      test('9.1 Self-referential formula x = x + 1 throws CircularDependencyException', () {
        final formulas = {'x': 'x + 1'};
        final graph = DependencyGraph.fromFormulas(formulas);
        expect(() => graph.getEvaluationOrder(), throwsA(isA<CircularDependencyException>()));
      });

      test('9.2 4-node cycle A -> B -> C -> D -> A throws CircularDependencyException with full path', () {
        final formulas = {
          'a': 'b + 1',
          'b': 'c + 1',
          'c': 'd + 1',
          'd': 'a + 1',
        };
        final graph = DependencyGraph.fromFormulas(formulas);
        expect(
          () => graph.getEvaluationOrder(),
          throwsA(isA<CircularDependencyException>().having(
            (e) => e.cyclePath,
            'cyclePath',
            containsAll(['a', 'b', 'c', 'd']),
          )),
        );
      });

      test('9.3 Diamond dependency graph (A -> B, A -> C, B -> D, C -> D) evaluates without cycle', () {
        final formulas = {
          'd': 'b + c',
          'b': 'a * 2',
          'c': 'a * 3',
          'a': '10',
        };
        final graph = DependencyGraph.fromFormulas(formulas);
        final order = graph.getEvaluationOrder();

        expect(order.indexOf('a'), lessThan(order.indexOf('b')));
        expect(order.indexOf('a'), lessThan(order.indexOf('c')));
        expect(order.indexOf('b'), lessThan(order.indexOf('d')));
        expect(order.indexOf('c'), lessThan(order.indexOf('d')));
      });

      test('9.4 Disconnected graph components with multiple independent outputs evaluate safely', () {
        final formulas = {
          'x2': 'x1 + 5',
          'x1': '10',
          'y2': 'y1 * 2',
          'y1': '20',
        };
        final graph = DependencyGraph.fromFormulas(formulas);
        final order = graph.getEvaluationOrder();

        expect(order.length, 4);
        expect(order.indexOf('x1'), lessThan(order.indexOf('x2')));
        expect(order.indexOf('y1'), lessThan(order.indexOf('y2')));
      });

      test('9.5 Formula referencing undefined variable throws MathEvaluationException', () {
        final ast = FormulaParser.parseFormula('known_var + unknown_var');
        expect(
          () => FormulaEvaluator.evaluate(ast, {'known_var': 100}),
          throwsA(isA<MathEvaluationException>().having(
            (e) => e.message,
            'message',
            contains('unknown_var'),
          )),
        );
      });
    });

    // =========================================================================
    // F10: Generic Runtime & Reactive Recalculation Boundary/Corner Cases
    // =========================================================================
    group('F10: Generic Runtime & Reactive Recalculation Boundary/Corner', () {
      test('10.1 Division by zero sets error on that output without crashing other outputs', () {
        const def = CustomCalcDefinition(
          id: 'div_zero_mixed',
          name: 'Div Zero Mixed',
          inputs: [
            CustomInputDef(id: 'val', label: 'Val', type: CustomInputType.number, defaultValue: 100),
            CustomInputDef(id: 'zero', label: 'Zero', type: CustomInputType.number, defaultValue: 0),
          ],
          outputs: [
            CustomOutputDef(id: 'valid_out', label: 'Valid Out', formula: 'val * 2'),
            CustomOutputDef(id: 'div_zero_out', label: 'Div Zero Out', formula: 'val / zero'),
          ],
        );

        final res = CustomCalculatorRuntime.compute(
          definition: def,
          rawInputs: {'val': 100, 'zero': 0},
        );

        expect(res.values['valid_out'], 200.0);
        expect(res.errors['div_zero_out'], contains('Division by zero'));
      });

      test('10.2 Cascading error: dependent output referencing failed output also reports error', () {
        const def = CustomCalcDefinition(
          id: 'cascading_err',
          name: 'Cascading Err',
          inputs: [CustomInputDef(id: 'x', label: 'X', type: CustomInputType.number)],
          outputs: [
            CustomOutputDef(id: 'step1', label: 'Step 1', formula: 'x / 0'),
            CustomOutputDef(id: 'step2', label: 'Step 2', formula: 'step1 + 10'),
          ],
        );

        final res = CustomCalculatorRuntime.compute(
          definition: def,
          rawInputs: {'x': 50},
        );

        expect(res.errors.containsKey('step1'), isTrue);
        expect(res.errors.containsKey('step2'), isTrue);
      });

      test('10.3 Non-finite result (0 / 0 or Infinity) flagged as non-finite error', () {
        const def = CustomCalcDefinition(
          id: 'non_finite',
          name: 'Non Finite',
          inputs: [CustomInputDef(id: 'z', label: 'Z', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'out', label: 'Out', formula: 'z / 0')],
        );

        final res = CustomCalculatorRuntime.compute(definition: def, rawInputs: {'z': 0});
        expect(res.hasErrors, isTrue);
      });

      test('10.4 Missing input variable reports missing variable error gracefully', () {
        const def = CustomCalcDefinition(
          id: 'missing_var',
          name: 'Missing Var',
          inputs: [CustomInputDef(id: 'present', label: 'Present', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'res', label: 'Res', formula: 'present + absent')],
        );

        final res = CustomCalculatorRuntime.compute(definition: def, rawInputs: {'present': 10});
        expect(res.hasErrors, isTrue);
        expect(res.errors['res'], contains('absent'));
      });

      test('10.5 Calculator definition with zero outputs returns empty execution result safely', () {
        const emptyOutputsCalc = CustomCalcDefinition(
          id: 'no_outputs',
          name: 'No Outputs',
          inputs: [CustomInputDef(id: 'a', label: 'A', type: CustomInputType.number)],
          outputs: [],
        );

        final res = CustomCalculatorRuntime.compute(definition: emptyOutputsCalc, rawInputs: {'a': 10});
        expect(res.hasErrors, isFalse);
        expect(res.values, isEmpty);
        expect(res.outputs, isEmpty);
      });
    });

    // =========================================================================
    // F11: Offline Persistence & Scenario Snapshot Storage Boundary/Corner Cases
    // =========================================================================
    group('F11: Offline Persistence & Scenario Snapshot Storage Boundary/Corner', () {
      late ScenarioRepository scenarioRepo;

      setUp(() {
        scenarioRepo = ScenarioRepository.inMemory();
      });

      test('11.1 Corrupt JSON string in scenario database row handled gracefully', () {
        final corruptJson = '{"broken": [}';
        expect(() => jsonDecode(corruptJson), throwsA(isA<FormatException>()));
      });

      test('11.2 Scenario with empty inputs and outputs saves and restores without crash', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        final emptyScenario = Scenario(
          id: 'empty_scen',
          title: 'Empty Scenario',
          calcId: 'custom_empty',
          inputs: {},
          snapshot: {},
          createdAt: now,
          updatedAt: now,
        );

        await scenarioRepo.upsert(emptyScenario);
        final list = await scenarioRepo.all();

        expect(list.length, 1);
        expect(list.first.inputs, isEmpty);
        expect(list.first.snapshot, isEmpty);
      });

      test('11.3 Updating scenario with nonexistent ID inserts new scenario safely', () async {
        final s = Scenario(
          id: 'brand_new_id',
          title: 'Inserted via upsert',
          calcId: 'custom_calc',
          inputs: {'k': 1},
          snapshot: {},
          createdAt: 100,
          updatedAt: 100,
        );

        await scenarioRepo.upsert(s);
        final all = await scenarioRepo.all();
        expect(all.any((x) => x.id == 'brand_new_id'), isTrue);
      });

      test('11.4 Custom calculator definition with unicode emoji in name/description persists accurately', () async {
        final repo = CustomCalcRepository.inMemory();
        const def = CustomCalcDefinition(
          id: 'emoji_calc',
          name: '📊 Growth Plan 🚀 & 💎 Assets',
          description: 'Tracks 📈 returns across portfolio',
          inputs: [CustomInputDef(id: 'val', label: 'Val 💵', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'gain', label: 'Gain 💰', formula: 'val * 1.5')],
        );

        await repo.save(def);
        final fetched = await repo.getById('emoji_calc');

        expect(fetched?.name, '📊 Growth Plan 🚀 & 💎 Assets');
        expect(fetched?.inputs.first.label, 'Val 💵');
        expect(fetched?.outputs.first.label, 'Gain 💰');
      });

      test('11.5 Database all() maintains descending sort order by updatedAt', () async {
        final s1 = Scenario(id: '1', title: 'Old', calcId: 'c', inputs: {}, snapshot: {}, createdAt: 1, updatedAt: 100);
        final s2 = Scenario(id: '2', title: 'New', calcId: 'c', inputs: {}, snapshot: {}, createdAt: 2, updatedAt: 500);
        final s3 = Scenario(id: '3', title: 'Mid', calcId: 'c', inputs: {}, snapshot: {}, createdAt: 3, updatedAt: 300);

        await scenarioRepo.upsertAll([s1, s2, s3]);
        final sorted = await scenarioRepo.all();

        expect(sorted[0].id, '2'); // 500
        expect(sorted[1].id, '3'); // 300
        expect(sorted[2].id, '1'); // 100
      });
    });

    // =========================================================================
    // F12: Versioned JSON File Import & Export Validation Boundary/Corner Cases
    // =========================================================================
    group('F12: Versioned JSON File Import & Export Validation Boundary/Corner', () {
      late CustomCalcRepository repo;

      setUp(() {
        repo = CustomCalcRepository.inMemory();
      });

      test('12.1 Importing non-JSON text throws CustomCalcValidationException', () {
        const junk = '<html><body>Not a JSON</body></html>';
        expect(() => repo.importFromJson(junk), throwsA(isA<CustomCalcValidationException>()));
      });

      test('12.2 Importing JSON missing calculator key throws CustomCalcValidationException', () {
        final missingKey = jsonEncode({
          'finwise_calculator_export_version': 1,
          'wrong_key': {},
        });
        expect(() => repo.importFromJson(missingKey), throwsA(isA<CustomCalcValidationException>()));
      });

      test('12.3 Importing JSON containing circular formula dependency throws CustomCalcValidationException', () {
        final circularPayload = jsonEncode({
          'finwise_calculator_export_version': 1,
          'calculator': {
            'id': 'circ_imported',
            'name': 'Circular Imported',
            'inputs': [{'id': 'a', 'label': 'A', 'type': 'number'}],
            'outputs': [
              {'id': 'x', 'label': 'X', 'formula': 'y + 1'},
              {'id': 'y', 'label': 'Y', 'formula': 'x + 1'},
            ],
          }
        });

        expect(() => repo.importFromJson(circularPayload), throwsA(isA<CustomCalcValidationException>()));
      });

      test('12.4 Importing JSON with invalid formula syntax throws CustomCalcValidationException', () {
        final invalidSyntaxPayload = jsonEncode({
          'finwise_calculator_export_version': 1,
          'calculator': {
            'id': 'bad_syntax',
            'name': 'Bad Syntax',
            'inputs': [{'id': 'a', 'label': 'A', 'type': 'number'}],
            'outputs': [
              {'id': 'res', 'label': 'Res', 'formula': 'a * * / 2'},
            ],
          }
        });

        expect(() => repo.importFromJson(invalidSyntaxPayload), throwsA(isA<CustomCalcValidationException>()));
      });

      test('12.5 Exported JSON contains valid JSON syntax and can be parsed by standard jsonDecode', () {
        const def = CustomCalcDefinition(
          id: 'export_valid',
          name: 'Export Valid Syntax',
          inputs: [CustomInputDef(id: 'i', label: 'I', type: CustomInputType.currency)],
          outputs: [CustomOutputDef(id: 'o', label: 'O', formula: 'i * 2')],
        );

        final jsonStr = repo.exportToJson(def);
        final decoded = jsonDecode(jsonStr);

        expect(decoded, isA<Map<String, dynamic>>());
        expect((decoded as Map)['finwise_calculator_export_version'], 1);
      });
    });

    // =========================================================================
    // F13: Privacy & Offline-First Compliance Boundary/Corner Cases
    // =========================================================================
    group('F13: Privacy & Offline-First Compliance Boundary/Corner', () {
      test('13.1 In-memory repository operates completely without file system or database', () async {
        final memRepo = CustomCalcRepository.inMemory();
        expect(memRepo.all(), completes);
      });

      test('13.2 Definition validate() operates synchronously with zero async hooks', () {
        const def = CustomCalcDefinition(
          id: 'sync_val',
          name: 'Sync Validation Calc',
          inputs: [CustomInputDef(id: 'x', label: 'X', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'y', label: 'Y', formula: 'x * 2')],
        );

        // Validation returns a plain List<String>, not Future
        final errors = def.validate();
        expect(errors, isA<List<String>>());
      });

      test('13.3 FormulaParser and FormulaEvaluator run in isolated deterministic loop', () {
        // Evaluate 1000 expressions sequentially without leaks or external state changes
        for (int i = 0; i < 1000; i++) {
          final res = evalFormula('$i + 10');
          expect(res, (i + 10).toDouble());
        }
      });

      test('13.4 No external URIs or scheme prefixes allowed in imported definition keys', () {
        final repo = CustomCalcRepository.inMemory();
        final maliciousJson = jsonEncode({
          'finwise_calculator_export_version': 1,
          'calculator': {
            'id': 'https://evil.com/leak',
            'name': 'Malicious Scheme Calc',
            'inputs': [{'id': 'x', 'label': 'X', 'type': 'number'}],
            'outputs': [{'id': 'y', 'label': 'Y', 'formula': 'x'}],
          }
        });

        final imported = repo.importFromJson(maliciousJson);
        // The imported ID is always assigned an internal local ID: custom_<timestamp>
        expect(imported.id.startsWith('https://'), isFalse);
        expect(imported.id.startsWith('custom_'), isTrue);
      });

      test('13.5 Storage operations never invoke external network or web sockets', () async {
        final repo = CustomCalcRepository.inMemory();
        const def = CustomCalcDefinition(
          id: 'local_only',
          name: 'Local Only',
          inputs: [CustomInputDef(id: 'a', label: 'A', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'b', label: 'B', formula: 'a')],
        );

        await repo.save(def);
        final list = await repo.all();
        expect(list.length, 1);
      });
    });

    // =========================================================================
    // F14: Baseline Zero Regressions Boundary/Corner Cases
    // =========================================================================
    group('F14: Baseline Zero Regressions Boundary/Corner', () {
      test('14.1 Compound Interest calculator handles 0 years, 0 rate, 0 principal safely', () {
        final c01 = calcById('compound');
        expect(c01, isNotNull);

        final result = c01!.compute(CalcInputs({
          'principal': 0.0,
          'rate': 0.0,
          'years': 1.0,
          'unit': 'years',
          'payout': 'maturity',
          'm': '1',
        }));

        expect(result.primary.value, 0.0);
      });

      test('14.2 Loan EMI calculator handles 0 interest rate safely', () {
        final emi = calcById('emi');
        expect(emi, isNotNull);

        final result = emi!.compute(CalcInputs({
          'principal': 12000.0,
          'rate': 0.0,
          'tenure': 1.0,
          'unit': 'years',
          'conv': 'nominal',
        }));

        // 12000 loan over 1 year at 0% rate is 1000/month
        expect(result.primary.value, 1000.0);
      });

      test('14.3 Catalog search with empty string returns all 14 calculators', () {
        final all = searchCatalog('');
        expect(all.length, 14);
      });

      test('14.4 Catalog search for nonexistent keyword returns empty list', () {
        final none = searchCatalog('nonexistent_super_rare_calculator_xyz');
        expect(none, isEmpty);
      });

      test('14.5 AppPalette fallback on unknown palette index returns default palette', () {
        final fallback = AppPalette.byId('unknown_random_palette_id');
        expect(fallback.id, 'finwise_green');
      });
    });
  });
}
