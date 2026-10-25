import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/tokens.dart';
import '../../core/format.dart';
import '../../domain/models/calc.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_elevation.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.result;
    final tabs = <String>['Summary', if (r.chart != null) 'Chart', if (r.schedule != null) 'Schedule', 'Notes'];
    if (tab >= tabs.length) tab = 0;
    final current = tabs[tab];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Result Card: primary container, radius 20, e2, big value onPrimary
      Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: p.primary,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: isDark ? AppElevation.e2Dark : AppElevation.e2Light,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  r.primary.label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppType.sans,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.onPrimary,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Icon(PhosphorIconsRegular.trendUp, size: 20, color: p.onPrimary.withValues(alpha: 0.85)),
            ],
          ),
          const SizedBox(height: Sp.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              widget.fmt.value(r.primary),
              style: AppType.figure(p.onPrimary, size: 36, w: FontWeight.w700),
            ),
          ),
          if (r.rows.length >= 2 && r.rows[0].value != null && r.rows[1].value != null) ...[
            const SizedBox(height: Sp.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.rows[0].label,
                          style: TextStyle(color: p.onPrimary.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.fmt.value(r.rows[0]),
                          style: AppType.figure(p.onPrimary, size: 14, w: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: p.onPrimary.withValues(alpha: 0.2)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.rows[1].label,
                          style: TextStyle(color: p.onPrimary.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.fmt.value(r.rows[1]),
                          style: AppType.figure(p.onPrimary, size: 14, w: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ]),
      ),
      const SizedBox(height: Sp.lg),
      _Segments(labels: tabs, index: tab, onChanged: (i) => setState(() => tab = i)),
      const SizedBox(height: Sp.lg),
      if (current == 'Summary') _Breakdown(rows: r.rows, fmt: widget.fmt),
      if (current == 'Chart') _Chart(spec: r.chart!, fmt: widget.fmt, rows: r.rows),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: p.outline, width: 1),
      ),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == index,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == index
                        ? p.primary.withValues(alpha: isDark ? 0.22 : 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: (i == index && !isDark) ? AppElevation.e1Light : null,
                    border: i == index
                        ? Border.all(color: p.primary.withValues(alpha: 0.35), width: 1)
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: i == index ? p.primary : p.inkMuted,
                          fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                  ),
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

    final colors = [
      AppColors.indigo,
      AppColors.brand500,
      AppColors.warning,
      AppColors.purple,
      AppColors.cyan,
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.sm),
      child: Column(children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, color: p.outline.withValues(alpha: 0.7)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: colors[i % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Sp.md),
              Expanded(
                child: Text(
                  rows[i].label,
                  style: t.bodyMedium?.copyWith(color: p.inkMuted, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: Sp.md),
              Flexible(
                child: Text(
                  fmt.value(rows[i]),
                  textAlign: TextAlign.right,
                  style: AppType.figure(p.ink, size: 15, w: FontWeight.w700),
                ),
              ),
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
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 10),
              child: Container(width: 5, height: 5, decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle)),
            ),
            Expanded(child: Text(s, style: t.bodyMedium)),
          ]),
        );
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('What this calculates', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: Sp.sm),
        Text(def.explains, style: t.bodyMedium?.copyWith(height: 1.45)),
        const SizedBox(height: Sp.lg),
        Text('Formula', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: Sp.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Sp.md),
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: Rd.r(Rd.md),
            border: Border.all(color: p.outline.withValues(alpha: 0.6)),
          ),
          child: Text(def.formula.join('\n'), style: AppType.figure(p.ink, size: 12.5)),
        ),
        const SizedBox(height: Sp.lg),
        Text('Assumptions', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: Sp.sm),
        for (final a in assumptions) bullet(a),
        bullet('Results are projections from the numbers you enter. They are not advice or a promise of future outcomes.'),
      ]),
    );
  }
}

class _Chart extends StatefulWidget {
  const _Chart({required this.spec, required this.fmt, required this.rows});
  final ChartSpec spec;
  final Fmt fmt;
  final List<ResultRow> rows;

  @override
  State<_Chart> createState() => _ChartState();
}

class _ChartState extends State<_Chart> {
  int _viewMode = 0; // 0 = Line Growth Curve, 1 = Donut Allocation

