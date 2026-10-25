import 'package:flutter/material.dart';

abstract final class FinwiseElevation {
  static const List<BoxShadow> e1Light = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> e2Light = [
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> e1Dark = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> e2Dark = [
    BoxShadow(
      color: Color(0x60000000),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  // Specific floating navbar shadows
  static const List<BoxShadow> navShadowLight = [
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 24,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> navShadowDark = [
    BoxShadow(
      color: Color(0x80000000),
      blurRadius: 24,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];
}
