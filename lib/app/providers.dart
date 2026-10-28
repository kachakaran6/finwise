import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/format.dart';
import '../data/storage.dart';
import '../domain/models/calc.dart';
import '../features/custom_studio/data/custom_calc_repository.dart';
import '../features/custom_studio/domain/models/custom_calc_definition.dart';

final prefsProvider =
    Provider<SharedPreferences>((_) => throw UnimplementedError());
final repoProvider =
    Provider<ScenarioRepository>((_) => throw UnimplementedError());

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.paletteId = 'finwise_green',
    this.currency = 'INR',
    this.locale = 'en_IN',
    this.favorites = const [],
    this.recents = const [],
  });
  final ThemeMode themeMode;
  final String paletteId;
  final String currency, locale;
  final List<String> favorites, recents;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? paletteId,
    String? currency,
    String? locale,
    List<String>? favorites,
    List<String>? recents,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        paletteId: paletteId ?? this.paletteId,
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
    final theme =
        _p.getString('theme') ?? _p.getString('theme_mode') ?? 'system';
    final palette = _p.getString('theme_palette') ?? 'finwise_green';
    return AppSettings(
      themeMode: ThemeMode.values
          .firstWhere((m) => m.name == theme, orElse: () => ThemeMode.system),
      paletteId: palette,
      currency: _p.getString('currency') ?? 'INR',
      locale: _p.getString('locale') ?? 'en_IN',
      favorites: _p.getStringList('favorites') ?? const [],
      recents: _p.getStringList('recents') ?? const [],
    );
  }

  void setTheme(ThemeMode m) {
    _p.setString('theme', m.name);
    _p.setString('theme_mode', m.name);
    state = state.copyWith(themeMode: m);
  }

  void setPalette(String id) {
    _p.setString('theme_palette', id);
    state = state.copyWith(paletteId: id);
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

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final fmtProvider = Provider<Fmt>((ref) {
  final s = ref.watch(settingsProvider);
  return Fmt(currencyByCode(s.currency), s.locale);
});

class ScenariosNotifier extends AsyncNotifier<List<Scenario>> {
  @override
  Future<List<Scenario>> build() => ref.read(repoProvider).all();

  Future<void> _reload() async =>
      state = AsyncData(await ref.read(repoProvider).all());

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

final scenariosProvider =
    AsyncNotifierProvider<ScenariosNotifier, List<Scenario>>(
        ScenariosNotifier.new);

final customCalcRepoProvider = Provider<CustomCalcRepository>(
    (ref) => ref.watch(repoProvider).customCalcRepo);

class CustomCalcsNotifier extends AsyncNotifier<List<CustomCalcDefinition>> {
  @override
  Future<List<CustomCalcDefinition>> build() =>
      ref.read(customCalcRepoProvider).all();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(customCalcRepoProvider).all());
  }

  Future<void> save(CustomCalcDefinition def) async {
    await ref.read(customCalcRepoProvider).save(def);
    await reload();
  }

  Future<void> delete(String id) async {
    await ref.read(customCalcRepoProvider).delete(id);
    await reload();
  }

  Future<CustomCalcDefinition> duplicate(String id) async {
    final copy = await ref.read(customCalcRepoProvider).duplicate(id);
    await reload();
    return copy;
  }
}

final customCalcsProvider =
    AsyncNotifierProvider<CustomCalcsNotifier, List<CustomCalcDefinition>>(
        CustomCalcsNotifier.new);

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(DateTime.now().millisecond * 7919 % 9973).toRadixString(36)}';
