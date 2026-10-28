// Pure Dart financial engine. No Flutter imports, no UI formatting.
// Rates are passed as percentages unless the name says "periodic" (decimal).
import 'dart:math' as math;

import '../models/calc.dart';

double pw(double a, double b) => math.pow(a, b).toDouble();
double round2(double x) => (x * 100).roundToDouble() / 100;
const double kZeroTol = 1e-9;

/// Periodic rate from an annual percentage. Nominal: r/k. Effective: (1+r)^(1/k)-1.
double periodicRate(double annualPct, int k, {bool effective = false}) {
  final r = annualPct / 100;
  return effective ? pw(1 + r, 1.0 / k) - 1 : r / k;
}

int periodsFor(double years, int perYear, {int max = 12000}) {
  final n = (years * perYear).round();
  if (n < 1) throw CalcException('Duration must cover at least one period.');
  if (n > max) throw CalcException('Duration is too long for this frequency.');
  return n;
}

// C01
double compoundValue(double principal, double annualPct, double years, int m) {
  final r = annualPct / 100;
  if (r == 0) return principal;
  if (years == 0) return principal;
  return principal * pw(1 + r / m, m * years);
}

/// Computes compound interest with explicit duration units ('years', 'months', 'days')
/// under the documented standard 365-day annual time convention (t = days ÷ 365.0).
double compoundValueWithUnit(
    double principal, double annualPct, double duration, String unit, int m) {
  final double t;
  switch (unit) {
    case 'days':
      t = duration / 365.0;
      break;
    case 'months':
      t = duration / 12.0;
      break;
    case 'years':
    default:
      t = duration;
      break;
  }
  return compoundValue(principal, annualPct, t, m);
}

// C02
double simpleInterest(double p, double annualPct, double years) =>
    p * (annualPct / 100) * years;

// C03
double annuityFv(double c, double i, int n, {bool begin = false}) {
  final base =
      i.abs() < kZeroTol ? c * n : c * (pw(1 + i, n.toDouble()) - 1) / i;
  return begin ? base * (1 + i) : base;
}

// C05
double goalContribution(double fv, double i, int n, {bool begin = false}) {
  final base =
      i.abs() < kZeroTol ? fv / n : fv * i / (pw(1 + i, n.toDouble()) - 1);
  return begin ? base / (1 + i) : base;
}

// C06
double presentValue(double fv, double i, double n) =>
    i.abs() < kZeroTol ? fv : fv / pw(1 + i, n);

// C07
double cagr(double v0, double v1, double t) {
  if (v0 <= 0) throw CalcException('Starting value must be greater than zero.');
  if (v1 < 0) throw CalcException('Ending value cannot be negative.');
  if (t <= 0) throw CalcException('Elapsed time must be greater than zero.');
  return pw(v1 / v0, 1 / t) - 1;
}

// C10
double emi(double p, double i, int n) {
  if (i.abs() < kZeroTol) return p / n;
  final g = pw(1 + i, n.toDouble());
  return p * i * g / (g - 1);
}

class Projection {
  Projection(this.balance, this.invested, this.perYear);
  final List<double> balance; // index 0 = opening
  final List<double> invested; // initial + cumulative contributions
  final int perYear;
  int get n => balance.length - 1;

  /// Indices at each year end plus the final period.
  List<int> checkpoints() {
    final out = <int>[];
    for (var p = perYear; p <= n; p += perYear) {
      out.add(p);
    }
    if (out.isEmpty || out.last != n) out.add(n);
    return out;
  }
}

Projection project({
  double initial = 0,
  required int n,
  required double i,
  required double Function(int p) contribution,
  required int perYear,
  bool begin = false,
}) {
  final bal = <double>[initial];
  final inv = <double>[initial];
  var b = initial, t = initial;
  for (var p = 0; p < n; p++) {
    final c = contribution(p);
    b = begin ? (b + c) * (1 + i) : b * (1 + i) + c;
    t += c;
    bal.add(b);
    inv.add(t);
  }
  return Projection(bal, inv, perYear);
}

ChartSpec chartFrom(Projection pr,
    {String value = 'Projected value', String invested = 'Amount invested'}) {
  final cp = [0, ...pr.checkpoints()];
  final xs = cp.map((p) => p / pr.perYear).toList();
  return ChartSpec('Years', [
    Series(invested, xs, cp.map((p) => pr.invested[p]).toList(),
        emphasis: false),
    Series(value, xs, cp.map((p) => pr.balance[p]).toList()),
  ]);
}

/// Yearly schedule for contribution-based projections.
/// Columns: Year, Per-period contribution, Contributed in year, Closing balance.
Schedule yearlySchedule(Projection pr, double Function(int p) contribution) {
  final rows = <List<double>>[];
  var prev = 0;
  var year = 1;
  for (final cp in pr.checkpoints()) {
    var contributed = 0.0;
    for (var p = prev; p < cp; p++) {
      contributed += contribution(p);
    }
    rows.add(
        [year.toDouble(), contribution(prev), contributed, pr.balance[cp]]);
    prev = cp;
    year++;
  }
  return Schedule(['Year', 'Per period', 'Contributed', 'Balance'], rows);
}

class LoanRow {
  LoanRow(this.period, this.opening, this.payment, this.interest,
      this.principal, this.closing);
  final int period;
  final double opening, payment, interest, principal, closing;
}

/// C11. Interest and payment are rounded to 2 dp per period (as lenders do);
/// the final payment clears the residual balance. Residuals below tolerance
/// are clamped to zero.
List<LoanRow> amortize(double principal, double i, int n, {double? payment}) {
  final pay = round2(payment ?? emi(principal, i, n));
  final rows = <LoanRow>[];
  var bal = principal;
  for (var j = 1; j <= n; j++) {
    final interest = round2(bal * i);
    var pm = pay;
    if (j == n || pm >= bal + interest - 1e-6) pm = round2(bal + interest);
    final princ = pm - interest;
    var closing = bal - princ;
    if (closing.abs() < 1e-6) closing = 0;
    rows.add(LoanRow(j, bal, pm, interest, princ, closing));
    bal = closing;
    if (bal == 0) break;
  }
  return rows;
}
