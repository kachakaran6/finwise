import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/format.dart';
import '../data/storage.dart';
import '../domain/models/calc.dart';

final prefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());
final repoProvider = Provider<ScenarioRepository>((_) => throw UnimplementedError());

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.currency = 'INR',
    this.locale = 'en_IN',
    this.favorites = const [],
    this.recents = const [],
  });
  final ThemeMode themeMode;
  final String currency, locale;
  final List<String> favorites, recents;

  AppSettings copyWith({ThemeMode? themeMode, String? currency, String? locale, List<String>? favorites, List<String>? recents}) => AppSettings(
        themeMode: themeMode ?? this.themeMode,
        currency: currency ?? this.currency,
        locale: locale ?? this.locale,
        favorites: favorites ?? this.favorites,
        recents: recents ?? this.recents,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  late SharedPreferences _p;

  @override
  AppSettings build() {
    _p = ref.read(prefsProvider);
    final theme = _p.getString('theme') ?? 'system';
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere((m) => m.name == theme, orElse: () => ThemeMode.system),
      currency: _p.getString('currency') ?? 'INR',
      locale: _p.getString('locale') ?? 'en_IN',
      favorites: _p.getStringList('favorites') ?? const [],
      recents: _p.getStringList('recents') ?? const [],
    );
  }

  void setTheme(ThemeMode m) {
    _p.setString('theme', m.name);
    state = state.copyWith(themeMode: m);
  }

  void setCurrency(String code) {
    _p.setString('currency', code);
    if (code == 'INR' && state.locale == 'en_US') {
      _p.setString('locale', 'en_IN');
      state = state.copyWith(currency: code, locale: 'en_IN');
      return;
    }
    state = state.copyWith(currency: code);
  }

  void setLocale(String l) {
    _p.setString('locale', l);
    state = state.copyWith(locale: l);
  }

  void toggleFavorite(String id) {
    final f = [...state.favorites];
    f.contains(id) ? f.remove(id) : f.add(id);
    _p.setStringList('favorites', f);
    state = state.copyWith(favorites: f);
  }

  void pushRecent(String id) {
    final r = [id, ...state.recents.where((e) => e != id)].take(6).toList();
    _p.setStringList('recents', r);
    state = state.copyWith(recents: r);
  }

  Future<void> resetAll() async {
    await _p.clear();
    state = const AppSettings();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final fmtProvider = Provider<Fmt>((ref) {
  final s = ref.watch(settingsProvider);
  return Fmt(currencyByCode(s.currency), s.locale);
});

class ScenariosNotifier extends AsyncNotifier<List<Scenario>> {
  @override
  Future<List<Scenario>> build() => ref.read(repoProvider).all();

  Future<void> _reload() async => state = AsyncData(await ref.read(repoProvider).all());

  Future<void> save(Scenario s) async {
    await ref.read(repoProvider).upsert(s);
    await _reload();
  }

  Future<void> saveAll(List<Scenario> list) async {
    await ref.read(repoProvider).upsertAll(list);
    await _reload();
  }

  Future<void> remove(String id) async {
    await ref.read(repoProvider).delete(id);
    await _reload();
  }

  Future<void> clear() async {
    await ref.read(repoProvider).clear();
    await _reload();
  }
}

final scenariosProvider = AsyncNotifierProvider<ScenariosNotifier, List<Scenario>>(ScenariosNotifier.new);

String newId() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(DateTime.now().millisecond * 7919 % 9973).toRadixString(36)}';
