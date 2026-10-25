import 'package:flutter/material.dart';

abstract final class FinwiseShapes {
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusPill = 999;

  static BorderRadius r(double v) => BorderRadius.circular(v);
  static BorderRadius get xs => BorderRadius.circular(radiusXs);
  static BorderRadius get sm => BorderRadius.circular(radiusSm);
  static BorderRadius get md => BorderRadius.circular(radiusMd);
  static BorderRadius get lg => BorderRadius.circular(radiusLg);
  static BorderRadius get xl => BorderRadius.circular(radiusXl);
  static BorderRadius get pill => BorderRadius.circular(radiusPill);

  // Component shapes
  static RoundedRectangleBorder get cardShape =>
      RoundedRectangleBorder(borderRadius: lg);
  static RoundedRectangleBorder get buttonShape =>
      RoundedRectangleBorder(borderRadius: md);
  static RoundedRectangleBorder get dialogShape =>
      RoundedRectangleBorder(borderRadius: xl);
  static RoundedRectangleBorder get sheetShape =>
      const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)));
}
