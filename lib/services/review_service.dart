import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages in-app rating/review prompts using [in_app_review].
///
/// The review prompt is only shown when:
///   1. The user has used the app at least [_minScanCount] times.
///   2. At least [_minDaysBetweenPrompts] days have passed since the last prompt.
///   3. The prompt hasn't already been shown [_maxPrompts] times.
///
/// These rules prevent the system review UI from appearing too aggressively,
/// which can cause platforms (Android / iOS) to suppress it entirely.
class ReviewService {
  static const String _keyLastPromptDate = 'review_last_prompt_date';
  static const String _keyPromptCount = 'review_prompt_count';
  static const int _minScanCount = 3;
  static const int _minDaysBetweenPrompts = 14;
  static const int _maxPrompts = 3;

  static final InAppReview _inAppReview = InAppReview.instance;

  /// Call this after a positive user interaction (e.g., completing a diagnosis,
  /// marking a plant as watered, or sharing a post). Pass the current [scanCount]
  /// from [GardenProvider] to enforce minimum usage threshold.
  static Future<void> maybeRequestReview({required int scanCount}) async {
    if (kDebugMode) {
      // Skip in debug builds to avoid interfering with development flow.
      debugPrint('🌿 ReviewService: skipping in debug mode.');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Check prompt count cap
      final promptCount = prefs.getInt(_keyPromptCount) ?? 0;
      if (promptCount >= _maxPrompts) return;

      // Check minimum usage threshold
      if (scanCount < _minScanCount) return;

      // Check cooldown since last prompt
      final lastPromptDateStr = prefs.getString(_keyLastPromptDate);
      if (lastPromptDateStr != null) {
        final lastDate = DateTime.tryParse(lastPromptDateStr);
        if (lastDate != null) {
          final daysSince = DateTime.now().difference(lastDate).inDays;
          if (daysSince < _minDaysBetweenPrompts) return;
        }
      }

      // Check availability (always false on emulators / simulators)
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) return;

      // Request the review prompt
      await _inAppReview.requestReview();

      // Record the prompt
      await prefs.setString(_keyLastPromptDate, DateTime.now().toIso8601String());
      await prefs.setInt(_keyPromptCount, promptCount + 1);
      debugPrint('✅ ReviewService: review prompt shown (#${promptCount + 1}).');
    } catch (e) {
      debugPrint('⚠️ ReviewService: failed to show review prompt: $e');
    }
  }

  /// Opens the store listing directly (for an explicit "Rate us" button).
  static Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(appStoreId: 'YOUR_APP_STORE_ID');
    } catch (e) {
      debugPrint('⚠️ ReviewService: failed to open store listing: $e');
    }
  }
}
