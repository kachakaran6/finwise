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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Input Fields (${inputs.length})',
                      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to configure, drag handles to reorder',
                      style: t.bodySmall?.copyWith(color: p.inkSubtle),
                    ),
                  ],
                ),
              ),
              if (inputs.isNotEmpty)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: p.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  icon: const Icon(PhosphorIconsBold.plus, size: 15),
                  label: const Text('Add Input', style: TextStyle(fontWeight: FontWeight.w700)),
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
                  // ignore: deprecated_member_use
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: p.outline),
        boxShadow: [
          BoxShadow(
            color: p.shadow.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(_iconForType(input.type), size: 20, color: p.primary),
          ),
          title: Text(
            input.label,
            style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: input.isComputational
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.surfaceAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          input.id,
                          style: AppType.figure(p.inkSubtle, size: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        '• ${_labelForType(input.type)}',
                        style: t.bodySmall?.copyWith(color: p.inkSubtle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Text(
                  _labelForType(input.type),
                  style: t.bodySmall?.copyWith(color: p.inkSubtle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                icon: const Icon(PhosphorIconsRegular.copy, size: 18),
                tooltip: 'Duplicate',
                onPressed: () => _duplicateInput(index),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: p.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                PhosphorIconsBold.slidersHorizontal,
                size: 34,
                color: p.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No input fields yet',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Add numeric, currency, percentage, dropdown, or toggle widgets to capture user inputs for your formulas.',
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: p.inkSubtle),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: p.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: p.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIconsBold.lightbulb, size: 16, color: p.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Input Types Available',
                        style: t.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildTipRow(context, 'Numeric', 'Currency, Percentages, Decimals, Sliders'),
                  const SizedBox(height: 6),
                  _buildTipRow(context, 'Choices', 'Dropdown lists, Boolean toggle switches'),
                  const SizedBox(height: 6),
                  _buildTipRow(context, 'Content', 'Dates, Section headers, Explanatory notes'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              icon: const Icon(PhosphorIconsBold.plus, size: 18),
              label: const Text(
                'Add First Input',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              onPressed: () => _addInput(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow(BuildContext context, String title, String detail) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            title,
            style: t.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: p.inkSubtle,
            ),
          ),
        ),
        Expanded(
          child: Text(
            detail,
            style: t.bodySmall?.copyWith(
              color: p.ink,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ],
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
