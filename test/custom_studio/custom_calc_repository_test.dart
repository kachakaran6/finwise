import 'package:flutter_test/flutter_test.dart';
import 'package:finwise/features/custom_studio/data/custom_calc_repository.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_calc_definition.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_input_def.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_output_def.dart';

void main() {
  group('CustomCalcDefinition Models & Validation Tests', () {
    CustomCalcDefinition createSampleFreelanceCalc({bool circular = false}) {
      return CustomCalcDefinition(
        id: 'freelance_income',
        name: 'Freelance Take-Home Calculator',
        description: 'Calculates net income after platform fees and tax',
        category: 'business',
        iconKey: 'wallet',
        inputs: const [
          CustomInputDef(
            id: 'revenue',
            label: 'Monthly Revenue',
            type: CustomInputType.currency,
            defaultValue: 50000.0,
          ),
          CustomInputDef(
            id: 'fee_rate',
            label: 'Platform Fee %',
            type: CustomInputType.percentage,
            defaultValue: 10.0,
          ),
          CustomInputDef(
            id: 'expenses',
            label: 'Operating Expenses',
            type: CustomInputType.currency,
            defaultValue: 5000.0,
          ),
        ],
        outputs: [
          const CustomOutputDef(
            id: 'platform_fees',
            label: 'Platform Fees',
            formula: 'revenue * fee_rate%',
            kind: CustomOutputKind.currency,
          ),
          CustomOutputDef(
            id: 'net_income',
            label: 'Net Take-Home Income',
            formula: circular
                ? 'platform_fees + net_income'
                : 'revenue - platform_fees - expenses',
            isPrimary: true,
            kind: CustomOutputKind.currency,
          ),
        ],
        createdAt: 1720000000,
        updatedAt: 1720000000,
      );
    }

    test('Valid definition passes validation without errors', () {
      final def = createSampleFreelanceCalc();
      final errors = def.validate();
      expect(errors, isEmpty);
    });

    test('Catches missing name and duplicate variable IDs', () {
      const invalid = CustomCalcDefinition(
        id: 'invalid',
        name: '   ',
        createdAt: 0,
        updatedAt: 0,
        inputs: [
          CustomInputDef(
            id: 'rev',
            label: 'Revenue 1',
            type: CustomInputType.number,
          ),
          CustomInputDef(
            id: 'rev',
            label: 'Revenue 2',
            type: CustomInputType.number,
          ),
        ],
        outputs: [
          CustomOutputDef(
            id: 'rev', // Clashes with input ID
            label: 'Total',
            formula: 'rev + 10',
          ),
        ],
      );

      final errors = invalid.validate();
      expect(errors, anyElement(contains('name cannot be empty')));
      expect(errors, anyElement(contains('Duplicate input variable ID')));
      expect(errors, anyElement(contains('clashes with an input variable ID')));
    });

    test('Catches circular dependency in outputs', () {
      final circular = createSampleFreelanceCalc(circular: true);
      final errors = circular.validate();
      expect(errors, anyElement(contains('Circular formula dependency')));
    });

    test('JSON serialization roundtrip preserves all fields', () {
      final original = createSampleFreelanceCalc();
      final json = original.toJson();
      final restored = CustomCalcDefinition.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.category, original.category);
      expect(restored.inputs.length, original.inputs.length);
      expect(restored.outputs.length, original.outputs.length);
      expect(restored.primaryOutput?.id, 'net_income');
    });
  });

  group('CustomCalcRepository Tests', () {
    late CustomCalcRepository repo;

    setUp(() {
      repo = CustomCalcRepository.inMemory();
    });

    test('Save, retrieve by ID, and list all calculators', () async {
      const def = CustomCalcDefinition(
        id: 'calc_1',
        name: 'Savings Planner',
        createdAt: 100,
        updatedAt: 100,
        inputs: [
          CustomInputDef(
            id: 'target',
            label: 'Target',
            type: CustomInputType.number,
          )
        ],
        outputs: [
          CustomOutputDef(
            id: 'out',
            label: 'Result',
            formula: 'target * 2',
          )
        ],
      );

      await repo.save(def);

      final list = await repo.all();
      expect(list.length, 1);
      expect(list.first.id, 'calc_1');

      final item = await repo.getById('calc_1');
      expect(item, isNotNull);
      expect(item!.name, 'Savings Planner');
    });

    test('Draft recovery and separation from published calculators', () async {
      const draft = CustomCalcDefinition(
        id: 'draft_1',
        name: 'Unfinished Calculator',
        isDraft: true,
        createdAt: 200,
        updatedAt: 200,
      );

      await repo.save(draft);

      // Default all(includeDrafts: false) excludes drafts
      final published = await repo.all(includeDrafts: false);
      expect(published, isEmpty);

      final all = await repo.all(includeDrafts: true);
      expect(all.length, 1);

      final latestDraft = await repo.getLatestDraft();
      expect(latestDraft, isNotNull);
      expect(latestDraft!.id, 'draft_1');
    });

    test('Duplicate and Delete operations', () async {
      const def = CustomCalcDefinition(
        id: 'original',
        name: 'Original Calculator',
        createdAt: 100,
        updatedAt: 100,
        inputs: [
          CustomInputDef(
            id: 'x',
            label: 'X',
            type: CustomInputType.number,
          )
        ],
        outputs: [
          CustomOutputDef(
            id: 'res',
            label: 'Result',
            formula: 'x * 5',
          )
        ],
      );

      await repo.save(def);

      final copy = await repo.duplicate('original');
      expect(copy.id, isNot('original'));
      expect(copy.name, 'Original Calculator (Copy)');

      final listAfterDuplication = await repo.all();
      expect(listAfterDuplication.length, 2);

      await repo.delete('original');
      final listAfterDelete = await repo.all();
      expect(listAfterDelete.length, 1);
      expect(listAfterDelete.first.id, copy.id);
    });

    test('Export to JSON and Import from JSON with validation', () async {
      const def = CustomCalcDefinition(
        id: 'exportable',
        name: 'Exportable Test',
        createdAt: 100,
        updatedAt: 100,
        inputs: [
          CustomInputDef(
            id: 'cost',
            label: 'Cost',
            type: CustomInputType.currency,
          )
        ],
        outputs: [
          CustomOutputDef(
            id: 'margin',
            label: 'Margin',
            formula: 'cost * 1.5',
            isPrimary: true,
          )
        ],
      );

      final exportedJson = repo.exportToJson(def);
      expect(exportedJson, contains('finwise_calculator_export_version'));
      expect(exportedJson, contains('Exportable Test'));

      final imported = repo.importFromJson(exportedJson);
      expect(imported.name, 'Exportable Test (Imported)');
      expect(imported.inputs.first.id, 'cost');
      expect(imported.outputs.first.formula, 'cost * 1.5');
    });
  });
}
