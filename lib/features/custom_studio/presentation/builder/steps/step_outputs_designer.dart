import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../../app/theme/tokens.dart';
import '../../../../../theme/app_radius.dart';
import '../../../../../theme/app_spacing.dart';
import '../../../domain/models/custom_input_def.dart';
import '../../../domain/models/custom_output_def.dart';
import '../output_config_sheet.dart';

class StepOutputsDesigner extends StatelessWidget {
  const StepOutputsDesigner({
    super.key,
    required this.inputs,
    required this.outputs,
    required this.onOutputsChanged,
  });

  final List<CustomInputDef> inputs;
  final List<CustomOutputDef> outputs;
  final ValueChanged<List<CustomOutputDef>> onOutputsChanged;

  Future<void> _addOutput(BuildContext context) async {
    final result = await OutputConfigSheet.show(
      context: context,
      availableInputs: inputs,
      otherOutputs: outputs,
    );
    if (result != null) {
      // If this is set as primary, unmark others
      List<CustomOutputDef> updated = List.from(outputs);
      if (result.isPrimary) {
        updated = updated.map((o) => o.copyWith(isPrimary: false)).toList();
      }
      updated.add(result);
      onOutputsChanged(updated);
    }
  }

  Future<void> _editOutput(BuildContext context, int index) async {
    final existing = outputs[index];
    final otherOutputs = List<CustomOutputDef>.from(outputs)..removeAt(index);
    final result = await OutputConfigSheet.show(
      context: context,
      initial: existing,
      availableInputs: inputs,
      otherOutputs: otherOutputs,
    );
    if (result != null) {
      List<CustomOutputDef> updated = List.from(outputs);
      if (result.isPrimary) {
        updated = updated.map((o) => o.copyWith(isPrimary: false)).toList();
      }
      updated[index] = result;
      onOutputsChanged(updated);
    }
  }

  void _duplicateOutput(int index) {
    final original = outputs[index];
    final newId = '${original.id}_copy';
    final copy = CustomOutputDef(
      id: newId,
      label: '${original.label} (Copy)',
      formula: original.formula,
      kind: original.kind,
      decimalPlaces: original.decimalPlaces,
      prefix: original.prefix,
      suffix: original.suffix,
      isPrimary: false,
      formulaExplanation: original.formulaExplanation,
    );
    final updated = List<CustomOutputDef>.from(outputs);
    updated.insert(index + 1, copy);
    onOutputsChanged(updated);
  }

  void _deleteOutput(int index) {
    final updated = List<CustomOutputDef>.from(outputs);
    updated.removeAt(index);
    onOutputsChanged(updated);
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
                    'Calculated Results (${outputs.length})',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Formulas evaluate in dependency order',
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
                label: const Text('Add Result'),
                onPressed: () => _addOutput(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: outputs.isEmpty
              ? _buildEmptyState(context)
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  itemCount: outputs.length,
                  onReorder: (oldIndex, newIndex) {
                    final updated = List<CustomOutputDef>.from(outputs);
                    if (oldIndex < newIndex) newIndex -= 1;
                    final item = updated.removeAt(oldIndex);
                    updated.insert(newIndex, item);
                    onOutputsChanged(updated);
                  },
                  itemBuilder: (context, index) {
                    final output = outputs[index];
                    return _buildOutputTile(context, output, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOutputTile(BuildContext context, CustomOutputDef output, int index) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;

    return Container(
      key: ValueKey('output_${output.id}_$index'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: output.isPrimary ? p.primary : p.outline,
          width: output.isPrimary ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          leading: Icon(
            output.isPrimary ? PhosphorIconsFill.star : PhosphorIconsRegular.equals,
            size: 22,
            color: output.isPrimary ? p.primary : p.inkSubtle,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  output.label,
                  style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (output.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PRIMARY',
                    style: t.labelSmall?.copyWith(
                      color: p.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                output.formula,
                style: AppType.figure(p.ink, size: 13, w: FontWeight.w500),
              ),
              if (output.formulaExplanation != null)
                Text(
                  output.formulaExplanation!,
                  style: t.bodySmall?.copyWith(color: p.inkSubtle),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(PhosphorIconsRegular.copy, size: 18),
                tooltip: 'Duplicate',
                onPressed: () => _duplicateOutput(index),
              ),
              IconButton(
                icon: Icon(PhosphorIconsRegular.trash, size: 18, color: p.loss),
                tooltip: 'Delete',
                onPressed: () => _deleteOutput(index),
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
          onTap: () => _editOutput(context, index),
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
            Icon(PhosphorIconsRegular.function, size: 48, color: p.inkSubtle),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No calculations defined',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Define formulas using simple math or advanced functions like min, max, sqrt, and round.',
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(color: p.inkSubtle),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              icon: const Icon(PhosphorIconsRegular.plus, size: 18),
              label: const Text('Add First Calculation'),
              onPressed: () => _addOutput(context),
            ),
          ],
        ),
      ),
    );
  }
}
