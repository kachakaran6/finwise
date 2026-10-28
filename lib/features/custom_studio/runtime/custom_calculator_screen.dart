import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/format.dart';
import '../../../core/validation.dart';
import '../../../domain/models/calc.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/keyboard_accessory_sheet.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../calculator/pdf_preview_screen.dart';
import '../domain/models/custom_calc_definition.dart';
import '../domain/models/custom_input_def.dart';
import '../domain/models/custom_output_def.dart';
import 'custom_calculator_runtime.dart';

class CustomCalculatorScreen extends ConsumerStatefulWidget {
  const CustomCalculatorScreen({
    super.key,
    required this.definition,
    this.existingScenario,
  });

  final CustomCalcDefinition definition;
  final Scenario? existingScenario;

  @override
  ConsumerState<CustomCalculatorScreen> createState() =>
      _CustomCalculatorScreenState();
}

class _CustomCalculatorScreenState
    extends ConsumerState<CustomCalculatorScreen> {
  final Map<String, TextEditingController> _ctrl = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, double> _inputValues = {};
  final Map<String, String> _dropdownSelections = {};
  String? _focusedFieldId;
  bool _dirty = false;
  Scenario? _saved;

  @override
  void initState() {
    super.initState();
    _saved = widget.existingScenario;
    _initializeInputs(widget.existingScenario?.inputs);
  }

  void _initializeInputs(Map<String, dynamic>? initial) {
    for (final input in widget.definition.inputs) {
      if (!input.isComputational) continue;

      double val = input.defaultValue ?? 0.0;
      if (initial != null && initial.containsKey(input.id)) {
        final raw = initial[input.id];
        if (raw is num) val = raw.toDouble();
      }

      _inputValues[input.id] = val;

      if (input.type == CustomInputType.dropdown) {
        final defaultOption = input.options.isNotEmpty
            ? input.options.first.value
            : '0';
        _dropdownSelections[input.id] = initial?[input.id]?.toString() ?? defaultOption;
        _inputValues[input.id] =
            double.tryParse(_dropdownSelections[input.id]!) ?? 0.0;
      } else if (input.type != CustomInputType.toggle) {
        final text = val == val.roundToDouble()
            ? val.toInt().toString()
            : val.toString();
        (_ctrl[input.id] ??= TextEditingController()).text = text;

        if (!_focusNodes.containsKey(input.id)) {
          final fn = FocusNode();
          fn.addListener(() {
            if (fn.hasFocus) {
              if (_focusedFieldId != input.id) {
                setState(() => _focusedFieldId = input.id);
              }
            } else if (_focusedFieldId == input.id) {
              final anyFocused =
                  _focusNodes.values.any((node) => node.hasFocus);
              if (!anyFocused) {
                setState(() => _focusedFieldId = null);
              }
            }
          });
          _focusNodes[input.id] = fn;
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

  void _reset() => setState(() {
        _dirty = false;
        _initializeInputs(null);
      });

  Future<void> _saveScenario(
    CustomCalcExecutionResult execResult,
    Fmt fmt,
  ) async {
    if (execResult.hasErrors) {
      toast(context, 'Resolve calculation errors before saving.');
      return;
    }

    final title = await askText(
      context,
      title: _saved == null ? 'Save scenario' : 'Update scenario',
      initial: _saved?.title ?? widget.definition.name,
      hint: 'Scenario name',
    );
    if (title == null || !mounted) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final primaryOut = execResult.primaryOutput;
    final primaryVal = execResult.primaryValue ?? 0.0;
    final formattedPrimary = primaryOut != null
        ? _formatValue(primaryVal, primaryOut, fmt)
        : fmt.money(primaryVal);

    final snapshot = <String, dynamic>{
      'primary_label': primaryOut?.label ?? 'Result',
      'primary_value': formattedPrimary,
      'outputs': {
        for (final o in execResult.outputs)
          o.def.label: o.value != null
              ? _formatValue(o.value!, o.def, fmt)
              : (o.errorMessage ?? '-')
      },
    };

    final s = _saved == null
        ? Scenario(
            id: newId(),
            title: title,
            calcId: 'custom_${widget.definition.id}',
            inputs: Map<String, dynamic>.from(_inputValues),
            snapshot: snapshot,
            createdAt: now,
            updatedAt: now,
          )
        : _saved!.copyWith(
            title: title,
            inputs: Map<String, dynamic>.from(_inputValues),
            snapshot: snapshot,
            updatedAt: now,
          );

    await ref.read(scenariosProvider.notifier).save(s);
    if (!mounted) return;
    setState(() {
      _saved = s;
      _dirty = false;
    });
    toast(context, 'Saved.');
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

  void _exportPdf(CustomCalcExecutionResult execResult, Fmt fmt) {
    if (execResult.hasErrors || execResult.primaryValue == null) {
      toast(context, 'Complete all inputs to generate the PDF report.');
      return;
    }

    final primaryOut = execResult.primaryOutput;
    final pdfResult = CalcResult(
      primary: ResultRow(
        primaryOut?.label ?? 'Primary Result',
        execResult.primaryValue ?? 0.0,
        kind: _valueKindForOutput(primaryOut?.kind),
      ),
      rows: execResult.outputs
          .map((o) => ResultRow(
                o.def.label,
                o.value ?? 0.0,
                kind: _valueKindForOutput(o.def.kind),
              ))
          .toList(),
      assumptions: [
        if (widget.definition.description.isNotEmpty)
          widget.definition.description,
        'Created with Finwise Custom Calculator Studio.',
      ],
    );

    // Adapt to standard CalculatorDef & CalcResult for the PDF generator
    final pdfCalcDef = CalculatorDef(
      id: 'custom_${widget.definition.id}',
      code: 'CUSTOM',
      name: widget.definition.name,
      category: CalcCategory.planning,
      summary: widget.definition.description,
      explains: widget.definition.description,
      formula: widget.definition.outputs
          .map((o) => '${o.label} = ${o.formula}')
          .toList(),
      fields: widget.definition.inputs
          .where((i) => i.isComputational)
          .map((i) => FieldDef(
                id: i.id,
                label: i.label,
                money: i.type == CustomInputType.currency,
                defaultValue: i.defaultValue ?? 0,
                suffix: i.suffix,
              ))
          .toList(),
      compute: (_) => pdfResult,
    );

    final inputState = InputState(
      {for (final e in _inputValues.entries) e.key: e.value},
      const {},
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          def: pdfCalcDef,
          state: inputState,
          result: pdfResult,
          fmt: fmt,
        ),
      ),
    );
  }

  ValueKind _valueKindForOutput(CustomOutputKind? kind) {
    switch (kind) {
      case CustomOutputKind.currency:
        return ValueKind.money;
      case CustomOutputKind.percentage:
        return ValueKind.percent;
      case CustomOutputKind.number:
      case null:
        return ValueKind.number;
    }
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.definition;
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final fmt = ref.watch(fmtProvider);
    final cur = fmt.currency.symbol.trim();
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final execResult = CustomCalculatorRuntime.compute(
      definition: def,
      rawInputs: _inputValues,
    );

    CustomInputDef? focusedInput;
    List<num>? focusedPresets;
    if (_focusedFieldId != null) {
      for (final input in def.inputs) {
        if (input.id == _focusedFieldId) {
          focusedInput = input;
          focusedPresets = _getPresets(input);
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
                icon: PhosphorIconsRegular.filePdf,
                tooltip: 'Export PDF',
                onPressed: () => _exportPdf(execResult, fmt),
              ),
              AppHeaderAction(
                icon: PhosphorIconsRegular.arrowCounterClockwise,
                tooltip: 'Reset',
                onPressed: _reset,
              ),
            ],
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.translucent,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.md,
                    AppSpacing.screen,
                    AppSpacing.bottomNavClearance(context),
                  ),
                  children: [
                    if (def.description.isNotEmpty) ...[
                      Text(
                        def.description,
                        style: t.bodyMedium?.copyWith(color: p.inkSubtle),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < def.inputs.length; i++) ...[
                            if (i > 0)
                              const SizedBox(height: AppSpacing.md),
                            _buildInputWidget(def.inputs[i], cur),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildResultsSection(execResult, fmt),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: () => _saveScenario(execResult, fmt),
                      icon: Icon(
                        _saved == null
                            ? PhosphorIconsRegular.bookmarkSimple
                            : PhosphorIconsRegular.check,
                        size: 20,
                      ),
                      label: Text(
                        _saved == null ? 'Save scenario' : 'Update saved scenario',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (keyboardOpen && focusedInput != null && focusedPresets != null)
            KeyboardAccessorySheet(
              fieldLabel: focusedInput.label,
              presets: focusedPresets,
              currentValue: _ctrl[focusedInput.id]?.text,
              formatLabel: (val) => _formatPreset(focusedInput!, val, cur),
              onSelect: (val) {
                final text = val == val.roundToDouble()
                    ? val.toInt().toString()
                    : val.toString();
                _ctrl[focusedInput!.id]?.text = text;
                _inputValues[focusedInput.id] = val.toDouble();
                setState(() => _dirty = true);
              },
            ),
        ],
      ),
    ),
    );
  }

  Widget _buildInputWidget(CustomInputDef input, String cur) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;

    switch (input.type) {
      case CustomInputType.sectionHeader:
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            input.label.toUpperCase(),
            style: t.labelSmall?.copyWith(
              color: p.inkSubtle,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        );

      case CustomInputType.infoBlock:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: p.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIconsRegular.info, size: 18, color: p.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  input.infoText ?? input.label,
                  style: t.bodySmall?.copyWith(color: p.inkMuted),
                ),
              ),
            ],
          ),
        );

      case CustomInputType.toggle:
        final active = (_inputValues[input.id] ?? 0.0) == 1.0;
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(input.label, style: t.bodyLarge),
          subtitle: input.description != null
              ? Text(input.description!, style: t.bodySmall)
              : null,
          value: active,
          onChanged: (v) {
            setState(() {
              _inputValues[input.id] = v ? 1.0 : 0.0;
              _dirty = true;
            });
          },
        );

      case CustomInputType.slider:
        final min = input.min ?? 0.0;
        final max = input.max ?? 100.0;
        final currentVal = (_inputValues[input.id] ?? min).clamp(min, max);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(input.label, style: t.bodyMedium),
                Text(
                  '${currentVal.toStringAsFixed(1)} ${input.suffix ?? ""}',
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Slider.adaptive(
              value: currentVal,
              min: min,
              max: max,
              divisions: ((max - min) / (input.step ?? 1.0)).round(),
              onChanged: (v) {
                setState(() {
                  _inputValues[input.id] = v;
                  _dirty = true;
                });
              },
            ),
          ],
        );

      case CustomInputType.dropdown:
        final selectedVal = _dropdownSelections[input.id] ?? '';
        final displayLabel = input.options
            .firstWhere(
              (o) => o.value == selectedVal,
              orElse: () => CustomChoiceOption(value: selectedVal, label: selectedVal),
            )
            .label;

        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () async {
            final options = input.options
                .map((o) => ChoiceOption(o.value, o.label))
                .toList();
            final v = await pickOne(
              context,
              title: input.label,
              options: options,
              selected: selectedVal,
            );
            if (v != null) {
              setState(() {
                _dropdownSelections[input.id] = v;
                _inputValues[input.id] = double.tryParse(v) ?? 0.0;
                _dirty = true;
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: input.label,
              helperText: input.description,
              suffixIcon: const Icon(PhosphorIconsRegular.caretDown, size: 18),
            ),
            child: Text(displayLabel, style: t.bodyLarge),
          ),
        );

      case CustomInputType.currency:
      case CustomInputType.percentage:
      case CustomInputType.duration:
      case CustomInputType.number:
      case CustomInputType.date:
        final isCurrency = input.type == CustomInputType.currency;
        final effectiveSuffix = input.type == CustomInputType.percentage
            ? '%'
            : (input.type == CustomInputType.duration
                ? input.durationUnit
                : input.suffix);

        return TextField(
          controller: _ctrl[input.id],
          focusNode: _focusNodes[input.id],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          onChanged: (v) {
            final parsed = double.tryParse(v) ?? 0.0;
            _inputValues[input.id] = parsed;
            setState(() => _dirty = true);
          },
          style: AppType.figure(p.ink, size: 16),
          decoration: InputDecoration(
            labelText: input.label,
            helperText: input.description,
            prefixText: isCurrency && cur.isNotEmpty ? '$cur ' : input.prefix,
            suffixText: effectiveSuffix,
          ),
        );
    }
  }

  Widget _buildResultsSection(CustomCalcExecutionResult result, Fmt fmt) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;

    if (result.hasErrors) {
      final firstError = result.errors.values.first;
      return AppCard(
        color: p.surfaceAlt,
        child: Row(
          children: [
            Icon(PhosphorIconsRegular.warningCircle, color: p.loss),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                firstError,
                style: t.bodyMedium?.copyWith(color: p.loss),
              ),
            ),
          ],
        ),
      );
    }

    final primary = result.primaryOutput;
    final primaryVal = result.primaryValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (primary != null && primaryVal != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  p.primary,
                  p.primary.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primary.label.toUpperCase(),
                  style: t.labelSmall?.copyWith(
                    color: p.onPrimary.withValues(alpha: 0.85),
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatValue(primaryVal, primary, fmt),
                  style: AppType.figure(
                    p.onPrimary,
                    size: 30,
                    w: FontWeight.w700,
                  ),
                ),
                if (primary.formulaExplanation != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    primary.formulaExplanation!,
                    style: t.bodySmall?.copyWith(
                      color: p.onPrimary.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              for (int i = 0; i < result.outputs.length; i++) ...[
                if (i > 0) const Divider(height: AppSpacing.lg),
                _buildOutputRow(result.outputs[i], fmt),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOutputRow(CustomOutputValue output, Fmt fmt) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;

    final formatted = output.value != null
        ? _formatValue(output.value!, output.def, fmt)
        : (output.errorMessage ?? '-');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(output.def.label, style: t.bodyMedium),
              if (output.def.formulaExplanation != null)
                Text(
                  output.def.formulaExplanation!,
                  style: t.bodySmall?.copyWith(color: p.inkSubtle),
                ),
            ],
          ),
        ),
        Text(
          formatted,
          style: AppType.figure(
            output.hasError ? p.loss : p.ink,
            size: 16,
            w: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatValue(double val, CustomOutputDef def, Fmt fmt) {
    switch (def.kind) {
      case CustomOutputKind.currency:
        return fmt.money(val);
      case CustomOutputKind.percentage:
        return '${val.toStringAsFixed(def.decimalPlaces)}%';
      case CustomOutputKind.number:
        final prefix = def.prefix ?? '';
        final suffix = def.suffix ?? '';
        final numStr = val == val.roundToDouble() && def.decimalPlaces == 0
            ? val.toInt().toString()
            : val.toStringAsFixed(def.decimalPlaces);
        return '$prefix$numStr$suffix';
    }
  }

  List<num>? _getPresets(CustomInputDef input) {
    if (input.type == CustomInputType.currency) {
      return const [5000, 10000, 25000, 50000, 100000];
    }
    if (input.type == CustomInputType.percentage) {
      return const [5, 10, 12, 15, 20];
    }
    if (input.type == CustomInputType.duration) {
      if (input.durationUnit == 'days') return const [30, 90, 180, 365];
      if (input.durationUnit == 'months') return const [6, 12, 24, 36];
      return const [1, 3, 5, 10];
    }
    return const [1, 5, 10, 50, 100];
  }

  String _formatPreset(CustomInputDef input, num val, String cur) {
    if (input.type == CustomInputType.currency) {
      return cur.isNotEmpty ? '$cur $val' : '$val';
    }
    if (input.type == CustomInputType.percentage) return '$val%';
    if (input.type == CustomInputType.duration) {
      return '$val ${input.durationUnit}';
    }
    return '$val';
  }
}
