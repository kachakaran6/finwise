import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/services.dart';

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
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final iconBrightness = isDark ? Brightness.light : Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: iconBrightness,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: iconBrightness,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const Shell(),
    );
  }
}
