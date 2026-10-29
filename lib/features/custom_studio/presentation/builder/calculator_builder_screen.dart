import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/common.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/models/custom_calc_definition.dart';
import '../../domain/models/custom_input_def.dart';
import '../../domain/models/custom_output_def.dart';
import 'steps/step_basic_info.dart';
import 'steps/step_inputs_designer.dart';
import 'steps/step_outputs_designer.dart';
import 'steps/step_preview.dart';

class CalculatorBuilderScreen extends ConsumerStatefulWidget {
  const CalculatorBuilderScreen({
    super.key,
    this.initial,
  });

  final CustomCalcDefinition? initial;

  @override
  ConsumerState<CalculatorBuilderScreen> createState() =>
      _CalculatorBuilderScreenState();
}

class _CalculatorBuilderScreenState
    extends ConsumerState<CalculatorBuilderScreen> {
  int _currentStep = 0;
  late final String _calcId;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late String _category;
  late String _iconKey;
  late List<CustomInputDef> _inputs;
  late List<CustomOutputDef> _outputs;
  late final int _createdAt;

  bool _dirty = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _calcId = init?.id ?? 'calc_${DateTime.now().millisecondsSinceEpoch}';
    _nameCtrl = TextEditingController(text: init?.name ?? '');
    _descCtrl = TextEditingController(text: init?.description ?? '');
    _category = init?.category ?? 'Income';
    _iconKey = init?.iconKey ?? 'calculator';
    _inputs = init != null ? List.from(init.inputs) : [];
    _outputs = init != null ? List.from(init.outputs) : [];
    _createdAt = (init != null && init.createdAt != 0)
        ? init.createdAt
        : DateTime.now().millisecondsSinceEpoch;

    _nameCtrl.addListener(() {
      _dirty = true;
      if (_nameError != null && _nameCtrl.text.trim().isNotEmpty) {
        setState(() => _nameError = null);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  CustomCalcDefinition _buildCurrentDefinition({required bool isDraft}) {
    return CustomCalcDefinition(
      id: _calcId,
      name: _nameCtrl.text.trim().isEmpty ? 'Untitled Calculator' : _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      iconKey: _iconKey,
      isDraft: isDraft,
      inputs: _inputs,
      outputs: _outputs,
      createdAt: _createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _autoSaveDraft() async {
    if (_nameCtrl.text.trim().isEmpty && _inputs.isEmpty && _outputs.isEmpty) {
      return;
    }
    final draft = _buildCurrentDefinition(isDraft: true);
    await ref.read(customCalcRepoProvider).save(draft);
    ref.invalidate(customCalcsProvider);
  }

  Future<void> _saveAndPublish() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() {
        _currentStep = 0;
        _nameError = 'Calculator name is required';
      });
      return;
    }

    if (_inputs.isEmpty) {
      setState(() => _currentStep = 1);
      toast(context, 'Add at least one input field before saving.');
      return;
    }

    if (_outputs.isEmpty) {
      setState(() => _currentStep = 2);
      toast(context, 'Add at least one calculated result before saving.');
      return;
    }

    final definition = _buildCurrentDefinition(isDraft: false);
    final validationErrors = definition.validate();
    if (validationErrors.isNotEmpty) {
      toast(context, 'Validation error: ${validationErrors.first}');
      return;
    }

    await ref.read(customCalcRepoProvider).save(definition);
    ref.invalidate(customCalcsProvider);

    _dirty = false;
    if (!mounted) return;
    toast(context, 'Calculator saved successfully!');
    Navigator.of(context).pop(definition);
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final res = await confirm(
      context,
      title: 'Exit Calculator Studio?',
      message: 'Unpublished changes will be preserved in your drafts.',
      action: 'Exit & Save Draft',
    );
    if (res) {
      await _autoSaveDraft();
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
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
              title: widget.initial == null ? 'Create Calculator' : 'Edit Calculator',
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.primary,
                      foregroundColor: p.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    onPressed: _saveAndPublish,
                    child: const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            // Step Navigation Indicator
            Container(
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(bottom: BorderSide(color: p.outline)),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Segmented step progress indicator
                  Row(
                    children: List.generate(4, (index) {
                      final isCompletedOrCurrent = index <= _currentStep;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: index < 3 ? 4.0 : 0.0),
                          height: 3,
                          decoration: BoxDecoration(
                            color: isCompletedOrCurrent
                                ? p.primary
                                : p.outline.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Step pill navigation
                  Row(
                    children: [
                      _buildStepChip(0, '1. Info'),
                      const SizedBox(width: 4),
                      _buildStepChip(1, '2. Inputs (${_inputs.length})'),
                      const SizedBox(width: 4),
                      _buildStepChip(2, '3. Formulas (${_outputs.length})'),
                      const SizedBox(width: 4),
                      _buildStepChip(3, '4. Preview'),
                    ],
                  ),
                ],
              ),
            ),
            // Step Body
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  StepBasicInfo(
                    nameCtrl: _nameCtrl,
                    descCtrl: _descCtrl,
                    category: _category,
                    onCategoryChanged: (cat) => setState(() {
                      _category = cat;
                      _dirty = true;
                    }),
                    iconKey: _iconKey,
                    onIconKeyChanged: (ic) => setState(() {
                      _iconKey = ic;
                      _dirty = true;
                    }),
                    nameError: _nameError,
                  ),
                  StepInputsDesigner(
                    inputs: _inputs,
                    onInputsChanged: (updated) => setState(() {
                      _inputs = updated;
                      _dirty = true;
                    }),
                  ),
                  StepOutputsDesigner(
                    inputs: _inputs,
                    outputs: _outputs,
                    onOutputsChanged: (updated) => setState(() {
                      _outputs = updated;
                      _dirty = true;
                    }),
                  ),
                  StepPreview(
                    definition: _buildCurrentDefinition(isDraft: true),
                  ),
                ],
              ),
            ),
            // Bottom Step Bar
            if (_currentStep < 3)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: p.surface,
                  border: Border(top: BorderSide(color: p.outline)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      if (_currentStep > 0) ...[
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: p.outline),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                              icon: const Icon(PhosphorIconsBold.arrowLeft, size: 16),
                              label: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
                              onPressed: () {
                                setState(() => _currentStep -= 1);
                                _autoSaveDraft();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        flex: _currentStep > 0 ? 2 : 1,
                        child: SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: p.primary,
                              foregroundColor: p.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            icon: Icon(
                              _currentStep == 2
                                  ? PhosphorIconsBold.play
                                  : PhosphorIconsBold.arrowRight,
                              size: 16,
                            ),
                            label: Text(
                              _currentStep == 2 ? 'Preview Calculator' : 'Next Step',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            onPressed: () {
                              if (_currentStep == 0 && _nameCtrl.text.trim().isEmpty) {
                                setState(() => _nameError = 'Calculator name is required');
                                return;
                              }
                              setState(() => _currentStep += 1);
                              _autoSaveDraft();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepChip(int stepIndex, String label) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final isSelected = _currentStep == stepIndex;
    final isPast = stepIndex < _currentStep;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () {
            setState(() => _currentStep = stepIndex);
            _autoSaveDraft();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? p.primary.withValues(alpha: 0.12)
                  : isPast
                      ? p.surfaceAlt.withValues(alpha: 0.6)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: isSelected
                    ? p.primary
                    : isPast
                        ? p.outline.withValues(alpha: 0.8)
                        : Colors.transparent,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPast) ...[
                      Icon(
                        PhosphorIconsBold.check,
                        size: 11,
                        color: p.primary,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      label,
                      maxLines: 1,
                      style: t.labelSmall?.copyWith(
                        color: isSelected
                            ? p.primary
                            : isPast
                                ? p.ink
                                : p.inkSubtle,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
