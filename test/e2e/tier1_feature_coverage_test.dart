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
  group('Tier 1: Feature Coverage E2E Suite', () {
    // Helper to evaluate raw formula strings
    double evalFormula(String formula, [Map<String, double> vars = const {}]) {
      final ast = FormulaParser.parseFormula(formula);
      return FormulaEvaluator.evaluate(ast, vars);
    }

    // =========================================================================
    // F1: Visual Studio & Guided Creation Wizard (R1)
    // =========================================================================
    group('F1: Visual Studio & Guided Creation Wizard', () {
      test('1.1 Basic info properties are populated and immutable', () {
        const def = CustomCalcDefinition(
          id: 'wizard_basic_1',
          name: 'Personal Savings Builder',
          description: 'Calculates monthly compounding for savings goals',
          category: 'savings',
          iconKey: 'piggy_bank',
        );

        expect(def.id, 'wizard_basic_1');
        expect(def.name, 'Personal Savings Builder');
        expect(def.description, 'Calculates monthly compounding for savings goals');
        expect(def.category, 'savings');
        expect(def.iconKey, 'piggy_bank');
        expect(def.schemaVersion, 1);
      });

      test('1.2 Wizard step validation: definition fails if name is empty', () {
        const def = CustomCalcDefinition(
          id: 'no_name',
          name: '   ',
          inputs: [
            CustomInputDef(id: 'income', label: 'Income', type: CustomInputType.currency)
          ],
          outputs: [
            CustomOutputDef(id: 'net', label: 'Net', formula: 'income')
          ],
        );

        final errors = def.validate();
        expect(errors, anyElement(contains('name cannot be empty')));
      });

      test('1.3 Wizard step validation: definition fails if no computational inputs provided', () {
        const def = CustomCalcDefinition(
          id: 'no_inputs',
          name: 'No Inputs Calculator',
          inputs: [
            CustomInputDef(id: 'header', label: 'Header', type: CustomInputType.sectionHeader)
          ],
          outputs: [
            CustomOutputDef(id: 'result', label: 'Result', formula: '100')
          ],
        );

        final errors = def.validate();
        expect(errors, anyElement(contains('At least one numeric, currency, or variable input is required')));
      });

      test('1.4 Wizard step validation: definition fails if no calculated outputs provided', () {
        const def = CustomCalcDefinition(
          id: 'no_outputs',
          name: 'No Outputs Calculator',
          inputs: [
            CustomInputDef(id: 'amount', label: 'Amount', type: CustomInputType.number)
          ],
          outputs: [],
        );

        final errors = def.validate();
        expect(errors, anyElement(contains('At least one calculated output is required')));
      });

      test('1.5 Wizard 4-step structure: valid complete definition passes validation', () {
        const def = CustomCalcDefinition(
          id: 'valid_complete',
          name: 'Valid Complete Calculator',
          description: 'A fully specified calculator meeting all 4 steps',
          category: 'growth',
          inputs: [
            CustomInputDef(id: 'principal', label: 'Principal', type: CustomInputType.currency, defaultValue: 1000),
            CustomInputDef(id: 'rate', label: 'Annual Rate', type: CustomInputType.percentage, defaultValue: 5),
          ],
          outputs: [
            CustomOutputDef(id: 'interest', label: 'Simple Interest', formula: 'principal * (rate / 100)', isPrimary: true),
          ],
        );

        final errors = def.validate();
        expect(errors, isEmpty);
      });
    });

    // =========================================================================
    // F2: Custom Calculator Library & CRUD Actions (R1)
    // =========================================================================
    group('F2: Custom Calculator Library & CRUD Actions', () {
      late CustomCalcRepository repo;

      setUp(() {
        repo = CustomCalcRepository.inMemory();
      });

      test('2.1 Library can add, retrieve by ID, and list saved calculators', () async {
        const def = CustomCalcDefinition(
          id: 'lib_test_1',
          name: 'Mortgage Amortizer',
          inputs: [CustomInputDef(id: 'p', label: 'Loan', type: CustomInputType.currency)],
          outputs: [CustomOutputDef(id: 'm', label: 'Payment', formula: 'p * 0.05')],
        );

        await repo.save(def);
        final fetched = await repo.getById('lib_test_1');
        final all = await repo.all();

        expect(fetched, isNotNull);
        expect(fetched!.name, 'Mortgage Amortizer');
        expect(all.length, 1);
        expect(all.first.id, 'lib_test_1');
      });

      test('2.2 Library duplicate operation creates a deep copy with (Copy) suffix and distinct ID', () async {
        const def = CustomCalcDefinition(
          id: 'original_calc',
          name: 'Investment ROI',
          inputs: [CustomInputDef(id: 'inv', label: 'Invested', type: CustomInputType.currency)],
          outputs: [CustomOutputDef(id: 'roi', label: 'ROI', formula: 'inv * 1.2', isPrimary: true)],
        );

        await repo.save(def);
        final copy = await repo.duplicate('original_calc');

        expect(copy.id, isNot('original_calc'));
        expect(copy.name, 'Investment ROI (Copy)');
        expect(copy.inputs.first.id, 'inv');
        expect(copy.outputs.first.formula, 'inv * 1.2');

        final all = await repo.all();
        expect(all.length, 2);
      });

      test('2.3 Library delete operation removes specified calculator from repository', () async {
        const def1 = CustomCalcDefinition(
          id: 'calc_del_1',
          name: 'Calc To Delete',
          inputs: [CustomInputDef(id: 'a', label: 'A', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'o', label: 'O', formula: 'a')],
        );
        const def2 = CustomCalcDefinition(
          id: 'calc_keep_2',
          name: 'Calc To Keep',
          inputs: [CustomInputDef(id: 'b', label: 'B', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'o2', label: 'O2', formula: 'b')],
        );

        await repo.save(def1);
        await repo.save(def2);

        expect((await repo.all()).length, 2);
        await repo.delete('calc_del_1');

        final remaining = await repo.all();
        expect(remaining.length, 1);
        expect(remaining.first.id, 'calc_keep_2');
        expect(await repo.getById('calc_del_1'), isNull);
      });

      test('2.4 Library update/rename persists new name and updated timestamp', () async {
        const original = CustomCalcDefinition(
          id: 'rename_test',
          name: 'Initial Name',
          createdAt: 1000,
          updatedAt: 1000,
          inputs: [CustomInputDef(id: 'x', label: 'X', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'y', label: 'Y', formula: 'x')],
        );

        await repo.save(original);

        final updated = original.copyWith(
          name: 'Renamed Calculator',
          updatedAt: 2000,
        );
        await repo.save(updated);

        final fetched = await repo.getById('rename_test');
        expect(fetched?.name, 'Renamed Calculator');
        expect(fetched?.updatedAt, 2000);
      });

      test('2.5 Library filter matches title, description, or category', () async {
        const defA = CustomCalcDefinition(
          id: 'tax_calc',
          name: 'GST Tax Estimator',
          description: 'Calculates Goods and Services Tax',
          category: 'business',
          inputs: [CustomInputDef(id: 'rev', label: 'Revenue', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'tax', label: 'Tax', formula: 'rev * 0.18')],
        );
        const defB = CustomCalcDefinition(
          id: 'rent_calc',
          name: 'Rental Yield',
          description: 'Real estate annual yield',
          category: 'real_estate',
          inputs: [CustomInputDef(id: 'rent', label: 'Rent', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'yield', label: 'Yield', formula: 'rent * 12')],
        );

        await repo.save(defA);
        await repo.save(defB);

        final all = await repo.all();
        final taxFiltered = all.where((c) =>
          c.name.toLowerCase().contains('gst') ||
          c.description.toLowerCase().contains('gst') ||
          c.category.toLowerCase().contains('gst')).toList();

        final realEstateFiltered = all.where((c) =>
          c.name.toLowerCase().contains('real estate') ||
          c.description.toLowerCase().contains('real estate') ||
          c.category.toLowerCase().contains('real_estate')).toList();

        expect(taxFiltered.length, 1);
        expect(taxFiltered.first.id, 'tax_calc');
        expect(realEstateFiltered.length, 1);
        expect(realEstateFiltered.first.id, 'rent_calc');
      });
    });

    // =========================================================================
    // F3: In-Progress Draft Preservation & Isolation (R1, R4)
    // =========================================================================
    group('F3: In-Progress Draft Preservation & Isolation', () {
      late CustomCalcRepository repo;

      setUp(() {
        repo = CustomCalcRepository.inMemory();
      });

      test('3.1 Saving a calculator with isDraft=true persists as draft', () async {
        const draft = CustomCalcDefinition(
          id: 'draft_101',
          name: 'Draft In Progress',
          isDraft: true,
          inputs: [],
          outputs: [],
        );

        await repo.save(draft);
        final fetched = await repo.getById('draft_101');

        expect(fetched, isNotNull);
        expect(fetched!.isDraft, isTrue);
        expect(fetched.name, 'Draft In Progress');
      });

      test('3.2 getLatestDraft() retrieves the most recently saved draft', () async {
        const draft1 = CustomCalcDefinition(
          id: 'draft_1',
          name: 'First Draft',
          isDraft: true,
          updatedAt: 100,
        );
        const draft2 = CustomCalcDefinition(
          id: 'draft_2',
          name: 'Second Draft (Recent)',
          isDraft: true,
          updatedAt: 500,
        );

        await repo.save(draft1);
        await repo.save(draft2);

        final latest = await repo.getLatestDraft();
        expect(latest, isNotNull);
        expect(latest!.id, 'draft_2');
        expect(latest.name, 'Second Draft (Recent)');
      });

      test('3.3 all(includeDrafts: false) excludes drafts from published library listings', () async {
        const published = CustomCalcDefinition(
          id: 'pub_calc',
          name: 'Published One',
          isDraft: false,
          inputs: [CustomInputDef(id: 'x', label: 'X', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'y', label: 'Y', formula: 'x * 2')],
        );
        const draft = CustomCalcDefinition(
          id: 'draft_calc',
          name: 'Draft Hidden',
          isDraft: true,
        );

        await repo.save(published);
        await repo.save(draft);

        final publishedOnly = await repo.all(includeDrafts: false);
        final withDrafts = await repo.all(includeDrafts: true);

        expect(publishedOnly.length, 1);
        expect(publishedOnly.first.id, 'pub_calc');
        expect(withDrafts.length, 2);
      });

      test('3.4 Overwriting or updating draft preserves published calculators without corruption', () async {
        const published = CustomCalcDefinition(
          id: 'steady_pub',
          name: 'Published Tool',
          isDraft: false,
          inputs: [CustomInputDef(id: 'val', label: 'Val', type: CustomInputType.currency)],
          outputs: [CustomOutputDef(id: 'doubled', label: 'Doubled', formula: 'val * 2')],
        );
        const draftV1 = CustomCalcDefinition(
          id: 'active_draft',
          name: 'Draft V1',
          isDraft: true,
          updatedAt: 100,
        );
        const draftV2 = CustomCalcDefinition(
          id: 'active_draft',
          name: 'Draft V2 (Updated)',
          isDraft: true,
          updatedAt: 200,
        );

        await repo.save(published);
        await repo.save(draftV1);
        await repo.save(draftV2);

        final pubCheck = await repo.getById('steady_pub');
        final draftCheck = await repo.getById('active_draft');

        expect(pubCheck?.name, 'Published Tool');
        expect(draftCheck?.name, 'Draft V2 (Updated)');
        expect(draftCheck?.updatedAt, 200);
      });

      test('3.5 Publishing a draft moves it to the published library', () async {
        const draft = CustomCalcDefinition(
          id: 'wip_calc',
          name: 'Work In Progress',
          isDraft: true,
          inputs: [CustomInputDef(id: 'a', label: 'A', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'b', label: 'B', formula: 'a + 10')],
        );

        await repo.save(draft);
        expect((await repo.all(includeDrafts: false)), isEmpty);

        final published = draft.copyWith(
          isDraft: false,
          name: 'Finalized Calculator',
        );
        await repo.save(published);

        final list = await repo.all(includeDrafts: false);
        expect(list.length, 1);
        expect(list.first.name, 'Finalized Calculator');
        expect(list.first.isDraft, isFalse);
      });
    });

    // =========================================================================
    // F4: Input Widget Library (10 Types) & Stable IDs (R2)
    // =========================================================================
    group('F4: Input Widget Library (10 Types) & Stable IDs', () {
      test('4.1 Numeric, Currency, Percentage, and Duration input definitions with stable IDs', () {
        const numInput = CustomInputDef(id: 'num_1', label: 'Units', type: CustomInputType.number, defaultValue: 10);
        const curInput = CustomInputDef(id: 'cur_1', label: 'Salary', type: CustomInputType.currency, defaultValue: 5000);
        const pctInput = CustomInputDef(id: 'pct_1', label: 'Interest Rate', type: CustomInputType.percentage, defaultValue: 6.5);
        const durInput = CustomInputDef(id: 'dur_1', label: 'Loan Term', type: CustomInputType.duration, defaultValue: 30, durationUnit: 'years');

        expect(numInput.id, 'num_1');
        expect(curInput.id, 'cur_1');
        expect(pctInput.id, 'pct_1');
        expect(durInput.id, 'dur_1');
        expect(durInput.durationUnit, 'years');
        expect(numInput.isComputational, isTrue);
      });

      test('4.2 Dropdown input definition with ChoiceOption values and labels', () {
        const dropdown = CustomInputDef(
          id: 'freq',
          label: 'Compounding Frequency',
          type: CustomInputType.dropdown,
          options: [
            CustomChoiceOption(value: '12', label: 'Monthly'),
            CustomChoiceOption(value: '4', label: 'Quarterly'),
            CustomChoiceOption(value: '1', label: 'Annually'),
          ],
        );

        expect(dropdown.type, CustomInputType.dropdown);
        expect(dropdown.options.length, 3);
        expect(dropdown.options.first.value, '12');
        expect(dropdown.options.first.label, 'Monthly');
        expect(dropdown.isComputational, isTrue);
      });

      test('4.3 Toggle and Slider input definitions with min, max, step', () {
        const toggle = CustomInputDef(id: 'is_taxable', label: 'Taxable?', type: CustomInputType.toggle, defaultValue: 1.0);
        const slider = CustomInputDef(
          id: 'risk_score',
          label: 'Risk Tolerance',
          type: CustomInputType.slider,
          min: 1.0,
          max: 10.0,
          step: 0.5,
          defaultValue: 5.0,
        );

        expect(toggle.defaultValue, 1.0);
        expect(slider.min, 1.0);
        expect(slider.max, 10.0);
        expect(slider.step, 0.5);
        expect(toggle.isComputational, isTrue);
        expect(slider.isComputational, isTrue);
      });

      test('4.4 Date input definition with defaultValue and stable ID', () {
        final nowEpoch = DateTime.now().millisecondsSinceEpoch.toDouble();
        final dateInput = CustomInputDef(
          id: 'target_date',
          label: 'Retirement Date',
          type: CustomInputType.date,
          defaultValue: nowEpoch,
        );

        expect(dateInput.id, 'target_date');
        expect(dateInput.type, CustomInputType.date);
        expect(dateInput.isComputational, isTrue);
      });

      test('4.5 Non-computational layout widgets (infoBlock, sectionHeader) have isComputational=false', () {
        const header = CustomInputDef(id: 'sec_header', label: 'Personal Information', type: CustomInputType.sectionHeader);
        const info = CustomInputDef(id: 'info_note', label: 'Notice', type: CustomInputType.infoBlock, infoText: 'Rates are indicative only.');

        expect(header.isComputational, isFalse);
        expect(info.isComputational, isFalse);
      });
    });

    // =========================================================================
    // F5: Decoupled Numeric Values vs Display Formatting (R2)
    // =========================================================================
    group('F5: Decoupled Numeric Values vs Display Formatting', () {
      test('5.1 Numeric value storage holds raw double regardless of display prefix/suffix', () {
        const input = CustomInputDef(
          id: 'weight',
          label: 'Gold Weight',
          type: CustomInputType.number,
          defaultValue: 25.5,
          suffix: 'grams',
        );

        expect(input.defaultValue, 25.5);
        expect(input.defaultValue is double, isTrue);
      });

      test('5.2 Currency input formatting preserves raw double value distinct from currency symbol', () {
        const input = CustomInputDef(
          id: 'capital',
          label: 'Initial Capital',
          type: CustomInputType.currency,
          defaultValue: 750000.0,
          prefix: r'$',
        );

        expect(input.defaultValue, 750000.0);
        expect(input.defaultValue, isNot(contains(r'$')));
      });

      test('5.3 Percentage input stores raw percentage number distinct from % suffix', () {
        const input = CustomInputDef(
          id: 'tax_rate',
          label: 'State Tax Rate',
          type: CustomInputType.percentage,
          defaultValue: 18.5,
          suffix: '%',
        );

        expect(input.defaultValue, 18.5);
      });

      test('5.4 Duration input preserves numeric scalar distinct from durationUnit', () {
        const input = CustomInputDef(
          id: 'horizon',
          label: 'Investment Horizon',
          type: CustomInputType.duration,
          defaultValue: 7.0,
          durationUnit: 'years',
        );

        expect(input.defaultValue, 7.0);
        expect(input.durationUnit, 'years');
      });

      test('5.5 Toggle stores 1.0 / 0.0 numeric representation for formula evaluation', () {
        const toggleTrue = CustomInputDef(id: 'apply_rebate', label: 'Apply Rebate', type: CustomInputType.toggle, defaultValue: 1.0);
        const toggleFalse = CustomInputDef(id: 'apply_rebate', label: 'Apply Rebate', type: CustomInputType.toggle, defaultValue: 0.0);

        expect(toggleTrue.defaultValue, 1.0);
        expect(toggleFalse.defaultValue, 0.0);
      });
    });

    // =========================================================================
    // F6: Calculated Output Widgets (4 Styles) (R2)
    // =========================================================================
    group('F6: Calculated Output Widgets (4 Styles)', () {
      test('6.1 Primary Result output marked with isPrimary=true and formatting kind', () {
        const primary = CustomOutputDef(
          id: 'total_due',
          label: 'Total Amount Due',
          formula: 'principal + interest',
          isPrimary: true,
          kind: CustomOutputKind.currency,
        );

        expect(primary.isPrimary, isTrue);
        expect(primary.kind, CustomOutputKind.currency);
      });

      test('6.2 Secondary Result output marked with isPrimary=false', () {
        const secondary = CustomOutputDef(
          id: 'monthly_interest',
          label: 'Monthly Interest',
          formula: 'total_interest / 12',
          isPrimary: false,
          kind: CustomOutputKind.currency,
        );

        expect(secondary.isPrimary, isFalse);
      });

      test('6.3 Output with formulaExplanation stores explanation text for user guidance', () {
        const explained = CustomOutputDef(
          id: 'effective_apr',
          label: 'Effective APR',
          formula: '((1 + rate / 12) ^ 12 - 1) * 100',
          formulaExplanation: 'Annual percentage rate compounding monthly',
          kind: CustomOutputKind.percentage,
        );

        expect(explained.formulaExplanation, isNotNull);
        expect(explained.formulaExplanation, contains('compounding monthly'));
      });

      test('6.4 Output with custom decimalPlaces and prefix/suffix', () {
        const formatted = CustomOutputDef(
          id: 'shares_bought',
          label: 'Shares Allocated',
          formula: 'capital / share_price',
          kind: CustomOutputKind.number,
          decimalPlaces: 4,
          suffix: ' units',
        );

        expect(formatted.decimalPlaces, 4);
        expect(formatted.suffix, ' units');
      });

      test('6.5 CustomOutputKind enum supports currency, percentage, and number', () {
        expect(CustomOutputKind.values, containsAll([
          CustomOutputKind.currency,
          CustomOutputKind.percentage,
          CustomOutputKind.number,
        ]));
      });
    });

    // =========================================================================
    // F7: Safe Deterministic Formula Engine & Operators (R3)
    // =========================================================================
    group('F7: Safe Deterministic Formula Engine & Operators', () {
      test('7.1 Basic arithmetic (+, -, *, /)', () {
        expect(evalFormula('15 + 35'), 50.0);
        expect(evalFormula('80 - 32'), 48.0);
        expect(evalFormula('12 * 11'), 132.0);
        expect(evalFormula('144 / 12'), 12.0);
      });

      test('7.2 Operator precedence adheres strictly to standard PEMDAS', () {
        expect(evalFormula('10 + 5 * 2'), 20.0);
        expect(evalFormula('(10 + 5) * 2'), 30.0);
        expect(evalFormula('50 - 20 / 4 + 3'), 48.0);
      });

      test('7.3 Exponentiation (^) operator evaluates right-associatively', () {
        expect(evalFormula('2 ^ 4'), 16.0);
        expect(evalFormula('2 ^ 3 ^ 2'), 512.0); // 2 ^ (3 ^ 2) = 2 ^ 9 = 512
      });

      test('7.4 Percentage postfix operator (%) scales numbers to hundredths', () {
        expect(evalFormula('15%'), 0.15);
        expect(evalFormula('5000 * 20%'), 1000.0);
        expect(evalFormula('200 + 200 * 10%'), 220.0);
      });

      test('7.5 Unary negation and parentheses grouping evaluate accurately', () {
        expect(evalFormula('-25 + 50'), 25.0);
        expect(evalFormula('-(10 + 30)'), -40.0);
        expect(evalFormula('-(-100)'), 100.0);
      });
    });

    // =========================================================================
    // F8: Math Functions (abs, sqrt, min, max, round, pow) (R3)
    // =========================================================================
    group('F8: Math Functions', () {
      test('8.1 abs computes absolute value for negative and positive inputs', () {
        expect(evalFormula('abs(-150.75)'), 150.75);
        expect(evalFormula('abs(150.75)'), 150.75);
        expect(evalFormula('abs(0)'), 0.0);
      });

      test('8.2 sqrt computes square root of positive numbers', () {
        expect(evalFormula('sqrt(49)'), 7.0);
        expect(evalFormula('sqrt(256)'), 16.0);
        expect(evalFormula('sqrt(2)'), closeTo(1.4142, 0.0001));
      });

      test('8.3 min and max select lower and upper bounds of 2 arguments', () {
        expect(evalFormula('min(45, 100)'), 45.0);
        expect(evalFormula('max(45, 100)'), 100.0);
        expect(evalFormula('min(-20, -50)'), -50.0);
      });

      test('8.4 round rounds to integer or specified decimal places', () {
        expect(evalFormula('round(123.456)'), 123.0);
        expect(evalFormula('round(123.456, 2)'), 123.46);
        expect(evalFormula('round(123.456, 1)'), 123.5);
      });

      test('8.5 pow raises base to specified exponent', () {
        expect(evalFormula('pow(3, 4)'), 81.0);
        expect(evalFormula('pow(10, 3)'), 1000.0);
        expect(evalFormula('pow(4, 0.5)'), 2.0);
      });
    });

    // =========================================================================
    // F9: Dependency Graph & Cycle Detection (R3)
    // =========================================================================
    group('F9: Dependency Graph & Cycle Detection', () {
      test('9.1 Linear dependency chain (A -> B -> C) sorts topologically', () {
        final formulas = {
          'c': 'b + 10',
          'b': 'a * 2',
          'a': 'input_val + 5',
        };
        final graph = DependencyGraph.fromFormulas(formulas);
        final order = graph.getEvaluationOrder();

        expect(order.indexOf('a'), lessThan(order.indexOf('b')));
        expect(order.indexOf('b'), lessThan(order.indexOf('c')));
      });

      test('9.2 Multi-branch dependency tree sorts correctly', () {
        final formulas = {
          'final_total': 'subtotal_a + subtotal_b',
          'subtotal_a': 'base * factor_a',
          'subtotal_b': 'base * factor_b',
        };
        final graph = DependencyGraph.fromFormulas(formulas);
        final order = graph.getEvaluationOrder();

        expect(order.indexOf('subtotal_a'), lessThan(order.indexOf('final_total')));
        expect(order.indexOf('subtotal_b'), lessThan(order.indexOf('final_total')));
      });

      test('9.3 Direct circular dependency (A -> B -> A) is detected and throws', () {
        final formulas = {
          'a': 'b + 1',
          'b': 'a * 2',
        };
        final graph = DependencyGraph.fromFormulas(formulas);
        expect(() => graph.getEvaluationOrder(), throwsA(isA<CircularDependencyException>()));
      });

      test('9.4 Indirect circular dependency (A -> B -> C -> A) is detected with cycle path', () {
        final formulas = {
          'a': 'b + 1',
          'b': 'c + 1',
          'c': 'a + 1',
        };
        final graph = DependencyGraph.fromFormulas(formulas);
        expect(
          () => graph.getEvaluationOrder(),
          throwsA(isA<CircularDependencyException>().having(
            (e) => e.cyclePath,
            'cyclePath',
            containsAll(['a', 'b', 'c']),
          )),
        );
      });

      test('9.5 Formula referencing self (A -> A) is detected as immediate cycle', () {
        final formulas = {
          'total': 'total + 10',
        };
        final graph = DependencyGraph.fromFormulas(formulas);
        expect(() => graph.getEvaluationOrder(), throwsA(isA<CircularDependencyException>()));
      });
    });

    // =========================================================================
    // F10: Generic Runtime & Reactive Recalculation (R4)
    // =========================================================================
    group('F10: Generic Runtime & Reactive Recalculation', () {
      final sampleCalc = CustomCalcDefinition(
        id: 'tax_calc',
        name: 'Sales Tax & Total',
        inputs: const [
          CustomInputDef(id: 'price', label: 'Item Price', type: CustomInputType.currency, defaultValue: 100),
          CustomInputDef(id: 'tax_rate', label: 'Tax Rate %', type: CustomInputType.percentage, defaultValue: 8),
        ],
        outputs: const [
          CustomOutputDef(id: 'tax_amount', label: 'Sales Tax', formula: 'price * (tax_rate / 100)'),
          CustomOutputDef(id: 'total_price', label: 'Total Price', formula: 'price + tax_amount', isPrimary: true),
        ],
      );

      test('10.1 Runtime computes all outputs from inputs and formulas in dependency order', () {
        final res = CustomCalculatorRuntime.compute(
          definition: sampleCalc,
          rawInputs: {'price': 200.0, 'tax_rate': 10.0},
        );

        expect(res.hasErrors, isFalse);
        expect(res.values['tax_amount'], 20.0);
        expect(res.values['total_price'], 220.0);
      });

      test('10.2 Runtime updates output reactively when input values change', () {
        final res1 = CustomCalculatorRuntime.compute(
          definition: sampleCalc,
          rawInputs: {'price': 50.0, 'tax_rate': 10.0},
        );
        final res2 = CustomCalculatorRuntime.compute(
          definition: sampleCalc,
          rawInputs: {'price': 100.0, 'tax_rate': 10.0},
        );

        expect(res1.values['total_price'], 55.0);
        expect(res2.values['total_price'], 110.0);
        expect(res2.values['total_price'], isNot(res1.values['total_price']));
      });

      test('10.3 Runtime makes earlier calculated outputs available to downstream formulas', () {
        const chainedCalc = CustomCalcDefinition(
          id: 'chained',
          name: 'Chained Calc',
          inputs: [CustomInputDef(id: 'x', label: 'X', type: CustomInputType.number)],
          outputs: [
            CustomOutputDef(id: 'step1', label: 'Step 1', formula: 'x * 2'),
            CustomOutputDef(id: 'step2', label: 'Step 2', formula: 'step1 + 5'),
            CustomOutputDef(id: 'step3', label: 'Step 3', formula: 'step2 * 3', isPrimary: true),
          ],
        );

        final res = CustomCalculatorRuntime.compute(
          definition: chainedCalc,
          rawInputs: {'x': 10.0},
        );

        // step1 = 20, step2 = 25, step3 = 75
        expect(res.values['step1'], 20.0);
        expect(res.values['step2'], 25.0);
        expect(res.values['step3'], 75.0);
      });

      test('10.4 Runtime handles formula evaluation errors gracefully without crashing the app', () {
        const errorCalc = CustomCalcDefinition(
          id: 'div_zero',
          name: 'Div Zero',
          inputs: [CustomInputDef(id: 'a', label: 'A', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'res', label: 'Result', formula: 'a / 0')],
        );

        final res = CustomCalculatorRuntime.compute(
          definition: errorCalc,
          rawInputs: {'a': 100.0},
        );

        expect(res.hasErrors, isTrue);
        expect(res.errors['res'], contains('Division by zero'));
      });

      test('10.5 Runtime identifies primaryOutput and sets primaryValue correctly', () {
        final res = CustomCalculatorRuntime.compute(
          definition: sampleCalc,
          rawInputs: {'price': 500.0, 'tax_rate': 5.0},
        );

        expect(res.primaryOutput?.id, 'total_price');
        expect(res.primaryValue, 525.0);
      });
    });

    // =========================================================================
    // F11: Offline Persistence & Scenario Snapshot Storage (R4)
    // =========================================================================
    group('F11: Offline Persistence & Scenario Snapshot Storage', () {
      late ScenarioRepository scenarioRepo;

      setUp(() {
        scenarioRepo = ScenarioRepository.inMemory();
      });

      test('11.1 CustomCalcDefinition serializes to and deserializes from JSON without data loss', () {
        const def = CustomCalcDefinition(
          id: 'json_def',
          name: 'JSON Test Calc',
          description: 'Testing JSON roundtrip',
          category: 'investments',
          inputs: [
            CustomInputDef(id: 'p', label: 'Principal', type: CustomInputType.currency, defaultValue: 10000),
          ],
          outputs: [
            CustomOutputDef(id: 'r', label: 'Return', formula: 'p * 1.1', kind: CustomOutputKind.currency, isPrimary: true),
          ],
        );

        final map = def.toJson();
        final restored = CustomCalcDefinition.fromJson(map);

        expect(restored.id, def.id);
        expect(restored.name, def.name);
        expect(restored.inputs.length, 1);
        expect(restored.outputs.length, 1);
        expect(restored.outputs.first.formula, 'p * 1.1');
      });

      test('11.2 Scenario storage saves calculation snapshots linked to custom calculator ID', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        final scenario = Scenario(
          id: 'scen_custom_1',
          title: 'My Custom Plan 2026',
          calcId: 'custom_tax_calc',
          inputs: {'price': 150.0, 'tax_rate': 8.0},
          snapshot: {
            'primary': {'l': 'Total Price', 'v': 162.0, 'k': 'currency', 't': null},
            'rows': [
              {'l': 'Sales Tax', 'v': 12.0, 'k': 'currency', 't': null},
              {'l': 'Total Price', 'v': 162.0, 'k': 'currency', 't': null},
            ],
          },
          createdAt: now,
          updatedAt: now,
        );

        await scenarioRepo.upsert(scenario);
        final list = await scenarioRepo.all();

        expect(list.length, 1);
        expect(list.first.calcId, 'custom_tax_calc');
        expect(list.first.title, 'My Custom Plan 2026');
      });

      test('11.3 Scenario repository can retrieve saved scenarios for custom calculators', () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        final s1 = Scenario(
          id: 'scen_1',
          title: 'Scenario 1',
          calcId: 'custom_calc_a',
          inputs: {'a': 10},
          snapshot: {},
          createdAt: now,
          updatedAt: now,
        );
        final s2 = Scenario(
          id: 'scen_2',
          title: 'Scenario 2',
          calcId: 'c01',
          inputs: {'pv': 1000},
          snapshot: {},
          createdAt: now + 1,
          updatedAt: now + 1,
        );

        await scenarioRepo.upsertAll([s1, s2]);
        final all = await scenarioRepo.all();

        final customOnly = all.where((s) => s.calcId.startsWith('custom_')).toList();
        expect(customOnly.length, 1);
        expect(customOnly.first.id, 'scen_1');
      });

      test('11.4 Scenario snapshot stores primary result and output row breakdown', () async {
        final snapshot = {
          'primary': {'l': 'Net Return', 'v': 4500.0, 'k': 'currency', 't': null},
          'rows': [
            {'l': 'Gross', 'v': 5000.0, 'k': 'currency', 't': null},
            {'l': 'Fee', 'v': 500.0, 'k': 'currency', 't': null},
          ],
        };

        expect(snapshot['primary'], isA<Map<String, dynamic>>());
        expect((snapshot['primary'] as Map)['v'], 4500.0);
        expect((snapshot['rows'] as List).length, 2);
      });

      test('11.5 Scenario updates existing record when saved with same ID', () async {
        final s1 = Scenario(
          id: 'same_id',
          title: 'Version 1',
          calcId: 'custom_sample',
          inputs: {'x': 100},
          snapshot: {},
          createdAt: 1000,
          updatedAt: 1000,
        );
        final s2 = s1.copyWith(
          title: 'Version 2 (Updated)',
          inputs: {'x': 200},
          updatedAt: 2000,
        );

        await scenarioRepo.upsert(s1);
        await scenarioRepo.upsert(s2);

        final list = await scenarioRepo.all();
        expect(list.length, 1);
        expect(list.first.title, 'Version 2 (Updated)');
        expect(list.first.inputs['x'], 200);
      });
    });

    // =========================================================================
    // F12: Versioned JSON File Import & Export Validation (R5)
    // =========================================================================
    group('F12: Versioned JSON File Import & Export Validation', () {
      late CustomCalcRepository repo;

      setUp(() {
        repo = CustomCalcRepository.inMemory();
      });

      test('12.1 Export generates valid JSON with finwise_calculator_export_version header', () {
        const def = CustomCalcDefinition(
          id: 'export_target',
          name: 'Annual Net Planner',
          inputs: [CustomInputDef(id: 'income', label: 'Income', type: CustomInputType.currency)],
          outputs: [CustomOutputDef(id: 'net', label: 'Net', formula: 'income * 0.8', isPrimary: true)],
        );

        final jsonString = repo.exportToJson(def);
        final parsed = jsonDecode(jsonString) as Map<String, dynamic>;

        expect(parsed.containsKey('finwise_calculator_export_version'), isTrue);
        expect(parsed['finwise_calculator_export_version'], 1);
        expect(parsed.containsKey('calculator'), isTrue);
      });

      test('12.2 Import successfully parses exported JSON and creates valid definition', () {
        const def = CustomCalcDefinition(
          id: 'roundtrip_def',
          name: 'Roundtrip Calculator',
          inputs: [CustomInputDef(id: 'a', label: 'A', type: CustomInputType.number, defaultValue: 5)],
          outputs: [CustomOutputDef(id: 'b', label: 'B', formula: 'a ^ 2', isPrimary: true)],
        );

        final exported = repo.exportToJson(def);
        final imported = repo.importFromJson(exported);

        expect(imported.inputs.first.id, 'a');
        expect(imported.outputs.first.formula, 'a ^ 2');
        expect(imported.validate(), isEmpty);
      });

      test('12.3 Import assigns fresh unique ID and appends (Imported) to name', () {
        const def = CustomCalcDefinition(
          id: 'unique_source',
          name: 'My Special Calculator',
          inputs: [CustomInputDef(id: 'x', label: 'X', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'y', label: 'Y', formula: 'x + 1', isPrimary: true)],
        );

        final exported = repo.exportToJson(def);
        final imported = repo.importFromJson(exported);

        expect(imported.id, isNot('unique_source'));
        expect(imported.name, 'My Special Calculator (Imported)');
      });

      test('12.4 Import validates schema and throws on missing calculator key', () {
        final invalidJson = jsonEncode({'version': 1, 'data': 'corrupt'});

        expect(
          () => repo.importFromJson(invalidJson),
          throwsA(isA<CustomCalcValidationException>()),
        );
      });

      test('12.5 Import validates internal formulas and throws on invalid formulas', () {
        final invalidFormulaCalc = {
          'finwise_calculator_export_version': 1,
          'calculator': {
            'id': 'broken_formula',
            'name': 'Broken Formula Calc',
            'inputs': [
              {'id': 'x', 'label': 'X', 'type': 'number'}
            ],
            'outputs': [
              {'id': 'out', 'label': 'Out', 'formula': 'x + * 5'}
            ]
          }
        };

        expect(
          () => repo.importFromJson(jsonEncode(invalidFormulaCalc)),
          throwsA(isA<CustomCalcValidationException>()),
        );
      });
    });

    // =========================================================================
    // F13: Privacy & Offline-First Compliance (R5)
    // =========================================================================
    group('F13: Privacy & Offline-First Compliance', () {
      test('13.1 Formula evaluation performs zero async or network operations', () {
        final stopwatch = Stopwatch()..start();
        final ast = FormulaParser.parseFormula('100 * (1 + 0.05) ^ 10');
        final val = FormulaEvaluator.evaluate(ast, const {});
        stopwatch.stop();

        expect(val, closeTo(162.889, 0.001));
        // Pure synchronous math takes less than 50 milliseconds
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('13.2 CustomCalcRepository functions in-memory without remote backend', () async {
        final repo = CustomCalcRepository.inMemory();
        const def = CustomCalcDefinition(
          id: 'offline_1',
          name: 'Offline Only',
          inputs: [CustomInputDef(id: 'x', label: 'X', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'y', label: 'Y', formula: 'x * 3')],
        );

        await repo.save(def);
        final list = await repo.all();
        expect(list.length, 1);
        expect(list.first.name, 'Offline Only');
      });

      test('13.3 Definition serialization produces self-contained payload with no remote URLs', () {
        const def = CustomCalcDefinition(
          id: 'payload_check',
          name: 'Local Payload',
          inputs: [CustomInputDef(id: 'in1', label: 'In', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'out1', label: 'Out', formula: 'in1')],
        );

        final jsonString = jsonEncode(def.toJson());
        expect(jsonString, isNot(contains('http://')));
        expect(jsonString, isNot(contains('https://')));
        expect(jsonString, isNot(contains('api.finwise.com')));
      });

      test('13.4 All input and output calculations evaluate purely client-side', () {
        const def = CustomCalcDefinition(
          id: 'client_side',
          name: 'Client Side Evaluation',
          inputs: [CustomInputDef(id: 'rate', label: 'Rate', type: CustomInputType.percentage)],
          outputs: [CustomOutputDef(id: 'factor', label: 'Factor', formula: '1 + rate / 100')],
        );

        final res = CustomCalculatorRuntime.compute(definition: def, rawInputs: {'rate': 12.0});
        expect(res.values['factor'], 1.12);
      });

      test('13.5 No telemetry, analytics, or user identifiers are embedded in exported definitions', () {
        final repo = CustomCalcRepository.inMemory();
        const def = CustomCalcDefinition(
          id: 'anon_calc',
          name: 'Anonymous Calculator',
          inputs: [CustomInputDef(id: 'v', label: 'V', type: CustomInputType.number)],
          outputs: [CustomOutputDef(id: 'res', label: 'Res', formula: 'v')],
        );

        final exportStr = repo.exportToJson(def);
        final exportMap = jsonDecode(exportStr) as Map<String, dynamic>;

        expect(exportMap.containsKey('user_id'), isFalse);
        expect(exportMap.containsKey('email'), isFalse);
        expect(exportMap.containsKey('device_id'), isFalse);
      });
    });

    // =========================================================================
    // F14: Baseline Zero Regressions (Catalog, Themes, Home) (Verification)
    // =========================================================================
    group('F14: Baseline Zero Regressions', () {
      test('14.1 Built-in catalog contains 14 standard calculators (C01-C14)', () {
        expect(catalog.length, 14);
        final codes = catalog.map((c) => c.code).toSet();
        expect(codes, containsAll([
          'C01', 'C02', 'C03', 'C04', 'C05', 'C06', 'C07',
          'C08', 'C09', 'C10', 'C11', 'C12', 'C13', 'C14',
        ]));
      });

      test('14.2 Built-in Compound Interest (c01) computes accurately', () {
        final c01 = calcById('compound');
        expect(c01, isNotNull);

        final result = c01!.compute(CalcInputs({
          'principal': 10000.0,
          'rate': 8.0,
          'years': 5.0,
          'unit': 'years',
          'payout': 'maturity',
          'm': '1',
        }));

        // FV = 10000 * (1.08)^5 = 14693.280768
        expect(result.primary.value, closeTo(14693.28, 0.01));
      });

      test('14.3 Built-in Loan EMI (c10) computes accurately', () {
        final c10 = calcById('emi');
        expect(c10, isNotNull);

        final result = c10!.compute(CalcInputs({
          'principal': 100000.0,
          'rate': 10.0,
          'tenure': 1.0,
          'unit': 'years',
          'conv': 'nominal',
        }));

        // 1-year loan of 100k at 10% monthly EMI ~ 8791.59
        expect(result.primary.value, closeTo(8791.59, 1.0));
      });

      test('14.4 Catalog search operates accurately across keywords and categories', () {
        final emiMatches = searchCatalog('EMI');
        expect(emiMatches.any((c) => c.code == 'C10'), isTrue);

        final inflationMatches = searchCatalog('Inflation');
        expect(inflationMatches.any((c) => c.code == 'C09'), isTrue);

        final growthCategoryCalcs = searchCatalog('', category: CalcCategory.growth);
        expect(growthCategoryCalcs, isNotEmpty);
      });

      test('14.5 Theme palette registry contains default Finwise Green and 6 palettes', () {
        expect(AppPalette.all.length, 6);
        expect(AppPalette.defaultPalette.id, 'finwise_green');
        expect(AppPalette.byId('finwise_green').seed.value, 0xFF059669);
      });
    });
  });
}
