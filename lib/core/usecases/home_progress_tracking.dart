import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/screens/hub/data/submission_progress.dart'
    show SubmissionProgress;
import 'package:audio_diaries_flutter/services/preference_service.dart'
    show PreferenceService;

const String submissionProgressKey = 'submissionProgress';

// In-memory cache to avoid read-modify-write races from rapid concurrent calls.
Map<int, SubmissionProgress>? _cache;

/// Updates the progress entry for [studyID].
///
/// [submissions] — number of new submissions to add (null = keep current).
/// Pass `0` to reset the count.
/// [activateAnimation] — overrides the flag when provided.
Future<void> modifyHomeProgressTracking(
    {required int studyID, int? submissions, bool? activateAnimation}) async {
  final all = await getAllHomeProgressTracking();
  final current = all[studyID] ??
      SubmissionProgress(studyID: studyID, submissions: 0, activateAnimation: false);

  final newCount = submissions == null
      ? current.submissions
      : submissions == 0
          ? 0
          : current.submissions + submissions;

  all[studyID] = SubmissionProgress(
      studyID: studyID,
      submissions: newCount,
      activateAnimation: activateAnimation ?? current.activateAnimation);

  _cache = all;
  await _persist(all);
}

/// Returns progress entries for every study that has been tracked.
Future<Map<int, SubmissionProgress>> getAllHomeProgressTracking() async {
  if (_cache != null) return Map.of(_cache!);

  final raw =
      await PreferenceService().getStringPreference(key: submissionProgressKey);

  if (raw == null) return {};

  Map<String, dynamic> decoded;
  try {
    decoded = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }

  // Try parsing as the current format: { "<studyID>": { submissions, activateAnimation } }
  try {
    final result = decoded.map((key, value) {
      final studyID = int.parse(key);
      return MapEntry(studyID,
          SubmissionProgress.fromJson(studyID, value as Map<String, dynamic>));
    });
    _cache = result;
    return Map.of(result);
  } catch (_) {}

  // Migrate from legacy single-object format: { submissions, activateAnimation, studyID }
  dev.log('Migrating legacy submissionProgress format.',
      name: 'home_progress_tracking');
  try {
    final studyID = (decoded['studyID'] as int?) ?? 0;
    final entry = SubmissionProgress.fromJson(studyID, decoded);
    final migrated = {studyID: entry};
    _cache = migrated;
    await _persist(migrated);
    return Map.of(migrated);
  } catch (_) {
    return {};
  }
}

/// Clears all submission progress — called when the user visits the History
/// page. Note: [activateAnimation] flags are also cleared here, so the
/// separate reset in [RingProgressIndicator.onAnimationComplete] is only
/// a belt-and-suspenders path for when the user never visits History.
Future<void> clearAllHomeProgressTracking() async {
  _cache = {};
  await PreferenceService().removePreference(key: submissionProgressKey);
  dev.log('Cleared all submission progress.', name: 'home_progress_tracking');
}

Future<void> _persist(Map<int, SubmissionProgress> all) async {
  final encoded =
      jsonEncode(all.map((id, p) => MapEntry(id.toString(), p.toJson())));
  dev.log('Persisting submissionProgress: $encoded',
      name: 'home_progress_tracking');
  await PreferenceService()
      .setStringPreference(key: submissionProgressKey, value: encoded);
}
