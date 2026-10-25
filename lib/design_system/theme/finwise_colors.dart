import 'package:flutter/material.dart';

/// Single source of truth for Finwise color definitions.
abstract final class FinwiseColors {
  // Brand Emerald ramp (The core Finwise brand identity)
  static const Color brand50 = Color(0xFFECFDF5);
  static const Color brand100 = Color(0xFFD1FAE5);
  static const Color brand200 = Color(0xFFA7F3D0);
  static const Color brand300 = Color(0xFF6EE7B7);
  static const Color brand400 = Color(0xFF34D399); // Dark mode radiant emerald
  static const Color brand500 = Color(0xFF10B981); // Emerald gain / accent
  static const Color brand600 = Color(0xFF059669); // Light mode brand primary
  static const Color brand700 = Color(0xFF047857);
  static const Color brand800 = Color(0xFF065F46);
  static const Color brand900 = Color(0xFF064E3B);
  static const Color brandDarkContrast = Color(0xFF04211A);
  static const Color brandAdaptiveIcon = Color(0xFF0F5C3A);

  // Slate Neutral ramp
  static const Color white = Color(0xFFFFFFFF);
  static const Color n50 = Color(0xFFF8FAFC);
  static const Color n100 = Color(0xFFF1F5F9);
  static const Color n200 = Color(0xFFE2E8F0);
  static const Color n300 = Color(0xFFCBD5E1);
  static const Color n400 = Color(0xFF94A3B8);
  static const Color n500 = Color(0xFF64748B);
  static const Color n600 = Color(0xFF475569);
  static const Color n700 = Color(0xFF334155);
  static const Color n800 = Color(0xFF1E293B);
  static const Color n900 = Color(0xFF0F172A);
  static const Color n950 = Color(0xFF020617);

  // Light theme surfaces
  static const Color lightBg = Color(0xFFF6F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightSurfaceGlass = Color(0xE6FFFFFF); // 90% opacity
  static const Color lightOutline = Color(0xFFE2E8F0);
  static const Color lightOutlineStrong = Color(0xFFCBD5E1);

  // Dark theme surfaces (Obsidian / Deep Space Navy)
  static const Color darkBg = Color(0xFF0B0F17);
  static const Color darkSurface = Color(0xFF151C28);
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkSurfaceGlass = Color(0xD9151C28); // 85% opacity
  static const Color darkOutline = Color(0xFF2A3340);
  static const Color darkOutlineStrong = Color(0xFF3A4553);

  // Category Domain Accents
  static const Color catGrowth = Color(0xFF10B981);
  static const Color catLoans = Color(0xFF6366F1);
  static const Color catGoals = Color(0xFFF59E0B);
  static const Color catReturns = Color(0xFF8B5CF6);
  static const Color catUtilities = Color(0xFF06B6D4);

  // Semantic Financial Colors (WCAG 2.1 AA compliant)
  static const Color gainLight = Color(0xFF047857);
  static const Color gainDark = Color(0xFF34D399);
  static const Color lossLight = Color(0xFFDC2626);
  static const Color lossDark = Color(0xFFF87171);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}
