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
import '../../app/theme/tokens.dart';
import '../../core/format.dart';
import '../../core/play_service.dart';
import '../../data/backup.dart';
import '../../domain/models/calc.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/common.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> with ScrollDividerMixin {
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final cur = currencyByCode(s.currency);
    final style = numberStyles.firstWhere((e) => e.locale == s.locale, orElse: () => numberStyles.first);

    Widget group(String title, List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle(title),
          AppCard(padding: EdgeInsets.zero, child: Column(children: children)),
        ]);

    Widget row(IconData icon, String title, String? subtitle, VoidCallback onTap, {bool last = false}) => Column(children: [
          ListTile(
            leading: Icon(icon, size: 22, color: p.primary),
            title: Text(title, style: t.bodyLarge),
            subtitle: subtitle == null ? null : Text(subtitle, style: t.bodySmall),
            trailing: Icon(PhosphorIconsRegular.caretRight, size: 18, color: p.inkSubtle),
            onTap: onTap,
          ),
          if (!last) Divider(height: 1, indent: 56, color: p.outline),
        ]);

    return Column(
      children: [
        AppHeader(title: 'Settings', scrolled: scrolled),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(Sp.page, Sp.lg, Sp.page, Sp.navClearance),
            children: [
              const SectionTitle('Appearance'),
              AppCard(
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(PhosphorIconsRegular.circleHalf, size: 18)),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(PhosphorIconsRegular.sun, size: 18)),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(PhosphorIconsRegular.moon, size: 18)),
                  ],
                  selected: {s.themeMode},
                  onSelectionChanged: (v) => n.setTheme(v.first),
                ),
              ),
              group('Display', [
                row(PhosphorIconsRegular.currencyCircleDollar, 'Currency', '${cur.name} (${cur.code})', () async {
                  final v = await pickOne(context, title: 'Currency symbol', selected: s.currency, options: [for (final c in currencies) ChoiceOption(c.code, '${c.name}  ·  ${c.code}')]);
                  if (v != null) n.setCurrency(v);
                }),
                row(PhosphorIconsRegular.listBullets, 'Number format', '${style.label}: ${style.example}', () async {
                  final v = await pickOne(context, title: 'Number format', selected: s.locale, options: [for (final e in numberStyles) ChoiceOption(e.locale, '${e.label}  ·  ${e.example}')]);
                  if (v != null) n.setLocale(v);
                }, last: true),
              ]),
              group('Backup', [
                row(PhosphorIconsRegular.export, 'Export backup', 'Encrypted or plain file', () => _export(context, ref)),
                row(PhosphorIconsRegular.downloadSimple, 'Restore backup', 'Preview before writing', () => _restore(context, ref), last: true),
              ]),
              group('Privacy', [
                row(PhosphorIconsFill.shieldCheck, 'Offline and private', null, () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Offline and private'),
                      content: const Text('Finwise has no network permission, no account, no analytics, no ads and no cloud sync. Your data never leaves this device unless you export a backup.'),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                    ),
                  );
                }, last: true),
              ]),
              group('Data', [
                row(PhosphorIconsRegular.trash, 'Delete all data', 'Removes scenarios and settings', () async {
                  final ok = await confirm(context, title: 'Delete all data?', message: 'All saved scenarios, favourites and settings on this device will be permanently removed.', action: 'Delete all');
                  if (!ok) return;
                  await ref.read(scenariosProvider.notifier).clear();
                  await n.resetAll();
                  if (context.mounted) toast(context, 'All data deleted.');
                }, last: true),
              ]),
              group('App', [
                row(PhosphorIconsRegular.arrowsClockwise, 'Check for updates', null, () => PlayService.checkForUpdateManual(context)),
                row(PhosphorIconsRegular.star, 'Rate Finwise', null, () => PlayService.rateApp(), last: true),
              ]),
              const SizedBox(height: Sp.xl),
              Center(child: Text('Finwise 1.0.1\nResults are estimates. Not financial advice.', textAlign: TextAlign.center, style: t.bodySmall)),
            ],
          ),
        ),
      ],
    );
  }

  // ───────── backup flows ─────────
  Future<T?> _busy<T>(BuildContext context, String label, Future<T> Function() work) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(content: Row(children: [const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)), const SizedBox(width: Sp.lg), Expanded(child: Text(label))])),
      ),
    );
    try {
      return await work();
    } finally {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<String?> _passphrase(BuildContext context, {required bool confirmField}) {
    final a = TextEditingController(), b = TextEditingController();
    String? err;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(confirmField ? 'Set backup passphrase' : 'Enter passphrase'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            if (confirmField)
              Padding(
                padding: const EdgeInsets.only(bottom: Sp.md),
                child: Text('If you lose this passphrase, the backup cannot be recovered.', style: Theme.of(ctx).textTheme.bodySmall),
              ),
            TextField(controller: a, obscureText: true, autofocus: true, decoration: const InputDecoration(labelText: 'Passphrase')),
            if (confirmField) ...[
              const SizedBox(height: Sp.md),
              TextField(controller: b, obscureText: true, decoration: InputDecoration(labelText: 'Confirm passphrase', errorText: err)),
            ],
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (confirmField && a.text.length < 8) return setState(() => err = 'Use at least 8 characters');
                if (confirmField && a.text != b.text) return setState(() => err = 'Passphrases do not match');
                if (a.text.isEmpty) return;
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
    if (scenarios.isEmpty) return toast(context, 'Nothing to back up yet. Save a scenario first.');
    final mode = await pickOne(context, title: 'Backup type', selected: 'enc', options: const [
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
      final bytes = await _busy<Uint8List>(context, 'Preparing backup…', () => Isolate.run(() => BackupService.export(scenarios, passphrase: pass)));
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final d = DateTime.now();
      final name = 'finwise-backup-${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}.ofcbackup';
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
      prev = await _busy<RestorePreview>(context, 'Checking backup…', () => Isolate.run(() => BackupService.parse(bytes, passphrase: pass)));
    } on BackupException catch (e) {
      if (context.mounted) toast(context, e.message);
      return;
    } catch (_) {
      if (context.mounted) toast(context, 'Wrong passphrase, or the file is damaged.');
      return;
    }
    if (prev == null || !context.mounted) return;
    final items = prev;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore preview'),
        content: Text('${items.scenarios.length} scenario(s) found${items.skipped > 0 ? ' (${items.skipped} invalid record(s) will be skipped)' : ''}.\n\nMerge keeps your current scenarios and adds or updates from the backup. Replace removes current scenarios first.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'replace'), child: const Text('Replace')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'merge'), child: const Text('Merge')),
        ],
      ),
    );
    if (choice == null) return;
    final notifier = ref.read(scenariosProvider.notifier);
    if (choice == 'replace') {
      await notifier.clear();
      await notifier.saveAll(items.scenarios);
    } else {
      final current = {for (final s in await ref.read(scenariosProvider.future)) s.id: s};
      await notifier.saveAll([for (final s in items.scenarios) if (current[s.id] == null || current[s.id]!.updatedAt < s.updatedAt) s]);
    }
    if (context.mounted) toast(context, 'Backup restored.');
  }
}
