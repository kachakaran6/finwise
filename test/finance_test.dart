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
