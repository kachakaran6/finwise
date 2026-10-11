import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/tokens.dart';
import '../../core/format.dart';
import '../../domain/models/calc.dart';
import 'common.dart';

class ResultView extends StatefulWidget {
  const ResultView({super.key, required this.def, required this.result, required this.fmt});
  final CalculatorDef def;
  final CalcResult result;
  final Fmt fmt;

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final r = widget.result;
    final tabs = <String>['Summary', if (r.chart != null) 'Chart', if (r.schedule != null) 'Schedule', 'Notes'];
    if (tab >= tabs.length) tab = 0;
    final current = tabs[tab];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(Sp.xl),
        decoration: BoxDecoration(color: p.primary, borderRadius: Rd.r(Rd.lg)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.primary.label.toUpperCase(), style: t.labelSmall?.copyWith(color: p.onPrimary.withValues(alpha: 0.78), letterSpacing: 0.8)),
          const SizedBox(height: Sp.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(widget.fmt.value(r.primary), style: AppType.figure(p.onPrimary, size: 34, w: FontWeight.w600)),
          ),
          const SizedBox(height: Sp.xs),
          Text('Estimate based on the assumptions below. Not a guarantee.', style: t.bodySmall?.copyWith(color: p.onPrimary.withValues(alpha: 0.78))),
        ]),
      ),
      const SizedBox(height: Sp.lg),
      _Segments(labels: tabs, index: tab, onChanged: (i) => setState(() => tab = i)),
      const SizedBox(height: Sp.lg),
      if (current == 'Summary') _Breakdown(rows: r.rows, fmt: widget.fmt),
      if (current == 'Chart') _Chart(spec: r.chart!, fmt: widget.fmt),
      if (current == 'Schedule') _ScheduleTable(schedule: r.schedule!, fmt: widget.fmt),
      if (current == 'Notes') _Notes(def: widget.def, assumptions: r.assumptions),
    ]);
  }
}

