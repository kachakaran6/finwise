import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../core/format.dart';
import '../../core/play_service.dart';
import '../../core/validation.dart';
import '../../domain/models/calc.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/keyboard_accessory_sheet.dart';
import '../../shared/widgets/result_view.dart';
import '../../theme/app_radius.dart';
import 'pdf_preview_screen.dart';

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
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, String> _choices = {};
  String? _focusedFieldId;
  bool _showAll = false;
  Scenario? _saved;

  /// Whether inputs have changed since last save / initial load.
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _saved = widget.existing;
    _load(widget.existing?.inputs);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(settingsProvider.notifier).pushRecent(widget.def.id));
  }

  void _load(Map<String, dynamic>? src) {
    for (final f in widget.def.fields) {
      final v =
          src != null && src.containsKey(f.id) ? src[f.id] : f.defaultValue;
      if (f.kind == FieldKind.choice) {
        _choices[f.id] = v is String ? v : f.defaultValue as String;
      } else {
        (_ctrl[f.id] ??= TextEditingController()).text = _initialText(v);
        if (!_focusNodes.containsKey(f.id)) {
          final fn = FocusNode();
          fn.addListener(() {
            if (fn.hasFocus) {
              if (_focusedFieldId != f.id) {
                setState(() => _focusedFieldId = f.id);
              }
            } else if (_focusedFieldId == f.id) {
              final anyFocused =
                  _focusNodes.values.any((node) => node.hasFocus);
              if (!anyFocused) {
                setState(() => _focusedFieldId = null);
              }
            }
          });
          _focusNodes[f.id] = fn;
        }
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    for (final fn in _focusNodes.values) {
      fn.dispose();
    }
    super.dispose();
  }

  InputState get _state => validateInputs(widget.def,
      {for (final e in _ctrl.entries) e.key: e.value.text}, _choices);

  void _reset() => setState(() {
        _dirty = false;
        _showAll = false;
        _load(null);
      });

  Future<void> _save(InputState st, CalcResult res) async {
    if (!st.valid) {
      setState(() => _showAll = true);
      toast(context, 'Fix the highlighted fields before saving.');
      return;
    }
    final title = await askText(context,
        title: _saved == null ? 'Save scenario' : 'Update scenario',
        initial: _saved?.title ?? widget.def.name,
        hint: 'Scenario name');
    if (title == null || !mounted) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final s = _saved == null
        ? Scenario(
            id: newId(),
            title: title,
            calcId: widget.def.id,
            inputs: Map<String, dynamic>.from(st.values),
            snapshot: res.toSnapshot(),
            createdAt: now,
            updatedAt: now)
        : _saved!.copyWith(
            title: title,
            inputs: Map<String, dynamic>.from(st.values),
            snapshot: res.toSnapshot(),
            updatedAt: now);
    await ref.read(scenariosProvider.notifier).save(s);
    PlayService.onScenarioSaved().ignore();
    if (!mounted) return;
    setState(() {
      _saved = s;
      _dirty = false;
    });
    toast(context, 'Saved.');
  }

  void _exportPdf(InputState st, CalcResult? result, Fmt fmt) {
    HapticFeedback.lightImpact();
    if (!st.valid || result == null) {
      setState(() => _showAll = true);
      toast(context, 'Complete all required fields to export the PDF report.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          def: widget.def,
          state: st,
          result: result,
          fmt: fmt,
        ),
      ),
    );
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    return confirm(
      context,
      title: 'Discard changes?',
      message: 'You have unsaved changes. Leave without saving?',
      action: 'Discard',
    );
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.def;
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final fmt = ref.watch(fmtProvider);
    final fav =
        ref.watch(settingsProvider.select((s) => s.favorites.contains(def.id)));
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

    final cur = fmt.currency.symbol.trim();
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    FieldDef? focusedField;
    List<num>? focusedPresets;
    if (_focusedFieldId != null) {
      for (final f in def.fields) {
        if (f.id == _focusedFieldId && f.visible(_choices)) {
          focusedField = f;
          focusedPresets = _getPresets(f);
          break;
        }
      }
    }

    final navigator = Navigator.of(context);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard();
        if (ok && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: p.bg,
        body: Column(
          children: [
            AppHeader(
              title: def.name,
              actions: [
                AppHeaderAction(
                  icon:
                      fav ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                  tooltip: fav ? 'Remove from favourites' : 'Add to favourites',
                  onPressed: () => ref
                      .read(settingsProvider.notifier)
                      .toggleFavorite(def.id),
                ),
                AppHeaderAction(
                  icon: PhosphorIconsRegular.filePdf,
                  tooltip: 'Export PDF Report',
                  onPressed: () => _exportPdf(st, result, fmt),
                ),
                AppHeaderAction(
                  icon: PhosphorIconsRegular.arrowCounterClockwise,
                  tooltip: 'Reset to defaults',
                  onPressed: _reset,
                ),
              ],
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      Sp.page, Sp.sm, Sp.page, Sp.xxxl),
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final f in def.fields)
                            if (f.visible(_choices))
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: f == def.fields.last ? 0 : Sp.lg,
                                ),
                                child: f.kind == FieldKind.choice
                                    ? _choiceField(f)
                                    : _numberField(f, st),
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Sp.xl),
                    if (result != null) ...[
                      ResultView(
                          key: ValueKey(def.id),
                          def: def,
                          result: result,
                          fmt: fmt),
                      const SizedBox(height: Sp.xl),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                        onPressed: () => _save(st, result!),
                        icon: Icon(
                            _saved == null
                                ? PhosphorIconsRegular.bookmarkSimple
                                : PhosphorIconsRegular.check,
                            size: 20),
                        label: Text(_saved == null
                            ? 'Save scenario'
                            : 'Update saved scenario'),
                      ),
                      const SizedBox(height: Sp.sm),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                          side: BorderSide(color: p.outline),
                          foregroundColor: p.ink,
                        ),
                        onPressed: () => _exportPdf(st, result, fmt),
                        icon:
                            const Icon(PhosphorIconsRegular.filePdf, size: 20),
                        label: const Text('Export PDF Report'),
                      ),
                    ] else
                      AppCard(
                        color: p.surfaceAlt,
                        child: Row(children: [
                          Icon(PhosphorIconsRegular.warningCircle,
                              color: error != null ? p.loss : p.inkMuted),
                          const SizedBox(width: Sp.md),
                          Expanded(
                              child: Text(
                                  error ??
                                      'Complete the highlighted fields to see the result.',
                                  style: t.bodyMedium)),
                        ]),
                      ),
                  ],
                ),
              ),
            ),
            if (focusedField != null &&
                focusedPresets != null &&
                (keyboardOpen ||
                    (_focusNodes[_focusedFieldId]?.hasFocus ?? false)))
              KeyboardAccessorySheet(
                fieldLabel: focusedField.label,
                presets: focusedPresets,
                currentValue: _ctrl[focusedField.id]?.text,
                formatLabel: (val) =>
                    _formatPresetLabel(focusedField!, val, cur),
                onSelect: (val) {
                  final text = val == val.roundToDouble()
                      ? val.toInt().toString()
                      : val.toString();
                  _ctrl[focusedField!.id]?.text = text;
                  _ctrl[focusedField.id]?.selection =
                      TextSelection.collapsed(offset: text.length);
                  setState(() => _dirty = true);
                },
              ),
          ],
        ),
      ),
    );
  }

  List<num>? _getPresets(FieldDef f) {
    if (f.money) return const [5000, 10000, 25000, 50000, 100000];
    if (f.id == 'rate' || f.id == 'aRate' || f.id == 'bRate') {
      return const [6, 8, 10, 12, 15];
    }
    if (f.id == 'years' ||
        f.id == 'yearsF' ||
        f.id == 'yearsP' ||
        f.id == 'yrs') {
      final unit = _choices['unit'];
      if (unit == 'days') return const [30, 90, 180, 365, 730];
      if (unit == 'months') return const [6, 12, 24, 36, 60];
      return const [3, 5, 10, 15, 20];
    }
    if (f.id == 'tenure') {
      final unit = _choices['unit'];
      if (unit == 'months') return const [12, 24, 36, 60, 120];
      return const [5, 10, 15, 20, 25];
    }
    if (f.id == 'stepup') {
      return const [5, 10, 15, 20];
    }
    if (f.id == 'inflation') {
      return const [4, 6, 8, 10];
    }
    if (f.id == 'nominal') {
      return const [8, 10, 12, 15];
    }
    if (f.id == 'pctA' || f.id == 'pctAdj') {
      return const [5, 10, 15, 18, 20, 28];
    }
    return null;
  }

  String _formatPresetLabel(FieldDef f, num val, String cur) {
    final effectiveSuffix = (f.id == 'years' && _choices.containsKey('unit'))
        ? _choices['unit']
        : f.suffix;
    if (f.money) {
      final s = val.toInt().toString();
      final withComma = s.length == 4
          ? '${s[0]},${s.substring(1)}'
          : (s.length == 5
              ? '${s.substring(0, 2)},${s.substring(2)}'
              : (s.length == 6
                  ? '${s[0]},${s.substring(1, 3)},${s.substring(3)}'
                  : s));
      return cur.isNotEmpty ? '$cur $withComma' : withComma;
    }
    if (effectiveSuffix != null && effectiveSuffix.isNotEmpty) {
      if (effectiveSuffix == '% per year' || effectiveSuffix == '%') {
        return '$val%';
      }
      return '$val $effectiveSuffix';
    }
    return '$val';
  }

  Widget _numberField(FieldDef f, InputState st) {
    final err = (_dirty || _showAll || (_ctrl[f.id]?.text.isNotEmpty ?? false))
        ? st.errors[f.id]
        : null;
    final p = context.pal;
    final cur = ref.read(fmtProvider).currency.symbol.trim();
    final allowNeg = (f.min ?? 0) < 0;
    final effectiveSuffix = (f.id == 'years' && _choices.containsKey('unit'))
        ? _choices['unit']
        : f.suffix;

    return TextField(
      controller: _ctrl[f.id],
      focusNode: _focusNodes[f.id],
      keyboardType:
          TextInputType.numberWithOptions(decimal: true, signed: allowNeg),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            RegExp(allowNeg ? r'[0-9.\-]' : r'[0-9.]'))
      ],
      onChanged: (_) => setState(() => _dirty = true),
      style: AppType.figure(p.ink, size: 16),
      decoration: InputDecoration(
        labelText: f.label,
        helperText: f.help,
        helperMaxLines: 3,
        errorText: err,
        prefixText: f.money && cur.isNotEmpty ? '$cur ' : null,
        prefixStyle: TextStyle(
            fontFamily: AppType.mono,
            fontSize: 16,
            color: p.inkMuted,
            fontWeight: FontWeight.w600),
        suffixText: effectiveSuffix,
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
        final v = await pickOne(context,
            title: f.label, options: f.options, selected: value);
        if (v != null) {
          setState(() {
            _choices[f.id] = v;
            _dirty = true;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: f.label,
          helperText: f.help,
          helperMaxLines: 3,
          suffixIcon:
              Icon(PhosphorIconsRegular.caretDown, size: 18, color: p.inkMuted),
        ),
        child: Text(f.optionLabel(value),
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w500)),
      ),
    );
  }
}
