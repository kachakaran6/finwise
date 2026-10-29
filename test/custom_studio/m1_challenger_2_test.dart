import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finwise/app/providers.dart';
import 'package:finwise/app/theme/theme.dart';
import 'package:finwise/core/format.dart';
import 'package:finwise/data/backup.dart';
import 'package:finwise/data/storage.dart';
import 'package:finwise/domain/calculators/catalog.dart';
import 'package:finwise/domain/models/calc.dart';
import 'package:finwise/features/calculator/calculator_screen.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_calc_definition.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_input_def.dart';
import 'package:finwise/features/custom_studio/domain/models/custom_output_def.dart';
import 'package:finwise/features/custom_studio/runtime/custom_calculator_screen.dart';
import 'package:finwise/features/saved/compare_page.dart';
import 'package:finwise/features/saved/saved_page.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ScenarioRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'theme': 'light',
      'currency': 'USD',
      'locale': 'en_US',
    });
    prefs = await SharedPreferences.getInstance();
    repo = ScenarioRepository.inMemory();
  });

  // =========================================================================
  // Focus Area 1: Backward Compatibility (C01–C14)
  // =========================================================================
  group('Focus 1: Backward Compatibility for Built-in Scenarios (C01–C14)', () {
    testWidgets('1.1 saved_page.dart correctly renders built-in scenarios across all 14 calculators', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testScenarios = <Scenario>[];
      for (final calc in catalog) {
        testScenarios.add(
          Scenario(
            id: 'sc_${calc.id}',
            title: 'Saved ${calc.name}',
            calcId: calc.id,
            inputs: {
              for (final f in calc.fields) f.id: f.defaultValue,
            },
            snapshot: {
              'primary': {'l': 'Primary Result', 'v': 1234.56, 'k': 'money', 't': null},
              'rows': [
                {'l': 'Primary Result', 'v': 1234.56, 'k': 'money', 't': null},
              ],
            },
            createdAt: 1000,
            updatedAt: 1000,
            schemaVersion: 1,
          ),
        );
      }

      for (final s in testScenarios) {
        await repo.upsert(s);
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            repoProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const Scaffold(body: SavedPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify every single built-in calculator scenario title and name is rendered
      for (final calc in catalog) {
        expect(find.text('Saved ${calc.name}'), findsOneWidget);
        expect(find.textContaining(calc.name), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.2 saved_page.dart opens built-in CalculatorScreen when a scenario card is tapped', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final s = Scenario(
        id: 'sc_compound_tap',
        title: 'Retirement Growth',
        calcId: 'compound',
        inputs: {'p': 50000.0, 'r': 7.5, 't': 20.0},
        snapshot: {
          'primary': {'l': 'Future Value', 'v': 212392.56, 'k': 'money', 't': null},
          'rows': [
            {'l': 'Future Value', 'v': 212392.56, 'k': 'money', 't': null},
          ],
        },
        createdAt: 1000,
        updatedAt: 1000,
        schemaVersion: 1,
      );
      await repo.upsert(s);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            repoProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const Scaffold(body: SavedPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retirement Growth'));
      await tester.pumpAndSettle();

      // Verified: Opens standard built-in CalculatorScreen with scenario values
      expect(find.byType(CalculatorScreen), findsOneWidget);
      expect(find.text('Compound Interest'), findsWidgets);
    });

    testWidgets('1.3 compare_page.dart compares built-in scenarios using def.fields and diff computation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final a = Scenario(
        id: 'sc_cmp_a',
        title: 'Plan Conservative',
        calcId: 'compound',
        inputs: {'p': 10000.0, 'r': 6.0, 't': 10.0, 'c': 'yearly'},
        snapshot: {
          'primary': {'l': 'Future Value', 'v': 17908.48, 'k': 'money', 't': null},
          'rows': [
            {'l': 'Future Value', 'v': 17908.48, 'k': 'money', 't': null},
            {'l': 'Total Interest', 'v': 7908.48, 'k': 'money', 't': null},
          ],
        },
        createdAt: 1000,
        updatedAt: 1000,
        schemaVersion: 1,
      );

      final b = Scenario(
        id: 'sc_cmp_b',
        title: 'Plan Aggressive',
        calcId: 'compound',
        inputs: {'p': 10000.0, 'r': 10.0, 't': 10.0, 'c': 'yearly'},
        snapshot: {
          'primary': {'l': 'Future Value', 'v': 25937.42, 'k': 'money', 't': null},
          'rows': [
            {'l': 'Future Value', 'v': 25937.42, 'k': 'money', 't': null},
            {'l': 'Total Interest', 'v': 15937.42, 'k': 'money', 't': null},
          ],
        },
        createdAt: 2000,
        updatedAt: 2000,
        schemaVersion: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            repoProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: ComparePage(a: a, b: b),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compare · Compound Interest'), findsOneWidget);
      expect(find.text('Plan Conservative'), findsOneWidget);
      expect(find.text('Plan Aggressive'), findsOneWidget);
      // Interest Rate field diff
      expect(find.text('Interest Rate'), findsOneWidget);
      expect(find.text('6.00%'), findsOneWidget);
      expect(find.text('10.00%'), findsOneWidget);
      // Result metrics
      expect(find.text('Result metrics'), findsOneWidget);
      expect(find.text('Future Value'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    test('1.4 backup.dart exports and restores all 14 built-in calculator scenarios without data loss', () async {
      final builtInScenarios = <Scenario>[];
      for (int i = 0; i < catalog.length; i++) {
        final calc = catalog[i];
        builtInScenarios.add(
          Scenario(
            id: 'backup_${calc.id}',
            title: '${calc.name} Snapshot',
            calcId: calc.id,
            inputs: {
              for (final f in calc.fields) f.id: f.defaultValue,
            },
            snapshot: {
              'primary': {'l': 'Main Metric', 'v': (i + 1) * 100.0, 'k': 'money', 't': null},
              'rows': [
                {'l': 'Main Metric', 'v': (i + 1) * 100.0, 'k': 'money', 't': null},
              ],
            },
            createdAt: 100000 + i,
            updatedAt: 100000 + i,
            schemaVersion: 1,
          ),
        );
      }

      // Plain backup round-trip
      final plainBytes = await BackupService.export(builtInScenarios);
      final plainPreview = await BackupService.parse(plainBytes);
      expect(plainPreview.skipped, 0);
      expect(plainPreview.scenarios.length, 14);

      // Encrypted backup round-trip
      const pass = 'FinwiseSuperSecretPass123';
      final encBytes = await BackupService.export(builtInScenarios, passphrase: pass);
      final encPreview = await BackupService.parse(encBytes, passphrase: pass);
      expect(encPreview.skipped, 0);
      expect(encPreview.scenarios.length, 14);

      for (int i = 0; i < catalog.length; i++) {
        final restored = encPreview.scenarios.firstWhere((s) => s.id == 'backup_${catalog[i].id}');
        expect(restored.calcId, catalog[i].id);
        expect(restored.primary.value, (i + 1) * 100.0);
      }
    });
  });

  // =========================================================================
  // Focus Area 2: Custom Scenario Format Compatibility
  // =========================================================================
  group('Focus 2: Custom Scenario Format Compatibility & Persistence', () {
    final customCalc = CustomCalcDefinition(
      id: 'tax_bracket_studio',
      name: 'Custom Tax Studio',
      description: 'Calculates tax brackets and net after tax',
      category: 'planning',
      inputs: const [
        CustomInputDef(
          id: 'gross',
          label: 'Gross Salary',
          type: CustomInputType.currency,
          defaultValue: 100000,
        ),
        CustomInputDef(
          id: 'deductions',
          label: 'Standard Deductions',
          type: CustomInputType.currency,
          defaultValue: 12500,
        ),
        CustomInputDef(
          id: 'rate_pct',
          label: 'Tax Bracket %',
          type: CustomInputType.percentage,
          defaultValue: 22,
        ),
      ],
      outputs: const [
        CustomOutputDef(
          id: 'taxable_income',
          label: 'Taxable Income',
          formula: 'max(0, gross - deductions)',
          kind: CustomOutputKind.currency,
        ),
        CustomOutputDef(
          id: 'tax_owed',
          label: 'Tax Owed',
          formula: 'taxable_income * (rate_pct / 100)',
          kind: CustomOutputKind.currency,
        ),
        CustomOutputDef(
          id: 'net_income',
          label: 'Net Take Home',
          formula: 'gross - tax_owed',
          kind: CustomOutputKind.currency,
          isPrimary: true,
        ),
      ],
    );

    testWidgets('2.1 Scenario saving from CustomCalculatorScreen writes exact contract keys to scenarios table', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await repo.customCalcRepo.save(customCalc);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            repoProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: CustomCalculatorScreen(definition: customCalc),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Save button in app bar
      await tester.tap(find.byIcon(PhosphorIconsRegular.bookmarkSimple));
      await tester.pumpAndSettle();

      // Expect askText dialog to appear
      expect(find.text('Save scenario'), findsOneWidget);
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'FY2026 Tax Estimate');
      await tester.pumpAndSettle();

      // Tap Save in dialog
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify scenario was persisted to repository
      final allScenarios = await repo.all();
      expect(allScenarios.length, 1);

      final saved = allScenarios.first;
      expect(saved.title, 'FY2026 Tax Estimate');
      expect(saved.calcId, 'custom_tax_bracket_studio');
      expect(saved.inputs['gross'], 100000.0);
      expect(saved.inputs['deductions'], 12500.0);
      expect(saved.inputs['rate_pct'], 22.0);

      // Verify snapshot structure matches contract
      final snap = saved.snapshot;
      expect(snap.containsKey('primary'), isTrue);
      expect(snap.containsKey('rows'), isTrue);

      final primMap = snap['primary'] as Map;
      expect(primMap['l'], 'Net Take Home');
      // taxable = 87500, tax_owed = 87500 * 0.22 = 19250, net = 100000 - 19250 = 80750
      expect(primMap['v'], 80750.0);
      expect(primMap['k'], 'money');
      expect(primMap['t'], isNull);

      final rowsList = snap['rows'] as List;
      expect(rowsList.length, 3);
      for (final r in rowsList) {
        final rMap = r as Map;
        expect(rMap.containsKey('l'), isTrue);
        expect(rMap.containsKey('v'), isTrue);
        expect(rMap.containsKey('k'), isTrue);
        expect(rMap.containsKey('t'), isTrue);
      }
    });

    test('2.2 ScenarioRepository deserialization of custom scenario validates ResultRow and fmt.value', () async {
      final snap = <String, dynamic>{
        'primary': {
          'l': 'Net Return',
          'v': 45250.75,
          'k': 'money',
          't': null,
        },
        'rows': [
          {'l': 'Gross Gain', 'v': 50000.0, 'k': 'money', 't': null},
          {'l': 'Expense Fee %', 'v': 1.25, 'k': 'percent', 't': null},
          {'l': 'Net Return', 'v': 45250.75, 'k': 'money', 't': null},
        ],
      };

      final customScenario = Scenario(
        id: 'sc_custom_deser_1',
        title: 'Investment Yield Snapshot',
        calcId: 'custom_yield_calc',
        inputs: {'principal': 250000, 'duration': 5},
        snapshot: snap,
        createdAt: 1000,
        updatedAt: 1000,
        schemaVersion: 1,
      );

      await repo.upsert(customScenario);

      // Deserialization via get() and all()
      final fetched = await repo.get('sc_custom_deser_1');
      expect(fetched, isNotNull);

      // Validate primary getter
      final prim = fetched!.primary;
      expect(prim.label, 'Net Return');
      expect(prim.value, 45250.75);
      expect(prim.kind, ValueKind.money);

      // Validate rows getter
      final rows = fetched.rows;
      expect(rows.length, 3);
      expect(rows[0].kind, ValueKind.money);
      expect(rows[1].kind, ValueKind.percent);
      expect(rows[2].kind, ValueKind.money);

      // Validate fmt.value formatting on custom scenario
      final fmt = Fmt(currencyByCode('USD'), 'en_US');
      expect(fmt.value(prim), r'$45,250.75');
      expect(fmt.value(rows[1]), '1.25%');
    });
  });

  // =========================================================================
  // Focus Area 3: Edge Cases Stress-Testing
  // =========================================================================
  group('Focus 3: Edge Cases Stress-Testing', () {
    testWidgets('3.1 Edge Case: calcId starting with custom_ but empty ID ("custom_")', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final emptyIdScenario = Scenario(
        id: 'sc_empty_custom_id',
        title: 'Empty Custom ID Scenario',
        calcId: 'custom_', // calcId starts with custom_ but has empty ID
        inputs: {'arg1': 42.0},
        snapshot: {
          'primary': {'l': 'Edge Result', 'v': 42.0, 'k': 'number', 't': null},
          'rows': [
            {'l': 'Edge Result', 'v': 42.0, 'k': 'number', 't': null},
          ],
        },
        createdAt: 1000,
        updatedAt: 1000,
        schemaVersion: 1,
      );

      await repo.upsert(emptyIdScenario);

      // 1. Verify in saved_page.dart
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            repoProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const Scaffold(body: SavedPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Empty Custom ID Scenario'), findsOneWidget);
      expect(find.textContaining('Custom Calculator'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tap card: should show graceful toast and not crash
      await tester.tap(find.text('Empty Custom ID Scenario'));
      await tester.pumpAndSettle();
      expect(find.text('Custom calculator definition not found.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. Verify in compare_page.dart with another custom_ scenario
      final emptyIdScenario2 = Scenario(
        id: 'sc_empty_custom_id_2',
        title: 'Empty Custom ID Scenario B',
        calcId: 'custom_',
        inputs: {'arg1': 84.0},
        snapshot: {
          'primary': {'l': 'Edge Result', 'v': 84.0, 'k': 'number', 't': null},
          'rows': [
            {'l': 'Edge Result', 'v': 84.0, 'k': 'number', 't': null},
          ],
        },
        createdAt: 2000,
        updatedAt: 2000,
        schemaVersion: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            repoProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: ComparePage(a: emptyIdScenario, b: emptyIdScenario2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compare · Custom Calculator'), findsOneWidget);
      expect(find.text('arg1'), findsOneWidget);
      expect(find.text('42.00'), findsOneWidget); // Fmt.number(42.0)
      expect(find.text('84.00'), findsOneWidget); // Fmt.number(84.0)
      expect(tester.takeException(), isNull);

      // 3. Verify in backup.dart
      final exportBytes = await BackupService.export([emptyIdScenario]);
      final preview = await BackupService.parse(exportBytes);
      expect(preview.skipped, 0);
      expect(preview.scenarios.length, 1);
      expect(preview.scenarios.first.calcId, 'custom_');
    });

    testWidgets('3.2 Edge Case: Custom scenario with null primary output value', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final nullPrimaryScenario = Scenario(
        id: 'sc_null_primary',
        title: 'Uncomputed / Indeterminate Scenario',
        calcId: 'custom_calc_indeterminate',
        inputs: {'input_x': 0},
        snapshot: {
          'primary': {'l': 'Indeterminate', 'v': null, 'k': 'number', 't': 'Undefined'},
          'rows': [
            {'l': 'Indeterminate', 'v': null, 'k': 'number', 't': 'Undefined'},
          ],
        },
        createdAt: 1000,
        updatedAt: 1000,
        schemaVersion: 1,
      );

      await repo.upsert(nullPrimaryScenario);

      // 1. Verify in saved_page.dart
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            repoProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const Scaffold(body: SavedPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Uncomputed / Indeterminate Scenario'), findsOneWidget);
      expect(find.text('Undefined'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. Verify in compare_page.dart
      final nullPrimaryScenario2 = Scenario(
        id: 'sc_null_primary_2',
        title: 'Uncomputed Scenario 2',
        calcId: 'custom_calc_indeterminate',
        inputs: {'input_x': 5},
        snapshot: {
          'primary': {'l': 'Indeterminate', 'v': null, 'k': 'number', 't': 'Undefined'},
          'rows': [
            {'l': 'Indeterminate', 'v': null, 'k': 'number', 't': 'Undefined'},
          ],
        },
        createdAt: 2000,
        updatedAt: 2000,
        schemaVersion: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            repoProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: ComparePage(a: nullPrimaryScenario, b: nullPrimaryScenario2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compare · Custom Calculator'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3.3 Edge Case: Custom scenario with zero rows (empty rows list)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final zeroRowsScenarioA = Scenario(
        id: 'sc_zero_rows_a',
        title: 'Zero Rows Scenario A',
        calcId: 'custom_simple_output',
        inputs: {'amount': 1000.0},
        snapshot: {
          'primary': {'l': 'Sole Output', 'v': 1000.0, 'k': 'money', 't': null},
          'rows': <Map<String, dynamic>>[],
        },
        createdAt: 1000,
        updatedAt: 1000,
        schemaVersion: 1,
      );

      final zeroRowsScenarioB = Scenario(
        id: 'sc_zero_rows_b',
        title: 'Zero Rows Scenario B',
        calcId: 'custom_simple_output',
        inputs: {'amount': 2500.0},
        snapshot: {
          'primary': {'l': 'Sole Output', 'v': 2500.0, 'k': 'money', 't': null},
          'rows': <Map<String, dynamic>>[],
        },
        createdAt: 2000,
        updatedAt: 2000,
        schemaVersion: 1,
      );

      await repo.upsert(zeroRowsScenarioA);
      await repo.upsert(zeroRowsScenarioB);

      // Verify in saved_page.dart
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            repoProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const Scaffold(body: SavedPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zero Rows Scenario A'), findsOneWidget);
      expect(find.text('Zero Rows Scenario B'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Verify in compare_page.dart
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            repoProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: ComparePage(a: zeroRowsScenarioA, b: zeroRowsScenarioB),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compare · Custom Calculator'), findsOneWidget);
      expect(find.text('Sole Output'), findsWidgets);
      expect(find.text(r'$1,000.00'), findsOneWidget);
      expect(find.text(r'$2,500.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
