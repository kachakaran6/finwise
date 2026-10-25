import 'package:flutter/material.dart';

@immutable
class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.seed,
    required this.primaryLight,
    required this.primaryDark,
    required this.accentGrowth,
    required this.accentLoans,
    required this.accentGoals,
    required this.accentReturns,
    required this.accentUtilities,
  });

  final String id;
  final String name;
  final Color seed;          // drives the whole M3 scheme
  final Color primaryLight;  // brand in light mode
  final Color primaryDark;   // brand in dark mode (lighter tone of same hue)
  final Color accentGrowth;
  final Color accentLoans;
  final Color accentGoals;
  final Color accentReturns;
  final Color accentUtilities;

  static AppPalette get defaultPalette => finwiseGreen;

  // 1 · DEFAULT: Finwise Emerald
  static const finwiseGreen = AppPalette(
    id: 'finwise_green',
    name: 'Finwise Emerald',
    seed: Color(0xFF059669),
    primaryLight: Color(0xFF059669),
    primaryDark: Color(0xFF34D399),
    accentGrowth: Color(0xFF10B981),
    accentLoans: Color(0xFF6366F1),
    accentGoals: Color(0xFFF59E0B),
    accentReturns: Color(0xFF8B5CF6),
    accentUtilities: Color(0xFF06B6D4),
  );

  // 2 · Arctic Cyan (Vibrant Fintech Tech Cyan)
  static const deepTeal = AppPalette(
    id: 'deep_teal',
    name: 'Arctic Cyan',
    seed: Color(0xFF0284C7),
    primaryLight: Color(0xFF0284C7),
    primaryDark: Color(0xFF38BDF8),
    accentGrowth: Color(0xFF10B981),
    accentLoans: Color(0xFF6366F1),
    accentGoals: Color(0xFFF59E0B),
    accentReturns: Color(0xFF8B5CF6),
    accentUtilities: Color(0xFF0284C7),
  );

  // 3 · Sapphire Blue (Classic Royal Blue)
  static const oceanBlue = AppPalette(
    id: 'ocean_blue',
    name: 'Sapphire Blue',
    seed: Color(0xFF2563EB),
    primaryLight: Color(0xFF2563EB),
    primaryDark: Color(0xFF60A5FA),
    accentGrowth: Color(0xFF0EA5E9),
    accentLoans: Color(0xFF6366F1),
    accentGoals: Color(0xFFF59E0B),
    accentReturns: Color(0xFF8B5CF6),
    accentUtilities: Color(0xFF14B8A6),
  );

  // 4 · Sunset Rose (Vibrant Fintech Coral-Rose)
  static const royalIndigo = AppPalette(
    id: 'royal_indigo',
    name: 'Sunset Rose',
    seed: Color(0xFFE11D48),
    primaryLight: Color(0xFFE11D48),
    primaryDark: Color(0xFFFB7185),
    accentGrowth: Color(0xFF10B981),
    accentLoans: Color(0xFF3B82F6),
    accentGoals: Color(0xFFF59E0B),
    accentReturns: Color(0xFFE11D48),
    accentUtilities: Color(0xFF06B6D4),
  );

  // 5 · Amber Gold (Radiant Bullion Gold)
  static const amberGold = AppPalette(
    id: 'amber_gold',
    name: 'Amber Gold',
    seed: Color(0xFFD97706),
    primaryLight: Color(0xFFD97706),
    primaryDark: Color(0xFFFBBF24),
    accentGrowth: Color(0xFF10B981),
    accentLoans: Color(0xFF6366F1),
    accentGoals: Color(0xFFF59E0B),
    accentReturns: Color(0xFF8B5CF6),
    accentUtilities: Color(0xFF06B6D4),
  );

  // 6 · Royal Amethyst (Rich Regal Purple)
  static const grapeViolet = AppPalette(
    id: 'grape_violet',
    name: 'Royal Amethyst',
    seed: Color(0xFF7C3AED),
    primaryLight: Color(0xFF7C3AED),
    primaryDark: Color(0xFFA78BFA),
    accentGrowth: Color(0xFF10B981),
    accentLoans: Color(0xFF3B82F6),
    accentGoals: Color(0xFFF59E0B),
    accentReturns: Color(0xFF7C3AED),
    accentUtilities: Color(0xFF06B6D4),
  );

  static const all = <AppPalette>[
    finwiseGreen,
    deepTeal,
    oceanBlue,
    royalIndigo,
    amberGold,
    grapeViolet,
  ];

  static AppPalette byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => finwiseGreen);
}
