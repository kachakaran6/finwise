import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../core/validation.dart';
import '../../domain/models/calc.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/result_view.dart';

String _initialText(Object? v) {
  if (v is! num) return '';
  return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key, required this.def, this.existing});
  final CalculatorDef def;
  final Scenario? existing;

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final Map<String, TextEditingController> _ctrl = {};
  final Map<String, String> _choices = {};
  final Set<String> _dirty = {};
  bool _showAll = false;
  Scenario? _saved;

  @override
  void initState() {
    super.initState();
    _saved = widget.existing;
    _load(widget.existing?.inputs);
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(settingsProvider.notifier).pushRecent(widget.def.id));
  }

  void _load(Map<String, dynamic>? src) {
    for (final f in widget.def.fields) {
      final v = src != null && src.containsKey(f.id) ? src[f.id] : f.defaultValue;
      if (f.kind == FieldKind.choice) {
        _choices[f.id] = v is String ? v : f.defaultValue as String;
      } else {
        (_ctrl[f.id] ??= TextEditingController()).text = _initialText(v);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  InputState get _state => validateInputs(widget.def, {for (final e in _ctrl.entries) e.key: e.value.text}, _choices);

  void _reset() => setState(() {
        _dirty.clear();
        _showAll = false;
        _load(null);
      });

  Future<void> _save(InputState st, CalcResult res) async {
    if (!st.valid) {
      setState(() => _showAll = true);
      toast(context, 'Fix the highlighted fields before saving.');
      return;
    }
    final title = await askText(context, title: _saved == null ? 'Save scenario' : 'Update scenario', initial: _saved?.title ?? widget.def.name, hint: 'Scenario name');
    if (title == null || !mounted) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final s = _saved == null
        ? Scenario(id: newId(), title: title, calcId: widget.def.id, inputs: Map<String, dynamic>.from(st.values), snapshot: res.toSnapshot(), createdAt: now, updatedAt: now)
        : _saved!.copyWith(title: title, inputs: Map<String, dynamic>.from(st.values), snapshot: res.toSnapshot(), updatedAt: now);
    await ref.read(scenariosProvider.notifier).save(s);
    if (!mounted) return;
    setState(() => _saved = s);
    toast(context, 'Saved on this device.');
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.def;
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final fmt = ref.watch(fmtProvider);
    final fav = ref.watch(settingsProvider.select((s) => s.favorites.contains(def.id)));
    final st = _state;

    CalcResult? result;
    String? error;
    if (st.valid) {
      try {
        result = def.compute(CalcInputs(st.values));
      } on CalcException catch (e) {
        error = e.message;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(def.name),
        actions: [
          IconButton(
            tooltip: fav ? 'Remove from favourites' : 'Add to favourites',
            icon: Icon(fav ? PhosphorIconsFill.star : PhosphorIconsRegular.star, color: fav ? p.accent : p.ink),
            onPressed: () => ref.read(settingsProvider.notifier).toggleFavorite(def.id),
          ),
          IconButton(tooltip: 'Reset to defaults', icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise), onPressed: _reset),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Sp.page, Sp.sm, Sp.page, Sp.xxxl),
          children: [
            Text(def.explains, style: t.bodyMedium?.copyWith(color: p.inkMuted)),
            const SizedBox(height: Sp.lg),
            AppCard(
              child: Column(children: [
                for (final f in def.fields)
                  if (f.visible(_choices))
                    Padding(
                      padding: const EdgeInsets.only(bottom: Sp.lg),
                      child: f.kind == FieldKind.choice ? _choiceField(f) : _numberField(f, st),
                    ),
              ]),
            ),
            const SizedBox(height: Sp.xl),
            if (result != null) ...[
              ResultView(key: ValueKey(def.id), def: def, result: result, fmt: fmt),
              const SizedBox(height: Sp.xl),
              FilledButton.icon(
                onPressed: () => _save(st, result!),
                icon: Icon(_saved == null ? PhosphorIconsRegular.floppyDisk : PhosphorIconsRegular.check, size: 20),
                label: Text(_saved == null ? 'Save scenario' : 'Update saved scenario'),
              ),
            ] else
              AppCard(
                color: p.surfaceAlt,
                child: Row(children: [
                  Icon(PhosphorIconsRegular.warningCircle, color: error != null ? p.loss : p.inkMuted),
                  const SizedBox(width: Sp.md),
                  Expanded(child: Text(error ?? 'Complete the highlighted fields to see the result.', style: t.bodyMedium)),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(FieldDef f, InputState st) {
    final err = (_dirty.contains(f.id) || _showAll || _ctrl[f.id]!.text.isNotEmpty) ? st.errors[f.id] : null;
    final p = context.pal;
    final cur = ref.read(fmtProvider).currency.symbol.trim();
    final allowNeg = (f.min ?? 0) < 0;
    return TextField(
      controller: _ctrl[f.id],
      keyboardType: TextInputType.numberWithOptions(decimal: true, signed: allowNeg),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(allowNeg ? r'[0-9.\-]' : r'[0-9.]'))],
      onChanged: (_) => setState(() => _dirty.add(f.id)),
      style: AppType.figure(p.ink, size: 16),
      decoration: InputDecoration(
        labelText: f.label,
        helperText: f.help,
        helperMaxLines: 3,
        errorText: err,
        prefixText: f.money && cur.isNotEmpty ? '$cur ' : null,
        suffixText: f.suffix,
        suffixStyle: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _choiceField(FieldDef f) {
    final p = context.pal;
    final value = _choices[f.id]!;
    return InkWell(
      borderRadius: Rd.r(Rd.md),
      onTap: () async {
        final v = await pickOne(context, title: f.label, options: f.options, selected: value);
        if (v != null) setState(() => _choices[f.id] = v);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: f.label, helperText: f.help, helperMaxLines: 3, suffixIcon: Icon(PhosphorIconsRegular.caretDown, size: 18, color: p.inkMuted)),
        child: Text(f.optionLabel(value), style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
