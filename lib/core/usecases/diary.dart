import 'dart:convert';
import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';

final preferences = PreferenceService();

/// Saving the start of the diary entry.
/// A map of Diary ID as Key and DateTime as value
/// Saves the start time in Shared Preferences
///
void diaryStart({required String diaryID}) async {
  // A map to save all the diaries starts
  final _starts = await preferences.getStringPreference(key: "diary_starts");
  final Map<String, String> starts =
      _starts != null ? jsonDecode(_starts).cast<String, String>() : {};
  final now = DateTime.now().toIso8601String();

  // Making sure we don't override the already saved diary
  // If the diary already exists then skip
  if (!starts.containsKey(diaryID)) {
    starts[diaryID] = now;
    await preferences.setStringPreference(
        key: "diary_starts", value: jsonEncode(starts));
  }
}

void diaryEnd({required String diaryID}) async {
  final _ends = await preferences.getStringPreference(key: "diary_ends");
  final Map<String, String> ends =
      _ends != null ? jsonDecode(_ends).cast<String, String>() : {};
  final now = DateTime.now().toIso8601String();

  ends[diaryID] = now;
  await preferences.setStringPreference(
      key: "diary_ends", value: jsonEncode(ends));
}

/// Submitting the completion diary with the start time and the end time
/// Collects the saved start itme in Shared preferences and submits with
/// the time of now to indicate the completion of a diary
/// The entry of [diaryID] is then removed from the Start Map to allow
/// reoccurring diaries to use the same ID for completion submission
///
/// Returns: List of [PromptEntry] to be add to the submission pool
Future<List<PromptEntry>> submitDiaryCompletionTime(
    {required DiaryModel diary,
    required StudyModel? study,
    required String participantID,
    required String experimentCode,
    required int promptLength}) async {
  try {
    final _starts = await preferences.getStringPreference(key: "diary_starts");
    final _end = await preferences.getStringPreference(key: "diary_ends");
    final Map<String, String> starts =
        _starts != null ? jsonDecode(_starts).cast<String, String>() : {};
    final Map<String, String> ends =
        _end != null ? jsonDecode(_end).cast<String, String>() : {};
    final entries = <PromptEntry>[];

    // Only submit if the diary has a start
    if (starts.containsKey(diary.id.toString())) {
      // start
      final startValue = starts[diary.id.toString()] ?? "";
      final start = PromptEntry(
          participantID: participantID,
          experimentCode: experimentCode,
          questionTitle: "Time the diary was started",
          diaryID: diary.id.toString(),
          diaryName: diary.name,
          study: study?.name ?? 'unknown',
          promptID: (promptLength + 1).toString(),
          response: startValue,
          respondedAt: "",
          questionsType: "start_time",
          required: true);
      entries.add(start);

      //Clean Up!
      // To avoid reoccurring diaries from having the same start time
      starts.removeWhere((key, _) => key == diary.id.toString());
      await preferences.setStringPreference(
          key: "diary_starts", value: jsonEncode(starts));
    }

    if (ends.containsKey(diary.id.toString())) {
      // end
      final endValue = ends[diary.id.toString()] ?? "";
      final end = PromptEntry(
          participantID: participantID,
          experimentCode: experimentCode,
          questionTitle: "Time the diary was completed",
          diaryID: diary.id.toString(),
          promptID: (promptLength + 2).toString(),
          diaryName: diary.name,
          study: study?.name ?? 'unknown',
          response: endValue,
          respondedAt: "",
          questionsType: "end_time",
          required: true);
      entries.add(end);

      // Clean Up!
      ends.removeWhere((key, _) => key == diary.id.toString());
      await preferences.setStringPreference(
          key: "diary_ends", value: jsonEncode(ends));
    }

    return entries;
  } catch (e, stackTrace) {
    dev.log('Failed to build completion time entries: $e',
        name: 'Diary - submitDiaryCompletionTime');
    CrashlyticsService().recordError(e, stackTrace,
        context: {
          'DiaryID': diary.id.toString(),
          'ParticipantID': participantID,
          'Diary': diary.name
        },
        reason:
            'Failed to read/decode completion time preferences — submission will continue without timing data');
    return [];
  }
}

Future<DateTime> getCompletionDate(String diaryID,
    {required DateTime fallback}) async {
  final _end = await preferences.getStringPreference(key: "diary_ends");
  final Map<String, String> ends =
      _end != null ? jsonDecode(_end).cast<String, String>() : {};

  if (ends.isEmpty) {
    return fallback;
  }

  final endValue = ends[diaryID] ?? "";

  if (endValue.isEmpty) {
    return fallback;
  }
  return DateTime.parse(endValue);
}
