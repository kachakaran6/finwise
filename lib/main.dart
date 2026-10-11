import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'data/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final prefs = await SharedPreferences.getInstance();
  final repo = await ScenarioRepository.open();
  runApp(ProviderScope(
    overrides: [prefsProvider.overrideWithValue(prefs), repoProvider.overrideWithValue(repo)],
    child: const FinanceApp(),
  ));
}
