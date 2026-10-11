// Calculator registry (Release 1: C01-C14, plus C11 as its own screen).
import 'dart:math' as math;

import '../calculations/finance.dart';
import '../models/calc.dart';

const _compounding = [
  ChoiceOption('1', 'Annually'),
  ChoiceOption('2', 'Semi-annually'),
  ChoiceOption('4', 'Quarterly'),
  ChoiceOption('12', 'Monthly'),
  ChoiceOption('365', 'Daily'),
];
const _frequency = [
  ChoiceOption('12', 'Monthly'),
  ChoiceOption('4', 'Quarterly'),
  ChoiceOption('2', 'Half-yearly'),
  ChoiceOption('1', 'Yearly'),
  ChoiceOption('52', 'Weekly'),
];
const _timing = [
  ChoiceOption('end', 'End of each period'),
  ChoiceOption('begin', 'Beginning of each period'),
];
const _convention = [
  ChoiceOption('nominal', 'Nominal (annual rate ÷ periods)'),
  ChoiceOption('effective', 'Effective annual rate'),
];

FieldDef _money(String id, String label, double def, {String? hint, String? help, bool req = true, double min = 0, String? showField, String? showValue}) =>
    FieldDef(id: id, label: label, money: true, defaultValue: def, hint: hint, help: help, required: req, min: min, max: 1e12, showWhenField: showField, showWhenValue: showValue);

FieldDef _rate(String id, String label, double def, {double min = -99, double max = 100, String? help, bool req = true, String? showField, String? showValue}) =>
    FieldDef(id: id, label: label, suffix: '% per year', defaultValue: def, min: min, max: max, help: help, required: req, showWhenField: showField, showWhenValue: showValue);

FieldDef _years(String id, String label, double def, {String? showField, String? showValue, double max = 100}) =>
    FieldDef(id: id, label: label, suffix: 'years', defaultValue: def, min: 0.01, max: max, showWhenField: showField, showWhenValue: showValue);

FieldDef _choice(String id, String label, List<ChoiceOption> o, String def, {String? help, String? showField, String? showValue}) =>
    FieldDef(id: id, label: label, kind: FieldKind.choice, options: o, defaultValue: def, help: help, showWhenField: showField, showWhenValue: showValue);

List<double> _yearPoints(double t) {
  final out = <double>[0];
  for (var y = 1; y <= t.floor(); y++) {
    out.add(y.toDouble());
  }
  if (t != t.floorToDouble() || out.length == 1) out.add(t);
  return out;
}

String _convText(bool eff, int k) => eff
    ? 'Effective annual rate converted to a periodic rate: (1 + r)^(1/$k) − 1.'
    : 'Nominal annual rate converted to a periodic rate: r ÷ $k.';

// ───────────────────────── C01 ─────────────────────────
CalcResult _compound(CalcInputs x) {
  final p = x.n('principal'), r = x.n('rate'), t = x.n('years');
  final m = int.parse(x.s('m'));
  final a = compoundValue(p, r, t, m);
  final pts = _yearPoints(t);
  final ys = pts.map((y) => compoundValue(p, r, y, m)).toList();
  final rows = <List<double>>[];
  for (var i = 1; i < pts.length; i++) {
    rows.add([pts[i], ys[i - 1], ys[i] - ys[i - 1], ys[i]]);
  }
  final ear = (pw(1 + r / 100 / m, m.toDouble()) - 1) * 100;
  return CalcResult(
    primary: ResultRow('Estimated final value', a),
    rows: [
      ResultRow('Principal', p),
      ResultRow('Estimated interest', a - p),
      ResultRow('Effective annual rate', ear, kind: ValueKind.percent),
      ResultRow('Duration', t, kind: ValueKind.years),
    ],
    assumptions: ['Interest is added to the balance $m time(s) per year.', 'No deposits, withdrawals, fees or taxes are modelled.'],
    chart: ChartSpec('Years', [Series('Principal', pts, pts.map((_) => p).toList(), emphasis: false), Series('Estimated value', pts, ys)]),
    schedule: Schedule(['Year', 'Opening', 'Interest', 'Closing'], rows),
  );
}

// ───────────────────────── C02 ─────────────────────────
CalcResult _simple(CalcInputs x) {
  final p = x.n('principal'), r = x.n('rate'), t = x.n('years');
  final i = simpleInterest(p, r, t);
  final pts = _yearPoints(t);
  final ys = pts.map((y) => p + simpleInterest(p, r, y)).toList();
  return CalcResult(
    primary: ResultRow('Total amount', p + i),
    rows: [ResultRow('Principal', p), ResultRow('Simple interest', i), ResultRow('Interest per year', simpleInterest(p, r, 1))],
    assumptions: ['Interest is earned on the original principal only. It does not compound.'],
    chart: ChartSpec('Years', [Series('Principal', pts, pts.map((_) => p).toList(), emphasis: false), Series('Total amount', pts, ys)]),
  );
}