class _Segments extends StatelessWidget {
  const _Segments({required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: Rd.r(Rd.md)),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == index,
              child: InkWell(
                borderRadius: Rd.r(Rd.sm),
                onTap: () => onChanged(i),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == index ? p.surface : Colors.transparent,
                    borderRadius: Rd.r(Rd.sm),
                    border: i == index ? Border.all(color: p.outline) : null,
                  ),
                  child: Text(labels[i], style: Theme.of(context).textTheme.labelLarge?.copyWith(color: i == index ? p.ink : p.inkMuted, fontSize: 13)),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.rows, required this.fmt});
  final List<ResultRow> rows;
  final Fmt fmt;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    if (rows.isEmpty) return const SizedBox.shrink();
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
      child: Column(children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, color: p.outline),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(rows[i].label, style: t.bodyMedium?.copyWith(color: p.inkMuted))),
              const SizedBox(width: Sp.md),
              Flexible(child: Text(fmt.value(rows[i]), textAlign: TextAlign.right, style: AppType.figure(p.ink, size: 15, w: FontWeight.w600))),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes({required this.def, required this.assumptions});
  final CalculatorDef def;
  final List<String> assumptions;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    Widget bullet(String s) => Padding(
          padding: const EdgeInsets.only(bottom: Sp.sm),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 8, right: 10), child: Container(width: 5, height: 5, decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle))),
            Expanded(child: Text(s, style: t.bodyMedium)),
          ]),
        );
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('What this calculates', style: t.titleSmall),
        const SizedBox(height: Sp.sm),
        Text(def.explains, style: t.bodyMedium),
        const SizedBox(height: Sp.lg),
        Text('Formula', style: t.titleSmall),
        const SizedBox(height: Sp.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Sp.md),
          decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: Rd.r(Rd.sm)),
          child: Text(def.formula.join('\n'), style: AppType.figure(p.ink, size: 12.5)),
        ),
        const SizedBox(height: Sp.lg),
        Text('Assumptions', style: t.titleSmall),
        const SizedBox(height: Sp.sm),
        for (final a in assumptions) bullet(a),
        bullet('Results are projections from the numbers you enter. They are not advice or a promise of future outcomes.'),
      ]),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.spec, required this.fmt});
  final ChartSpec spec;
  final Fmt fmt;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final colors = [p.accent, p.primary, p.inkMuted];
    // Emphasised series uses primary; others use accent / muted.
    Color colorFor(int i, Series s) => s.emphasis ? p.primary : (i == 0 ? p.accent : colors[2]);
    final bars = <LineChartBarData>[];
    for (var i = 0; i < spec.series.length; i++) {
      final s = spec.series[i];
      final c = colorFor(i, s);
      bars.add(LineChartBarData(
        spots: [for (var k = 0; k < s.xs.length; k++) FlSpot(s.xs[k], s.ys[k])],
        isCurved: false,
        color: c,
        barWidth: s.emphasis ? 3 : 2,
        dashArray: s.emphasis ? null : [6, 4],
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: s.emphasis && spec.series.length <= 2, color: c.withValues(alpha: 0.10)),
      ));
    }
    final allY = spec.series.expand((s) => s.ys);
    final minY = allY.reduce((a, b) => a < b ? a : b);
    final maxY = allY.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() * 0.08 + 1e-6;
    final maxX = spec.series.first.xs.last;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(Sp.sm, Sp.lg, Sp.lg, Sp.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: Sp.md, bottom: Sp.md),
          child: Wrap(spacing: Sp.lg, runSpacing: Sp.xs, children: [
            for (var i = 0; i < spec.series.length; i++)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: colorFor(i, spec.series[i]), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 6),
                Text(spec.series[i].name, style: t.bodySmall),
              ]),
          ]),
        ),
        SizedBox(
          height: 240,
          child: LineChart(LineChartData(
            minX: 0,
            maxX: maxX,
            minY: minY >= 0 ? 0 : minY - pad,
            maxY: maxY + pad,
            lineBarsData: bars,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: p.outline, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  getTitlesWidget: (v, meta) {
                    if (v == meta.min || v == meta.max) return const SizedBox.shrink();
                    return Padding(padding: const EdgeInsets.only(right: 6), child: Text(fmt.axis(v), style: AppType.figure(p.inkSubtle, size: 10.5), textAlign: TextAlign.right));
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: Text(spec.xLabel, style: t.labelSmall),
                axisNameSize: 20,
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: maxX <= 10 ? 1 : (maxX / 5).ceilToDouble(),
                  getTitlesWidget: (v, meta) => Padding(padding: const EdgeInsets.only(top: 6), child: Text(v.round().toString(), style: AppType.figure(p.inkSubtle, size: 10.5))),
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => p.navBg,
                getTooltipItems: (spots) => [
                  for (final s in spots)
                    LineTooltipItem(
                      '${spec.series[s.barIndex].name}\n${fmt.money(s.y)}',
                      const TextStyle(fontFamily: AppType.mono, fontSize: 11, color: Color(0xFFEAF0EC)),
                    ),
                ],
              ),
            ),
          )),
        ),
      ]),
    );
  }
}

class _ScheduleTable extends StatefulWidget {
  const _ScheduleTable({required this.schedule, required this.fmt});
  final Schedule schedule;
  final Fmt fmt;

  @override
  State<_ScheduleTable> createState() => _ScheduleTableState();
}

class _ScheduleTableState extends State<_ScheduleTable> {
  bool all = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final s = widget.schedule;
    final limit = all ? s.rows.length : (s.rows.length > 24 ? 24 : s.rows.length);
    TableRow row(List<String> cells, {bool head = false, bool alt = false}) => TableRow(
          decoration: BoxDecoration(color: head ? p.surfaceAlt : (alt ? p.surfaceAlt.withValues(alpha: 0.45) : null)),
          children: [
            for (var i = 0; i < cells.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  cells[i],
                  textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                  style: head ? t.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: p.ink) : AppType.figure(p.ink, size: 12.5),
                ),
              ),
          ],
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              row(s.columns, head: true),
              for (var r = 0; r < limit; r++)
                row([for (var c = 0; c < s.rows[r].length; c++) widget.fmt.scheduleCell(s.rows[r][c], c, s.firstColumnIsIndex)], alt: r.isOdd),
            ],
          ),
        ),
      ),
      if (s.rows.length > 24)
        Padding(
          padding: const EdgeInsets.only(top: Sp.md),
          child: OutlinedButton.icon(
            onPressed: () => setState(() => all = !all),
            icon: Icon(all ? PhosphorIconsRegular.caretRight : PhosphorIconsRegular.listBullets, size: 18),
            label: Text(all ? 'Show first 24 rows' : 'Show all ${s.rows.length} rows'),
          ),
        ),
    ]);
  }
}
