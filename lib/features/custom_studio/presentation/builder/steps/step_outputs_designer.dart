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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculated Results (${outputs.length})',
                      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Formulas evaluate in dependency order',
                      style: t.bodySmall?.copyWith(color: p.inkSubtle),
                    ),
                  ],
                ),
              ),
              if (outputs.isNotEmpty)
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
                  label: const Text('Add Result', style: TextStyle(fontWeight: FontWeight.w700)),
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
                  // ignore: deprecated_member_use
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: output.isPrimary ? p.primary : p.outline,
          width: output.isPrimary ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: p.shadow.withValues(alpha: output.isPrimary ? 0.05 : 0.03),
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
              color: output.isPrimary
                  ? p.primary.withValues(alpha: 0.15)
                  : p.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              output.isPrimary ? PhosphorIconsFill.star : PhosphorIconsRegular.function,
              size: 20,
              color: output.isPrimary ? p.primary : p.inkSubtle,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  output.label,
                  style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (output.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
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
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: p.outline.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'f(x) = ',
                      style: TextStyle(
                        color: p.primary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        output.formula,
                        style: AppType.figure(p.ink, size: 12, w: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (output.formulaExplanation != null)
                Text(
                  output.formulaExplanation!,
                  style: t.bodySmall?.copyWith(color: p.inkSubtle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
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
                onPressed: () => _duplicateOutput(index),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
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
                PhosphorIconsBold.function,
                size: 34,
                color: p.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No calculations defined',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Define formulas using simple math or advanced functions like min, max, sqrt, and round.',
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
                        'Formula Guide',
                        style: t.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildTipRow(context, 'Variables', 'Reference input IDs (e.g. loan_amount * rate / 100)'),
                  const SizedBox(height: 6),
                  _buildTipRow(context, 'Operators', '+  −  *  /  ^  ( )'),
                  const SizedBox(height: 6),
                  _buildTipRow(context, 'Functions', 'min(a,b), max(a,b), round(x), sqrt(x)'),
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
                'Add First Calculation',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              onPressed: () => _addOutput(context),
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
}