// ───────────────────────── C03 / C04 ─────────────────────────
CalcResult _sip(CalcInputs x) {
  final c = x.n('contribution'), r = x.n('rate');
  final k = int.parse(x.s('freq'));
  final eff = x.s('conv') == 'effective';
  final begin = x.s('timing') == 'begin';
  final i = periodicRate(r, k, effective: eff);
  final n = periodsFor(x.n('years'), k);
  final fv = annuityFv(c, i, n, begin: begin);
  final pr = project(n: n, i: i, contribution: (_) => c, perYear: k, begin: begin);
  final paid = c * n;
  return CalcResult(
    primary: ResultRow('Projected value', fv),
    rows: [
      ResultRow('Total contributions', paid),
      ResultRow('Estimated growth', fv - paid),
      ResultRow('Number of contributions', n.toDouble(), kind: ValueKind.number),
      ResultRow('Periodic rate', i * 100, kind: ValueKind.percent),
    ],
    assumptions: [_convText(eff, k), 'Contributions are made at the ${begin ? 'beginning' : 'end'} of each period.', 'Returns are constant. Real returns vary and are not guaranteed.'],
    chart: chartFrom(pr),
    schedule: yearlySchedule(pr, (_) => c),
  );
}

CalcResult _stepUp(CalcInputs x) {
  final c = x.n('contribution'), s = x.n('stepup'), r = x.n('rate');
  final k = int.parse(x.s('freq'));
  final eff = x.s('conv') == 'effective';
  final begin = x.s('timing') == 'begin';
  final i = periodicRate(r, k, effective: eff);
  final n = periodsFor(x.n('years'), k);
  double contrib(int p) => c * pw(1 + s / 100, (p ~/ k).toDouble());
  final pr = project(n: n, i: i, contribution: contrib, perYear: k, begin: begin);
  final fv = pr.balance.last;
  final paid = pr.invested.last;
  return CalcResult(
    primary: ResultRow('Projected value', fv),
    rows: [
      ResultRow('Total contributions', paid),
      ResultRow('Estimated growth', fv - paid),
      ResultRow('Final-year contribution per period', contrib(n - 1)),
    ],
    assumptions: [
      'Year 1 uses the initial contribution. The amount steps up by ${s.toStringAsFixed(2)}% at the start of each later investment year.',
      _convText(eff, k),
      'Contributions are made at the ${begin ? 'beginning' : 'end'} of each period.',
    ],
    chart: chartFrom(pr),
    schedule: yearlySchedule(pr, contrib),
  );
}

// ───────────────────────── C05 ─────────────────────────
CalcResult _goalContribution(CalcInputs x) {
  final target = x.n('target'), r = x.n('rate');
  final k = int.parse(x.s('freq'));
  final eff = x.s('conv') == 'effective';
  final begin = x.s('timing') == 'begin';
  final i = periodicRate(r, k, effective: eff);
  final n = periodsFor(x.n('years'), k);
  if (target <= 0) throw CalcException('Target amount must be greater than zero.');
  final c = goalContribution(target, i, n, begin: begin);
  final pr = project(n: n, i: i, contribution: (_) => c, perYear: k, begin: begin);
  return CalcResult(
    primary: ResultRow('Contribution needed per period', c),
    rows: [
      ResultRow('Target amount', target),
      ResultRow('Total contributions', c * n),
      ResultRow('Estimated growth', target - c * n),
      ResultRow('Number of contributions', n.toDouble(), kind: ValueKind.number),
    ],
    assumptions: [_convText(eff, k), 'Contributions are made at the ${begin ? 'beginning' : 'end'} of each period.', 'Assumes a constant return. Not a guarantee.'],
    chart: chartFrom(pr),
    schedule: yearlySchedule(pr, (_) => c),
  );
}

// ───────────────────────── C06 ─────────────────────────
CalcResult _presentValue(CalcInputs x) {
  final fv = x.n('target'), r = x.n('rate'), t = x.n('years');
  final m = int.parse(x.s('m'));
  if (fv <= 0) throw CalcException('Target amount must be greater than zero.');
  final pv = presentValue(fv, r / 100 / m, m * t);
  final pts = _yearPoints(t);
  return CalcResult(
    primary: ResultRow('Lump sum needed today', pv),
    rows: [ResultRow('Target amount', fv), ResultRow('Growth required', fv - pv), ResultRow('Duration', t, kind: ValueKind.years)],
    assumptions: ['Periodic rate = annual rate ÷ $m, applied for ${(m * t).toStringAsFixed(m * t == (m * t).roundToDouble() ? 0 : 2)} period(s).', 'Rate and period length must match (annual rate with annual periods, and so on).'],
    chart: ChartSpec('Years', [Series('Value of lump sum', pts, pts.map((y) => compoundValue(pv, r, y, m)).toList())]),
  );
}

