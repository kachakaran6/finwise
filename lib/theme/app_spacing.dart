import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  static const screen = 16.0; // horizontal screen padding
  static const cardGap = 10.0; // gap between cards
  static const sectionGap = 18.0; // gap between sections
  static const navClearance = 112.0; // bottom scroll clearance for floating nav
  static const navDockHeight = 54.0;
  static const navDockMargin = 8.0;

  /// Dynamic bottom scroll clearance that incorporates system navigation insets and breathing room.
  static double bottomNavClearance(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final dockBottom = bottomInset > 0 ? bottomInset + navDockMargin : md;
    return navDockHeight + dockBottom + xl;
  }
}
