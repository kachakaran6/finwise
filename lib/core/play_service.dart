import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_info.dart';

/// Service implementing the official Google Play in-app update and review flows,
/// as well as external store navigation and URL handling.
///
/// Strictly uses official Google Play APIs without custom dialog imitations.
/// All methods are lifecycle-safe, idempotent, and fail-silent when Play services
/// are unavailable (sideloaded builds, offline mode, non-Play devices).
class PlayService {
  const PlayService._();

  static const _kLastUpdateCheck = 'play_last_update_check';
  static const _kSaveCount = 'play_save_count';
  static const _kLastReviewDate = 'play_last_review_date';

  /// Engagement threshold before attempting review flow
  static const _kReviewThreshold = 3;

  /// Samyukt standard: minimum 15-day cooldown between review-flow requests
  static const _kReviewCooldownDays = 15;

  /// In-memory session flag to prevent duplicate review requests during the same app session
  static bool _sessionReviewRequested = false;

  /// Guard to prevent concurrent or duplicate update flows
  static bool _isCheckingUpdate = false;

  // ─── Native In-App Updates ────────────────────────────────────────────────

  /// Check for a Play Store update at app startup.
  /// Deduplicated to at most once per 24 hours automatically, but immediately resumes
  /// any previously downloaded flexible update.
  static Future<void> checkForUpdate(BuildContext context) async {
    if (_isCheckingUpdate) return;
    _isCheckingUpdate = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_kLastUpdateCheck) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final shouldCheckRemote = now - lastMs >= const Duration(hours: 24).inMilliseconds;

      final info = await InAppUpdate.checkForUpdate();

      // If a flexible update was already downloaded, prompt user to complete/restart
      if (info.installStatus == InstallStatus.downloaded) {
        if (context.mounted) _showFlexibleUpdateSnackBar(context);
        return;
      }

      if (!shouldCheckRemote) return;
      await prefs.setInt(_kLastUpdateCheck, now);

      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      if (info.updatePriority >= 4 && info.immediateUpdateAllowed) {
        // High-priority / mandatory update: Launch native immediate full-screen Play UI
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.flexibleUpdateAllowed) {
        if (!context.mounted) return;
        await _handleFlexibleUpdate(context);
      }
    } catch (_) {
      // Fail silently on non-Play devices, sideloads, or missing Play services
    } finally {
      _isCheckingUpdate = false;
    }
  }

  /// Resume or recover an in-progress update when app returns to foreground.
  static Future<void> onResume(BuildContext context) async {
    if (_isCheckingUpdate) return;
    try {
      final info = await InAppUpdate.checkForUpdate();

      // Flexible update downloaded in background -> notify user to complete
      if (info.installStatus == InstallStatus.downloaded) {
        if (context.mounted) _showFlexibleUpdateSnackBar(context);
        return;
      }

      // Immediate update interrupted -> re-launch native flow
      if (info.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (_) {
      // Fail silently
    }
  }

  /// Manually triggered from Settings "Check for updates" row.
  static Future<void> checkForUpdateManual(BuildContext context) async {
    if (_isCheckingUpdate) return;
    _isCheckingUpdate = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastUpdateCheck, 0); // reset timer to force check

      final info = await InAppUpdate.checkForUpdate();

      if (info.installStatus == InstallStatus.downloaded) {
        if (context.mounted) _showFlexibleUpdateSnackBar(context);
        return;
      }

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You're up to date with the latest version."),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (info.updatePriority >= 4 && info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.flexibleUpdateAllowed) {
        if (!context.mounted) return;
        await _handleFlexibleUpdate(context);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Google Play services are currently unavailable."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _isCheckingUpdate = false;
    }
  }

  static Future<void> _handleFlexibleUpdate(BuildContext context) async {
    try {
      final res = await InAppUpdate.startFlexibleUpdate();
      if (res == AppUpdateResult.success && context.mounted) {
        _showFlexibleUpdateSnackBar(context);
      }
    } catch (_) {
      // Fail silently
    }
  }

  static void _showFlexibleUpdateSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('An update has been downloaded.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(days: 1), // Remains until interacted
        action: SnackBarAction(
          label: 'Restart',
          onPressed: () {
            InAppUpdate.completeFlexibleUpdate().ignore();
          },
        ),
      ),
    );
  }

  // ─── Native In-App Review ─────────────────────────────────────────────────

  /// Call after a successful scenario save or meaningful user interaction.
  /// Follows the strict Samyukt Ecosystem review policy:
  /// 1. User meets engagement threshold (>= 3 saves).
  /// 2. Minimum 15-day cooldown has elapsed since the last attempt.
  /// 3. Never requests more than once per app session.
  /// 4. Never builds custom dialogs or fakes Play review UI.
  static Future<void> onScenarioSaved() async {
    if (_sessionReviewRequested) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt(_kSaveCount) ?? 0) + 1;
      await prefs.setInt(_kSaveCount, count);

      if (count < _kReviewThreshold) return;

      final lastMs = prefs.getInt(_kLastReviewDate) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastMs < const Duration(days: _kReviewCooldownDays).inMilliseconds) {
        return; // Still within 15-day cooldown
      }

      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        _sessionReviewRequested = true;
        await prefs.setInt(_kLastReviewDate, now);
        await review.requestReview();
      }
    } catch (_) {
      // Fail silently without disrupting user flow
    }
  }

  // ─── Rate Now (Direct Store Listing) ──────────────────────────────────────

  /// Explicit "Rate Now" action triggered from Settings.
  /// Opens the official Google Play Store listing directly.
  /// Does NOT represent this as the native in-app review API.
  static Future<void> openPlayStoreListing({String? packageName}) async {
    final pkg = packageName ?? AppInfoService.packageName;
    final marketUri = Uri.parse('market://details?id=$pkg');
    final webUri = Uri.parse('https://play.google.com/store/apps/details?id=$pkg');

    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Fallback to InAppReview's openStoreListing
      try {
        await InAppReview.instance.openStoreListing();
      } catch (_) {
        // Fail silently
      }
    }
  }

  /// Safe external URL launcher for links like https://samyukt.pro
  static Future<bool> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }
}
