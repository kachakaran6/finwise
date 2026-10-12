import 'package:flutter/material.dart';

/// Design tokens. Single source of truth for colour, spacing, radius, type.
///
/// Palette: ink-and-paper — warm neutral paper (light) / true graphite (dark).
/// One primary colour only: deep banknote green / ink-teal.
/// No brass/gold accent. Semantic colours only: gain (green) and loss (red).
/// 60 / 30 / 10 split: neutrals 60 %, primary 10 %, surface 30 %.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.outline,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.primary,
    required this.onPrimary,
    required this.gain,
    required this.loss,
    required this.navBg,
    required this.shadow,
  });

  final Color bg, surface, surfaceAlt, outline;
  final Color ink, inkMuted, inkSubtle;
  final Color primary, onPrimary;
  final Color gain, loss;
  final Color navBg, shadow;

  // ── Light theme — warm paper tones, no green tint on backgrounds ──────────
  static const light = AppPalette(
    bg:         Color(0xFFF5F4F0), // warm paper
    surface:    Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFECEBE6), // slightly warm off-white
    outline:    Color(0xFFDDDBD3),
    ink:        Color(0xFF17181A), // near-black ink
    inkMuted:   Color(0xFF5E6168),
    inkSubtle:  Color(0xFF82858C),
    primary:    Color(0xFF1F5A44), // deep banknote green
    onPrimary:  Color(0xFFFFFFFF),
    gain:       Color(0xFF1B7A4B),
    loss:       Color(0xFFB3261E),
    navBg:      Color(0xFF1A1C1F), // dark graphite — no green tint
    shadow:     Color(0x1A17181A),
  );

  // ── Dark theme — true graphite, no green tint on backgrounds ─────────────
  static const dark = AppPalette(
    bg:         Color(0xFF0E0F11),
    surface:    Color(0xFF16181B),
    surfaceAlt: Color(0xFF1D2024),
    outline:    Color(0xFF2A2D32),
    ink:        Color(0xFFECEDEF),
    inkMuted:   Color(0xFFA3A7AE),
    inkSubtle:  Color(0xFF70747B),
    primary:    Color(0xFF5DBB92), // lighter for dark backgrounds
    onPrimary:  Color(0xFF08130E),
    gain:       Color(0xFF5DBB92),
    loss:       Color(0xFFE5786D),
    navBg:      Color(0xFF1D2024), // matches surfaceAlt — neutral graphite
    shadow:     Color(0x66000000),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) =>
      other is AppPalette ? (t < 0.5 ? this : other) : this;
}

extension PaletteContext on BuildContext {
  AppPalette get pal => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

class Sp {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 20, xxl = 24, xxxl = 32;
  static const double page = 20;
  /// Space reserved at the bottom of scroll views for the floating nav bar.
  static const double navClearance = 96;
}

class Rd {
  static const double sm = 10, md = 14, lg = 20, xl = 28;
  static BorderRadius r(double v) => BorderRadius.circular(v);
}

class AppType {
  static const sans = 'IBMPlexSans';
  static const mono = 'IBMPlexMono';

  static const _tab = [FontFeature.tabularFigures()];

  static TextTheme textTheme(Color ink, Color muted) => TextTheme(
        displayLarge: TextStyle(fontFamily: sans, fontSize: 36, height: 1.15, fontWeight: FontWeight.w600, color: ink),
        headlineMedium: TextStyle(fontFamily: sans, fontSize: 26, height: 1.2, fontWeight: FontWeight.w600, color: ink),
        titleLarge: TextStyle(fontFamily: sans, fontSize: 20, height: 1.25, fontWeight: FontWeight.w600, color: ink),
        titleMedium: TextStyle(fontFamily: sans, fontSize: 16, height: 1.3, fontWeight: FontWeight.w600, color: ink),
        titleSmall: TextStyle(fontFamily: sans, fontSize: 14, height: 1.3, fontWeight: FontWeight.w600, color: ink),
        bodyLarge: TextStyle(fontFamily: sans, fontSize: 16, height: 1.45, color: ink),
        bodyMedium: TextStyle(fontFamily: sans, fontSize: 14, height: 1.45, color: ink),
        bodySmall: TextStyle(fontFamily: sans, fontSize: 12.5, height: 1.4, color: muted),
        labelLarge: TextStyle(fontFamily: sans, fontSize: 14, fontWeight: FontWeight.w600, color: ink),
        labelMedium: TextStyle(fontFamily: sans, fontSize: 12.5, fontWeight: FontWeight.w500, color: muted),
        labelSmall: TextStyle(fontFamily: sans, fontSize: 11, letterSpacing: 0.4, fontWeight: FontWeight.w500, color: muted),
      );

  /// Monospaced tabular figures for money values.
  static TextStyle figure(Color c, {double size = 15, FontWeight w = FontWeight.w500}) =>
      TextStyle(fontFamily: mono, fontSize: size, fontWeight: w, color: c, fontFeatures: _tab);
}
