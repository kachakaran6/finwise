import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:finwise/core/validation.dart';
import 'package:finwise/data/backup.dart';
import 'package:finwise/domain/calculations/finance.dart';
import 'package:finwise/domain/calculators/catalog.dart';
import 'package:finwise/domain/models/calc.dart';

void main() {
  group('core formulas', () {
    test('C01 compound interest', () {
      expect(compoundValue(10000, 10, 1, 1), closeTo(11000, 1e-9));
      expect(compoundValue(10000, 0, 5, 12), 10000);
    });
    test('C02 simple interest', () {
      expect(simpleInterest(1000, 5, 2), closeTo(100, 1e-9));
    });
    test('C03 SIP ordinary annuity and annuity due', () {
      expect(annuityFv(1000, 0.01, 12), closeTo(12682.50, 0.01));
      expect(annuityFv(1000, 0.01, 12, begin: true), closeTo(12809.33, 0.01));
      expect(annuityFv(1000, 0, 12), 12000);
    });
    test('SIP closed form equals simulation', () {
      for (final begin in [false, true]) {
        final pr = project(n: 120, i: 0.008, contribution: (_) => 250, perYear: 12, begin: begin);
        expect(pr.balance.last, closeTo(annuityFv(250, 0.008, 120, begin: begin), 1e-6));
      }
    });
    test('C04 step-up with 0% equals SIP', () {
      final def = calcById('stepup')!;
      final sip = calcById('sip')!;
      final common = {'contribution': 500.0, 'rate': 10.0, 'conv': 'nominal', 'freq': '12', 'years': 10.0, 'timing': 'end'};
      final a = def.compute(CalcInputs({...common, 'stepup': 0.0}));
      final b = sip.compute(CalcInputs(common));
      expect(a.primary.value, closeTo(b.primary.value!, 1e-6));
    });
    test('C05 goal contribution round-trips with SIP', () {
      const i = 0.005;
      const n = 96;
      final c = goalContribution(100000, i, n);
      expect(annuityFv(c, i, n), closeTo(100000, 1e-6));
      final cb = goalContribution(100000, i, n, begin: true);
      expect(annuityFv(cb, i, n, begin: true), closeTo(100000, 1e-6));
      expect(goalContribution(1200, 0, 12), 100);
    });
    test('C06 present value', () {
      expect(presentValue(110, 0.1, 1), closeTo(100, 1e-9));
      expect(presentValue(500, 0, 7), 500);
    });
    test('C07 CAGR', () {
      expect(cagr(100, 200, 5), closeTo(0.148698, 1e-6));
      expect(cagr(100, 0, 3), closeTo(-1, 1e-12));
      expect(() => cagr(0, 10, 3), throwsA(isA<CalcException>()));
      expect(() => cagr(10, 10, 0), throwsA(isA<CalcException>()));
    });
    test('C10 EMI', () {
      expect(emi(100000, 0.01, 12), closeTo(8884.88, 0.01));
      expect(emi(1200, 0, 12), 100);
    });
    test('C11 amortization clears to zero and principal sums to loan', () {
      final rows = amortize(250000, 0.085 / 12, 240);
      expect(rows.last.closing, 0);
      final repaid = rows.fold<double>(0, (a, r) => a + r.principal);
      expect(repaid, closeTo(250000, 0.005));
      for (final r in rows) {
        expect(r.interest, greaterThanOrEqualTo(0));
      }
    });
    test('periodic rate conventions', () {
      expect(periodicRate(12, 12), closeTo(0.01, 1e-12));
      expect(pw(1 + periodicRate(12, 12, effective: true), 12), closeTo(1.12, 1e-9));
    });
  });

  group('calculators', () {
    test('every calculator computes with its default inputs', () {
      for (final def in catalog) {
        final raw = <String, String>{};
        final choices = <String, String>{};
        for (final f in def.fields) {
          if (f.kind == FieldKind.choice) {
            choices[f.id] = f.defaultValue as String;
          } else {
            raw[f.id] = '${f.defaultValue}';
          }
        }
        final st = validateInputs(def, raw, choices);
        expect(st.valid, isTrue, reason: '${def.id}: ${st.errors}');
        final res = def.compute(CalcInputs(st.values));
        expect(res.primary.value!.isFinite, isTrue, reason: def.id);
      }
    });
    test('validation never replaces invalid input with zero', () {
      final def = calcById('compound')!;
      final st = validateInputs(def, {'principal': '', 'rate': 'abc', 'years': '-3'}, {'m': '12'});
      expect(st.errors.keys, containsAll(['principal', 'rate', 'years']));
    });
    test('percent change keeps zero denominator explicit', () {
      final def = calcById('percent')!;
      expect(() => def.compute(CalcInputs({'mode': 'change', 'oldV': 0.0, 'newV': 5.0})), throwsA(isA<CalcException>()));
    });
  });

  group('Compound Interest 20-Point Financial Validation Framework', () {
    final comp = calcById('compound')!;

    CalcResult runComp({
      double principal = 10000,
      double rate = 8,
      double duration = 10,
      String unit = 'years',
      String m = '12',
    }) {
      return comp.compute(CalcInputs({
        'principal': principal,
        'rate': rate,
        'years': duration,
        'unit': unit,
        'm': m,
      }));
    }

    test('1. Principal ₹10,000, 8%, 10 years, monthly compounding produces ~₹22,196.40', () {
      final res = runComp(principal: 10000, rate: 8, duration: 10, unit: 'years', m: '12');
      expect(res.primary.value, closeTo(22196.40, 0.01));
      expect(res.rows[1].value, closeTo(12196.40, 0.01)); // interest
    });

    test('2. Same inputs with annual compounding produces ~₹21,589.25', () {
      final res = runComp(principal: 10000, rate: 8, duration: 10, unit: 'years', m: '1');
      expect(res.primary.value, closeTo(21589.25, 0.01));
    });

    test('3. Same inputs with daily compounding produces ~₹22,253.46', () {
      final res = runComp(principal: 10000, rate: 8, duration: 10, unit: 'years', m: '365');
      expect(res.primary.value, closeTo(22253.46, 0.01));
    });

    test('4. Duration of 30 days (8%, daily compounding) produces ~₹10,065.96', () {
      final res = runComp(principal: 10000, rate: 8, duration: 30, unit: 'days', m: '365');
      expect(res.primary.value, closeTo(10065.96, 0.01));
      expect(res.rows[1].value, closeTo(65.96, 0.01));
    });

    test('5. Duration of 90 days (8%, daily compounding) produces ~₹10,199.20', () {
      final res = runComp(principal: 10000, rate: 8, duration: 90, unit: 'days', m: '365');
      expect(res.primary.value, closeTo(10199.20, 0.01));
      expect(res.rows[1].value, closeTo(199.20, 0.01));
    });

    test('6. Duration of 180 days (8%, daily compounding) produces ~₹10,402.36', () {
      final res = runComp(principal: 10000, rate: 8, duration: 180, unit: 'days', m: '365');
      expect(res.primary.value, closeTo(10402.36, 0.01));
      expect(res.rows[1].value, closeTo(402.36, 0.01));
    });

    test('7. Duration of 365 days (8%, daily compounding) produces ~₹10,832.78', () {
      final res = runComp(principal: 10000, rate: 8, duration: 365, unit: 'days', m: '365');
      expect(res.primary.value, closeTo(10832.78, 0.01));
      expect(res.rows[1].value, closeTo(832.78, 0.01));
    });

    test('8. Duration of zero leaves principal unchanged', () {
      final res = runComp(principal: 10000, rate: 8, duration: 0, unit: 'years', m: '12');
      expect(res.primary.value, 10000);
      expect(res.rows[1].value, 0);
    });

    test('9. Principal of zero produces zero final value and zero interest', () {
      final res = runComp(principal: 0, rate: 8, duration: 5, unit: 'years', m: '12');
      expect(res.primary.value, 0);
      expect(res.rows[1].value, 0);
    });

    test('10. Interest rate of zero leaves principal unchanged and EAR is 0%', () {
      final res = runComp(principal: 10000, rate: 0, duration: 10, unit: 'years', m: '12');
      expect(res.primary.value, 10000);
      expect(res.rows[1].value, 0);
      expect(res.rows[2].value, 0); // EAR = 0%
    });

    test('11. Very small positive interest rate (0.01%) calculates accurately', () {
      final res = runComp(principal: 10000, rate: 0.01, duration: 1, unit: 'years', m: '1');
      expect(res.primary.value, closeTo(10001.00, 0.01));
      expect(res.rows[1].value, closeTo(1.00, 0.01));
    });

    test('12. Large but valid principal (₹100,000,000) does not overflow', () {
      final res = runComp(principal: 100000000, rate: 8, duration: 10, unit: 'years', m: '12');
      expect(res.primary.value!.isFinite, isTrue);
      expect(res.primary.value, closeTo(221964023.45, 1.0));
    });

    test('13. Invalid negative principal is rejected by validation', () {
      final st = validateInputs(comp, {'principal': '-5000', 'rate': '8', 'years': '5'}, {'unit': 'years', 'm': '12'});
      expect(st.valid, isFalse);
      expect(st.errors.containsKey('principal'), isTrue);
    });

    test('14. Invalid negative duration is rejected by validation', () {
      final st = validateInputs(comp, {'principal': '10000', 'rate': '8', 'years': '-2'}, {'unit': 'years', 'm': '12'});
      expect(st.valid, isFalse);
      expect(st.errors.containsKey('years'), isTrue);
    });

    test('15. Invalid negative interest rate is rejected by validation', () {
      final st = validateInputs(comp, {'principal': '10000', 'rate': '-5', 'years': '5'}, {'unit': 'years', 'm': '12'});
      expect(st.valid, isFalse);
      expect(st.errors.containsKey('rate'), isTrue);
    });

    test('16. Extremely large duration (100 years) remains finite and stable', () {
      final res = runComp(principal: 10000, rate: 8, duration: 100, unit: 'years', m: '12');
      expect(res.primary.value!.isFinite, isTrue);
      expect(res.primary.value, greaterThan(10000));
    });

    test('17. Compounding frequency monotonicity holds across all supported frequencies', () {
      final m1 = runComp(m: '1').primary.value!;
      final m2 = runComp(m: '2').primary.value!;
      final m4 = runComp(m: '4').primary.value!;
      final m12 = runComp(m: '12').primary.value!;
      final m365 = runComp(m: '365').primary.value!;

      expect(m1 < m2, isTrue, reason: 'Annually < Semi-annually');
      expect(m2 < m4, isTrue, reason: 'Semi-annually < Quarterly');
      expect(m4 < m12, isTrue, reason: 'Quarterly < Monthly');
      expect(m12 < m365, isTrue, reason: 'Monthly < Daily');
    });

    test('18. Day-to-year conversion consistency under 365-day convention', () {
      final oneYearInDays = runComp(principal: 10000, rate: 8, duration: 365, unit: 'days', m: '1').primary.value!;
      final oneYearDirect = runComp(principal: 10000, rate: 8, duration: 1, unit: 'years', m: '1').primary.value!;
      expect(oneYearInDays, closeTo(oneYearDirect, 1e-9));
    });

    test('19. Legacy saved calculation without unit key restores and computes correctly', () {
      // Legacy scenarios saved with only principal, rate, years, m
      final legacy = comp.compute(CalcInputs({
        'principal': 10000.0,
        'rate': 8.0,
        'years': 10.0,
        'm': '12',
      }));
      expect(legacy.primary.value, closeTo(22196.40, 0.01));
    });

    test('20. Complete consistency between summary, chart, and schedule', () {
      for (final u in ['days', 'months', 'years']) {
        final res = runComp(principal: 10000, rate: 8, duration: u == 'days' ? 90 : 5, unit: u, m: '365');
        final sched = res.schedule!;
        final chart = res.chart!;

        // Primary value equals last row closing balance
        expect(res.primary.value, closeTo(sched.rows.last[3], 1e-6));

        // Initial principal equals first row opening balance
        expect(sched.rows.first[1], closeTo(10000, 1e-6));

        // Sum of periodic interest equals estimated interest in summary
        final sumInterest = sched.rows.fold<double>(0, (sum, r) => sum + r[2]);
        expect(res.rows[1].value, closeTo(sumInterest, 1e-6));

        // Chart final point equals final closing balance
        expect(chart.series[1].ys.last, closeTo(res.primary.value!, 1e-6));
      }
    });
  });

  group('backup', () {
    final scenario = Scenario(
      id: 'abc123',
      title: 'My SIP',
      calcId: 'sip',
      inputs: {'contribution': 500.0, 'rate': 10.0, 'conv': 'nominal', 'freq': '12', 'years': 10.0, 'timing': 'end'},
      snapshot: {'primary': const ResultRow('Projected value', 1.0).toJson(), 'rows': []},
      createdAt: 1,
      updatedAt: 2,
    );
    test('plain round trip', () async {
      final bytes = await BackupService.export([scenario]);
      final prev = await BackupService.parse(bytes);
      expect(prev.scenarios.single.title, 'My SIP');
      expect(prev.skipped, 0);
    });
    test('encrypted round trip and wrong passphrase', () async {
      final bytes = await BackupService.export([scenario], passphrase: 'correct horse battery');
      expect(BackupService.isEncrypted(bytes), isTrue);
      expect(utf8.decode(bytes).contains('My SIP'), isFalse);
      final prev = await BackupService.parse(bytes, passphrase: 'correct horse battery');
      expect(prev.scenarios.length, 1);
      expect(() => BackupService.parse(bytes, passphrase: 'wrong passphrase'), throwsA(isA<BackupException>()));
    });
    test('invalid records are skipped, junk is rejected', () async {
      final bad = utf8.encode(jsonEncode({'format': 'ofc-backup', 'version': 1, 'scenarios': [{'id': 1}]}));
      final prev = await BackupService.parse(Uint8List.fromList(bad));
      expect(prev.skipped, 1);
      expect(() => BackupService.parse(Uint8List.fromList(utf8.encode('not json'))), throwsA(isA<BackupException>()));
    });
  });
}
