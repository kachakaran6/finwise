import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that wraps native Google Play in-app update and review flows.
///
/// All methods are fail-silent: on non-Play builds, sideloads, or devices
/// without the Play Store they return immediately without showing anything.
/// No custom UI is shown — only the native Play UI is triggered.
class PlayService {
  const PlayService._();

  static const _kLastUpdateCheck = 'play_last_update_check';
  static const _kSaveCount = 'play_save_count';
  static const _kLastReviewDate = 'play_last_review_date';
  static const _kReviewThreshold = 3; // trigger review after N successful saves
  static const _kReviewCooldownDays = 60;

  // ─── Updates ──────────────────────────────────────────────────────────────

  /// Check for a Play Store update. At most once per 24 hours.
  ///
  /// Pass [scaffoldKey] so we can show the "Update ready / Restart" snackbar
  /// when a flexible download completes.
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_kLastUpdateCheck) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastMs < const Duration(hours: 24).inMilliseconds) return;
      await prefs.setInt(_kLastUpdateCheck, now);

      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      if (info.updatePriority >= 4 && info.immediateUpdateAllowed) {
        // High-priority: full-screen Play UI.
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.flexibleUpdateAllowed) {
        if (!context.mounted) return;
        await _handleFlexible(context);
      }
    } catch (_) {
      // Fail silently on non-Play devices, sideloads, or missing Play services.
    }
  }

  /// Manually triggered from Settings "Check for updates" row.
  static Future<void> checkForUpdateManual(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastUpdateCheck, 0); // reset to force check
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You're up to date")),
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
        await _handleFlexible(context);
      }
    } catch (_) {
      // Fail silently.
    }
  }

  static Future<void> _handleFlexible(BuildContext context) async {
    try {
      final res = await InAppUpdate.startFlexibleUpdate();
      if (res == AppUpdateResult.success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Update ready'),
            action: SnackBarAction(
              label: 'Restart',
              onPressed: () {
                InAppUpdate.completeFlexibleUpdate().ignore();
              },
            ),
          ),
        );
      }
    } catch (_) {
      // Fail silently.
    }
  }

  // ─── Reviews ──────────────────────────────────────────────────────────────

  /// Call after a successful scenario save. Triggers review on the 3rd save,
  /// then no more than once every 60 days.
  static Future<void> onScenarioSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt(_kSaveCount) ?? 0) + 1;
      await prefs.setInt(_kSaveCount, count);
      if (count < _kReviewThreshold) return;

      final lastMs = prefs.getInt(_kLastReviewDate) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastMs < const Duration(days: _kReviewCooldownDays).inMilliseconds) return;

      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
        await prefs.setInt(_kLastReviewDate, now);
      }
    } catch (_) {
      // Fail silently.
    }
  }

  /// Manually triggered from Settings "Rate Finwise" row.
  static Future<void> rateApp() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: '');
      }
    } catch (_) {
      // Fail silently.
    }
  }
}
