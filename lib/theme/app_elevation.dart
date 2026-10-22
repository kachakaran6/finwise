import 'package:flutter/material.dart';

abstract final class AppElevation {
  // Light: soft shadow (<=10% opacity). Dark: surface + border, no shadow.
  static const e1Light = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F0F172A), // 6% opacity
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const e2Light = <BoxShadow>[
    BoxShadow(
      color: Color(0x1A0F172A), // 10% opacity
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const e2Dark = <BoxShadow>[
    BoxShadow(
      color: Color(0x73000000), // 45% black
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
