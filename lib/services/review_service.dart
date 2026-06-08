import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:in_app_review/in_app_review.dart';

class InAppReviewService {
  static const int _activeDayThreshold = 10;
  static const String _activeDaysKey = 'review_active_days';
  static const String _reviewRequestedKey = 'review_requested';

  final InAppReview _inAppReview;
  final PreferenceService _prefs;

  InAppReviewService({
    InAppReview? inAppReview,
    PreferenceService? prefs,
  })  : _inAppReview = inAppReview ?? InAppReview.instance,
        _prefs = prefs ?? PreferenceService();

  /// Call once per app launch to track distinct active days.
  Future<void> recordActiveDay() async {
    final today = _todayKey();
    final existing =
        await _prefs.getStringListPreference(key: _activeDaysKey) ?? [];
    if (!existing.contains(today)) {
      await _prefs.setStringListPreference(
          key: _activeDaysKey, value: [...existing, today]);
    }
  }

  /// Call after a positive user action (e.g. diary submitted successfully).
  /// No-ops if the review has already been requested or the engagement
  /// threshold has not yet been met.
  Future<void> maybeRequestReview() async {
    final alreadyRequested =
        await _prefs.getBoolPreference(key: _reviewRequestedKey) ?? false;
    if (alreadyRequested) return;

    final activeDays =
        await _prefs.getStringListPreference(key: _activeDaysKey) ?? [];
    if (activeDays.length < _activeDayThreshold) return;

    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
      await _prefs.setBoolPreference(key: _reviewRequestedKey, value: true);
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
