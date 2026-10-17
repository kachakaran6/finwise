import 'dart:ui';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

class AppInfoService {
  AppInfoService._();

  static PackageInfo? _packageInfo;

  /// Load package info at startup or lazily.
  static Future<PackageInfo> init() async {
    if (_packageInfo != null) return _packageInfo!;
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (_) {
      _packageInfo = PackageInfo(
        appName: 'Finwise',
        packageName: 'com.finwise.appilcation',
        version: '1.0.1',
        buildNumber: '2',
        buildSignature: '',
      );
    }
    return _packageInfo!;
  }

  static String get appName => _packageInfo?.appName.isNotEmpty == true ? _packageInfo!.appName : 'Finwise';
  static String get packageName => _packageInfo?.packageName.isNotEmpty == true ? _packageInfo!.packageName : 'com.finwise.appilcation';
  static String get version => _packageInfo?.version.isNotEmpty == true ? _packageInfo!.version : '1.0.1';
  static String get buildNumber => _packageInfo?.buildNumber.isNotEmpty == true ? _packageInfo!.buildNumber : '2';

  /// Standardized version string: "Version 1.0.1 (Build 2)"
  static String get formattedVersion => 'Version $version (Build $buildNumber)';

  /// Official Play Store listing URL
  static String get playStoreUrl => 'https://play.google.com/store/apps/details?id=$packageName';

  /// Market scheme for native Play Store intent
  static String get playStoreMarketUri => 'market://details?id=$packageName';

  /// Samyukt official ecosystem portal
  static const String samyuktUrl = 'https://samyukt.pro';

  /// Generates the standard ecosystem share message dynamically
  static String generateShareMessage() {
    return 'Discover $appName — Privacy-first, fully offline personal finance and investment calculators.\n\n'
        'Explore the app and try it today:\n'
        '$playStoreUrl\n\n'
        'Made with care by Samyukt.';
  }

  /// Triggers the native Android Sharesheet with dynamic application content
  static Future<void> shareApp({Rect? sharePositionOrigin}) async {
    final message = generateShareMessage();
    try {
      await Share.share(
        message,
        subject: '$appName — Offline Finance Calculators',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (_) {
      // Fail silently on platform issues
    }
  }
}
