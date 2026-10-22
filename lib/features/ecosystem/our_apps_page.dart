import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/tokens.dart';
import '../../core/app_info.dart';
import '../../core/play_service.dart';
import '../../data/samyukt_registry.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/common.dart';

class OurAppsPage extends StatefulWidget {
  const OurAppsPage({super.key});

  @override
  State<OurAppsPage> createState() => _OurAppsPageState();
}

class _OurAppsPageState extends State<OurAppsPage> with ScrollDividerMixin {
  final _service = SamyuktRegistryService();
  late Future<List<SamyuktApp>> _appsFuture;

  @override
  void initState() {
    super.initState();
    _loadApps(forceRefresh: false);
  }

  void _loadApps({bool forceRefresh = false}) {
    setState(() {
      _appsFuture = _service.fetchApps(forceRefresh: forceRefresh);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppHeader(
        title: 'Our Apps',
        scrolled: scrolled,
        actions: [
          AppHeaderAction(
            icon: PhosphorIconsRegular.arrowsClockwise,
            tooltip: 'Refresh',
            onPressed: () => _loadApps(forceRefresh: true),
          ),
        ],
      ),
      body: FutureBuilder<List<SamyuktApp>>(
        future: _appsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: Sp.md),
                  Text(
                    'Loading ecosystem apps…',
                    style: t.bodySmall?.copyWith(color: p.inkMuted),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Sp.page),
                child: AppCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconBadge(
                        PhosphorIconsRegular.warningCircle,
                        size: 48,
                        color: p.loss,
                      ),
                      const SizedBox(height: Sp.md),
                      Text(
                        'Unable to load catalog',
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: Sp.xs),
                      Text(
                        'Please check your network connection and try again.',
                        textAlign: TextAlign.center,
                        style: t.bodySmall?.copyWith(color: p.inkMuted),
                      ),
                      const SizedBox(height: Sp.lg),
                      FilledButton.icon(
                        onPressed: () => _loadApps(forceRefresh: true),
                        icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 16),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final apps = snapshot.data ?? [];
          // Filter out current app if present in catalog by package name
          final currentPackage = AppInfoService.packageName;
          final filteredApps = apps.where((a) => a.packageName != currentPackage).toList();

          if (filteredApps.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Sp.page),
                child: Text(
                  'No other applications currently listed.',
                  style: t.bodyMedium?.copyWith(color: p.inkMuted),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadApps(forceRefresh: true),
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(Sp.page, Sp.sm, Sp.page, Sp.xl),
              itemCount: filteredApps.length,
              itemBuilder: (context, index) {
                final app = filteredApps[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: Sp.md),
                  child: _AppCardItem(app: app),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AppCardItem extends StatelessWidget {
  const _AppCardItem({required this.app});

  final SamyuktApp app;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final iconUrl = app.resolvedIconUrl;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Icon with graceful network fallback
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 52,
                  height: 52,
                  color: p.surfaceAlt,
                  child: iconUrl.isNotEmpty
                      ? Image.network(
                          iconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              PhosphorIconsRegular.appWindow,
                              size: 26,
                              color: p.primary,
                            ),
                          ),
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            PhosphorIconsRegular.appWindow,
                            size: 26,
                            color: p.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: Sp.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.appName,
                      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (app.tagline.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        app.tagline,
                        style: t.bodySmall?.copyWith(
                          color: p.inkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (app.description.isNotEmpty) ...[
            const SizedBox(height: Sp.md),
            Text(
              app.description,
              style: t.bodySmall?.copyWith(
                color: p.inkSubtle,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: Sp.md),
          Divider(height: 1, color: p.outline.withValues(alpha: 0.6)),
          const SizedBox(height: Sp.sm),
          Row(
            children: [
              if (app.category.isNotEmpty)
                Expanded(
                  child: Text(
                    app.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppType.mono,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: p.inkSubtle,
                    ),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: Sp.sm),
              if (app.status.isAvailable && app.playStoreUrl.isNotEmpty)
                FilledButton.tonalIcon(
                  onPressed: () => PlayService.openUrl(app.playStoreUrl),
                  icon: const Icon(PhosphorIconsRegular.arrowSquareOut, size: 16),
                  label: const Text('View App'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: null, // Disabled intentionally for coming soon
                  icon: const Icon(PhosphorIconsRegular.clock, size: 16),
                  label: const Text('Coming Soon'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
            ],
          ),

        ],
      ),
    );
  }
}

