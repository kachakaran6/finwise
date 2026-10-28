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

  group('comprehensive financial formula audit (C02 - C14)', () {
    test('C02 Simple Interest: zero rate, zero time, boundary accuracy', () {
      final calc = calcById('simple')!;
      // Zero rate
      final r0 = calc.compute(CalcInputs({'principal': 50000.0, 'rate': 0.0, 'years': 5.0}));
      expect(r0.primary.value, 50000.0);
      expect(r0.rows[1].value, 0.0);

      // Standard calculation
      final r1 = calc.compute(CalcInputs({'principal': 10000.0, 'rate': 7.5, 'years': 3.0}));
      // I = 10000 * 0.075 * 3 = 2250, Total = 12250
      expect(r1.rows[1].value, closeTo(2250.0, 1e-9));
      expect(r1.primary.value, closeTo(12250.0, 1e-9));
    });

    test('C03 SIP: zero return, timing comparison (begin vs end), and monotonicity', () {
      final calc = calcById('sip')!;
      // Zero return: total contributions = projected value
      final rZero = calc.compute(CalcInputs({
        'contribution': 5000.0,
        'rate': 0.0,
        'conv': 'nominal',
        'freq': '12',
        'years': 5.0,
        'timing': 'end',
      }));
      expect(rZero.primary.value, 300000.0); // 5000 * 60
      expect(rZero.rows[1].value, 0.0); // 0 estimated growth

      // Timing comparison: begin of period earns interest on all payments immediately
      final rEnd = calc.compute(CalcInputs({
        'contribution': 10000.0,
        'rate': 12.0,
        'conv': 'nominal',
        'freq': '12',
        'years': 10.0,
        'timing': 'end',
      }));
      final rBegin = calc.compute(CalcInputs({
        'contribution': 10000.0,
        'rate': 12.0,
        'conv': 'nominal',
        'freq': '12',
        'years': 10.0,
        'timing': 'begin',
      }));
      expect(rBegin.primary.value!, greaterThan(rEnd.primary.value!));
      // In nominal monthly 12% annual = 1% monthly rate: rBegin = rEnd * (1 + 0.01)
      expect(rBegin.primary.value!, closeTo(rEnd.primary.value! * 1.01, 0.05));
    });

    test('C04 Step-Up SIP: yearly incrementation strictly increases total compared to flat SIP', () {
      final stepCalc = calcById('stepup')!;
      final sipCalc = calcById('sip')!;
      final inputs = {
        'contribution': 10000.0,
        'rate': 10.0,
        'conv': 'nominal',
        'freq': '12',
        'years': 5.0,
        'timing': 'end',
      };
      final flat = sipCalc.compute(CalcInputs(inputs));
      final step = stepCalc.compute(CalcInputs({...inputs, 'stepup': 10.0}));

      expect(step.primary.value!, greaterThan(flat.primary.value!));
      expect(step.rows[0].value!, greaterThan(flat.rows[0].value!)); // total contributions higher
    });

    test('C05 Goal Contribution: target <= 0 validation, zero return behavior', () {
      final calc = calcById('goal')!;
      expect(
        () => calc.compute(CalcInputs({
          'target': 0.0,
          'rate': 8.0,
          'conv': 'nominal',
          'freq': '12',
          'years': 5.0,
          'timing': 'end',
        })),
        throwsA(isA<CalcException>()),
      );

      // Zero return requires exact division of target by number of periods
      final rZero = calc.compute(CalcInputs({
        'target': 120000.0,
        'rate': 0.0,
        'conv': 'nominal',
        'freq': '12',
        'years': 10.0,
        'timing': 'end',
      }));
      // 120000 / 120 = 1000 per month
      expect(rZero.primary.value, closeTo(1000.0, 1e-9));
      expect(rZero.rows[1].value, closeTo(120000.0, 1e-9)); // total contributions
      expect(rZero.rows[2].value, closeTo(0.0, 1e-9)); // estimated growth
    });

    test('C06 Present Value: zero rate and discount verification', () {
      final calc = calcById('pv')!;
      // Zero rate: PV = FV
      final rZero = calc.compute(CalcInputs({'target': 500000.0, 'rate': 0.0, 'years': 5.0, 'm': '1'}));
      expect(rZero.primary.value, 500000.0);

      // 10% annual discounting for 2 years: PV = 121000 / (1.1)^2 = 100000
      final r = calc.compute(CalcInputs({'target': 121000.0, 'rate': 10.0, 'years': 2.0, 'm': '1'}));
      expect(r.primary.value, closeTo(100000.0, 0.01));
      expect(r.rows[1].value, closeTo(21000.0, 0.01));
    });

    test('C07 CAGR: valid range and boundary protections', () {
      final calc = calcById('cagr')!;
      // Doubling in 5 years: CAGR = 2^(1/5) - 1 = 14.8698%
      final r = calc.compute(CalcInputs({'start': 100000.0, 'end': 200000.0, 'years': 5.0}));
      expect(r.primary.value, closeTo(14.8698, 0.001));

      // Ending value 0: -100%
      final rZero = calc.compute(CalcInputs({'start': 100000.0, 'end': 0.0, 'years': 5.0}));
      expect(rZero.primary.value, closeTo(-100.0, 1e-6));

      // Invalid start <= 0
      expect(() => calc.compute(CalcInputs({'start': 0.0, 'end': 100.0, 'years': 2.0})), throwsA(isA<CalcException>()));
      // Invalid years <= 0
      expect(() => calc.compute(CalcInputs({'start': 100.0, 'end': 200.0, 'years': 0.0})), throwsA(isA<CalcException>()));
    });

    test('C08 Absolute Return: distributions and costs accounting', () {
      final calc = calcById('absret')!;
      // Invest 100,000, sells at 120,000 with 5,000 dividend and 2,000 cost
      // Net gain = 120000 + 5000 - 2000 - 100000 = 23000 (23%)
      final r = calc.compute(CalcInputs({
        'start': 100000.0,
        'end': 120000.0,
        'dist': 5000.0,
        'cost': 2000.0,
      }));
      expect(r.primary.value, closeTo(23.0, 1e-9));
      expect(r.rows[0].value, closeTo(23000.0, 1e-9));
    });

    test('C09 Inflation: real return fisher equation and purchasing power loss', () {
      final calc = calcById('inflation')!;
      // Mode = real return: 12% nominal with 6% inflation
      // Real = (1 + 0.12) / (1 + 0.06) - 1 = 1.12 / 1.06 - 1 = 5.66038%
      final rReal = calc.compute(CalcInputs({
        'mode': 'real',
        'nominal': 12.0,
        'inflation': 6.0,
      }));
      expect(rReal.primary.value, closeTo(5.66038, 0.0001));

      // Mode = purchasing power: 100,000 today in 10 years at 7% inflation
      // Value in today money = 100,000 / (1.07)^10 = 50,834.93
      final rPower = calc.compute(CalcInputs({
        'mode': 'power',
        'amountP': 100000.0,
        'yearsP': 10.0,
        'inflation': 7.0,
      }));
      expect(rPower.primary.value, closeTo(50834.93, 0.05));
    });

    test('C10 EMI & C11 Amortization: zero rate, monthly payments, total repayment equals loan', () {
      final emiCalc = calcById('emi')!;
      // Zero interest loan: EMI = Principal / N
      final rZero = emiCalc.compute(CalcInputs({
        'principal': 120000.0,
        'rate': 0.0,
        'conv': 'nominal',
        'tenure': 1.0,
        'unit': 'years',
      }));
      expect(rZero.primary.value, 10000.0); // 120000 / 12 months

      // Amortization schedule integrity:
      final amortCalc = calcById('amort')!;
      final rAmort = amortCalc.compute(CalcInputs({
        'principal': 500000.0,
        'rate': 9.0,
        'conv': 'nominal',
        'tenure': 5.0,
        'unit': 'years',
      }));
      expect(rAmort.rows[0].value, 500000.0);
      expect(rAmort.schedule!.rows.last[5], 0.0); // closing balance is 0
    });

    test('C12 Savings Goal: existing savings growth and target boundary', () {
      final calc = calcById('savings')!;
      // Target 1,000,000 in 5 years at 8% with 200,000 already saved (growing)
      final r = calc.compute(CalcInputs({
        'target': 1000000.0,
        'current': 200000.0,
        'growth': 'grow',
        'rate': 8.0,
        'years': 5.0,
      }));
      expect(r.primary.value!, greaterThan(0));
      expect(r.rows[1].value!, greaterThan(200000.0)); // grown existing savings
    });

    test('C13 Percentage: of, change, points, add, remove, undo', () {
      final calc = calcById('percent')!;
      // Of: 15% of 200 = 30
      expect(calc.compute(CalcInputs({'mode': 'of', 'valA': 200.0, 'pctA': 15.0})).primary.value, 30.0);

      // Change: 100 -> 125 = +25%
      expect(calc.compute(CalcInputs({'mode': 'change', 'oldV': 100.0, 'newV': 125.0})).primary.value, 25.0);

      // Points: 5% to 8% = +3 points
      expect(calc.compute(CalcInputs({'mode': 'points', 'oldRate': 5.0, 'newRate': 8.0})).primary.value, 3.0);

      // Add: 100 + 18% GST = 118
      expect(calc.compute(CalcInputs({'mode': 'adj', 'baseAmt': 100.0, 'pctAdj': 18.0, 'adjDir': 'add'})).primary.value, 118.0);

      // Undo Add: 118 undo 18% = 100
      expect(calc.compute(CalcInputs({'mode': 'adj', 'baseAmt': 118.0, 'pctAdj': 18.0, 'adjDir': 'undo_add'})).primary.value, closeTo(100.0, 1e-9));
    });

    test('C14 Investment Comparison: Scenario A vs Scenario B delta', () {
      final calc = calcById('compare')!;
      final r = calc.compute(CalcInputs({
        'yrs': 10.0,
        'aInit': 50000.0,
        'aRate': 8.0,
        'aMon': 5000.0,
        'bInit': 50000.0,
        'bRate': 12.0,
        'bMon': 5000.0,
      }));
      // Scenario B has 12% vs Scenario A's 8%, so B - A is strictly positive
      expect(r.primary.value!, greaterThan(0));
      expect(r.primary.value, closeTo(r.rows[1].value! - r.rows[0].value!, 1e-6));
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
