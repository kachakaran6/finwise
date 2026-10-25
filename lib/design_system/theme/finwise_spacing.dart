import 'package:flutter/widgets.dart';

abstract final class FinwiseSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Semantic layout spacing
  static const double screen = 16;
  static const double page = 16;
  static const double cardGap = 12;
  static const double sectionGap = 24;

  // Bottom navigation clearance so scroll views are never cut off
  static const double navClearance = 112;
  static const double navBarHeight = 54;
  static const double navDockHeight = 54;
  static const double navDockMargin = 8;

  /// Dynamic bottom scroll clearance that incorporates system navigation insets and breathing room.
  static double bottomNavClearance(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final dockBottom = bottomInset > 0 ? bottomInset + navDockMargin : md;
    return navDockHeight + dockBottom + xl;
  }
}
