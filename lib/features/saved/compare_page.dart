import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../domain/calculators/catalog.dart';
import '../../domain/models/calc.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/common.dart';

/// Side-by-side comparison of two saved scenarios of the same calculator.
class ComparePage extends ConsumerWidget {
  const ComparePage({super.key, required this.a, required this.b});
  final Scenario a, b;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final fmt = ref.watch(fmtProvider);
    final def = calcById(a.calcId)!;

    String inputText(FieldDef f, Map<String, dynamic> m) {
      final v = m[f.id];
      if (v == null) return '–';
      if (f.kind == FieldKind.choice) return f.optionLabel(v as String);
      final d = (v as num).toDouble();
      return f.money ? fmt.money(d) : fmt.number(d);
    }

    final diffs = def.fields.where((f) => f.visible({...a.inputs}) && '${a.inputs[f.id]}' != '${b.inputs[f.id]}').toList();
    final rowsA = [a.primary, ...a.rows];
    final rowsB = {for (final r in [b.primary, ...b.rows]) r.label: r};

    Widget header() => Row(children: [
          const Expanded(flex: 4, child: SizedBox()),
          Expanded(flex: 3, child: Text(a.title, style: t.labelLarge, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text(b.title, style: t.labelLarge, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]);

    Widget line(String label, String x, String y, {bool hi = false, String? delta, bool? up}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 4, child: Text(label, style: t.bodySmall)),
              Expanded(flex: 3, child: Text(x, textAlign: TextAlign.right, style: AppType.figure(p.ink, size: 12.5))),
              Expanded(flex: 3, child: Text(y, textAlign: TextAlign.right, style: AppType.figure(hi ? p.primary : p.ink, size: 12.5, w: hi ? FontWeight.w600 : FontWeight.w500))),
            ]),
            if (delta != null)
              Align(alignment: Alignment.centerRight, child: Text('Change: $delta', style: t.labelSmall?.copyWith(color: up == null ? p.inkMuted : (up ? p.gain : p.loss), fontWeight: FontWeight.w600))),
          ]),
        );

    String signed(String s, double d) => d > 0 ? '+ $s' : (d < 0 ? '− $s' : s);

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(title: 'Compare · ${def.name}'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(Sp.page, Sp.sm, Sp.page, Sp.xxxl), children: [
              const SectionTitle('Inputs that differ'),
              AppCard(
                child: diffs.isEmpty
                    ? Text('Both scenarios use the same inputs.', style: t.bodyMedium)
                    : Column(children: [header(), const Divider(), for (final f in diffs) line(f.label, inputText(f, a.inputs), inputText(f, b.inputs), hi: true)]),
              ),
              const SectionTitle('Results'),
              AppCard(
                child: Column(children: [
                  header(),
                  const Divider(),
                  for (final ra in rowsA)
                    if (rowsB[ra.label] != null && ra.value != null && rowsB[ra.label]!.value != null)
                      Builder(builder: (_) {
                        final rb = rowsB[ra.label]!;
                        final d = rb.value! - ra.value!;
                        final changed = d.abs() > 1e-9;
                        final dText = signed(fmt.value(ResultRow(ra.label, d.abs(), kind: ra.kind)), d);
                        return line(ra.label, fmt.value(ra), fmt.value(rb), delta: changed ? dText : null, up: changed ? d > 0 : null);
                      }),
                ]),
              ),
              const SizedBox(height: Sp.lg),
              Text('Scenarios compared as saved. Different assumptions do not imply equal risk.', style: t.bodySmall),
            ]),
          ),
        ],
      ),
    );
  }
}
