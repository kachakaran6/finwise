import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0; // buttons, inputs, icon tiles
  static const lg = 16.0; // cards
  static const xl = 20.0; // sheets, result card
  static const pill = 999.0; // chips, pills, nav

  static BorderRadius r(double v) => BorderRadius.circular(v);
}
