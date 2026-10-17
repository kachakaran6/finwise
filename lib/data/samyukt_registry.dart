import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum SamyuktAppStatus {
  production,
  published,
  comingSoon;

  bool get isAvailable => this == SamyuktAppStatus.production || this == SamyuktAppStatus.published;
  bool get isComingSoon => this == SamyuktAppStatus.comingSoon;

  String get displayName {
    switch (this) {
      case SamyuktAppStatus.production:
      case SamyuktAppStatus.published:
        return 'Available';
      case SamyuktAppStatus.comingSoon:
        return 'Coming Soon';
    }
  }
}

class SamyuktApp {
  final String id;
  final String appName;
  final String packageName;
  final String playStoreUrl;
  final String iconUrl;
  final SamyuktAppStatus status;
  final String category;
  final String tagline;
  final String description;
  final bool featured;
  final List<String> highlights;

  const SamyuktApp({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.playStoreUrl,
    required this.iconUrl,
    required this.status,
    required this.category,
    required this.tagline,
    required this.description,
    this.featured = false,
    this.highlights = const [],
  });

  /// Resolves relative or absolute icon paths against the Samyukt asset base.
  String get resolvedIconUrl {
    if (iconUrl.isEmpty) return '';
    if (iconUrl.startsWith('http://') || iconUrl.startsWith('https://')) {
      return iconUrl;
    }
    const assetBase = SamyuktRegistryService.assetBaseUrl;
    // If it starts with /images/, strip /images/ and append to asset base
    if (iconUrl.startsWith('/images/')) {
      final filename = iconUrl.substring('/images/'.length);
      return '$assetBase$filename';
    }
    // If it starts with /, strip leading slash
    final clean = iconUrl.startsWith('/') ? iconUrl.substring(1) : iconUrl;
    return '$assetBase$clean';
  }

  factory SamyuktApp.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? '').trim().toLowerCase();
    final status = _parseStatus(statusStr);
    if (status == null) {
      throw FormatException('Unsupported status: $statusStr');
    }

    return SamyuktApp(
      id: (json['id'] as String? ?? '').trim(),
      appName: (json['appName'] as String? ?? json['name'] as String? ?? '').trim(),
      packageName: (json['packageName'] as String? ?? '').trim(),
      playStoreUrl: (json['playStoreUrl'] as String? ?? '').trim(),
      iconUrl: (json['iconUrl'] as String? ?? '').trim(),
      status: status,
      category: (json['category'] as String? ?? '').trim(),
      tagline: (json['tagline'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      featured: json['featured'] as bool? ?? false,
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'appName': appName,
        'packageName': packageName,
        'playStoreUrl': playStoreUrl,
        'iconUrl': iconUrl,
        'status': status.name,
        'category': category,
        'tagline': tagline,
        'description': description,
        'featured': featured,
        'highlights': highlights,
      };

  static SamyuktAppStatus? _parseStatus(String raw) {
    switch (raw) {
      case 'production':
        return SamyuktAppStatus.production;
      case 'published':
        return SamyuktAppStatus.published;
      case 'coming_soon':
      case 'comingsoon':
        return SamyuktAppStatus.comingSoon;
      default:
        return null; // Exclude draft, in_progress, closed_testing, unknown
    }
  }
}

class SamyuktRegistryService {
  static const registryUrl =
      'https://raw.githubusercontent.com/kachakaran6/Application-json/main/app.json';
  static const assetBaseUrl =
      'https://raw.githubusercontent.com/kachakaran6/Application-json/main/images/';

  static const _cacheKey = 'samyukt_registry_cache_v1';
  static const _cacheTimeKey = 'samyukt_registry_cache_time_v1';

  final http.Client _client;
  SamyuktRegistryService({http.Client? client}) : _client = client ?? http.Client();

  /// Parse registry JSON string strictly according to Samyukt Ecosystem standards.
  /// Only includes mobile apps from `apps[]` with eligible statuses.
  /// Never includes entries from `websites[]`.
  static List<SamyuktApp> parseRegistryJson(String jsonString) {
    final decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected root object in registry JSON');
    }

    final appsRaw = decoded['apps'];
    if (appsRaw is! List<dynamic>) {
      throw const FormatException('Missing or invalid "apps" array in registry JSON');
    }

    final result = <SamyuktApp>[];
    for (final item in appsRaw) {
      if (item is Map<String, dynamic>) {
        final statusStr = (item['status'] as String? ?? '').trim().toLowerCase();
        // Only production, published, coming_soon
        if (statusStr != 'production' && statusStr != 'published' && statusStr != 'coming_soon') {
          continue;
        }
        try {
          final app = SamyuktApp.fromJson(item);
          if (app.appName.isNotEmpty) {
            result.add(app);
          }
        } catch (_) {
          // Skip invalid entries safely
        }
      }
    }
    return result;
  }

  /// Fetches apps from the remote registry, caching locally for offline resilience.
  /// Falls back to cached data if the remote request fails or the device is offline.
  Future<List<SamyuktApp>> fetchApps({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      // Check if we have recent cached data
      final cachedJson = prefs.getString(_cacheKey);
      final cachedTime = prefs.getInt(_cacheTimeKey) ?? 0;
      final isFresh = DateTime.now().millisecondsSinceEpoch - cachedTime < const Duration(hours: 6).inMilliseconds;

      if (cachedJson != null && isFresh) {
        try {
          final apps = parseRegistryJson(cachedJson);
          if (apps.isNotEmpty) return apps;
        } catch (_) {
          // Invalid cache, continue to fetch
        }
      }
    }

    try {
      final res = await _client
          .get(Uri.parse(registryUrl))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final apps = parseRegistryJson(res.body);
        // Cache the raw valid response
        await prefs.setString(_cacheKey, res.body);
        await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
        return apps;
      } else {
        throw Exception('Server returned ${res.statusCode}');
      }
    } catch (e) {
      // Fallback to cache on network failure or offline state
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null) {
        try {
          final apps = parseRegistryJson(cachedJson);
          if (apps.isNotEmpty) return apps;
        } catch (_) {}
      }
      rethrow;
    }
  }
}
