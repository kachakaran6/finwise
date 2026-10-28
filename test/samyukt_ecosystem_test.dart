import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finwise/app/providers.dart';
import 'package:finwise/app/theme/theme.dart';
import 'package:finwise/core/app_info.dart';
import 'package:finwise/data/samyukt_registry.dart';
import 'package:finwise/data/storage.dart';
import 'package:finwise/features/ecosystem/our_apps_page.dart';
import 'package:finwise/features/settings/settings_page.dart';

const _mockValidRegistry = '''
{
  "version": "2.0.0",
  "updatedAt": "2026-10-14",
  "apps": [
    {
      "id": "com.vaultx.vault_x",
      "appName": "Vault X",
      "packageName": "com.vaultx.vault_x",
      "playStoreUrl": "https://play.google.com/store/apps/details?id=com.vaultx.vault_x",
      "iconUrl": "/images/vaultx.png",
      "status": "production",
      "category": "Android utility & Privacy",
      "tagline": "Secure on-device digital bookmark vault",
      "description": "The ultimate link vault."
    },
    {
      "id": "com.trusttracker.trust_tracker_flutter",
      "appName": "Trust Tracker",
      "packageName": "com.trusttracker.trust_tracker_flutter",
      "playStoreUrl": "https://play.google.com/store/apps/details?id=com.trusttracker.trust_tracker_flutter",
      "iconUrl": "https://example.com/icon.png",
      "status": "PUBLISHED",
      "category": "Android utility",
      "tagline": "Expense ledger",
      "description": "Track subscriptions"
    },
    {
      "id": "com.upcoming.app",
      "appName": "Upcoming App",
      "packageName": "com.upcoming.app",
      "playStoreUrl": "",
      "iconUrl": "/images/upcoming.png",
      "status": "coming_soon",
      "category": "Productivity",
      "tagline": "Coming soon",
      "description": "In the pipeline"
    },
    {
      "id": "com.draft.app",
      "appName": "Draft App",
      "packageName": "com.draft.app",
      "status": "draft"
    },
    {
      "id": "com.closed.app",
      "appName": "Testing App",
      "packageName": "com.closed.app",
      "status": "closed_testing"
    },
    {
      "id": "com.wip.app",
      "appName": "WIP App",
      "packageName": "com.wip.app",
      "status": "in_progress"
    }
  ],
  "websites": [
    {
      "id": "web1",
      "name": "Web Application",
      "status": "production"
    }
  ]
}
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Samyukt Ecosystem Registry Parsing & Filtering Tests', () {
    test(
        'Strict filtering: only includes production, published, coming_soon from apps[]',
        () {
      final apps = SamyuktRegistryService.parseRegistryJson(_mockValidRegistry);

      // Total apps: 6, but only Vault X (production), Trust Tracker (PUBLISHED -> published), and Upcoming App (coming_soon) should be included.
      // Draft, closed_testing, in_progress, and all entries from websites[] MUST be excluded.
      expect(apps.length, 3);
      expect(apps[0].appName, 'Vault X');
      expect(apps[0].status, SamyuktAppStatus.production);
      expect(apps[1].appName, 'Trust Tracker');
      expect(apps[1].status, SamyuktAppStatus.published);
      expect(apps[2].appName, 'Upcoming App');
      expect(apps[2].status, SamyuktAppStatus.comingSoon);

      // Verify no websites leaked
      expect(apps.any((a) => a.appName == 'Web Application'), isFalse);
      expect(apps.any((a) => a.appName == 'Draft App'), isFalse);
    });

    test('Resolves relative and absolute icon URLs correctly', () {
      final apps = SamyuktRegistryService.parseRegistryJson(_mockValidRegistry);

      // Relative icon starting with /images/
      expect(
        apps[0].resolvedIconUrl,
        'https://raw.githubusercontent.com/kachakaran6/Application-json/main/images/vaultx.png',
      );

      // Absolute https icon URL
      expect(apps[1].resolvedIconUrl, 'https://example.com/icon.png');
    });

    test('Handles malformed and unexpected JSON gracefully', () {
      expect(() => SamyuktRegistryService.parseRegistryJson('not a json'),
          throwsA(isA<FormatException>()));
      expect(
          () => SamyuktRegistryService.parseRegistryJson('{"no_apps": true}'),
          throwsA(isA<FormatException>()));

      // Empty apps array returns empty list safely
      final empty = SamyuktRegistryService.parseRegistryJson('{"apps": []}');
      expect(empty, isEmpty);
    });
  });

  group('Samyukt Registry Offline Caching Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Falls back to cached registry data when remote fetch fails',
        () async {
      // Mock network failure
      final mockClient = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      // Pre-seed cache
      await prefs.setString('samyukt_registry_cache_v1', _mockValidRegistry);

      final service = SamyuktRegistryService(client: mockClient);
      final apps = await service.fetchApps();

      expect(apps.length, 3);
      expect(apps[0].appName, 'Vault X');
    });
  });

  group('AppInfoService & Standard Dynamic Sharing Tests', () {
    test('Generates ecosystem compliant share message', () {
      final message = AppInfoService.generateShareMessage();

      expect(message, contains('Discover Finwise'));
      expect(
          message,
          contains(
              'https://play.google.com/store/apps/details?id=com.finwise.appilcation'));
      expect(message, contains('Made with care by Samyukt.'));
    });

    test('Formatted version complies with Version X.Y.Z (Build N)', () {
      final version = AppInfoService.formattedVersion;
      expect(version, matches(r'^Version .+\(Build .+\)$'));
    });
  });

  group('Settings & Ecosystem UI Integration Tests', () {
    late SharedPreferences prefs;
    late ScenarioRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'theme': 'system',
        'currency': 'INR',
        'locale': 'en_IN',
        'samyukt_registry_cache_v1': _mockValidRegistry,
      });
      prefs = await SharedPreferences.getInstance();
      repo = ScenarioRepository.inMemory();
    });

    Widget createTestApp(Widget home) {
      return ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          repoProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: home,
        ),
      );
    }

    testWidgets(
        'SettingsPage renders Our Apps, dynamic version, and Samyukt attribution',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester
          .pumpWidget(createTestApp(const Scaffold(body: SettingsPage())));
      await tester.pumpAndSettle();

      // Check Ecosystem group
      expect(find.text('Our Apps'), findsOneWidget);
      expect(find.text('Explore apps by Samyukt'), findsOneWidget);

      // Check App actions
      expect(find.text('Share Finwise'), findsOneWidget);
      expect(find.text('Rate Finwise'), findsOneWidget);
      expect(find.text('Check for updates'), findsOneWidget);

      // Check Samyukt attribution
      expect(find.text('Made with care by Samyukt'), findsOneWidget);

      // Check dynamic version badge
      expect(find.textContaining('Version'), findsOneWidget);
    });

    testWidgets('OurAppsPage renders application cards from registry',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp(const OurAppsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Our Apps'), findsOneWidget);
      expect(find.text('Vault X'), findsOneWidget);
      expect(find.text('Trust Tracker'), findsOneWidget);
      expect(find.text('Upcoming App'), findsOneWidget);
      expect(find.text('Coming Soon'), findsOneWidget);
      expect(find.text('View App'), findsNWidgets(2));
    });
  });
}
