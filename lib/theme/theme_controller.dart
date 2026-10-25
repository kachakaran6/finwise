import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_palette.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs)
      : _mode = _readMode(_prefs),
        _palette = _readPalette(_prefs);

  final SharedPreferences _prefs;
  ThemeMode _mode;
  AppPalette _palette;

  ThemeMode get mode => _mode;
  AppPalette get palette => _palette;

  void setMode(ThemeMode m) {
    _mode = m;
    _prefs.setString('theme_mode', m.name);
    _prefs.setString('theme', m.name);
    notifyListeners();
  }

  void setPalette(AppPalette p) {
    _palette = p;
    _prefs.setString('theme_palette', p.id);
    notifyListeners();
  }

  static ThemeMode _readMode(SharedPreferences p) => ThemeMode.values
      .firstWhere((m) => m.name == (p.getString('theme_mode') ?? p.getString('theme')),
          orElse: () => ThemeMode.system);

  // Default when nothing is saved = Finwise Green
  static AppPalette _readPalette(SharedPreferences p) => AppPalette.all
      .firstWhere((x) => x.id == p.getString('theme_palette'),
          orElse: () => AppPalette.finwiseGreen);
}