// ───────────────────────── C07 ─────────────────────────
CalcResult _cagr(CalcInputs x) {
  final v0 = x.n('start'), v1 = x.n('end'), t = x.n('years');
  final g = cagr(v0, v1, t) * 100;
  return CalcResult(
    primary: ResultRow('CAGR', g, kind: ValueKind.percent),
    rows: [
      ResultRow('Absolute gain / loss', v1 - v0),
      ResultRow('Total return', (v1 / v0 - 1) * 100, kind: ValueKind.percent),
      ResultRow('Growth multiple', v1 / v0, kind: ValueKind.number),
    ],
    assumptions: ['CAGR uses only the start and end values. It does not describe what happened in between.', 'An ending value of zero gives −100%.'],
  );
}

// ───────────────────────── C08 ─────────────────────────
CalcResult _absReturn(CalcInputs x) {
  final v0 = x.n('start'), v1 = x.n('end');
  final dist = x.nOr('dist', 0), cost = x.nOr('cost', 0);
  if (v0 <= 0) throw CalcException('Initial value must be greater than zero.');
  final gain = v1 + dist - cost - v0;
  return CalcResult(
    primary: ResultRow('Absolute return', gain / v0 * 100, kind: ValueKind.percent),
    rows: [
      ResultRow('Gain / loss', gain),
      ResultRow('Initial value', v0),
      ResultRow('Final value', v1),
      ResultRow('Distributions received', dist),
      ResultRow('Costs paid', cost),
    ],
    assumptions: ['Gain = final value + distributions − costs − initial value.', 'This is not an annualised return. Use CAGR to compare across different time periods.'],
  );
}

// ───────────────────────── C09 ─────────────────────────
CalcResult _inflation(CalcInputs x) {
  final mode = x.s('mode');
  final inf = x.n('inflation') / 100;
  if (inf <= -1) throw CalcException('Inflation must be greater than −100%.');
  if (mode == 'real') {
    final nom = x.n('nominal') / 100;
    final real = ((1 + nom) / (1 + inf) - 1) * 100;
    return CalcResult(
      primary: ResultRow('Real return', real, kind: ValueKind.percent),
      rows: [ResultRow('Nominal return', nom * 100, kind: ValueKind.percent), ResultRow('Inflation', inf * 100, kind: ValueKind.percent), ResultRow('Approximation (nominal − inflation)', (nom - inf) * 100, kind: ValueKind.percent)],
      assumptions: ['Real return = (1 + nominal) ÷ (1 + inflation) − 1.', 'The subtraction approximation is shown for comparison only.'],
    );
  }
  final future = mode == 'future';
  final amt = x.n(future ? 'amountF' : 'amountP');
  final t = x.n(future ? 'yearsF' : 'yearsP');
  final factor = pw(1 + inf, t);
  final res = future ? amt * factor : amt / factor;
  final pts = _yearPoints(t);
  final ys = pts.map((y) => future ? amt * pw(1 + inf, y) : amt / pw(1 + inf, y)).toList();
  return CalcResult(
    primary: ResultRow(future ? 'Future cost' : 'Purchasing power', res),
    rows: [
      ResultRow(future ? 'Cost today' : 'Money amount', amt),
      ResultRow(future ? 'Increase from inflation' : 'Purchasing power lost', (res - amt).abs()),
      ResultRow('Cumulative change', (res / amt - 1) * 100, kind: ValueKind.percent),
    ],
    assumptions: ['Inflation is assumed constant at ${(inf * 100).toStringAsFixed(2)}% per year.', future ? 'Future cost = cost today × (1 + inflation)^years.' : 'Purchasing power = amount ÷ (1 + inflation)^years, expressed in today\'s money.'],
    chart: ChartSpec('Years', [Series(future ? 'Cost' : 'Purchasing power', pts, ys)]),
  );
}

