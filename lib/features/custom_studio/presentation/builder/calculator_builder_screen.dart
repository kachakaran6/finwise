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
                TextButton(
                  onPressed: _saveAndPublish,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: p.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            // Step Navigation Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(bottom: BorderSide(color: p.outline)),
              ),
              child: Row(
                children: [
                  _buildStepChip(0, '1. Info'),
                  const SizedBox(width: AppSpacing.xs),
                  _buildStepChip(1, '2. Inputs (${_inputs.length})'),
                  const SizedBox(width: AppSpacing.xs),
                  _buildStepChip(2, '3. Formulas (${_outputs.length})'),
                  const SizedBox(width: AppSpacing.xs),
                  _buildStepChip(3, '4. Preview'),
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
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: p.surface,
                  border: Border(top: BorderSide(color: p.outline)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        OutlinedButton.icon(
                          icon: const Icon(PhosphorIconsRegular.arrowLeft, size: 16),
                          label: const Text('Back'),
                          onPressed: () {
                            setState(() => _currentStep -= 1);
                            _autoSaveDraft();
                          },
                        )
                      else
                        const SizedBox.shrink(),
                      FilledButton.icon(
                        icon: const Icon(PhosphorIconsRegular.arrowRight, size: 16),
                        label: Text(_currentStep == 2 ? 'Preview Calculator' : 'Next Step'),
                        onPressed: () {
                          if (_currentStep == 0 && _nameCtrl.text.trim().isEmpty) {
                            setState(() => _nameError = 'Calculator name is required');
                            return;
                          }
                          setState(() => _currentStep += 1);
                          _autoSaveDraft();
                        },
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

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () {
          setState(() => _currentStep = stepIndex);
          _autoSaveDraft();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? p.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: isSelected ? Border.all(color: p.primary) : null,
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.labelSmall?.copyWith(
                color: isSelected ? p.primary : p.inkSubtle,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
