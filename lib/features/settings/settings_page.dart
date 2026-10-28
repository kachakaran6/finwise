import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart' hide AppPalette;
import '../../core/app_info.dart';
import '../../core/format.dart';
import '../../core/play_service.dart';
import '../../data/backup.dart';
import '../../domain/models/calc.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/common.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../ecosystem/our_apps_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with ScrollDividerMixin {
  @override
  void initState() {
    super.initState();
    AppInfoService.init().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final cur = currencyByCode(s.currency);
    final style = numberStyles.firstWhere((e) => e.locale == s.locale,
        orElse: () => numberStyles.first);

    Widget group(String title, List<Widget> children) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle(title),
          AppCard(padding: EdgeInsets.zero, child: Column(children: children)),
        ]);

    Widget row(
            IconData icon, String title, String? subtitle, VoidCallback onTap,
            {bool last = false, Color? iconColor}) =>
        Column(children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: IconBadge(
              icon,
              size: 38,
              color: iconColor ?? p.primary,
            ),
            title: Text(title,
                style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: subtitle == null
                ? null
                : Text(subtitle,
                    style: t.bodySmall?.copyWith(color: p.inkMuted)),
            trailing: Icon(PhosphorIconsRegular.caretRight,
                size: 16, color: p.inkSubtle),
            onTap: onTap,
          ),
          if (!last)
            Divider(
                height: 1, indent: 64, color: p.outline.withValues(alpha: 0.7)),
        ]);

    return Column(
      children: [
        AppHeader(title: 'Settings', scrolled: scrolled),
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
              const SectionTitle('Appearance'),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        emptySelectionAllowed: true,
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(PhosphorIconsRegular.sun, size: 18),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(PhosphorIconsRegular.moon, size: 18),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: s.themeMode == ThemeMode.light
                            ? const {ThemeMode.light}
                            : s.themeMode == ThemeMode.dark
                                ? const {ThemeMode.dark}
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const {ThemeMode.dark}
                                    : const <ThemeMode>{}),
                        onSelectionChanged: (set) {
                          if (set.isNotEmpty) {
                            n.setTheme(set.first);
                          } else {
                            n.setTheme(s.themeMode == ThemeMode.dark
                                ? ThemeMode.light
                                : ThemeMode.dark);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Theme colour',
                      style: t.labelSmall?.copyWith(
                        color: p.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ThemeColorPicker(
                      selectedPaletteId: s.paletteId,
                      onPaletteSelected: (palette) => n.setPalette(palette.id),
                    ),
                  ],
                ),
              ),
              group('Display', [
                row(PhosphorIconsRegular.currencyCircleDollar, 'Currency',
                    '${cur.name} (${cur.code})', () async {
                  final v = await pickOne(context,
                      title: 'Currency symbol',
                      selected: s.currency,
                      options: [
                        for (final c in currencies)
                          ChoiceOption(c.code, '${c.name}  ·  ${c.code}')
                      ]);
                  if (v != null) n.setCurrency(v);
                }),
                row(PhosphorIconsRegular.listBullets, 'Number format',
                    '${style.label}: ${style.example}', () async {
                  final v = await pickOne(context,
                      title: 'Number format',
                      selected: s.locale,
                      options: [
                        for (final e in numberStyles)
                          ChoiceOption(e.locale, '${e.label}  ·  ${e.example}')
                      ]);
                  if (v != null) n.setLocale(v);
                }, last: true),
              ]),
              group('Backup', [
                row(PhosphorIconsRegular.export, 'Export backup',
                    'Encrypted or plain file', () => _export(context, ref)),
                row(PhosphorIconsRegular.downloadSimple, 'Restore backup',
                    'Preview before writing', () => _restore(context, ref),
                    last: true),
              ]),
              group('Privacy', [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconBadge(PhosphorIconsFill.shieldCheck,
                          size: 40, color: p.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Offline and private',
                                style: t.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              'Finwise has no network permission, no account, no analytics, no ads and no cloud sync. Your data never leaves this device.',
                              style: t.bodyMedium
                                  ?.copyWith(height: 1.35, color: p.inkMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              group('Data', [
                row(PhosphorIconsRegular.trash, 'Delete all data',
                    'Removes scenarios and settings', () async {
                  final ok = await confirm(context,
                      title: 'Delete all data?',
                      message:
                          'All saved scenarios, favourites and settings on this device will be permanently removed.',
                      action: 'Delete all');
                  if (!ok) return;
                  await ref.read(scenariosProvider.notifier).clear();
                  await n.resetAll();
                  if (context.mounted) toast(context, 'All data deleted.');
                }, last: true, iconColor: p.loss),
              ]),
              group('Ecosystem', [
                row(
                  PhosphorIconsRegular.squaresFour,
                  'Our Apps',
                  'Explore apps by Samyukt',
                  () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OurAppsPage())),
                  last: true,
                ),
              ]),
              group('App', [
                row(PhosphorIconsRegular.shareNetwork, 'Share Finwise',
                    'Share with friends and family', () {
                  final box = context.findRenderObject() as RenderBox?;
                  final origin = box != null && box.hasSize
                      ? (box.localToGlobal(Offset.zero) & box.size)
                      : null;
                  AppInfoService.shareApp(sharePositionOrigin: origin);
                }),
                row(
                    PhosphorIconsRegular.star,
                    'Rate Finwise',
                    'Review on Google Play',
                    () => PlayService.openPlayStoreListing()),
                row(
                    PhosphorIconsRegular.arrowsClockwise,
                    'Check for updates',
                    'Check for Google Play updates',
                    () => PlayService.checkForUpdateManual(context),
                    last: true),
              ]),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border:
                            Border.all(color: p.outline.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        AppInfoService.formattedVersion,
                        style: TextStyle(
                            fontFamily: AppType.mono,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: p.inkMuted),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Results are estimates. Not financial advice.',
                        textAlign: TextAlign.center,
                        style: t.bodySmall?.copyWith(color: p.inkSubtle)),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      onTap: () =>
                          PlayService.openUrl(AppInfoService.samyuktUrl),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Made with care by Samyukt',
                              style: t.bodySmall?.copyWith(
                                color: p.inkMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              PhosphorIconsRegular.arrowSquareOut,
                              size: 13,
                              color: p.inkSubtle,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────── backup flows ─────────
  Future<T?> _busy<T>(
      BuildContext context, String label, Future<T> Function() work) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
            content: Row(children: [
          const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(width: Sp.lg),
          Expanded(child: Text(label))
        ])),
      ),
    );
    try {
      return await work();
    } finally {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<String?> _passphrase(BuildContext context,
      {required bool confirmField}) {
    final a = TextEditingController(), b = TextEditingController();
    String? err;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title:
              Text(confirmField ? 'Set backup passphrase' : 'Enter passphrase'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            if (confirmField)
              Padding(
                padding: const EdgeInsets.only(bottom: Sp.md),
                child: Text(
                    'If you lose this passphrase, the backup cannot be recovered.',
                    style: Theme.of(ctx).textTheme.bodySmall),
              ),
            TextField(
                controller: a,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Passphrase')),
            if (confirmField) ...[
              const SizedBox(height: Sp.md),
              TextField(
                  controller: b,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: 'Confirm passphrase', errorText: err)),
            ],
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (confirmField && a.text.length < 8) {
                  return setState(() => err = 'Use at least 8 characters');
                }
                if (confirmField && a.text != b.text) {
                  return setState(() => err = 'Passphrases do not match');
                }
                if (a.text.isEmpty) {
                  return;
                }
                Navigator.pop(ctx, a.text);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final scenarios = await ref.read(scenariosProvider.future);
    if (!context.mounted) return;
    if (scenarios.isEmpty) {
      return toast(context, 'Nothing to back up yet. Save a scenario first.');
    }
    final mode = await pickOne(context,
        title: 'Backup type',
        selected: 'enc',
        options: const [
          ChoiceOption('enc', 'Encrypted (recommended)'),
          ChoiceOption('plain', 'Unencrypted file'),
        ]);
    if (mode == null || !context.mounted) return;
    String? pass;
    if (mode == 'enc') {
      pass = await _passphrase(context, confirmField: true);
      if (pass == null || !context.mounted) return;
    }
    try {
      final bytes = await _busy<Uint8List>(
          context,
          'Preparing backup…',
          () => Isolate.run(
              () => BackupService.export(scenarios, passphrase: pass)));
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final d = DateTime.now();
      final name =
          'finwise-backup-${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}.ofcbackup';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(file.path)], subject: 'Finwise backup');
    } catch (e) {
      if (context.mounted) toast(context, 'Export failed: $e');
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final pick = await FilePicker.platform.pickFiles(withData: true);
    final bytes = pick?.files.single.bytes;
    if (bytes == null || !context.mounted) return;
    String? pass;
    if (BackupService.isEncrypted(bytes)) {
      pass = await _passphrase(context, confirmField: false);
      if (pass == null || !context.mounted) return;
    }
    RestorePreview? prev;
    try {
      prev = await _busy<RestorePreview>(
          context,
          'Checking backup…',
          () =>
              Isolate.run(() => BackupService.parse(bytes, passphrase: pass)));
    } on BackupException catch (e) {
      if (context.mounted) toast(context, e.message);
      return;
    } catch (_) {
      if (context.mounted) {
        toast(context, 'Wrong passphrase, or the file is damaged.');
      }
      return;
    }
    if (prev == null || !context.mounted) return;
    final items = prev;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore preview'),
        content: Text(
            '${items.scenarios.length} scenario(s) found${items.skipped > 0 ? ' (${items.skipped} invalid record(s) will be skipped)' : ''}.\n\nMerge keeps your current scenarios and adds or updates from the backup. Replace removes current scenarios first.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'replace'),
              child: const Text('Replace')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'merge'),
              child: const Text('Merge')),
        ],
      ),
    );
    if (choice == null) return;
    final notifier = ref.read(scenariosProvider.notifier);
    if (choice == 'replace') {
      await notifier.clear();
      await notifier.saveAll(items.scenarios);
    } else {
      final current = {
        for (final s in await ref.read(scenariosProvider.future)) s.id: s
      };
      await notifier.saveAll([
        for (final s in items.scenarios)
          if (current[s.id] == null || current[s.id]!.updatedAt < s.updatedAt) s
      ]);
    }
    if (context.mounted) toast(context, 'Backup restored.');
  }
}

class ThemeColorPicker extends StatelessWidget {
  const ThemeColorPicker({
    super.key,
    required this.selectedPaletteId,
    required this.onPaletteSelected,
  });

  final String selectedPaletteId;
  final ValueChanged<AppPalette> onPaletteSelected;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final count = AppPalette.all.length;
        // Optimal size between 36 and 42 dp to guarantee single-line fit with breathing room
        final size =
            ((totalWidth - ((count - 1) * 8)) / count).clamp(36.0, 42.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: AppPalette.all.map((p) {
            final selected = selectedPaletteId == p.id;
            return Semantics(
              label: 'Theme colour: ${p.name}',
              selected: selected,
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: () => onPaletteSelected(p),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [p.primaryLight, p.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: selected ? onSurface : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: p.primaryLight.withValues(alpha: 0.35),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: selected
                      ? Icon(
                          Icons.check,
                          color: p.id == 'amber_gold'
                              ? const Color(0xFF0F172A)
                              : Colors.white,
                          size: size * 0.48,
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