// ───────────────────────── C10 / C11 ─────────────────────────
List<FieldDef> _loanFields() => [
      _money('principal', 'Loan amount', 250000, min: 1),
      _rate('rate', 'Interest rate', 8.5, min: 0, max: 100),
      _choice('conv', 'Rate convention', _convention, 'nominal', help: 'Nominal: monthly rate = annual ÷ 12. Effective: monthly rate = (1 + annual)^(1/12) − 1.'),
      const FieldDef(id: 'tenure', label: 'Loan term', defaultValue: 20, min: 1, max: 1200, integer: false),
      _choice('unit', 'Term unit', const [ChoiceOption('years', 'Years'), ChoiceOption('months', 'Months')], 'years'),
    ];

({double principal, double i, int n, List<LoanRow> rows}) _loan(CalcInputs x) {
  final p = x.n('principal');
  final eff = x.s('conv') == 'effective';
  final i = periodicRate(x.n('rate'), 12, effective: eff);
  final months = x.s('unit') == 'years' ? x.n('tenure') * 12 : x.n('tenure');
  final n = months.round();
  if (n < 1 || n > 1200) throw CalcException('Loan term must be between 1 and 1200 months.');
  return (principal: p, i: i, n: n, rows: amortize(p, i, n));
}

Schedule _loanSchedule(List<LoanRow> rows) => Schedule(
      ['Month', 'Opening', 'Payment', 'Interest', 'Principal', 'Closing'],
      rows.map((r) => [r.period.toDouble(), r.opening, r.payment, r.interest, r.principal, r.closing]).toList(),
    );

ChartSpec _loanChart(List<LoanRow> rows) {
  final xs = <double>[0], bal = <double>[rows.first.opening], cum = <double>[0];
  var ci = 0.0;
  for (final r in rows) {
    ci += r.interest;
    if (r.period % 12 == 0 || r.period == rows.length) {
      xs.add(r.period / 12);
      bal.add(r.closing);
      cum.add(ci);
    }
  }
  return ChartSpec('Years', [Series('Outstanding balance', xs, bal), Series('Interest paid to date', xs, cum, emphasis: false)]);
}

CalcResult _emi(CalcInputs x) {
  final l = _loan(x);
  final total = l.rows.fold<double>(0, (a, r) => a + r.payment);
  final interest = total - l.principal;
  final first = l.rows.first.payment, last = l.rows.last.payment;
  return CalcResult(
    primary: ResultRow('Monthly EMI', first),
    rows: [
      ResultRow('Total payments', total),
      ResultRow('Total interest', interest),
      ResultRow('Interest share of payments', total == 0 ? 0 : interest / total * 100, kind: ValueKind.percent),
      if ((last - first).abs() > 0.005) ResultRow('Final payment (adjusted)', last),
    ],
    assumptions: ['Monthly rate = ${(l.i * 100).toStringAsFixed(4)}%.', 'Payments are made at the end of each month. Fees and insurance are not included.', 'The final payment is adjusted to clear rounding differences.'],
    chart: _loanChart(l.rows),
    schedule: _loanSchedule(l.rows),
  );
}

CalcResult _amort(CalcInputs x) {
  final l = _loan(x);
  final paidInterest = l.rows.fold<double>(0, (a, r) => a + r.interest);
  return CalcResult(
    primary: ResultRow('Total interest', paidInterest),
    rows: [
      ResultRow('Loan amount', l.principal),
      ResultRow('Monthly payment', l.rows.first.payment),
      ResultRow('Number of payments', l.rows.length.toDouble(), kind: ValueKind.number),
    ],
    assumptions: ['interest = opening balance × monthly rate; principal = payment − interest.', 'Balances below a small tolerance are cleared to zero. The last payment closes the loan.'],
    chart: _loanChart(l.rows),
    schedule: _loanSchedule(l.rows),
  );
}

// ───────────────────────── C12 ─────────────────────────
CalcResult _savingsGoal(CalcInputs x) {
  final target = x.n('target'), current = x.nOr('current', 0), r = x.nOr('rate', 0);
  final grow = x.s('growth') == 'grow';
  final n = periodsFor(x.n('years'), 12);
  final i = r / 1200;
  if (target <= 0) throw CalcException('Target amount must be greater than zero.');
  double existing(int p) => grow ? current * pw(1 + i, p.toDouble()) : current;
  final remaining = math.max(0.0, target - existing(n));
  final c = remaining == 0 ? 0.0 : goalContribution(remaining, i, n);
  final pr = project(n: n, i: i, contribution: (_) => c, perYear: 12);
  final combined = Projection(
    [for (var p = 0; p <= n; p++) existing(p) + pr.balance[p]],
    [for (var p = 0; p <= n; p++) current + pr.invested[p]],
    12,
  );
  return CalcResult(
    primary: ResultRow('Monthly contribution needed', c),
    rows: [
      ResultRow('Target amount', target),
      ResultRow('Existing savings at end of period', existing(n)),
      ResultRow('Remaining to fund', remaining),
      ResultRow('Total new contributions', c * n),
      ResultRow('Estimated growth on contributions', remaining - c * n),
    ],
    assumptions: [
      grow ? 'Existing savings compound at the assumed rate alongside new contributions.' : 'Existing savings do not grow. Only new contributions earn the assumed rate.',
      'Monthly contributions at the end of each month; monthly rate = annual ÷ 12.',
      if (r == 0) 'No-growth mode: remaining amount ÷ number of months.',
    ],
    chart: chartFrom(combined, value: 'Projected savings', invested: 'Savings + contributions'),
    schedule: yearlySchedule(pr, (_) => c),
  );
}

