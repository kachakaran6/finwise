import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../domain/calculators/catalog.dart';
import '../../domain/models/calc.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/common.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../custom_studio/domain/models/custom_input_def.dart';

class _DiffItem {
  const _DiffItem({required this.label, required this.textA, required this.textB});
  final String label;
  final String textA;
  final String textB;
}

/// Side-by-side comparison of two saved scenarios of the same calculator.
/// Displays scenario overviews, differing inputs, and full result metric deltas
/// without misleading or colored gain/loss badge assumptions.
class ComparePage extends ConsumerWidget {
  const ComparePage({super.key, required this.a, required this.b});
  final Scenario a, b;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final fmt = ref.watch(fmtProvider);
    final isCustom = a.calcId.startsWith('custom_');
    final def = isCustom ? null : calcById(a.calcId);
    final customCalcs = ref.watch(customCalcsProvider).valueOrNull ?? const [];
    final customId = isCustom ? a.calcId.replaceFirst('custom_', '') : null;
    final customDef = isCustom
        ? customCalcs.where((c) => c.id == customId).firstOrNull
        : null;
    final calcName = def?.name ?? customDef?.name ?? 'Custom Calculator';
    final df = DateFormat.yMMMd();

    String inputText(FieldDef f, Map<String, dynamic> m) {
      final v = m[f.id];
      if (v == null) return '–';
      if (f.kind == FieldKind.choice) return f.optionLabel(v as String);
      final d = (v as num).toDouble();
      return f.money ? fmt.money(d) : fmt.number(d);
    }

    String customInputText(CustomInputDef f, Map<String, dynamic> m) {
      final v = m[f.id];
      if (v == null) return '–';
      if (v is num) {
        final d = v.toDouble();
        if (f.type == CustomInputType.currency) return fmt.money(d);
        if (f.type == CustomInputType.percentage) return fmt.percent(d);
        return fmt.number(d);
      }
      return v.toString();
    }

    final List<_DiffItem> diffs;
    if (def != null) {
      diffs = def.fields
          .where((f) =>
              f.visible({...a.inputs}) && '${a.inputs[f.id]}' != '${b.inputs[f.id]}')
          .map((f) => _DiffItem(
                label: f.label,
                textA: inputText(f, a.inputs),
                textB: inputText(f, b.inputs),
              ))
          .toList();
    } else if (customDef != null) {
      diffs = customDef.inputs
          .where((f) =>
              f.isComputational &&
              '${a.inputs[f.id]}' != '${b.inputs[f.id]}')
          .map((f) => _DiffItem(
                label: f.label,
                textA: customInputText(f, a.inputs),
                textB: customInputText(f, b.inputs),
              ))
          .toList();
    } else {
      final allKeys = {...a.inputs.keys, ...b.inputs.keys};
      diffs = allKeys
          .where((k) => '${a.inputs[k]}' != '${b.inputs[k]}')
          .map((k) {
            String formatVal(dynamic v) {
              if (v == null) return '–';
              if (v is num) return fmt.number(v.toDouble());
              return v.toString();
            }
            return _DiffItem(
              label: k,
              textA: formatVal(a.inputs[k]),
              textB: formatVal(b.inputs[k]),
            );
          })
          .toList();
    }

    final rowsA = [a.primary, ...a.rows];
    final rowsB = {for (final r in [b.primary, ...b.rows]) r.label: r};

