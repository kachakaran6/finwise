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

  // ── Light theme — crisp modern fintech palette ──────────────────────────
  static const light = AppPalette(
    bg:         Color(0xFFF8FAFC), // crisp clean slate-tinted canvas
    surface:    Color(0xFFFFFFFF), // pure white elevated cards
    surfaceAlt: Color(0xFFF1F5F9), // modern cool slate
    outline:    Color(0xFFE2E8F0), // ultra-subtle border
    ink:        Color(0xFF0F172A), // deep obsidian navy ink
    inkMuted:   Color(0xFF475569), // readable slate subtitle
    inkSubtle:  Color(0xFF94A3B8), // muted hint
    primary:    Color(0xFF059669), // modern emerald fintech green
    onPrimary:  Color(0xFFFFFFFF),
    gain:       Color(0xFF10B981), // emerald gain
    loss:       Color(0xFFEF4444), // coral rose loss
    navBg:      Color(0xFFFFFFFF), // pure white floating surface
    shadow:     Color(0x0F0F172A), // soft modern elevation
  );

  // ── Dark theme — sleek obsidian & deep space navy ─────────────────────────
  static const dark = AppPalette(
    bg:         Color(0xFF0B0F19), // rich obsidian background
    surface:    Color(0xFF131B2E), // velvety deep navy card
    surfaceAlt: Color(0xFF1E293B), // elevated slate container
    outline:    Color(0xFF243044), // subtle definition
    ink:        Color(0xFFF8FAFC), // crisp luminous white
    inkMuted:   Color(0xFF94A3B8), // soft slate
    inkSubtle:  Color(0xFF64748B), // muted
    primary:    Color(0xFF10B981), // radiant emerald
    onPrimary:  Color(0xFF042F24), // deep contrast
    gain:       Color(0xFF34D399),
    loss:       Color(0xFFF87171),
    navBg:      Color(0xFF131B2E),
    shadow:     Color(0x55000000),
  );

  LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, primary.withValues(alpha: 0.85)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get heroGradient => LinearGradient(
        colors: [
          primary,
          Color.lerp(primary, const Color(0xFF0D9488), 0.5) ?? primary,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Domain category accent colors
  Color get accentGrowth => const Color(0xFF10B981);
  Color get accentLoans => const Color(0xFF6366F1);
  Color get accentGoals => const Color(0xFFF59E0B);
  Color get accentReturns => const Color(0xFF8B5CF6);
  Color get accentUtilities => const Color(0xFF06B6D4);

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? outline,
    Color? ink,
    Color? inkMuted,
    Color? inkSubtle,
    Color? primary,
    Color? onPrimary,
    Color? gain,
    Color? loss,
    Color? navBg,
    Color? shadow,
  }) =>
      AppPalette(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt ?? this.surfaceAlt,
        outline: outline ?? this.outline,
        ink: ink ?? this.ink,
        inkMuted: inkMuted ?? this.inkMuted,
        inkSubtle: inkSubtle ?? this.inkSubtle,
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        gain: gain ?? this.gain,
        loss: loss ?? this.loss,
        navBg: navBg ?? this.navBg,
        shadow: shadow ?? this.shadow,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkSubtle: Color.lerp(inkSubtle, other.inkSubtle, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      gain: Color.lerp(gain, other.gain, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      navBg: Color.lerp(navBg, other.navBg, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
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
  static const double xs = 6, sm = 10, md = 14, lg = 20, xl = 28, full = 999;
  static BorderRadius r(double v) => BorderRadius.circular(v);
}

class AppType {
  static const sans = 'IBMPlexSans';
  static const mono = 'IBMPlexMono';

  static const _tab = [FontFeature.tabularFigures()];

  static TextTheme textTheme(Color ink, Color muted) => TextTheme(
        displayLarge: TextStyle(fontFamily: sans, fontSize: 36, height: 1.15, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontFamily: sans, fontSize: 26, height: 1.2, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.3),
        titleLarge: TextStyle(fontFamily: sans, fontSize: 20, height: 1.25, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.2),
        titleMedium: TextStyle(fontFamily: sans, fontSize: 16, height: 1.3, fontWeight: FontWeight.w600, color: ink),
        titleSmall: TextStyle(fontFamily: sans, fontSize: 14.5, height: 1.3, fontWeight: FontWeight.w600, color: ink),
        bodyLarge: TextStyle(fontFamily: sans, fontSize: 16, height: 1.45, color: ink),
        bodyMedium: TextStyle(fontFamily: sans, fontSize: 14, height: 1.45, color: ink),
        bodySmall: TextStyle(fontFamily: sans, fontSize: 12.5, height: 1.4, color: muted),
        labelLarge: TextStyle(fontFamily: sans, fontSize: 14, fontWeight: FontWeight.w600, color: ink),
        labelMedium: TextStyle(fontFamily: sans, fontSize: 12.5, fontWeight: FontWeight.w500, color: muted),
        labelSmall: TextStyle(fontFamily: sans, fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.w600, color: muted),
      );

  /// Monospaced tabular figures for money values.
  static TextStyle figure(Color c, {double size = 15, FontWeight w = FontWeight.w600}) =>
      TextStyle(fontFamily: mono, fontSize: size, fontWeight: w, color: c, fontFeatures: _tab);
}
