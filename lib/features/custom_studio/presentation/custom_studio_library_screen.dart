import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/common.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../data/custom_calc_repository.dart';
import '../domain/models/custom_calc_definition.dart';
import '../runtime/custom_calculator_screen.dart';
import 'builder/calculator_builder_screen.dart';

class CustomStudioLibraryScreen extends ConsumerStatefulWidget {
  const CustomStudioLibraryScreen({super.key});

  @override
  ConsumerState<CustomStudioLibraryScreen> createState() =>
      _CustomStudioLibraryScreenState();
}

class _CustomStudioLibraryScreenState
    extends ConsumerState<CustomStudioLibraryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = 'all'; // all, published, drafts

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openCalculator(CustomCalcDefinition def) {
    if (def.isDraft) {
      _editCalculator(def);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomCalculatorScreen(definition: def),
      ),
    );
  }

  void _editCalculator(CustomCalcDefinition def) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalculatorBuilderScreen(initial: def),
      ),
    );
  }

  Future<void> _duplicateCalculator(CustomCalcDefinition def) async {
    final repo = ref.read(customCalcRepoProvider);
    await repo.duplicate(def.id);
    ref.invalidate(customCalcsProvider);
    if (mounted) {
      toast(context, 'Duplicated "${def.name}".');
    }
  }

  Future<void> _deleteCalculator(CustomCalcDefinition def) async {
    final ok = await confirm(
      context,
      title: 'Delete calculator?',
      message: 'Are you sure you want to permanently delete "${def.name}"?',
      action: 'Delete',
    );
    if (!ok) return;

    final repo = ref.read(customCalcRepoProvider);
    await repo.delete(def.id);
    ref.invalidate(customCalcsProvider);
    if (mounted) {
      toast(context, 'Deleted "${def.name}".');
    }
  }

  Future<void> _exportCalculator(CustomCalcDefinition def) async {
    final repo = ref.read(customCalcRepoProvider);
    final jsonStr = repo.exportToJson(def);

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final p = ctx.pal;
        final t = Theme.of(ctx).textTheme;
        return Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Export "${def.name}"', style: t.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Share or save this calculator definition as a safe, offline JSON file.',
                  style: t.bodySmall?.copyWith(color: p.inkSubtle),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  leading: const Icon(PhosphorIconsRegular.shareNetwork),
                  title: const Text('Share Definition File'),
                  onTap: () => Navigator.of(ctx).pop('share'),
                ),
                ListTile(
                  leading: const Icon(PhosphorIconsRegular.copy),
                  title: const Text('Copy JSON to Clipboard'),
                  onTap: () => Navigator.of(ctx).pop('copy'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: jsonStr));
      if (mounted) toast(context, 'Calculator JSON copied to clipboard.');
    } else if (action == 'share') {
      await Share.share(
        jsonStr,
        subject: 'Finwise Custom Calculator: ${def.name}',
      );
    }
  }

  Future<void> _importCalculator() async {
    final jsonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final p = ctx.pal;
        final t = Theme.of(ctx).textTheme;
        return AlertDialog(
          title: const Text('Import Calculator'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste a exported Finwise calculator JSON definition below to import it into your studio.',
                style: t.bodySmall?.copyWith(color: p.inkSubtle),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: jsonCtrl,
                maxLines: 6,
                style: AppType.figure(p.ink, size: 12),
                decoration: const InputDecoration(
                  hintText: '{\n  "finwise_calculator_export_version": 1,\n  "calculator": { ... }\n}',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Import & Validate'),
            ),
          ],
        );
      },
    );

    if (ok == true && jsonCtrl.text.trim().isNotEmpty) {
      final repo = ref.read(customCalcRepoProvider);
      try {
        final imported = repo.importFromJson(jsonCtrl.text.trim());
        await repo.save(imported);
        ref.invalidate(customCalcsProvider);
        if (mounted) {
          toast(context, 'Successfully imported "${imported.name}"!');
        }
      } on CustomCalcValidationException catch (e) {
        if (mounted) {
          toast(context, 'Import failed: ${e.errors.join(", ")}');
        }
      } catch (e) {
        if (mounted) {
          toast(context, 'Import error: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final calcsAsync = ref.watch(customCalcsProvider);

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            title: 'Custom Calculator Studio',
            actions: [
              AppHeaderAction(
                icon: PhosphorIconsRegular.fileArrowDown,
                tooltip: 'Import JSON',
                onPressed: _importCalculator,
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: p.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  icon: const Icon(PhosphorIconsBold.plus, size: 14),
                  label: const Text(
                    'Create',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CalculatorBuilderScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Search & Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.xs,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search my calculators...',
                prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(PhosphorIconsRegular.x, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: p.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: p.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: p.outline),
                ),
              ),
            ),
          ),
          // Filter Chips
          calcsAsync.maybeWhen(
            data: (calcs) {
              if (calcs.isEmpty) return const SizedBox.shrink();
              final publishedCount = calcs.where((c) => !c.isDraft).length;
              final draftsCount = calcs.where((c) => c.isDraft).length;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    _buildFilterPill('all', 'All', calcs.length),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterPill('published', 'Published', publishedCount),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterPill('drafts', 'Drafts', draftsCount),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const Divider(height: 1),
          // Calculators List
          Expanded(
            child: calcsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator.adaptive()),
              error: (err, _) => Center(child: Text('Error loading calculators: $err')),
              data: (calcs) {
                final query = _searchCtrl.text.trim().toLowerCase();
                final filtered = calcs.where((c) {
                  if (_filter == 'published' && c.isDraft) return false;
                  if (_filter == 'drafts' && !c.isDraft) return false;
                  if (query.isNotEmpty) {
                    final matchName = c.name.toLowerCase().contains(query);
                    final matchDesc = c.description.toLowerCase().contains(query);
                    return matchName || matchDesc;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(calcs.isEmpty);
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.md,
                    AppSpacing.screen,
                    AppSpacing.bottomNavClearance(context),
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildCalculatorCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String key, String label, int count) {
    final p = context.pal;
    final isSelected = _filter == key;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () => setState(() => _filter = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? p.primary : p.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected ? p.primary : p.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? p.onPrimary : p.ink,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? p.onPrimary.withValues(alpha: 0.22)
                        : p.outline.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? p.onPrimary : p.inkSubtle,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorCard(CustomCalcDefinition def) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final dateStr = DateFormat('MMM d, yyyy').format(
      DateTime.fromMillisecondsSinceEpoch(def.updatedAt),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: p.outline),
        boxShadow: [
          BoxShadow(
            color: p.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _openCalculator(def),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: p.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      _iconForKey(def.iconKey),
                      size: 24,
                      color: p.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                def.name,
                                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (def.isDraft)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: p.loss.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppRadius.xs),
                                ),
                                child: Text(
                                  'DRAFT',
                                  style: t.labelSmall?.copyWith(
                                    color: p.loss,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              )
                            else if (def.category.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: p.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(AppRadius.xs),
                                ),
                                child: Text(
                                  def.category.toUpperCase(),
                                  style: TextStyle(
                                    color: p.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (def.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            def.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall?.copyWith(color: p.inkSubtle),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(PhosphorIconsRegular.dotsThreeVertical, size: 20),
                    onSelected: (val) {
                      switch (val) {
                        case 'open':
                          _openCalculator(def);
                          break;
                        case 'edit':
                          _editCalculator(def);
                          break;
                        case 'duplicate':
                          _duplicateCalculator(def);
                          break;
                        case 'export':
                          _exportCalculator(def);
                          break;
                        case 'delete':
                          _deleteCalculator(def);
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: def.isDraft ? 'edit' : 'open',
                        child: Row(
                          children: [
                            Icon(def.isDraft ? PhosphorIconsRegular.pencil : PhosphorIconsRegular.play, size: 18),
                            const SizedBox(width: AppSpacing.sm),
                            Text(def.isDraft ? 'Continue Draft' : 'Open Calculator'),
                          ],
                        ),
                      ),
                      if (!def.isDraft)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(PhosphorIconsRegular.pencil, size: 18),
                              SizedBox(width: AppSpacing.sm),
                              Text('Edit Definition'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(PhosphorIconsRegular.copy, size: 18),
                            SizedBox(width: AppSpacing.sm),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(PhosphorIconsRegular.export, size: 18),
                            SizedBox(width: AppSpacing.sm),
                            Text('Export JSON'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(PhosphorIconsRegular.trash, size: 18, color: p.loss),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Delete', style: TextStyle(color: p.loss)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.surfaceAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${def.inputs.length} inputs • ${def.outputs.length} formulas',
                          style: t.labelSmall?.copyWith(color: p.inkMuted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Updated $dateStr',
                    style: t.labelSmall?.copyWith(color: p.inkSubtle),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isCompletelyEmpty) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: p.primary.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: Icon(
                PhosphorIconsBold.calculator,
                size: 38,
                color: p.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isCompletelyEmpty
                  ? 'Build Your Own Calculators'
                  : 'No matching calculators',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                isCompletelyEmpty
                    ? 'Build bespoke calculators with custom inputs, reactive formulas, and live evaluation.'
                    : 'Try adjusting your search query or filter chips.',
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: p.inkSubtle),
              ),
            ),
            if (isCompletelyEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: p.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: p.outline),
                ),
                child: Column(
                  children: [
                    _buildStudioFeature(
                      context,
                      PhosphorIconsBold.slidersHorizontal,
                      'Custom Inputs',
                      'Currency, numbers, sliders, toggles & dropdown lists.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStudioFeature(
                      context,
                      PhosphorIconsBold.function,
                      'Smart Formula Engine',
                      'Combine variables with basic math & advanced functions.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStudioFeature(
                      context,
                      PhosphorIconsBold.shareNetwork,
                      'Instant Save & Export',
                      'Simulate scenarios and export definitions as JSON.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: p.primary,
                  foregroundColor: p.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                icon: const Icon(PhosphorIconsBold.plus, size: 18),
                label: const Text(
                  'Create First Calculator',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CalculatorBuilderScreen(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton.icon(
                icon: const Icon(PhosphorIconsRegular.fileArrowDown, size: 16),
                label: const Text('Import from JSON'),
                onPressed: _importCalculator,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudioFeature(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: p.outline),
          ),
          child: Icon(icon, size: 18, color: p.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: t.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
              Text(
                description,
                style: t.bodySmall?.copyWith(color: p.inkSubtle, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconForKey(String key) {
    switch (key) {
      case 'wallet':
        return PhosphorIconsRegular.wallet;
      case 'coins':
        return PhosphorIconsRegular.coins;
      case 'trendUp':
        return PhosphorIconsRegular.trendUp;
      case 'chartLine':
        return PhosphorIconsRegular.chartLine;
      case 'piggyBank':
        return PhosphorIconsRegular.piggyBank;
      case 'bank':
        return PhosphorIconsRegular.bank;
      case 'receipt':
        return PhosphorIconsRegular.receipt;
      case 'scales':
        return PhosphorIconsRegular.scales;
      case 'buildings':
        return PhosphorIconsRegular.buildings;
      case 'target':
        return PhosphorIconsRegular.target;
      case 'briefcase':
        return PhosphorIconsRegular.briefcase;
      case 'calculator':
      default:
        return PhosphorIconsRegular.calculator;
    }
  }
}