// ───────────────────────── C13 ─────────────────────────
CalcResult _percentage(CalcInputs x) {
  switch (x.s('mode')) {
    case 'of':
      final part = x.n('valA') * x.n('pctA') / 100;
      return CalcResult(primary: ResultRow('Result', part, kind: ValueKind.number), rows: [ResultRow('Remainder', x.n('valA') - part, kind: ValueKind.number)], assumptions: ['part = value × percentage ÷ 100.']);
    case 'change':
      final o = x.n('oldV'), n = x.n('newV');
      if (o == 0) throw CalcException('Old value cannot be zero.');
      return CalcResult(primary: ResultRow('Percentage change', (n - o) / o * 100, kind: ValueKind.percent), rows: [ResultRow('Absolute change', n - o, kind: ValueKind.number)], assumptions: ['change % = (new − old) ÷ old × 100.']);
    case 'points':
      final o = x.n('oldRate'), n = x.n('newRate');
      return CalcResult(
        primary: ResultRow('Change in percentage points', n - o, kind: ValueKind.number),
        rows: [if (o != 0) ResultRow('Relative change', (n - o) / o * 100, kind: ValueKind.percent)],
        assumptions: ['Percentage points are the simple difference between two rates. They differ from percent change.'],
      );
    default:
      final b = x.n('baseAmt'), p = x.n('pctAdj') / 100;
      final dir = x.s('adjDir');
      late double res;
      late String note;
      switch (dir) {
        case 'add':
          res = b * (1 + p);
          note = 'Result = amount × (1 + %).';
        case 'remove':
          res = b * (1 - p);
          note = 'Result = amount × (1 − %).';
        case 'undo_add':
          if (1 + p == 0) throw CalcException('Percentage cannot be −100%.');
          res = b / (1 + p);
          note = 'Original = amount ÷ (1 + %): the amount before the percentage was added.';
        default:
          if (1 - p == 0) throw CalcException('Percentage cannot be 100% for this operation.');
          res = b / (1 - p);
          note = 'Original = amount ÷ (1 − %): the amount before the percentage was removed.';
      }
      return CalcResult(primary: ResultRow('Result', res, kind: ValueKind.number), rows: [ResultRow('Difference', res - b, kind: ValueKind.number)], assumptions: [note, 'The percentage is applied to the amount you enter, before any separate tax or fee.']);
  }
}

// ───────────────────────── C14 ─────────────────────────
CalcResult _compare(CalcInputs x) {
  final t = x.n('yrs');
  final n = periodsFor(t, 12);
  Projection run(String a) => project(initial: x.n('${a}Init'), n: n, i: x.n('${a}Rate') / 1200, contribution: (_) => x.n('${a}Mon'), perYear: 12);
  final A = run('a'), B = run('b');
  final cp = [0, ...A.checkpoints()];
  final xs = cp.map((p) => p / 12).toList();
  return CalcResult(
    primary: ResultRow('Difference in final value (B − A)', B.balance.last - A.balance.last),
    rows: [
      ResultRow('A: final value', A.balance.last),
      ResultRow('B: final value', B.balance.last),
      ResultRow('A: total invested', A.invested.last),
      ResultRow('B: total invested', B.invested.last),
      ResultRow('A: estimated gain', A.balance.last - A.invested.last),
      ResultRow('B: estimated gain', B.balance.last - B.invested.last),
    ],
    assumptions: ['Both scenarios use the same horizon, monthly contributions at month end, and monthly compounding (rate ÷ 12).', 'Different rates do not imply equal risk. Higher assumed returns are not guaranteed.'],
    chart: ChartSpec('Years', [Series('Scenario A', xs, cp.map((p) => A.balance[p]).toList(), emphasis: false), Series('Scenario B', xs, cp.map((p) => B.balance[p]).toList())]),
  );
}

// ───────────────────────── Registry ─────────────────────────
FieldDef _pct(String id, String label, double def, String mode) =>
    FieldDef(id: id, label: label, suffix: '%', defaultValue: def, min: -1e9, max: 1e9, showWhenField: 'mode', showWhenValue: mode);
