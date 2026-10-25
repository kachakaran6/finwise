import 'package:flutter/material.dart';
import 'finwise_colors.dart';

@immutable
class FinwisePalette {
  const FinwisePalette({
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
  final Color seed;
  final Color primaryLight;
  final Color primaryDark;
  final Color accentGrowth;
  final Color accentLoans;
  final Color accentGoals;
  final Color accentReturns;
  final Color accentUtilities;

  // 1 · DEFAULT: Finwise Emerald (The genuine brand identity)
  static const finwiseGreen = FinwisePalette(
    id: 'finwise_green',
    name: 'Finwise Emerald',
    seed: Color(0xFF059669),
    primaryLight: Color(0xFF059669),
    primaryDark: Color(0xFF34D399),
    accentGrowth: FinwiseColors.catGrowth,
    accentLoans: FinwiseColors.catLoans,
    accentGoals: FinwiseColors.catGoals,
    accentReturns: FinwiseColors.catReturns,
    accentUtilities: FinwiseColors.catUtilities,
  );

  // 2 · Arctic Cyan (Vibrant Fintech Tech Cyan)
  static const deepTeal = FinwisePalette(
    id: 'deep_teal',
    name: 'Arctic Cyan',
    seed: Color(0xFF0284C7),
    primaryLight: Color(0xFF0284C7),
    primaryDark: Color(0xFF38BDF8),
    accentGrowth: Color(0xFF10B981),
    accentLoans: FinwiseColors.catLoans,
    accentGoals: FinwiseColors.catGoals,
    accentReturns: FinwiseColors.catReturns,
    accentUtilities: Color(0xFF0284C7),
  );

  // 3 · Sapphire Blue (Classic Royal Blue)
  static const oceanBlue = FinwisePalette(
    id: 'ocean_blue',
    name: 'Sapphire Blue',
    seed: Color(0xFF2563EB),
    primaryLight: Color(0xFF2563EB),
    primaryDark: Color(0xFF60A5FA),
    accentGrowth: Color(0xFF0EA5E9),
    accentLoans: FinwiseColors.catLoans,
    accentGoals: FinwiseColors.catGoals,
    accentReturns: FinwiseColors.catReturns,
    accentUtilities: Color(0xFF14B8A6),
  );

  // 4 · Sunset Rose (Vibrant Fintech Coral-Rose)
  static const royalIndigo = FinwisePalette(
    id: 'royal_indigo',
    name: 'Sunset Rose',
    seed: Color(0xFFE11D48),
    primaryLight: Color(0xFFE11D48),
    primaryDark: Color(0xFFFB7185),
    accentGrowth: FinwiseColors.catGrowth,
    accentLoans: Color(0xFF3B82F6),
    accentGoals: FinwiseColors.catGoals,
    accentReturns: Color(0xFFE11D48),
    accentUtilities: FinwiseColors.catUtilities,
  );

  // 5 · Amber Gold (Radiant Bullion Gold)
  static const amberGold = FinwisePalette(
    id: 'amber_gold',
    name: 'Amber Gold',
    seed: Color(0xFFD97706),
    primaryLight: Color(0xFFD97706),
    primaryDark: Color(0xFFFBBF24),
    accentGrowth: FinwiseColors.catGrowth,
    accentLoans: FinwiseColors.catLoans,
    accentGoals: FinwiseColors.catGoals,
    accentReturns: FinwiseColors.catReturns,
    accentUtilities: FinwiseColors.catUtilities,
  );

  // 6 · Royal Amethyst (Rich Regal Purple)
  static const grapeViolet = FinwisePalette(
    id: 'grape_violet',
    name: 'Royal Amethyst',
    seed: Color(0xFF7C3AED),
    primaryLight: Color(0xFF7C3AED),
    primaryDark: Color(0xFFA78BFA),
    accentGrowth: FinwiseColors.catGrowth,
    accentLoans: Color(0xFF3B82F6),
    accentGoals: FinwiseColors.catGoals,
    accentReturns: Color(0xFF7C3AED),
    accentUtilities: FinwiseColors.catUtilities,
  );

  static const defaultPalette = finwiseGreen;

  static const all = <FinwisePalette>[
    finwiseGreen,
    deepTeal,
    oceanBlue,
    royalIndigo,
    amberGold,
    grapeViolet,
  ];

  static FinwisePalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => finwiseGreen);
}
