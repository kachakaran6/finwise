import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/shell/shell.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import 'providers.dart';

class FinanceApp extends ConsumerWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final palette = AppPalette.byId(settings.paletteId);
    return MaterialApp(
      title: 'Finwise',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.light(palette),
      darkTheme: AppTheme.dark(palette),
      home: const Shell(),
    );
  }
}
