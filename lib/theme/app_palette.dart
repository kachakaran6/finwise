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

  // 1 · DEFAULT
  static const royalIndigo = AppPalette(
    id: 'royal_indigo',
    name: 'Royal Indigo',
    seed: Color(0xFF4F46E5),
    primaryLight: Color(0xFF4F46E5),
    primaryDark: Color(0xFF818CF8),
    accentGrowth: Color(0xFF10B981),
    accentLoans: Color(0xFF3B82F6),
    accentGoals: Color(0xFFF59E0B),
    accentReturns: Color(0xFFA855F7),
    accentUtilities: Color(0xFF06B6D4),
  );

  // 2 · the current brand
  static const finwiseGreen = AppPalette(
    id: 'finwise_green',
    name: 'Finwise Green',
    seed: Color(0xFF059669),
    primaryLight: Color(0xFF059669),
    primaryDark: Color(0xFF34D399),
    accentGrowth: Color(0xFF10B981),
    accentLoans: Color(0xFF6366F1),
    accentGoals: Color(0xFFF59E0B),
    accentReturns: Color(0xFF8B5CF6),
    accentUtilities: Color(0xFF06B6D4),
  );

  // 3 · Ocean Blue
  static const oceanBlue = AppPalette(
    id: 'ocean_blue',
    name: 'Ocean Blue',
    seed: Color(0xFF2563EB),
    primaryLight: Color(0xFF2563EB),
    primaryDark: Color(0xFF60A5FA),
    accentGrowth: Color(0xFF0EA5E9),
    accentLoans: Color(0xFF6366F1),
    accentGoals: Color(0xFFF59E0B),
    accentReturns: Color(0xFF8B5CF6),
    accentUtilities: Color(0xFF14B8A6),
  );

  // 4 · Deep Teal
  static const deepTeal = AppPalette(
    id: 'deep_teal',
    name: 'Deep Teal',
    seed: Color(0xFF0D9488),
    primaryLight: Color(0xFF0D9488),
    primaryDark: Color(0xFF2DD4BF),
    accentGrowth: Color(0xFF22C55E),
    accentLoans: Color(0xFF6366F1),
    accentGoals: Color(0xFFF59E0B),
    accentReturns: Color(0xFF8B5CF6),
    accentUtilities: Color(0xFF0EA5E9),
  );

  // 5 · Grape Violet
  static const grapeViolet = AppPalette(
    id: 'grape_violet',
    name: 'Grape Violet',
    seed: Color(0xFF7C3AED),
    primaryLight: Color(0xFF7C3AED),
    primaryDark: Color(0xFFA78BFA),
    accentGrowth: Color(0xFF10B981),
    accentLoans: Color(0xFF3B82F6),
    accentGoals: Color(0xFFF59E0B),
    accentReturns: Color(0xFFEC4899),
    accentUtilities: Color(0xFF06B6D4),
  );

  // 6 · Amber Gold
  static const amberGold = AppPalette(
    id: 'amber_gold',
    name: 'Amber Gold',
    seed: Color(0xFFD97706),
    primaryLight: Color(0xFFB45309),
    primaryDark: Color(0xFFFBBF24),
    accentGrowth: Color(0xFF10B981),
    accentLoans: Color(0xFF6366F1),
    accentGoals: Color(0xFFF97316),
    accentReturns: Color(0xFF8B5CF6),
    accentUtilities: Color(0xFF06B6D4),
  );

  static const all = <AppPalette>[
    royalIndigo,
    finwiseGreen,
    oceanBlue,
    deepTeal,
    grapeViolet,
    amberGold,
  ];

  static AppPalette byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => royalIndigo);
}
