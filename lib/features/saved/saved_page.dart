import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../domain/calculators/catalog.dart';
import '../../domain/models/calc.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/common.dart';
import '../../theme/app_spacing.dart';
import '../home/home_page.dart';
import 'compare_page.dart';

class SavedPage extends ConsumerStatefulWidget {
  const SavedPage({super.key});
  @override
  ConsumerState<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends ConsumerState<SavedPage> with ScrollDividerMixin {
  bool _selecting = false;
  final List<String> _picked = [];

  /// Cancel compare selection mode. Returns true if selection was active.
  bool _cancelSelecting() {
    if (_selecting) {
      setState(() {
        _selecting = false;
        _picked.clear();
      });
      return true;
    }
    return false;
  }

  Future<void> _delete(Scenario s) async {
    await ref.read(scenariosProvider.notifier).remove(s.id);
    if (!mounted) return;
    toast(context, 'Deleted "${s.title}"',
        action: 'Undo',
        onAction: () => ref.read(scenariosProvider.notifier).save(s));
  }

  Future<void> _rename(Scenario s) async {
    final name =
        await askText(context, title: 'Rename scenario', initial: s.title);
    if (name == null) return;
    await ref.read(scenariosProvider.notifier).save(s.copyWith(
        title: name, updatedAt: DateTime.now().millisecondsSinceEpoch));
  }

  Future<void> _duplicate(Scenario s) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await ref.read(scenariosProvider.notifier).save(s.copyWith(
        id: newId(),
        title: '${s.title} (copy)',
        createdAt: now,
        updatedAt: now));
  }

  void _toggle(Scenario s, List<Scenario> all) {
    setState(() {
      if (_picked.contains(s.id)) {
        _picked.remove(s.id);
      } else if (_picked.length < 2) {
        final first = _picked.isEmpty
            ? null
            : all.firstWhere((e) => e.id == _picked.first);
        if (first != null && first.calcId != s.calcId) {
          toast(context, 'Compare scenarios from the same calculator.');
          return;
        }
        _picked.add(s.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final fmt = ref.watch(fmtProvider);
    final async = ref.watch(scenariosProvider);
    final df = DateFormat.yMMMd();

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
          icon: PhosphorIconsRegular.warningCircle,
          title: 'Could not load saved scenarios',
          message: '$e'),
      data: (list) => PopScope(
        // When in selection mode, back cancels selection first
        canPop: !_selecting,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _cancelSelecting();
        },
        child: Column(
          children: [
            AppHeader(
              title: 'Saved',
              scrolled: scrolled,
              actions: [
                if (list.length >= 2)
                  AppHeaderAction(
                    icon: _selecting
                        ? PhosphorIconsRegular.x
                        : PhosphorIconsRegular.scales,
                    tooltip:
                        _selecting ? 'Cancel compare' : 'Compare scenarios',
                    onPressed: () => setState(() {
                      _selecting = !_selecting;
                      _picked.clear();
                    }),
                  ),
              ],
            ),
            if (_selecting)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(Sp.page, Sp.sm, Sp.page, Sp.sm),
                child: AppCard(
                  color: p.surfaceAlt,
                  child: Row(children: [
                    Expanded(
                        child: Text(
                            'Select two scenarios from the same calculator (${_picked.length}/2).',
                            style: t.bodyMedium)),
                    const SizedBox(width: Sp.md),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40)),
                      onPressed: _picked.length == 2
                          ? () {
                              final a =
                                  list.firstWhere((e) => e.id == _picked[0]);
                              final b =
                                  list.firstWhere((e) => e.id == _picked[1]);
                              setState(() {
                                _selecting = false;
                                _picked.clear();
                              });
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ComparePage(a: a, b: b)));
                            }
                          : null,
                      child: const Text('Compare'),
                    ),
                  ]),
                ),
              ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.md,
                  AppSpacing.screen,
                  AppSpacing.bottomNavClearance(context),
                ),
                children: [
                  if (list.isEmpty)
                    const EmptyState(
                        icon: PhosphorIconsRegular.bookmarkSimple,
                        title: 'No saved scenarios',
                        message:
                            'Open any calculator and tap Save to keep a scenario here.'),
                  for (final s in list)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.cardGap),
                      child: Builder(builder: (context) {
                        final def = calcById(s.calcId);
                        if (def == null) return const SizedBox.shrink();
                        final catColor = categoryAccent(context, def.category);

                        return AppCard(
                          onTap: _selecting
                              ? () => _toggle(s, list)
                              : () => openCalc(context, def, existing: s),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              if (_selecting)
                                Padding(
                                  padding: const EdgeInsets.only(right: Sp.md),
                                  child: Checkbox(
                                      value: _picked.contains(s.id),
                                      onChanged: (_) => _toggle(s, list)),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.only(right: Sp.md),
                                  child: IconBadge(
                                    iconForCalc(def.id),
                                    color: catColor,
                                    size: 40,
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.title,
                                      style: t.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${def.name} · ${df.format(DateTime.fromMillisecondsSinceEpoch(s.updatedAt))}',
                                      style: t.bodySmall
                                          ?.copyWith(color: p.inkMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: p.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        fmt.value(s.primary),
                                        style: AppType.figure(p.primary,
                                            size: 14, w: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!_selecting)
                                PopupMenuButton<String>(
                                  tooltip: 'Scenario actions',
                                  icon: Icon(
                                      PhosphorIconsRegular.dotsThreeVertical,
                                      size: 20,
                                      color: p.inkMuted),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: Rd.r(Rd.md)),
                                  onSelected: (v) {
                                    if (v == 'rename') _rename(s);
                                    if (v == 'copy') _duplicate(s);
                                    if (v == 'delete') _delete(s);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                        value: 'rename', child: Text('Rename')),
                                    PopupMenuItem(
                                        value: 'copy',
                                        child: Text('Duplicate')),
                                    PopupMenuItem(
                                        value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                            ],
                          ),
                        );
                      }),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
