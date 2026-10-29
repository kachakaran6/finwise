import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finwise/app/app.dart';
import 'package:finwise/app/providers.dart';
import 'package:finwise/app/theme/theme.dart';
import 'package:finwise/data/backup.dart';
import 'package:finwise/data/storage.dart';
import 'package:finwise/domain/models/calc.dart';
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

  group('M1 Challenger Suite 1: HomePage Viewport & Text Scale Stress', () {
    final viewports = <String, Size>{
      'UltraNarrow_320x480': const Size(320, 480),
      'iPhoneSE1_320x568': const Size(320, 568),
      'SmallAndroid_360x640': const Size(360, 640),
      'iPhone8_375x667': const Size(375, 667),
      'iPhone14_390x844': const Size(390, 844),
      'Pixel8_412x915': const Size(412, 915),
      'iPhonePlus_428x926': const Size(428, 926),
      'SmallTablet_600x900': const Size(600, 900),
      'iPadPortrait_768x1024': const Size(768, 1024),
      'iPadLandscape_1024x768': const Size(1024, 768),
      'TabletLandscape_1280x800': const Size(1280, 800),
    };

    for (final entry in viewports.entries) {
      testWidgets('HomePage has 0 RenderFlex overflow on ${entry.key} at 1.0x scale', (tester) async {
        await tester.binding.setSurfaceSize(entry.value);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              prefsProvider.overrideWithValue(prefs),
              repoProvider.overrideWithValue(repo),
            ],
            child: const FinanceApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'RenderFlex overflow occurred on ${entry.key}');
        expect(find.text('Categories'), findsOneWidget);
        expect(find.text('Growth & Investing'), findsOneWidget);
        expect(find.text('Loans & Debt'), findsOneWidget);
        expect(find.text('Goals & Planning'), findsOneWidget);
        expect(find.text('Returns & Inflation'), findsOneWidget);
        expect(find.text('Utilities'), findsOneWidget);
        expect(find.text('All Calculators'), findsOneWidget);
      });
    }

    testWidgets('HomePage on 320px viewport with 1.2x font scale has 0 overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            repoProvider.overrideWithValue(repo),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.2),
            ),
            child: const FinanceApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('All Calculators'), findsOneWidget);
    });
  });

  group('M1 Challenger Suite 2: Scenario Snapshot Contract & ResultRow Stress', () {
    test('Standard ResultRow round-trip serialization preserves all types', () {
      final r1 = const ResultRow('Net Profit', 4500.50, kind: ValueKind.money);
      final json1 = r1.toJson();
      expect(json1, {'l': 'Net Profit', 'v': 4500.50, 'k': 'money', 't': null});
      final restored1 = ResultRow.fromJson(json1);
      expect(restored1.label, 'Net Profit');
      expect(restored1.value, 4500.50);
      expect(restored1.kind, ValueKind.money);
      expect(restored1.text, isNull);

      final r2 = const ResultRow('ROI %', 14.25, kind: ValueKind.percent);
      final restored2 = ResultRow.fromJson(r2.toJson());
      expect(restored2.kind, ValueKind.percent);
      expect(restored2.value, 14.25);

      final r3 = const ResultRow('Count', 12.0, kind: ValueKind.number);
      final restored3 = ResultRow.fromJson(r3.toJson());
      expect(restored3.kind, ValueKind.number);

      final r4 = const ResultRow.text('Status', 'APPROVED');
      final restored4 = ResultRow.fromJson(r4.toJson());
      expect(restored4.kind, ValueKind.text);
      expect(restored4.value, isNull);
      expect(restored4.text, 'APPROVED');
    });

    test('ResultRow.fromJson gracefully falls back on unknown kind or null values', () {
      final json = <String, dynamic>{
        'l': 'Unknown Metric',
        'v': null,
        'k': 'non_existent_kind',
        't': null,
      };
      final row = ResultRow.fromJson(json);
      expect(row.label, 'Unknown Metric');
      expect(row.value, isNull);
      expect(row.kind, ValueKind.number); // Fallback
    });

    test('Scenario primary and rows getters parse custom calculator snapshot without throwing', () {
      final snapshot = <String, dynamic>{
        'primary': {
          'l': 'Take Home Pay',
          'v': 7450.25,
          'k': 'money',
          't': null,
        },
        'rows': [
          {'l': 'Gross Income', 'v': 10000.0, 'k': 'money', 't': null},
          {'l': 'Effective Tax Rate', 'v': 25.5, 'k': 'percent', 't': null},
          {'l': 'Score / Ratio', 'v': 3.42, 'k': 'number', 't': null},
          {'l': 'Note', 'v': null, 'k': 'text', 't': 'Valid Estimate'},
        ],
      };

      final s = Scenario(
        id: 'sc_test_1',
        title: 'My Custom Plan',
        calcId: 'custom_salary_calc',
        inputs: {'gross': 10000, 'tax_pct': 25.5},
        snapshot: snapshot,
        createdAt: 1000000,
        updatedAt: 1000000,
        schemaVersion: 1,
      );

      expect(s.primary.label, 'Take Home Pay');
      expect(s.primary.value, 7450.25);
      expect(s.primary.kind, ValueKind.money);

      expect(s.rows.length, 4);
      expect(s.rows[0].label, 'Gross Income');
      expect(s.rows[1].kind, ValueKind.percent);
      expect(s.rows[2].kind, ValueKind.number);
      expect(s.rows[3].kind, ValueKind.text);
      expect(s.rows[3].text, 'Valid Estimate');

      // Test SQLite JSON round-trip
      final encodedSnap = jsonEncode(s.snapshot);
      final decodedSnap = Map<String, dynamic>.from(jsonDecode(encodedSnap) as Map);
      final s2 = s.copyWith(snapshot: decodedSnap);

      expect(s2.primary.label, s.primary.label);
      expect(s2.primary.value, s.primary.value);
      expect(s2.primary.kind, s.primary.kind);
      expect(s2.rows.length, s.rows.length);
      for (int i = 0; i < s.rows.length; i++) {
        expect(s2.rows[i].label, s.rows[i].label);
        expect(s2.rows[i].value, s.rows[i].value);
        expect(s2.rows[i].kind, s.rows[i].kind);
      }
    });

    test('Scenario with empty rows returns empty list without error', () {
      final s = Scenario(
        id: 'sc_test_empty_rows',
        title: 'Empty Rows',
        calcId: 'custom_minimal',
        inputs: {},
        snapshot: {
          'primary': {'l': 'Result', 'v': 0.0, 'k': 'number', 't': null},
          'rows': <Map<String, dynamic>>[],
        },
        createdAt: 100,
        updatedAt: 100,
        schemaVersion: 1,
      );

      expect(s.primary.label, 'Result');
      expect(s.primary.value, 0.0);
      expect(s.rows, isEmpty);
    });
  });

  group('M1 Challenger Suite 3: SavedPage Custom Scenarios Integration', () {
    testWidgets('SavedPage displays custom calculator scenario with valid custom def', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final customDef = CustomCalcDefinition(
        id: 'freelance_1',
        name: 'Freelance Invoicing',
        description: 'Calculates net invoice amount.',
        category: 'planning',
        inputs: const [
          CustomInputDef(id: 'rate', label: 'Hourly Rate', type: CustomInputType.currency, defaultValue: 80),
          CustomInputDef(id: 'hours', label: 'Billed Hours', type: CustomInputType.number, defaultValue: 40),
        ],
        outputs: const [
          CustomOutputDef(id: 'total', label: 'Total Billed', formula: 'rate * hours', kind: CustomOutputKind.currency, isPrimary: true),
        ],
      );

      await repo.customCalcRepo.save(customDef);

      final savedScenario = Scenario(
        id: 'sc_free_1',
        title: 'October Client Work',
        calcId: 'custom_freelance_1',
        inputs: {'rate': 85.0, 'hours': 42.0},
        snapshot: {
          'primary': {'l': 'Total Billed', 'v': 3570.0, 'k': 'money', 't': null},
          'rows': [
            {'l': 'Total Billed', 'v': 3570.0, 'k': 'money', 't': null},
          ],
        },
        createdAt: 1698500000000,
        updatedAt: 1698500000000,
        schemaVersion: 1,
      );

      await repo.upsert(savedScenario);

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

      expect(find.text('October Client Work'), findsOneWidget);
      expect(find.textContaining('Freelance Invoicing'), findsOneWidget);
      expect(find.textContaining('3,570.00'), findsOneWidget);

      // Tap card to open CustomCalculatorScreen
      await tester.tap(find.text('October Client Work'));
      await tester.pumpAndSettle();

      expect(find.byType(CustomCalculatorScreen), findsOneWidget);
      expect(find.text('Freelance Invoicing'), findsOneWidget);
    });

    testWidgets('SavedPage displays custom calculator scenario with MISSING def and handles tap gracefully', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Scenario whose definition does NOT exist in customCalcRepo
      final orphanScenario = Scenario(
        id: 'sc_orphan_1',
        title: 'Deleted Calculator Scenario',
        calcId: 'custom_deleted_tool_99',
        inputs: {'x': 100},
        snapshot: {
          'primary': {'l': 'Calculated Output', 'v': 999.0, 'k': 'number', 't': null},
          'rows': [
            {'l': 'Calculated Output', 'v': 999.0, 'k': 'number', 't': null},
          ],
        },
        createdAt: 1698500000000,
        updatedAt: 1698500000000,
        schemaVersion: 1,
      );

      await repo.upsert(orphanScenario);

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

      expect(find.text('Deleted Calculator Scenario'), findsOneWidget);
      expect(find.textContaining('Custom Calculator'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tapping orphan scenario should toast without throwing NullCheckException
      await tester.tap(find.text('Deleted Calculator Scenario'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Custom calculator definition not found.'), findsOneWidget);
    });

    testWidgets('SavedPage selection mode validates matching calcId for comparison', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final sc1 = Scenario(
        id: 'sc_c1',
        title: 'Custom Calc A',
        calcId: 'custom_tool_alpha',
        inputs: {'val': 10},
        snapshot: {
          'primary': {'l': 'Res', 'v': 10.0, 'k': 'number', 't': null},
          'rows': [],
        },
        createdAt: 100,
        updatedAt: 100,
        schemaVersion: 1,
      );

      final sc2 = Scenario(
        id: 'sc_c2',
        title: 'Custom Calc B (Different ID)',
        calcId: 'custom_tool_beta',
        inputs: {'val': 20},
        snapshot: {
          'primary': {'l': 'Res', 'v': 20.0, 'k': 'number', 't': null},
          'rows': [],
        },
        createdAt: 200,
        updatedAt: 200,
        schemaVersion: 1,
      );

      await repo.upsert(sc1);
      await repo.upsert(sc2);

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

      // Enter compare mode
      await tester.tap(find.byIcon(PhosphorIconsRegular.scales));
      await tester.pumpAndSettle();

      // Select first scenario
      await tester.tap(find.text('Custom Calc A'));
      await tester.pumpAndSettle();

      // Select second scenario (different calcId) -> should show toast warning
      await tester.tap(find.text('Custom Calc B (Different ID)'));
      await tester.pumpAndSettle();

      expect(find.text('Compare scenarios from the same calculator.'), findsOneWidget);
    });
  });

  group('M1 Challenger Suite 4: ComparePage Robustness & Edge Cases', () {
    testWidgets('ComparePage compares custom scenarios with valid custom definition', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final customDef = CustomCalcDefinition(
        id: 'investment_model',
        name: 'Investment Model',
        description: 'Simulates returns.',
        inputs: const [
          CustomInputDef(id: 'principal', label: 'Principal', type: CustomInputType.currency, defaultValue: 10000),
          CustomInputDef(id: 'rate', label: 'Rate %', type: CustomInputType.percentage, defaultValue: 7),
        ],
        outputs: const [
          CustomOutputDef(id: 'future_value', label: 'Future Value', formula: 'principal * (1 + rate / 100)', kind: CustomOutputKind.currency, isPrimary: true),
        ],
      );

      await repo.customCalcRepo.save(customDef);

      final a = Scenario(
        id: 'sc_inv_a',
        title: 'Plan A (Conservative)',
        calcId: 'custom_investment_model',
        inputs: {'principal': 10000.0, 'rate': 5.0},
        snapshot: {
          'primary': {'l': 'Future Value', 'v': 10500.0, 'k': 'money', 't': null},
          'rows': [
            {'l': 'Future Value', 'v': 10500.0, 'k': 'money', 't': null},
          ],
        },
        createdAt: 100,
        updatedAt: 100,
        schemaVersion: 1,
      );

      final b = Scenario(
        id: 'sc_inv_b',
        title: 'Plan B (Aggressive)',
        calcId: 'custom_investment_model',
        inputs: {'principal': 10000.0, 'rate': 10.0},
        snapshot: {
          'primary': {'l': 'Future Value', 'v': 11000.0, 'k': 'money', 't': null},
          'rows': [
            {'l': 'Future Value', 'v': 11000.0, 'k': 'money', 't': null},
          ],
        },
        createdAt: 200,
        updatedAt: 200,
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

      expect(find.text('Compare · Investment Model'), findsOneWidget);
      expect(find.text('Plan A (Conservative)'), findsOneWidget);
      expect(find.text('Plan B (Aggressive)'), findsOneWidget);
      expect(find.text('Rate %'), findsOneWidget);
      expect(find.text('5.00%'), findsOneWidget);
      expect(find.text('10.00%'), findsOneWidget);
      expect(find.text('Result metrics'), findsOneWidget);
      expect(find.text('Future Value'), findsWidgets);
    });

    testWidgets('ComparePage compares custom scenarios when custom def is MISSING without crashing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final a = Scenario(
        id: 'sc_lost_a',
        title: 'Orphan Scenario A',
        calcId: 'custom_unregistered_tool',
        inputs: {'input1': 150.0, 'input2': 25.0},
        snapshot: {
          'primary': {'l': 'Score', 'v': 175.0, 'k': 'number', 't': null},
          'rows': [
            {'l': 'Score', 'v': 175.0, 'k': 'number', 't': null},
          ],
        },
        createdAt: 100,
        updatedAt: 100,
        schemaVersion: 1,
      );

      final b = Scenario(
        id: 'sc_lost_b',
        title: 'Orphan Scenario B',
        calcId: 'custom_unregistered_tool',
        inputs: {'input1': 200.0, 'input2': 25.0},
        snapshot: {
          'primary': {'l': 'Score', 'v': 225.0, 'k': 'number', 't': null},
          'rows': [
            {'l': 'Score', 'v': 225.0, 'k': 'number', 't': null},
          ],
        },
        createdAt: 200,
        updatedAt: 200,
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

      expect(tester.takeException(), isNull);
      expect(find.text('Compare · Custom Calculator'), findsOneWidget);
      expect(find.text('input1'), findsOneWidget);
      expect(find.text('150.00'), findsOneWidget);
      expect(find.text('200.00'), findsOneWidget);
    });
  });

  group('M1 Challenger Suite 5: BackupService Custom Scenario Stress', () {
    test('Exports and restores custom calculator scenarios correctly', () async {
      final customScenario = Scenario(
        id: 'sc_backup_custom',
        title: 'Backup Custom Calc Test',
        calcId: 'custom_tax_tool',
        inputs: {'salary': 95000, 'bracket': '24%'},
        snapshot: {
          'primary': {'l': 'Tax Owed', 'v': 18500.0, 'k': 'money', 't': null},
          'rows': [
            {'l': 'Tax Owed', 'v': 18500.0, 'k': 'money', 't': null},
          ],
        },
        createdAt: 1698500000000,
        updatedAt: 1698500000000,
        schemaVersion: 1,
      );

      final builtInScenario = Scenario(
        id: 'sc_backup_builtin',
        title: 'Backup Builtin Test',
        calcId: 'compound',
        inputs: {'p': 10000, 'r': 8, 't': 5},
        snapshot: {
          'primary': {'l': 'Future Value', 'v': 14693.28, 'k': 'money', 't': null},
          'rows': [
            {'l': 'Future Value', 'v': 14693.28, 'k': 'money', 't': null},
          ],
        },
        createdAt: 1698500000000,
        updatedAt: 1698500000000,
        schemaVersion: 1,
      );

      final exportBytes = await BackupService.export([customScenario, builtInScenario]);
      expect(exportBytes, isNotEmpty);

      final preview = await BackupService.parse(exportBytes);
      expect(preview.skipped, 0);
      expect(preview.scenarios.length, 2);

      final restoredCustom = preview.scenarios.firstWhere((s) => s.id == 'sc_backup_custom');
      expect(restoredCustom.calcId, 'custom_tax_tool');
      expect(restoredCustom.inputs['salary'], 95000);
      expect(restoredCustom.primary.label, 'Tax Owed');
      expect(restoredCustom.primary.value, 18500.0);
    });

    test('Encrypted backup preserves custom calculator scenarios', () async {
      final customScenario = Scenario(
        id: 'sc_enc_custom',
        title: 'Encrypted Custom Calc',
        calcId: 'custom_secret_formula',
        inputs: {'secret_multiplier': 42},
        snapshot: {
          'primary': {'l': 'Secret Result', 'v': 420.0, 'k': 'number', 't': null},
          'rows': [],
        },
        createdAt: 1698500000000,
        updatedAt: 1698500000000,
        schemaVersion: 1,
      );

      const pass = 'SuperStrongPassphrase123!';
      final encBytes = await BackupService.export([customScenario], passphrase: pass);
      expect(BackupService.isEncrypted(encBytes), isTrue);

      final preview = await BackupService.parse(encBytes, passphrase: pass);
      expect(preview.scenarios.length, 1);
      expect(preview.scenarios.first.calcId, 'custom_secret_formula');

      // Wrong passphrase throws BackupException
      expect(
        () => BackupService.parse(encBytes, passphrase: 'WrongPassword'),
        throwsA(isA<BackupException>()),
      );
    });

    test('Corrupted or invalid records are safely skipped during restore', () async {
      final rawBackup = {
        'format': BackupService.plainFormat,
        'version': BackupService.version,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'scenarios': [
          // 1. Valid custom scenario
          {
            'id': 'valid_1',
            'title': 'Valid Custom',
            'calcId': 'custom_valid_tool',
            'inputs': {'a': 1},
            'snapshot': {'primary': {'l': 'R', 'v': 1.0, 'k': 'number', 't': null}, 'rows': []},
            'schemaVersion': 1,
            'createdAt': 100,
            'updatedAt': 100,
          },
          // 2. Corrupted calcId (unrecognized built-in, does NOT start with custom_)
          {
            'id': 'corrupt_calc_id',
            'title': 'Corrupt Calc ID',
            'calcId': 'unknown_calculator_xyz',
            'inputs': {'a': 1},
            'snapshot': {'primary': {'l': 'R', 'v': 1.0, 'k': 'number', 't': null}, 'rows': []},
            'schemaVersion': 1,
            'createdAt': 100,
            'updatedAt': 100,
          },
          // 3. Corrupted input types (nested object instead of num/String)
          {
            'id': 'corrupt_inputs',
            'title': 'Corrupt Inputs',
            'calcId': 'custom_valid_tool',
            'inputs': {'nested': {'bad': 'object'}},
            'snapshot': {'primary': {'l': 'R', 'v': 1.0, 'k': 'number', 't': null}, 'rows': []},
            'schemaVersion': 1,
            'createdAt': 100,
            'updatedAt': 100,
          },
          // 4. Missing snapshot (null snapshot)
          {
            'id': 'null_snap',
            'title': 'Null Snapshot',
            'calcId': 'custom_valid_tool',
            'inputs': {'a': 1},
            'snapshot': null,
            'schemaVersion': 1,
            'createdAt': 100,
            'updatedAt': 100,
          },
        ],
      };

      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(rawBackup)));
      final preview = await BackupService.parse(bytes);

      expect(preview.scenarios.length, 1);
      expect(preview.scenarios.first.id, 'valid_1');
      expect(preview.skipped, 3);
    });
  });
}