FieldDef _num(String id, String label, double def, String mode, {String? suffix}) =>
    FieldDef(id: id, label: label, suffix: suffix, defaultValue: def, min: -1e12, max: 1e12, showWhenField: 'mode', showWhenValue: mode);

final List<CalculatorDef> catalog = [
  CalculatorDef(
    id: 'compound', code: 'C01', name: 'Compound Interest', category: CalcCategory.growth,
    summary: 'Growth of a lump sum with compounding.', explains: 'Shows how a single deposit grows when interest is added to the balance at a chosen frequency.',
    aliases: ['lump sum', 'lumpsum', 'future value', 'interest on interest'],
    formula: ['A = P × (1 + r/m)^(m×t)', 'Interest = A − P', 'If r = 0, A = P'],
    fields: [_money('principal', 'Principal', 10000), _rate('rate', 'Annual interest rate', 8, min: 0), _years('years', 'Time period', 10), _choice('m', 'Compounding', _compounding, '12')],
    compute: _compound,
  ),
  CalculatorDef(
    id: 'simple', code: 'C02', name: 'Simple Interest', category: CalcCategory.growth,
    summary: 'Interest on the original principal only.', explains: 'Calculates interest that does not compound. Useful for short-term loans and basic deposits.',
    aliases: ['si', 'flat interest'],
    formula: ['I = P × r × t', 'A = P + I'],
    fields: [_money('principal', 'Principal', 10000), _rate('rate', 'Annual interest rate', 6, min: 0), _years('years', 'Time period', 3)],
    compute: _simple,
  ),
  CalculatorDef(
    id: 'sip', code: 'C03', name: 'Recurring Investment (SIP)', category: CalcCategory.growth,
    summary: 'Projected value of regular contributions.', explains: 'Projects the future value of equal periodic investments at a constant assumed return.',
    aliases: ['sip', 'systematic investment', 'monthly investment', 'recurring deposit', 'annuity'],
    formula: ['FV = C × ((1+i)^n − 1) / i  (end of period)', 'FV × (1+i) for beginning-of-period', 'If i = 0, FV = C × n'],
    fields: [
      _money('contribution', 'Contribution per period', 500),
      _rate('rate', 'Expected annual return', 10),
      _choice('conv', 'Rate convention', _convention, 'nominal'),
      _choice('freq', 'Contribution frequency', _frequency, '12'),
      _years('years', 'Duration', 15),
      _choice('timing', 'Contribution timing', _timing, 'end'),
    ],
    compute: _sip,
  ),
  CalculatorDef(
    id: 'stepup', code: 'C04', name: 'Step-Up Investment', category: CalcCategory.growth,
    summary: 'Regular contributions that increase each year.', explains: 'Projects growth when the contribution rises by a fixed percentage at the start of every investment year.',
    aliases: ['step up sip', 'increasing contribution', 'annual increase'],
    formula: ['Contribution in year y = C × (1 + s)^(y−1)', 'Each payment is compounded to the end date.'],
    fields: [
      _money('contribution', 'Initial contribution per period', 500),
      const FieldDef(id: 'stepup', label: 'Annual step-up', suffix: '%', defaultValue: 10, min: 0, max: 100),
      _rate('rate', 'Expected annual return', 10),
      _choice('conv', 'Rate convention', _convention, 'nominal'),
      _choice('freq', 'Contribution frequency', _frequency, '12'),
      _years('years', 'Duration', 15),
      _choice('timing', 'Contribution timing', _timing, 'end'),
    ],
    compute: _stepUp,
  ),
  CalculatorDef(
    id: 'goal', code: 'C05', name: 'Goal Contribution', category: CalcCategory.planning,
    summary: 'Regular amount needed to reach a target.', explains: 'Finds the periodic contribution required to reach a target value by a given date.',
    aliases: ['target', 'how much to invest', 'sinking fund'],
    formula: ['C = FV × i / ((1+i)^n − 1)', 'Beginning of period: divide by (1+i)', 'If i = 0, C = FV ÷ n'],
    fields: [
      _money('target', 'Target amount', 100000, min: 1),
      _rate('rate', 'Expected annual return', 8),
      _choice('conv', 'Rate convention', _convention, 'nominal'),
      _choice('freq', 'Contribution frequency', _frequency, '12'),
      _years('years', 'Time to goal', 10),
      _choice('timing', 'Contribution timing', _timing, 'end'),
    ],
    compute: _goalContribution,
  ),
  CalculatorDef(
    id: 'pv', code: 'C06', name: 'Goal Lump Sum (Present Value)', category: CalcCategory.planning,
    summary: 'Single amount needed today to reach a target.', explains: 'Discounts a future target back to today at an assumed rate.',
    aliases: ['present value', 'pv', 'discount'],
    formula: ['PV = FV / (1 + i)^n', 'If i = 0, PV = FV'],
    fields: [_money('target', 'Target amount', 100000, min: 1), _rate('rate', 'Expected annual return', 8), _years('years', 'Time to goal', 10), _choice('m', 'Compounding', _compounding, '1')],
    compute: _presentValue,
  ),
  CalculatorDef(
    id: 'cagr', code: 'C07', name: 'CAGR', category: CalcCategory.returns,
    summary: 'Annualised growth between two values.', explains: 'Computes the constant yearly growth rate that links a start value to an end value.',
    aliases: ['compound annual growth rate', 'annualised return', 'annualized return'],
    formula: ['CAGR = (V1 / V0)^(1/t) − 1'],
    fields: [_money('start', 'Starting value', 10000, min: 0.01), _money('end', 'Ending value', 25000), _years('years', 'Elapsed time', 6)],
    compute: _cagr,
  ),
  CalculatorDef(
    id: 'absret', code: 'C08', name: 'Absolute Return', category: CalcCategory.returns,
    summary: 'Total gain or loss as a percentage.', explains: 'Measures overall gain or loss against the starting value, including optional distributions and costs.',
    aliases: ['total return', 'profit', 'gain', 'roi'],
    formula: ['Gain = V1 + distributions − costs − V0', 'Return % = Gain ÷ V0 × 100'],
    fields: [_money('start', 'Initial value', 10000, min: 0.01), _money('end', 'Final value', 12500), _money('dist', 'Distributions received (optional)', 0, req: false), _money('cost', 'Costs paid (optional)', 0, req: false)],
    compute: _absReturn,
  ),
  CalculatorDef(
    id: 'inflation', code: 'C09', name: 'Inflation & Real Return', category: CalcCategory.returns,
    summary: 'Future cost, purchasing power, real return.', explains: 'Shows how inflation changes costs and buying power, and converts a nominal return into a real return.',
    aliases: ['future cost', 'purchasing power', 'real return', 'cost of living'],
    formula: ['Future cost = Cost × (1 + inf)^years', 'Purchasing power = Money ÷ (1 + inf)^years', 'Real = (1 + nominal) ÷ (1 + inf) − 1'],
    fields: [
      _choice('mode', 'Calculate', const [ChoiceOption('future', 'Future cost'), ChoiceOption('power', 'Purchasing power'), ChoiceOption('real', 'Real return')], 'future'),
      const FieldDef(id: 'amountF', label: 'Cost today', money: true, defaultValue: 1000, min: 0, max: 1e12, showWhenField: 'mode', showWhenValue: 'future'),
      const FieldDef(id: 'yearsF', label: 'Years ahead', suffix: 'years', defaultValue: 10, min: 0.01, max: 100, showWhenField: 'mode', showWhenValue: 'future'),
      const FieldDef(id: 'amountP', label: 'Future money amount', money: true, defaultValue: 1000, min: 0, max: 1e12, showWhenField: 'mode', showWhenValue: 'power'),
      const FieldDef(id: 'yearsP', label: 'Years ahead', suffix: 'years', defaultValue: 10, min: 0.01, max: 100, showWhenField: 'mode', showWhenValue: 'power'),
      const FieldDef(id: 'nominal', label: 'Nominal return', suffix: '% per year', defaultValue: 8, min: -99, max: 1000, showWhenField: 'mode', showWhenValue: 'real'),
      const FieldDef(id: 'inflation', label: 'Inflation rate', suffix: '% per year', defaultValue: 4, min: -50, max: 1000),
    ],
    compute: _inflation,
  ),
  CalculatorDef(
    id: 'emi', code: 'C10', name: 'EMI Calculator', category: CalcCategory.loans,
    summary: 'Monthly instalment for a loan.', explains: 'Calculates the fixed monthly payment, total interest and a repayment schedule.',
    aliases: ['loan', 'mortgage', 'car loan', 'home loan', 'instalment', 'installment', 'payment'],
    formula: ['EMI = P × i × (1+i)^n / ((1+i)^n − 1)', 'If i = 0, EMI = P ÷ n'],
    fields: _loanFields(),
    compute: _emi,
  ),
  CalculatorDef(
    id: 'amort', code: 'C11', name: 'Amortization Schedule', category: CalcCategory.loans,
    summary: 'Month-by-month loan repayment table.', explains: 'Lists opening balance, payment, interest, principal and closing balance for every month.',
    aliases: ['repayment schedule', 'loan table', 'principal and interest'],
    formula: ['interest = opening × i', 'principal = payment − interest', 'closing = opening − principal'],
    fields: _loanFields(),
    compute: _amort,
  ),
  CalculatorDef(
    id: 'savings', code: 'C12', name: 'Savings Goal', category: CalcCategory.planning,
    summary: 'Monthly saving needed for a target.', explains: 'Combines current savings, time and an optional return to find the monthly amount required.',
    aliases: ['save for', 'target savings', 'down payment', 'emergency fund'],
    formula: ['Remaining = max(0, Target − projected current savings)', 'Monthly = Remaining × i / ((1+i)^n − 1)', 'No growth: Remaining ÷ n'],
    fields: [
      _money('target', 'Target amount', 50000, min: 1),
      _money('current', 'Current savings', 5000, req: false),
      _years('years', 'Time horizon', 4),
      _rate('rate', 'Assumed annual return', 3, min: 0, req: false),
      _choice('growth', 'Existing savings', const [ChoiceOption('grow', 'Grow at the assumed return'), ChoiceOption('flat', 'Stay flat (no growth)')], 'grow'),
    ],
    compute: _savingsGoal,
  ),
  CalculatorDef(
    id: 'percent', code: 'C13', name: 'Percentage', category: CalcCategory.utilities,
    summary: 'Percent of, percent change, points, add or remove.', explains: 'Handles common percentage operations and keeps percent change distinct from percentage points.',
    aliases: ['discount', 'markup', 'percent change', 'percentage points', 'margin'],
    formula: ['part = total × % ÷ 100', 'change % = (new − old) ÷ old × 100', 'points = new rate − old rate'],
    fields: [
      _choice('mode', 'Operation', const [ChoiceOption('of', 'Percentage of a value'), ChoiceOption('change', 'Percentage change'), ChoiceOption('points', 'Percentage-point change'), ChoiceOption('adjust', 'Add or remove a percentage')], 'of'),
      _pct('pctA', 'Percentage', 15, 'of'),
      _num('valA', 'Value', 2000, 'of'),
      _num('oldV', 'Old value', 80, 'change'),
      _num('newV', 'New value', 100, 'change'),
      _pct('oldRate', 'Old rate', 4.5, 'points'),
      _pct('newRate', 'New rate', 5.25, 'points'),
      _num('baseAmt', 'Amount', 1000, 'adjust'),
      _pct('pctAdj', 'Percentage', 10, 'adjust'),
      const FieldDef(id: 'adjDir', label: 'Operation', kind: FieldKind.choice, defaultValue: 'add', showWhenField: 'mode', showWhenValue: 'adjust', options: [
        ChoiceOption('add', 'Add percentage'),
        ChoiceOption('remove', 'Remove percentage'),
        ChoiceOption('undo_add', 'Find original (percentage was added)'),
        ChoiceOption('undo_remove', 'Find original (percentage was removed)'),
      ]),
    ],
    compute: _percentage,
  ),
  CalculatorDef(
    id: 'compare', code: 'C14', name: 'Investment Comparison', category: CalcCategory.growth,
    summary: 'Compare two scenarios side by side.', explains: 'Runs two investment scenarios over the same horizon with the same model and shows the difference.',
    aliases: ['compare', 'scenario', 'versus', 'a vs b'],
    formula: ['Balance(p+1) = Balance(p) × (1 + i) + contribution', 'i = annual rate ÷ 12, month-end contributions'],
    fields: [
      _years('yrs', 'Common horizon', 10),
      _money('aInit', 'A: starting amount', 10000),
      _money('aMon', 'A: monthly contribution', 300),
      _rate('aRate', 'A: annual return', 7),
      _money('bInit', 'B: starting amount', 10000),
      _money('bMon', 'B: monthly contribution', 300),
      _rate('bRate', 'B: annual return', 9),
    ],
    compute: _compare,
  ),
];

CalculatorDef? calcById(String id) {
  for (final c in catalog) {
    if (c.id == id) return c;
  }
  return null;
}

List<CalculatorDef> searchCatalog(String q, {CalcCategory? category}) {
  final s = q.trim().toLowerCase();
  return catalog.where((c) {
    if (category != null && c.category != category) return false;
    if (s.isEmpty) return true;
    return c.name.toLowerCase().contains(s) ||
        c.code.toLowerCase() == s ||
        c.category.label.toLowerCase().contains(s) ||
        c.summary.toLowerCase().contains(s) ||
        c.aliases.any((a) => a.toLowerCase().contains(s));
  }).toList();
}
