import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:finwise/data/storage.dart';
import 'package:finwise/domain/models/calc.dart';
import 'package:finwise/features/custom_studio/data/custom_calc_repository.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_calc_definition.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_input_def.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_output_def.dart';
import 'package:finwise/features/custom_studio/runtime/custom_calculator_runtime.dart';

void main() {
  group('Tier 3: Cross-Feature Pairwise Combinations E2E Suite', () {
    // =========================================================================
    // Pairwise 1: Wizard Creation (F1) -> Persistence (F11) -> Library Retrieval (F2)
    // =========================================================================
    test('P1: Wizard creation validates, persists to repository, and is retrievable via library listing', () async {
      final repo = CustomCalcRepository.inMemory();

      const def = CustomCalcDefinition(
        id: 'p1_freelance_tax',
        name: 'Freelancer Flat Tax',
        description: 'Computes flat rate tax on freelance income',
        category: 'taxes',
        inputs: [
          CustomInputDef(id: 'income', label: 'Monthly Income', type: CustomInputType.currency, defaultValue: 8000),
          CustomInputDef(id: 'tax_rate', label: 'Tax Rate %', type: CustomInputType.percentage, defaultValue: 15),
        ],
        outputs: [
          CustomOutputDef(id: 'tax_owed', label: 'Tax Owed', formula: 'income * (tax_rate / 100)', isPrimary: true),
        ],
      );

      // Validate
      expect(def.validate(), isEmpty);

      // Persist
      await repo.save(def);

      // Retrieve via Library query
      final all = await repo.all(includeDrafts: false);
      expect(all.length, 1);
      expect(all.first.id, 'p1_freelance_tax');
      expect(all.first.name, 'Freelancer Flat Tax');
      expect(all.first.inputs.length, 2);
    });

    // =========================================================================
    // Pairwise 2: In-Progress Draft (F3) -> Discard/Resume -> Wizard Completion (F1)
    // =========================================================================
    test('P2: In-progress draft preserves partial state and transitions to published upon wizard completion', () async {
      final repo = CustomCalcRepository.inMemory();

      // Step 1: Save incomplete draft (missing outputs)
      const draftStep1 = CustomCalcDefinition(
        id: 'p2_draft_flow',
        name: 'Draft Loan Analyzer',
        isDraft: true,
        updatedAt: 1000,
        inputs: [
          CustomInputDef(id: 'borrowed', label: 'Borrowed Amount', type: CustomInputType.currency, defaultValue: 50000),
        ],
        outputs: [],
      );
      await repo.save(draftStep1);

      // Verify draft state exists and published is empty
      expect((await repo.all(includeDrafts: false)), isEmpty);
      final retrievedDraft = await repo.getLatestDraft();
      expect(retrievedDraft?.id, 'p2_draft_flow');

      // Step 2: Resume draft and complete wizard by adding outputs and unsetting isDraft
      final completedCalc = retrievedDraft!.copyWith(
        isDraft: false,
        updatedAt: 2000,
        outputs: [
          const CustomOutputDef(id: 'repay', label: 'Total Repayment', formula: 'borrowed * 1.1', isPrimary: true),
        ],
      );
      await repo.save(completedCalc);

      // Verify published list now contains it
      final published = await repo.all(includeDrafts: false);
      expect(published.length, 1);
      expect(published.first.id, 'p2_draft_flow');
      expect(published.first.outputs.first.formula, 'borrowed * 1.1');
    });

    // =========================================================================
    // Pairwise 3: Input Widget Configuration (F4) -> Decoupled Values (F5) -> Formula Evaluation (F7)
    // =========================================================================
    test('P3: Heterogeneous inputs with decoupled formatting feed clean doubles into formula engine', () {
      const def = CustomCalcDefinition(
        id: 'p3_decoupled',
        name: 'Decoupled Values Engine Test',
        inputs: [
          CustomInputDef(id: 'revenue', label: 'Revenue', type: CustomInputType.currency, defaultValue: 250000.0, prefix: r'$'),
          CustomInputDef(id: 'discount', label: 'Discount %', type: CustomInputType.percentage, defaultValue: 12.5, suffix: '%'),
          CustomInputDef(id: 'apply_fee', label: 'Apply Fixed Fee', type: CustomInputType.toggle, defaultValue: 1.0),
          CustomInputDef(id: 'fee_rate', label: 'Fee Scalar', type: CustomInputType.number, defaultValue: 500.0),
        ],
        outputs: [
          CustomOutputDef(
            id: 'discounted_rev',
            label: 'Discounted Revenue',
            formula: 'revenue * (1 - discount / 100)',
          ),
          CustomOutputDef(
            id: 'final_total',
            label: 'Final Total',
            formula: 'discounted_rev - (apply_fee * fee_rate)',
            isPrimary: true,
          ),
        ],
      );

      final inputs = {
        'revenue': 200000.0,
        'discount': 10.0, // 10%
        'apply_fee': 1.0,  // toggle active
        'fee_rate': 1500.0,
      };

      final result = CustomCalculatorRuntime.compute(definition: def, rawInputs: inputs);

      expect(result.hasErrors, isFalse);
      // discounted_rev = 200000 * 0.90 = 180000
      expect(result.values['discounted_rev'], 180000.0);
      // final_total = 180000 - (1.0 * 1500) = 178500
      expect(result.values['final_total'], 178500.0);
    });

    // =========================================================================
    // Pairwise 4: Math Functions (F8) -> Multi-Step Dependency Graph (F9) -> Runtime Reactive Compute (F10)
    // =========================================================================
    test('P4: Advanced math functions in multi-step dependency tree compute reactively', () {
      const def = CustomCalcDefinition(
        id: 'p4_math_tree',
        name: 'Math Functions Dependency Tree',
        inputs: [
          CustomInputDef(id: 'base_score', label: 'Score', type: CustomInputType.number, defaultValue: 64.0),
          CustomInputDef(id: 'factor', label: 'Factor', type: CustomInputType.number, defaultValue: 3.0),
        ],
        outputs: [
          CustomOutputDef(id: 'step_sqrt', label: 'Square Root', formula: 'sqrt(base_score)'), // sqrt(64) = 8
          CustomOutputDef(id: 'step_pow', label: 'Power', formula: 'pow(step_sqrt, 2)'), // 8^2 = 64
          CustomOutputDef(id: 'step_minmax', label: 'Min/Max Bounded', formula: 'min(100, max(10, step_pow * factor))'),
          CustomOutputDef(id: 'final_round', label: 'Rounded Result', formula: 'round(step_minmax / 7, 2)', isPrimary: true),
        ],
      );

      final inputs1 = {'base_score': 64.0, 'factor': 1.5};
      // step_sqrt = 8, step_pow = 64, step_pow * 1.5 = 96
      // step_minmax = min(100, max(10, 96)) = 96
      // final_round = round(96 / 7, 2) = round(13.7142857, 2) = 13.71
      final res1 = CustomCalculatorRuntime.compute(definition: def, rawInputs: inputs1);
      expect(res1.hasErrors, isFalse);
      expect(res1.values['step_sqrt'], 8.0);
      expect(res1.values['step_pow'], 64.0);
      expect(res1.values['step_minmax'], 96.0);
      expect(res1.values['final_round'], 13.71);

      // Reactively change input
      final inputs2 = {'base_score': 100.0, 'factor': 2.0};
      // step_sqrt = 10, step_pow = 100, step_pow * 2 = 200
      // step_minmax = min(100, max(10, 200)) = 100
      // final_round = round(100 / 7, 2) = round(14.285714, 2) = 14.29
      final res2 = CustomCalculatorRuntime.compute(definition: def, rawInputs: inputs2);
      expect(res2.values['step_sqrt'], 10.0);
      expect(res2.values['step_pow'], 100.0);
      expect(res2.values['step_minmax'], 100.0);
      expect(res2.values['final_round'], 14.29);
    });

    // =========================================================================
    // Pairwise 5: Reusable Inputs (F4, F5) -> Formatted Output Widgets (F6) -> Scenario Snapshot (F11)
    // =========================================================================
    test('P5: Custom calculator run generates formatted scenario snapshot and persists in storage', () async {
      final scenarioRepo = ScenarioRepository.inMemory();

      const def = CustomCalcDefinition(
        id: 'p5_roi_calc',
        name: 'Venture ROI Calculator',
        inputs: [
          CustomInputDef(id: 'investment', label: 'Investment', type: CustomInputType.currency, defaultValue: 50000),
          CustomInputDef(id: 'exit_valuation', label: 'Exit Valuation', type: CustomInputType.currency, defaultValue: 250000),
        ],
        outputs: [
          CustomOutputDef(id: 'net_profit', label: 'Net Profit', formula: 'exit_valuation - investment', kind: CustomOutputKind.currency),
          CustomOutputDef(id: 'roi_pct', label: 'Total ROI', formula: 'round(((exit_valuation - investment) / investment) * 100, 1)', kind: CustomOutputKind.percentage, isPrimary: true),
        ],
      );

      final execResult = CustomCalculatorRuntime.compute(
        definition: def,
        rawInputs: {'investment': 50000.0, 'exit_valuation': 250000.0},
      );

      expect(execResult.hasErrors, isFalse);
      expect(execResult.values['net_profit'], 200000.0);
      expect(execResult.values['roi_pct'], 400.0);

      // Create snapshot aligned with project scenario contract
      final snapshot = {
        'primary': {
          'l': execResult.primaryOutput!.label,
          'v': execResult.primaryValue,
          'k': execResult.primaryOutput!.kind.name,
          't': null,
        },
        'rows': [
          for (final out in execResult.outputs)
            {
              'l': out.def.label,
              'v': out.value,
              'k': out.def.kind.name,
              't': null,
            }
        ],
      };

      final scenario = Scenario(
        id: 'scen_p5_venture',
        title: 'Seed Round Exit',
        calcId: 'custom_${def.id}',
        inputs: {'investment': 50000.0, 'exit_valuation': 250000.0},
        snapshot: snapshot,
        createdAt: 100,
        updatedAt: 100,
      );

      await scenarioRepo.upsert(scenario);
      final retrieved = (await scenarioRepo.all()).first;

      expect(retrieved.calcId, 'custom_p5_roi_calc');
      expect((retrieved.snapshot['primary'] as Map)['v'], 400.0);
      expect((retrieved.snapshot['rows'] as List).length, 2);
    });

    // =========================================================================
    // Pairwise 6: Visual Wizard Definition (F1) -> Formatted Outputs (F6) -> Versioned JSON Export (F12)
    // =========================================================================
    test('P6: Wizard-configured definition with rich output formatting exports cleanly to versioned JSON', () {
      final repo = CustomCalcRepository.inMemory();

      const def = CustomCalcDefinition(
        id: 'p6_export_wizard',
        name: 'Rich Formatted Output Calc',
        category: 'wealth',
        inputs: [CustomInputDef(id: 'capital', label: 'Capital', type: CustomInputType.currency, defaultValue: 100000)],
        outputs: [
          CustomOutputDef(
            id: 'dividend',
            label: 'Quarterly Dividend',
            formula: 'capital * 0.02',
            kind: CustomOutputKind.currency,
            decimalPlaces: 2,
            isPrimary: true,
            formulaExplanation: 'Assumes conservative 2% per quarter dividend yield',
          ),
        ],
      );

      final exportedStr = repo.exportToJson(def);
      final map = jsonDecode(exportedStr) as Map<String, dynamic>;

      expect(map['finwise_calculator_export_version'], 1);
      final calcData = map['calculator'] as Map<String, dynamic>;
      expect(calcData['name'], 'Rich Formatted Output Calc');
      final outputData = (calcData['outputs'] as List).first as Map<String, dynamic>;
      expect(outputData['formulaExplanation'], contains('2% per quarter'));
      expect(outputData['isPrimary'], isTrue);
    });

    // =========================================================================
    // Pairwise 7: Versioned JSON Export (F12) -> Strict JSON Import (F12) -> Runtime Execution (F10)
    // =========================================================================
    test('P7: Exported calculator imports into separate instance and produces identical execution results', () {
      final repo = CustomCalcRepository.inMemory();

      const original = CustomCalcDefinition(
        id: 'p7_roundtrip_calc',
        name: 'Compound Growth Predictor',
        inputs: [
          CustomInputDef(id: 'principal', label: 'Principal', type: CustomInputType.currency, defaultValue: 10000),
          CustomInputDef(id: 'annual_rate', label: 'Annual Rate %', type: CustomInputType.percentage, defaultValue: 8),
          CustomInputDef(id: 'years', label: 'Years', type: CustomInputType.duration, defaultValue: 5),
        ],
        outputs: [
          CustomOutputDef(
            id: 'future_val',
            label: 'Future Value',
            formula: 'round(principal * (1 + annual_rate / 100) ^ years, 2)',
            isPrimary: true,
          ),
        ],
      );

      // Export
      final jsonExport = repo.exportToJson(original);

      // Import
      final imported = repo.importFromJson(jsonExport);
      expect(imported.name, 'Compound Growth Predictor (Imported)');
      expect(imported.id, isNot('p7_roundtrip_calc'));

      // Execute both on runtime with same inputs
      final inputs = {'principal': 25000.0, 'annual_rate': 7.5, 'years': 10.0};
      final resOriginal = CustomCalculatorRuntime.compute(definition: original, rawInputs: inputs);
      final resImported = CustomCalculatorRuntime.compute(definition: imported, rawInputs: inputs);

      expect(resImported.primaryValue, resOriginal.primaryValue);
      expect(resImported.primaryValue, closeTo(51525.79, 0.1));
    });

    // =========================================================================
    // Pairwise 8: Complex Math Formulas (F7, F8) -> Error Resilience (F10) -> Partial Output Availability
    // =========================================================================
    test('P8: Faulty formula in one branch does not poison independent calculation branches', () {
      const def = CustomCalcDefinition(
        id: 'p8_partial_fault',
        name: 'Fault Tolerant Multi-Branch',
        inputs: [
          CustomInputDef(id: 'a', label: 'A', type: CustomInputType.number, defaultValue: 50),
          CustomInputDef(id: 'zero', label: 'Zero', type: CustomInputType.number, defaultValue: 0),
        ],
        outputs: [
          // Healthy branch
          CustomOutputDef(id: 'healthy_out', label: 'Healthy', formula: 'a * 3'),
          // Faulty branch (div zero)
          CustomOutputDef(id: 'faulty_out', label: 'Faulty', formula: 'a / zero'),
          // Dependent on faulty branch
          CustomOutputDef(id: 'dependent_out', label: 'Dependent', formula: 'faulty_out + 10'),
          // Another healthy branch
          CustomOutputDef(id: 'healthy_out_2', label: 'Healthy 2', formula: 'sqrt(a * 2)', isPrimary: true),
        ],
      );

      final res = CustomCalculatorRuntime.compute(
        definition: def,
        rawInputs: {'a': 50.0, 'zero': 0.0},
      );

      expect(res.hasErrors, isTrue);
      // Independent healthy outputs evaluate successfully
      expect(res.values['healthy_out'], 150.0);
      expect(res.values['healthy_out_2'], 10.0); // sqrt(100) = 10
      // Faulty outputs register error messages
      expect(res.errors['faulty_out'], contains('Division by zero'));
      expect(res.errors['dependent_out'], isNotNull);
    });

    // =========================================================================
    // Pairwise 9: Library Duplicate Action (F2) -> Independent Definition Modification -> Draft Isolation (F3)
    // =========================================================================
    test('P9: Duplicating a calculator enables isolated modification without affecting parent', () async {
      final repo = CustomCalcRepository.inMemory();

      const original = CustomCalcDefinition(
        id: 'p9_parent',
        name: 'Base Financial Model',
        isDraft: false,
        inputs: [CustomInputDef(id: 'rev', label: 'Revenue', type: CustomInputType.currency)],
        outputs: [CustomOutputDef(id: 'net', label: 'Net', formula: 'rev * 0.7', isPrimary: true)],
      );
      await repo.save(original);

      // Duplicate
      final copy = await repo.duplicate('p9_parent');
      expect(copy.name, 'Base Financial Model (Copy)');

      // Modify the copy and save as draft
      final modifiedDraft = copy.copyWith(
        isDraft: true,
        name: 'Draft Experimental Model',
        outputs: [
          const CustomOutputDef(id: 'net', label: 'Net Aggressive', formula: 'rev * 0.85', isPrimary: true),
        ],
      );
      await repo.save(modifiedDraft);

      // Verify parent remains published with original formula
      final parentAfter = await repo.getById('p9_parent');
      expect(parentAfter?.name, 'Base Financial Model');
      expect(parentAfter?.isDraft, isFalse);
      expect(parentAfter?.outputs.first.formula, 'rev * 0.7');

      // Verify draft copy has updated formula
      final draftAfter = await repo.getById(copy.id);
      expect(draftAfter?.isDraft, isTrue);
      expect(draftAfter?.outputs.first.formula, 'rev * 0.85');
    });

    // =========================================================================
    // Pairwise 10: Dropdown Choice Inputs (F4) -> Formula Variable Resolution (F7) -> Dependency Ordering (F9)
    // =========================================================================
    test('P10: Dropdown choice numeric values resolve accurately across multi-tier dependencies', () {
      const def = CustomCalcDefinition(
        id: 'p10_dropdown_calc',
        name: 'Tiered Tax Bracket Dropdown Calc',
        inputs: [
          CustomInputDef(id: 'taxable_income', label: 'Income', type: CustomInputType.currency, defaultValue: 100000),
          CustomInputDef(
            id: 'bracket_rate',
            label: 'Tax Bracket',
            type: CustomInputType.dropdown,
            options: [
              CustomChoiceOption(value: '0.10', label: '10% Bracket'),
              CustomChoiceOption(value: '0.22', label: '22% Bracket'),
              CustomChoiceOption(value: '0.37', label: '37% Bracket'),
            ],
            defaultValue: 0.22,
          ),
        ],
        outputs: [
          CustomOutputDef(id: 'tax_amount', label: 'Tax Amount', formula: 'taxable_income * bracket_rate'),
          CustomOutputDef(id: 'net_after_tax', label: 'Net Income', formula: 'taxable_income - tax_amount', isPrimary: true),
        ],
      );

      // Evaluate with 22% bracket
      final res22 = CustomCalculatorRuntime.compute(
        definition: def,
        rawInputs: {'taxable_income': 100000.0, 'bracket_rate': 0.22},
      );
      expect(res22.values['tax_amount'], 22000.0);
      expect(res22.values['net_after_tax'], 78000.0);

      // Evaluate with 37% bracket
      final res37 = CustomCalculatorRuntime.compute(
        definition: def,
        rawInputs: {'taxable_income': 100000.0, 'bracket_rate': 0.37},
      );
      expect(res37.values['tax_amount'], 37000.0);
      expect(res37.values['net_after_tax'], 63000.0);
    });

    // =========================================================================
    // Pairwise 11: Toggle and Slider Inputs (F4) -> Reactive Runtime Compute (F10) -> Output Formatting (F5, F6)
    // =========================================================================
    test('P11: Toggle and slider inputs adjust calculation values and drive formatted outputs', () {
      const def = CustomCalcDefinition(
        id: 'p11_toggle_slider',
        name: 'Warranty & Coverage Calculator',
        inputs: [
          CustomInputDef(id: 'product_cost', label: 'Product Cost', type: CustomInputType.currency, defaultValue: 1000),
          CustomInputDef(id: 'has_warranty', label: 'Add 2-Year Warranty?', type: CustomInputType.toggle, defaultValue: 1.0),
          CustomInputDef(id: 'coverage_pct', label: 'Coverage Level', type: CustomInputType.slider, min: 5.0, max: 20.0, step: 1.0, defaultValue: 10.0),
        ],
        outputs: [
          CustomOutputDef(
            id: 'warranty_cost',
            label: 'Warranty Fee',
            formula: 'has_warranty * (product_cost * (coverage_pct / 100))',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'total_charge',
            label: 'Total Charged',
            formula: 'product_cost + warranty_cost',
            kind: CustomOutputKind.currency,
            isPrimary: true,
          ),
        ],
      );

      // With warranty ON (1.0) and coverage 15%
      final resOn = CustomCalculatorRuntime.compute(
        definition: def,
        rawInputs: {'product_cost': 1200.0, 'has_warranty': 1.0, 'coverage_pct': 15.0},
      );
      // warranty_cost = 1.0 * (1200 * 0.15) = 180.0
      expect(resOn.values['warranty_cost'], 180.0);
      expect(resOn.values['total_charge'], 1380.0);

      // With warranty OFF (0.0)
      final resOff = CustomCalculatorRuntime.compute(
        definition: def,
        rawInputs: {'product_cost': 1200.0, 'has_warranty': 0.0, 'coverage_pct': 15.0},
      );
      // warranty_cost = 0.0 * ... = 0.0
      expect(resOff.values['warranty_cost'], 0.0);
      expect(resOff.values['total_charge'], 1200.0);
    });

    // =========================================================================
    // Pairwise 12: Library Deletion (F2) -> Persistence Cleanup (F11) -> Draft State Consistency (F3)
    // =========================================================================
    test('P12: Deleting a published calculator preserves independent draft state in storage', () async {
      final repo = CustomCalcRepository.inMemory();

      const published = CustomCalcDefinition(
        id: 'p12_pub_to_delete',
        name: 'Obsolete Published Calculator',
        isDraft: false,
        inputs: [CustomInputDef(id: 'a', label: 'A', type: CustomInputType.number)],
        outputs: [CustomOutputDef(id: 'b', label: 'B', formula: 'a')],
      );
      const draft = CustomCalcDefinition(
        id: 'p12_wip_draft',
        name: 'Work In Progress Draft',
        isDraft: true,
      );

      await repo.save(published);
      await repo.save(draft);

      expect((await repo.all(includeDrafts: false)).length, 1);
      expect((await repo.all(includeDrafts: true)).length, 2);

      // Delete the published calculator
      await repo.delete('p12_pub_to_delete');

      // Published list is now empty
      expect((await repo.all(includeDrafts: false)), isEmpty);

      // Draft remains retrievable
      final remainingDraft = await repo.getLatestDraft();
      expect(remainingDraft, isNotNull);
      expect(remainingDraft!.id, 'p12_wip_draft');
    });

    // =========================================================================
    // Pairwise 13: Offline Import (F12, F13) -> Strict Cycle Rejection (F9) -> Safe State Recovery
    // =========================================================================
    test('P13: Offline import rejecting cyclic definitions leaves repository state pristine', () async {
      final repo = CustomCalcRepository.inMemory();

      const existing = CustomCalcDefinition(
        id: 'p13_pristine',
        name: 'Pristine Safe Calculator',
        inputs: [CustomInputDef(id: 'x', label: 'X', type: CustomInputType.number)],
        outputs: [CustomOutputDef(id: 'y', label: 'Y', formula: 'x * 10')],
      );
      await repo.save(existing);

      final corruptJson = jsonEncode({
        'finwise_calculator_export_version': 1,
        'calculator': {
          'id': 'corrupt_cycle',
          'name': 'Corrupt Cycle Calculator',
          'inputs': [{'id': 'in1', 'label': 'In', 'type': 'number'}],
          'outputs': [
            {'id': 'node_a', 'label': 'Node A', 'formula': 'node_b + 1'},
            {'id': 'node_b', 'label': 'Node B', 'formula': 'node_a + 1'},
          ],
        }
      });

      // Attempt import and expect CustomCalcValidationException
      expect(() => repo.importFromJson(corruptJson), throwsA(isA<CustomCalcValidationException>()));

      // Verify repository remains unchanged
      final list = await repo.all();
      expect(list.length, 1);
      expect(list.first.id, 'p13_pristine');
    });

    // =========================================================================
    // Pairwise 14: Built-in Catalog Calculators (F14) Coexistence with Custom Calculator Scenarios (F11)
    // =========================================================================
    test('P14: Built-in catalog scenario snapshots and custom calculator snapshots coexist safely in storage', () async {
      final scenarioRepo = ScenarioRepository.inMemory();

      final now = DateTime.now().millisecondsSinceEpoch;

      // Scenario for built-in Compound Interest (c01)
      final builtInScenario = Scenario(
        id: 'scen_builtin_c01',
        title: 'Retirement FD Plan',
        calcId: 'compound',
        inputs: {'principal': 100000.0, 'rate': 8.5, 'years': 10.0, 'm': '1', 'unit': 'years', 'payout': 'maturity'},
        snapshot: {
          'primary': {'l': 'Estimated final value', 'v': 226098.33, 'k': 'money', 't': null},
          'rows': [{'l': 'Principal', 'v': 100000.0, 'k': 'money', 't': null}],
        },
        createdAt: now,
        updatedAt: now,
      );

      // Scenario for custom calculator
      final customScenario = Scenario(
        id: 'scen_custom_fire',
        title: 'Lean FIRE Projection',
        calcId: 'custom_fire_planner_2026',
        inputs: {'expenses': 40000.0, 'swr': 4.0},
        snapshot: {
          'primary': {'l': 'Target Portfolio', 'v': 1000000.0, 'k': 'currency', 't': null},
          'rows': [{'l': 'Annual Spending', 'v': 40000.0, 'k': 'currency', 't': null}],
        },
        createdAt: now + 1,
        updatedAt: now + 1,
      );

      await scenarioRepo.upsertAll([builtInScenario, customScenario]);
      final all = await scenarioRepo.all();

      expect(all.length, 2);

      // Verify built-in lookup
      final builtIns = all.where((s) => !s.calcId.startsWith('custom_')).toList();
      expect(builtIns.length, 1);
      expect(builtIns.first.calcId, 'compound');

      // Verify custom lookup
      final customs = all.where((s) => s.calcId.startsWith('custom_')).toList();
      expect(customs.length, 1);
      expect(customs.first.calcId, 'custom_fire_planner_2026');
      expect((customs.first.snapshot['primary'] as Map)['v'], 1000000.0);
    });
  });
}
