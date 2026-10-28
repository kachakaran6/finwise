import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../../app/theme/tokens.dart';
import '../../../../../theme/app_radius.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../domain/models/custom_input_def.dart';
import '../input_config_sheet.dart';

class StepInputsDesigner extends StatelessWidget {
  const StepInputsDesigner({
    super.key,
    required this.inputs,
    required this.onInputsChanged,
  });

  final List<CustomInputDef> inputs;
  final ValueChanged<List<CustomInputDef>> onInputsChanged;

  Set<String> get _variableIds =>
      inputs.where((i) => i.isComputational).map((i) => i.id).toSet();

  Future<void> _addInput(BuildContext context) async {
    final result = await InputConfigSheet.show(
      context: context,
      existingVariableIds: _variableIds,
    );
    if (result != null) {
      onInputsChanged([...inputs, result]);
    }
  }

  Future<void> _editInput(BuildContext context, int index) async {
    final existing = inputs[index];
    final otherIds = _variableIds.difference({existing.id});
    final result = await InputConfigSheet.show(
      context: context,
      initial: existing,
      existingVariableIds: otherIds,
    );
    if (result != null) {
      final updated = List<CustomInputDef>.from(inputs);
      updated[index] = result;
      onInputsChanged(updated);
    }
  }

  void _duplicateInput(int index) {
    final original = inputs[index];
    final newId = '${original.id}_copy';
    final copy = CustomInputDef(
      id: newId,
      label: '${original.label} (Copy)',
      type: original.type,
      description: original.description,
      defaultValue: original.defaultValue,
      min: original.min,
      max: original.max,
      step: original.step,
      prefix: original.prefix,
      suffix: original.suffix,
      durationUnit: original.durationUnit,
      options: original.options,
      infoText: original.infoText,
    );
    final updated = List<CustomInputDef>.from(inputs);
    updated.insert(index + 1, copy);
    onInputsChanged(updated);
  }

  void _deleteInput(int index) {
    final updated = List<CustomInputDef>.from(inputs);
    updated.removeAt(index);
    onInputsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Input Fields (${inputs.length})',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Drag handles to reorder inputs',
                    style: t.bodySmall?.copyWith(color: p.inkSubtle),
                  ),
                ],
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                label: const Text('Add Input'),
                onPressed: () => _addInput(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: inputs.isEmpty
              ? _buildEmptyState(context)
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  itemCount: inputs.length,
                  onReorder: (oldIndex, newIndex) {
                    final updated = List<CustomInputDef>.from(inputs);
                    if (oldIndex < newIndex) newIndex -= 1;
                    final item = updated.removeAt(oldIndex);
                    updated.insert(newIndex, item);
                    onInputsChanged(updated);
                  },
                  itemBuilder: (context, index) {
                    final input = inputs[index];
                    return _buildInputTile(context, input, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInputTile(BuildContext context, CustomInputDef input, int index) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;

    return Container(
      key: ValueKey('input_${input.id}_$index'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: p.outline),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          leading: Icon(_iconForType(input.type), size: 22, color: p.primary),
          title: Text(input.label, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: input.isComputational
              ? Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.surfaceAlt,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        input.id,
                        style: AppType.figure(p.inkSubtle, size: 12),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '• ${_labelForType(input.type)}',
                      style: t.bodySmall?.copyWith(color: p.inkSubtle),
                    ),
                  ],
                )
              : Text(
                  _labelForType(input.type),
                  style: t.bodySmall?.copyWith(color: p.inkSubtle),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(PhosphorIconsRegular.copy, size: 18),
                tooltip: 'Duplicate',
                onPressed: () => _duplicateInput(index),
              ),
              IconButton(
                icon: Icon(PhosphorIconsRegular.trash, size: 18, color: p.loss),
                tooltip: 'Delete',
                onPressed: () => _deleteInput(index),
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(PhosphorIconsRegular.dotsSixVertical, size: 22),
                ),
              ),
            ],
          ),
          onTap: () => _editInput(context, index),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.slidersHorizontal, size: 48, color: p.inkSubtle),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No input fields yet',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add numeric, currency, percentage, dropdown, or toggle widgets to capture user inputs for your formulas.',
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(color: p.inkSubtle),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              icon: const Icon(PhosphorIconsRegular.plus, size: 18),
              label: const Text('Add First Input'),
              onPressed: () => _addInput(context),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(CustomInputType type) {
    switch (type) {
      case CustomInputType.currency:
        return PhosphorIconsRegular.currencyDollar;
      case CustomInputType.number:
        return PhosphorIconsRegular.hash;
      case CustomInputType.percentage:
        return PhosphorIconsRegular.percent;
      case CustomInputType.duration:
        return PhosphorIconsRegular.clock;
      case CustomInputType.dropdown:
        return PhosphorIconsRegular.list;
      case CustomInputType.toggle:
        return PhosphorIconsRegular.toggleRight;
      case CustomInputType.slider:
        return PhosphorIconsRegular.sliders;
      case CustomInputType.date:
        return PhosphorIconsRegular.calendar;
      case CustomInputType.sectionHeader:
        return PhosphorIconsRegular.textT;
      case CustomInputType.infoBlock:
        return PhosphorIconsRegular.info;
    }
  }

  String _labelForType(CustomInputType type) {
    switch (type) {
      case CustomInputType.currency:
        return 'Currency';
      case CustomInputType.number:
        return 'Number';
      case CustomInputType.percentage:
        return 'Percentage';
      case CustomInputType.duration:
        return 'Duration';
      case CustomInputType.dropdown:
        return 'Dropdown';
      case CustomInputType.toggle:
        return 'Toggle';
      case CustomInputType.slider:
        return 'Slider';
      case CustomInputType.date:
        return 'Date';
      case CustomInputType.sectionHeader:
        return 'Section Header';
      case CustomInputType.infoBlock:
        return 'Info Note';
    }
  }
}