    String signedDiff(String formattedValue, double delta) {
      if (delta > 0) return '+$formattedValue';
      if (delta < 0) return '−$formattedValue';
      return '0';
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(title: 'Compare · $calcName'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                AppSpacing.xxxl,
              ),
              children: [
                // Top scenario identifier cards
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SCENARIO A',
                              style: TextStyle(
                                fontFamily: AppType.sans,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: p.inkSubtle,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.title,
                              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              df.format(DateTime.fromMillisecondsSinceEpoch(a.updatedAt)),
                              style: t.bodySmall?.copyWith(color: p.inkMuted, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fmt.value(a.primary),
                              style: AppType.figure(p.ink, size: 15, w: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SCENARIO B',
                              style: TextStyle(
                                fontFamily: AppType.sans,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: p.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              b.title,
                              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              df.format(DateTime.fromMillisecondsSinceEpoch(b.updatedAt)),
                              style: t.bodySmall?.copyWith(color: p.inkMuted, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fmt.value(b.primary),
                              style: AppType.figure(p.primary, size: 15, w: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SectionTitle('Inputs that differ'),
                AppCard(
                  child: diffs.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          child: Text(
                            'Both scenarios use identical input parameters.',
                            style: t.bodyMedium?.copyWith(color: p.inkMuted),
                          ),
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text('Parameter', style: t.labelSmall?.copyWith(color: p.inkSubtle)),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text('A', textAlign: TextAlign.right, style: t.labelSmall?.copyWith(color: p.inkSubtle, fontWeight: FontWeight.w600)),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text('B', textAlign: TextAlign.right, style: t.labelSmall?.copyWith(color: p.primary, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            for (int i = 0; i < diffs.length; i++) ...[
                              if (i > 0) Divider(height: 1, color: p.outline.withValues(alpha: 0.5)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        diffs[i].label,
                                        style: t.bodySmall?.copyWith(color: p.inkMuted, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        diffs[i].textA,
                                        textAlign: TextAlign.right,
                                        style: AppType.figure(p.ink, size: 13),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        diffs[i].textB,
                                        textAlign: TextAlign.right,
                                        style: AppType.figure(p.primary, size: 13, w: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                ),

                const SectionTitle('Result metrics'),
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text('Metric', style: t.labelSmall?.copyWith(color: p.inkSubtle)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('A', textAlign: TextAlign.right, style: t.labelSmall?.copyWith(color: p.inkSubtle, fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('B', textAlign: TextAlign.right, style: t.labelSmall?.copyWith(color: p.primary, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      for (int i = 0; i < rowsA.length; i++) ...[
                        if (rowsB[rowsA[i].label] != null &&
                            rowsA[i].value != null &&
                            rowsB[rowsA[i].label]!.value != null)
                          Builder(builder: (_) {
                            final ra = rowsA[i];
                            final rb = rowsB[ra.label]!;
                            final d = rb.value! - ra.value!;
                            final changed = d.abs() > 1e-9;
                            final deltaText = signedDiff(fmt.value(ResultRow(ra.label, d.abs(), kind: ra.kind)), d);
                            final isPrimary = i == 0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Text(
                                          ra.label,
                                          style: t.bodySmall?.copyWith(
                                            color: isPrimary ? p.ink : p.inkMuted,
                                            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          fmt.value(ra),
                                          textAlign: TextAlign.right,
                                          style: AppType.figure(p.ink, size: isPrimary ? 14 : 13),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          fmt.value(rb),
                                          textAlign: TextAlign.right,
                                          style: AppType.figure(
                                            isPrimary ? p.primary : p.ink,
                                            size: isPrimary ? 14 : 13,
                                            w: isPrimary ? FontWeight.w700 : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (changed) ...[
                                    const SizedBox(height: 3),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: p.surfaceAlt,
                                          borderRadius: BorderRadius.circular(AppRadius.xs),
                                          border: Border.all(color: p.outline.withValues(alpha: 0.6)),
                                        ),
                                        child: Text(
                                          'Diff: $deltaText',
                                          style: TextStyle(
                                            fontFamily: AppType.mono,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: p.inkMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (i < rowsA.length - 1)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Divider(height: 1, color: p.outline.withValues(alpha: 0.4)),
                                    ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Scenarios are compared strictly as saved. Differences reflect distinct inputs and assumptions.',
                  style: t.bodySmall?.copyWith(color: p.inkSubtle),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
