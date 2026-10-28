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
                tooltip: 'Import Calculator',
                onPressed: _importCalculator,
              ),
              AppHeaderAction(
                icon: PhosphorIconsRegular.plus,
                tooltip: 'Create Calculator',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CalculatorBuilderScreen(),
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
              ),
            ),
          ),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: AppSpacing.xs),
            child: Row(
              children: [
                _buildFilterChip('all', 'All'),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('published', 'Published'),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('drafts', 'Drafts'),
              ],
            ),
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

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (val) {
        if (val) setState(() => _filter = key);
      },
    );
  }

  Widget _buildCalculatorCard(CustomCalcDefinition def) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final dateStr = DateFormat('MMM d, yyyy').format(
      DateTime.fromMillisecondsSinceEpoch(def.updatedAt),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.cardGap),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: p.outline),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: p.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      _iconForKey(def.iconKey),
                      size: 22,
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
                              ),
                            ),
                            if (def.isDraft)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: p.loss.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'DRAFT',
                                  style: t.labelSmall?.copyWith(
                                    color: p.loss,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (def.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
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
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.surfaceAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${def.inputs.length} inputs • ${def.outputs.length} outputs',
                          style: t.labelSmall?.copyWith(color: p.inkMuted),
                        ),
                      ),
                      if (def.category.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '• ${def.category}',
                          style: t.labelSmall?.copyWith(color: p.inkSubtle),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    dateStr,
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIconsRegular.calculator, size: 32, color: p.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isCompletelyEmpty ? 'Build Your Own Calculators' : 'No matching calculators',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isCompletelyEmpty
                  ? 'Custom Calculator Studio lets you create tailored financial calculators for freelance revenue, rental yield, custom margins, or unique repayment schedules.'
                  : 'Try adjusting your search query or filter chips.',
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(color: p.inkSubtle),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isCompletelyEmpty) ...[
              FilledButton.icon(
                icon: const Icon(PhosphorIconsRegular.plus, size: 18),
                label: const Text('Create First Calculator'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CalculatorBuilderScreen(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                icon: const Icon(PhosphorIconsRegular.fileArrowDown, size: 18),
                label: const Text('Import from JSON'),
                onPressed: _importCalculator,
              ),
            ],
          ],
        ),
      ),
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