  static const _donutColors = [
    AppColors.indigo,
    AppColors.brand500,
    AppColors.warning,
    AppColors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final spec = widget.spec;

    // Filter positive money rows for Donut breakdown
    final validRows = widget.rows
        .where((r) => r.kind == ValueKind.money && r.value != null && r.value! > 0)
        .toList();
    final hasDonut = validRows.length >= 2;
    final total = validRows.fold<double>(0, (sum, r) => sum + r.value!);

    // Series colors for line chart
    Color colorFor(int i, Series s) => s.emphasis ? p.primary : p.inkMuted;

    final bars = <LineChartBarData>[];
    for (var i = 0; i < spec.series.length; i++) {
      final s = spec.series[i];
      final c = colorFor(i, s);
      bars.add(LineChartBarData(
        spots: [for (var k = 0; k < s.xs.length; k++) FlSpot(s.xs[k], s.ys[k])],
        isCurved: true,
        curveSmoothness: 0.3,
        color: c,
        barWidth: s.emphasis ? 3.2 : 2.0,
        dashArray: s.emphasis ? null : [6, 4],
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: s.emphasis,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              c.withValues(alpha: 0.24),
              c.withValues(alpha: 0.0),
            ],
          ),
        ),
      ));
    }

    final allY = spec.series.expand((s) => s.ys);
    final minY = allY.reduce((a, b) => a < b ? a : b);
    final maxY = allY.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() * 0.08 + 1e-6;
    final maxX = spec.series.first.xs.last;

    return AppCard(
      padding: const EdgeInsets.all(Sp.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Mode toggle if Donut chart is available
        if (hasDonut) ...[
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => setState(() => _viewMode = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _viewMode == 0 ? p.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _viewMode == 0
                            ? [BoxShadow(color: p.shadow.withValues(alpha: 0.06), blurRadius: 4)]
                            : null,
                      ),
                      child: Text(
                        'Growth Curve',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _viewMode == 0 ? FontWeight.w700 : FontWeight.w500,
                          color: _viewMode == 0 ? p.ink : p.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => setState(() => _viewMode = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _viewMode == 1 ? p.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _viewMode == 1
                            ? [BoxShadow(color: p.shadow.withValues(alpha: 0.06), blurRadius: 4)]
                            : null,
                      ),
                      child: Text(
                        'Allocation Donut',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _viewMode == 1 ? FontWeight.w700 : FontWeight.w500,
                          color: _viewMode == 1 ? p.ink : p.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Sp.lg),
        ],

        if (_viewMode == 1 && hasDonut) ...[
          // Donut Pie Chart Breakdown
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 48,
                sections: [
                  for (var i = 0; i < validRows.length; i++)
                    PieChartSectionData(
                      color: _donutColors[i % _donutColors.length],
                      value: validRows[i].value!,
                      title: '${((validRows[i].value! / total) * 100).round()}%',
                      radius: 36,
                      titleStyle: const TextStyle(
                        fontFamily: AppType.mono,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Sp.lg),
          // Legend list
          for (var i = 0; i < validRows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _donutColors[i % _donutColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: Text(validRows[i].label, style: t.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                  ),
                  Text(
                    widget.fmt.value(validRows[i]),
                    style: AppType.figure(p.ink, size: 13.5, w: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _donutColors[i % _donutColors.length].withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${((validRows[i].value! / total) * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: AppType.mono,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _donutColors[i % _donutColors.length],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ] else ...[
          // Interactive Curved Line Chart
          Wrap(spacing: Sp.lg, runSpacing: Sp.xs, children: [
            for (var i = 0; i < spec.series.length; i++)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: colorFor(i, spec.series[i]), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 6),
                Text(spec.series[i].name, style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              ]),
          ]),
          const SizedBox(height: Sp.md),
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
                getDrawingHorizontalLine: (_) => FlLine(color: p.outline.withValues(alpha: 0.8), strokeWidth: 1),
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
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(widget.fmt.axis(v), style: AppType.figure(p.inkSubtle, size: 10.5), textAlign: TextAlign.right),
                      );
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
                    getTitlesWidget: (v, meta) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(v.round().toString(), style: AppType.figure(p.inkSubtle, size: 10.5)),
                    ),
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => p.surface,
                  tooltipBorder: BorderSide(color: p.outline, width: 1),
                  getTooltipItems: (spots) => [
                    for (final s in spots)
                      LineTooltipItem(
                        '${spec.series[s.barIndex].name}\n${widget.fmt.money(s.y)}',
                        TextStyle(fontFamily: AppType.mono, fontSize: 11, fontWeight: FontWeight.w600, color: p.ink),
                      ),
                  ],
                ),
              ),
            )),
          ),
        ],
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Text(
                  cells[i],
                  textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                  style: head ? t.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: p.ink) : AppType.figure(p.ink, size: 12.5),
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

