import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/models/custom_input_def.dart';
import '../../domain/models/custom_output_def.dart';
import '../../engine/formula_evaluator.dart';
import '../../engine/formula_parser.dart';
import '../../engine/formula_validator.dart';

/// Modal bottom sheet for configuring an output formula with Visual Builder (Mode A) and Formula Editor (Mode B).
class OutputConfigSheet extends StatefulWidget {
  const OutputConfigSheet({
    super.key,
    this.initial,
    required this.availableInputs,
    required this.otherOutputs,
  });

  final CustomOutputDef? initial;
  final List<CustomInputDef> availableInputs;
  final List<CustomOutputDef> otherOutputs;

  static Future<CustomOutputDef?> show({
    required BuildContext context,
    CustomOutputDef? initial,
    required List<CustomInputDef> availableInputs,
    required List<CustomOutputDef> otherOutputs,
  }) {
    return showModalBottomSheet<CustomOutputDef>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OutputConfigSheet(
        initial: initial,
        availableInputs: availableInputs,
        otherOutputs: otherOutputs,
      ),
    );
  }

  @override
  State<OutputConfigSheet> createState() => _OutputConfigSheetState();
}

class _OutputConfigSheetState extends State<OutputConfigSheet> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _idCtrl;
  late final TextEditingController _formulaCtrl;
  late final TextEditingController _prefixCtrl;
  late final TextEditingController _suffixCtrl;
  late final TextEditingController _explanationCtrl;

  bool _isModeB = false; // false = Mode A (Visual Builder), true = Mode B (Formula Editor)
  CustomOutputKind _selectedKind = CustomOutputKind.currency;
  int _decimalPlaces = 2;
  bool _isPrimary = false;
  bool _idManuallyEdited = false;

  // Visual Builder (Mode A) state
  String? _modeALeftVar;
  String _modeAOperator = '-';
  String? _modeARightVar;

  String? _labelError;
  String? _idError;
  String? _formulaError;
  double? _sampleValue;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _labelCtrl = TextEditingController(text: init?.label ?? '');
    _idCtrl = TextEditingController(text: init?.id ?? '');
    _idManuallyEdited = init != null;
    _formulaCtrl = TextEditingController(text: init?.formula ?? '');
    _prefixCtrl = TextEditingController(text: init?.prefix ?? '');
    _suffixCtrl = TextEditingController(text: init?.suffix ?? '');
    _explanationCtrl = TextEditingController(text: init?.formulaExplanation ?? '');

    _selectedKind = init?.kind ?? CustomOutputKind.currency;
    _decimalPlaces = init?.decimalPlaces ?? 2;
    _isPrimary = init?.isPrimary ?? false;

    // Detect if formula was complex -> default to Mode B
    if (init != null && init.formula.isNotEmpty) {
      if (!_tryParseModeA(init.formula)) {
        _isModeB = true;
      }
    } else {
      // Pick first two computational inputs if available
      final compInputs = widget.availableInputs.where((i) => i.isComputational).toList();
      if (compInputs.isNotEmpty) {
        _modeALeftVar = compInputs.first.id;
        if (compInputs.length > 1) {
          _modeARightVar = compInputs[1].id;
        }
        _updateFormulaFromModeA();
      }
    }

    _labelCtrl.addListener(_onLabelChanged);
    _formulaCtrl.addListener(_validateFormula);

    _validateFormula();
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _idCtrl.dispose();
    _formulaCtrl.dispose();
    _prefixCtrl.dispose();
    _suffixCtrl.dispose();
    _explanationCtrl.dispose();
    super.dispose();
  }

  bool _tryParseModeA(String formula) {
    final regex = RegExp(r'^\s*([a-zA-Z0-9_]+)\s*([\+\-\*\/])\s*([a-zA-Z0-9_]+)\s*$');
    final match = regex.firstMatch(formula);
    if (match != null) {
      _modeALeftVar = match.group(1);
      _modeAOperator = match.group(2)!;
      _modeARightVar = match.group(3);
      return true;
    }
    return false;
  }

  void _updateFormulaFromModeA() {
    if (_modeALeftVar != null && _modeARightVar != null) {
      _formulaCtrl.text = '$_modeALeftVar $_modeAOperator $_modeARightVar';
    }
  }

  void _onLabelChanged() {
    if (!_idManuallyEdited) {
      final generated = _labelCtrl.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      _idCtrl.text = generated;
    }
  }

  Set<String> get _allDeclaredVariables {
    final set = <String>{};
    for (final i in widget.availableInputs) {
      if (i.isComputational) set.add(i.id);
    }
    for (final o in widget.otherOutputs) {
      set.add(o.id);
    }
    return set;
  }

  void _validateFormula() {
    final formula = _formulaCtrl.text.trim();
    if (formula.isEmpty) {
      setState(() {
        _formulaError = 'Formula cannot be empty';
        _sampleValue = null;
      });
      return;
    }

    // Static validation
    final result = FormulaValidator.validate(
      formula,
      availableVariables: _allDeclaredVariables,
    );

    if (!result.isValid) {
      setState(() {
        _formulaError = result.errorMessage;
        _sampleValue = null;
      });
      return;
    }

    // Try mock evaluation to calculate sample value
    try {
      final mockContext = <String, double>{};
      for (final i in widget.availableInputs) {
        if (i.isComputational) {
          mockContext[i.id] = (i.defaultValue ?? 100).toDouble();
        }
      }
      for (final o in widget.otherOutputs) {
        mockContext[o.id] = 50.0;
      }

      final ast = FormulaParser.parseFormula(formula);
      final val = FormulaEvaluator.evaluate(ast, mockContext);
      setState(() {
        _formulaError = null;
        _sampleValue = val;
      });
    } catch (e) {
      setState(() {
        _formulaError = 'Evaluation test: $e';
        _sampleValue = null;
      });
    }
  }

  void _insertToken(String token) {
    final text = _formulaCtrl.text;
    final selection = _formulaCtrl.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, token);
    _formulaCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }

  bool _validate() {
    setState(() {
      _labelError = null;
      _idError = null;
    });

    if (_labelCtrl.text.trim().isEmpty) {
      setState(() => _labelError = 'Label is required');
      return false;
    }

    final id = _idCtrl.text.trim();
    if (id.isEmpty) {
      setState(() => _idError = 'Variable ID is required');
      return false;
    }
    if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(id)) {
      setState(() => _idError = 'ID must start with a letter and contain only letters, numbers, and underscores');
      return false;
    }

    final otherOutputIds = widget.otherOutputs.map((o) => o.id).toSet();
    final isNewOrRenamed = widget.initial == null || widget.initial!.id != id;
    if (isNewOrRenamed && otherOutputIds.contains(id)) {
      setState(() => _idError = 'Output ID "$id" already exists');
      return false;
    }

    if (_formulaError != null) {
      return false;
    }

    return true;
  }

  void _submit() {
    if (!_validate()) return;

    final def = CustomOutputDef(
      id: _idCtrl.text.trim(),
      label: _labelCtrl.text.trim(),
      formula: _formulaCtrl.text.trim(),
      kind: _selectedKind,
      decimalPlaces: _decimalPlaces,
      prefix: _prefixCtrl.text.trim().isNotEmpty ? _prefixCtrl.text.trim() : null,
      suffix: _suffixCtrl.text.trim().isNotEmpty ? _suffixCtrl.text.trim() : null,
      isPrimary: _isPrimary,
      formulaExplanation: _explanationCtrl.text.trim().isNotEmpty ? _explanationCtrl.text.trim() : null,
    );

    Navigator.of(context).pop(def);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;

    return Material(
      color: p.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: p.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initial == null ? 'Add Calculated Result' : 'Edit Calculated Result',
                    style: t.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                shrinkWrap: true,
                children: [
                  // Label
                  TextField(
                    controller: _labelCtrl,
                    decoration: InputDecoration(
                      labelText: 'Result Label',
                      hintText: 'e.g. Net Take-Home',
                      errorText: _labelError,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ID
                  TextField(
                    controller: _idCtrl,
                    onChanged: (_) => _idManuallyEdited = true,
                    decoration: InputDecoration(
                      labelText: 'Result Identifier',
                      hintText: 'e.g. net_take_home',
                      errorText: _idError,
                      helperText: 'Internal identifier can be referenced by other formulas.',
                      prefixIcon: const Icon(PhosphorIconsRegular.code, size: 18),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Format Kind
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<CustomOutputKind>(
                          initialValue: _selectedKind,
                          decoration: const InputDecoration(labelText: 'Display Format'),
                          items: const [
                            DropdownMenuItem(value: CustomOutputKind.currency, child: Text('Currency')),
                            DropdownMenuItem(value: CustomOutputKind.percentage, child: Text('Percentage')),
                            DropdownMenuItem(value: CustomOutputKind.number, child: Text('Plain Number')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedKind = v);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      SizedBox(
                        width: 100,
                        child: DropdownButtonFormField<int>(
                          initialValue: _decimalPlaces,
                          decoration: const InputDecoration(labelText: 'Decimals'),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('0')),
                            DropdownMenuItem(value: 1, child: Text('1')),
                            DropdownMenuItem(value: 2, child: Text('2')),
                            DropdownMenuItem(value: 3, child: Text('3')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _decimalPlaces = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Primary Result Switch
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Primary Highlight Result'),
                    subtitle: const Text('Renders as the prominent hero card at top of the screen.'),
                    value: _isPrimary,
                    onChanged: (v) => setState(() => _isPrimary = v),
                  ),
                  const Divider(height: AppSpacing.lg),

                  // Mode Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CALCULATION FORMULA',
                        style: t.labelSmall?.copyWith(color: p.inkSubtle, letterSpacing: 1.1),
                      ),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Visual'),
                            icon: Icon(PhosphorIconsRegular.cards, size: 16),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Formula'),
                            icon: Icon(PhosphorIconsRegular.function, size: 16),
                          ),
                        ],
                        selected: {_isModeB},
                        onSelectionChanged: (set) {
                          setState(() {
                            _isModeB = set.first;
                            if (!_isModeB) {
                              _updateFormulaFromModeA();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (!_isModeB) ...[
                    // Mode A: Visual Builder
                    _buildVisualBuilder(),
                  ] else ...[
                    // Mode B: Advanced Formula Editor
                    _buildFormulaEditor(),
                  ],

                  const SizedBox(height: AppSpacing.sm),

                  // Validation Feedback & Sample Result
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: _formulaError != null ? p.loss.withValues(alpha: 0.1) : p.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: _formulaError != null ? p.loss : p.outline,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _formulaError != null ? PhosphorIconsRegular.warningCircle : PhosphorIconsRegular.checkCircle,
                          size: 20,
                          color: _formulaError != null ? p.loss : p.gain,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formulaError != null ? 'Invalid Formula' : 'Valid Expression',
                                style: t.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _formulaError != null ? p.loss : p.gain,
                                ),
                              ),
                              if (_formulaError != null)
                                Text(_formulaError!, style: t.bodySmall?.copyWith(color: p.loss))
                              else if (_sampleValue != null)
                                Text(
                                  'Sample calculation result: ${_sampleValue!.toStringAsFixed(_decimalPlaces)}',
                                  style: t.bodySmall?.copyWith(color: p.inkMuted),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Formula explanation
                  TextField(
                    controller: _explanationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Formula Explanation (optional)',
                      hintText: 'e.g. Revenue − Fees − Expenses',
                      helperText: 'Displayed under the result for transparency.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Confirm button
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: const Icon(PhosphorIconsRegular.check, size: 18),
                    label: Text(widget.initial == null ? 'Add Calculated Result' : 'Save Changes'),
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildVisualBuilder() {
    final compVars = <DropdownMenuItem<String>>[];
    for (final i in widget.availableInputs) {
      if (i.isComputational) {
        compVars.add(DropdownMenuItem(value: i.id, child: Text(i.label)));
      }
    }
    for (final o in widget.otherOutputs) {
      compVars.add(DropdownMenuItem(value: o.id, child: Text('Output: ${o.label}')));
    }

    if (compVars.isEmpty) {
      return const Text('Add at least one input field first to configure calculations visually.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: compVars.any((m) => m.value == _modeALeftVar) ? _modeALeftVar : compVars.first.value,
                decoration: const InputDecoration(labelText: 'Operand 1'),
                items: compVars,
                onChanged: (v) {
                  setState(() {
                    _modeALeftVar = v;
                    _updateFormulaFromModeA();
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 80,
              child: DropdownButtonFormField<String>(
                initialValue: _modeAOperator,
                decoration: const InputDecoration(labelText: 'Op', isDense: true),
                items: const [
                  DropdownMenuItem(value: '+', child: Text('+')),
                  DropdownMenuItem(value: '-', child: Text('−')),
                  DropdownMenuItem(value: '*', child: Text('×')),
                  DropdownMenuItem(value: '/', child: Text('÷')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _modeAOperator = v;
                      _updateFormulaFromModeA();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: compVars.any((m) => m.value == _modeARightVar)
                    ? _modeARightVar
                    : (compVars.length > 1 ? compVars[1].value : compVars.first.value),
                decoration: const InputDecoration(labelText: 'Operand 2'),
                items: compVars,
                onChanged: (v) {
                  setState(() {
                    _modeARightVar = v;
                    _updateFormulaFromModeA();
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormulaEditor() {
    final p = context.pal;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _formulaCtrl,
          style: AppType.figure(p.ink, size: 16),
          decoration: const InputDecoration(
            labelText: 'Mathematical Formula',
            hintText: 'e.g. revenue * (1 - tax / 100)',
            prefixIcon: Icon(PhosphorIconsRegular.function, size: 18),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Insert Available Variables:',
          style: t.labelSmall?.copyWith(color: p.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final i in widget.availableInputs.where((x) => x.isComputational))
              ActionChip(
                avatar: const Icon(PhosphorIconsRegular.code, size: 14),
                label: Text('${i.label} (${i.id})'),
                onPressed: () => _insertToken(' ${i.id} '),
              ),
            for (final o in widget.otherOutputs)
              ActionChip(
                avatar: const Icon(PhosphorIconsRegular.mathOperations, size: 14),
                label: Text('${o.label} (${o.id})'),
                onPressed: () => _insertToken(' ${o.id} '),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Math Operators & Functions:',
          style: t.labelSmall?.copyWith(color: p.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final op in ['+', '-', '*', '/', '^', '(', ')', '%'])
              ActionChip(
                label: Text(op, style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _insertToken(' $op '),
              ),
            for (final fn in ['max(a, b)', 'min(a, b)', 'sqrt(x)', 'round(x, 2)', 'abs(x)', 'pow(a, b)'])
              ActionChip(
                label: Text(fn),
                onPressed: () {
                  final call = fn.substring(0, fn.indexOf('(') + 1);
                  _insertToken(call);
                },
              ),
          ],
        ),
      ],
    );
  }
}
