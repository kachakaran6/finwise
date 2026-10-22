import 'package:flutter/material.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';

export '../../theme/app_palette.dart';
export '../../theme/app_theme.dart';

ThemeData buildTheme(Brightness b, [AppPalette? palette]) {
  return b == Brightness.dark ? AppTheme.dark(palette) : AppTheme.light(palette);
}
