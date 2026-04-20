import 'dart:convert';

import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:flutter/foundation.dart';

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
    {required String diaryID,
    required String participantID,
    required String experimentCode,
    required int promptLength}) async {
  final _starts = await preferences.getStringPreference(key: "diary_starts");
  final _end = await preferences.getStringPreference(key: "diary_ends");
  final Map<String, String> starts =
      _starts != null ? jsonDecode(_starts).cast<String, String>() : {};
  final Map<String, String> ends =
      _end != null ? jsonDecode(_end).cast<String, String>() : {};
  final entries = <PromptEntry>[];

  // Only submit if the diary has a start
  if (starts.containsKey(diaryID)) {
    // start
    final startValue = starts[diaryID] ?? "";
    final start = PromptEntry(
        participantID: participantID,
        experimentCode: experimentCode,
        questionTitle: "Time the diary was started",
        diaryID: diaryID,
        promptID: (promptLength + 1).toString(),
        response: startValue,
        respondedAt: "",
        questionsType: "start_time",
        required: true,);
    entries.add(start);

    //Clean Up!
    // To avoid reoccurring diaries from having the same start time
    starts.removeWhere((key, _) => key == diaryID);
    await preferences.setStringPreference(
        key: "diary_starts", value: jsonEncode(starts));
  }

  if (ends.containsKey(diaryID)) {
    // end
    final endValue = ends[diaryID] ?? "";
    final end = PromptEntry(
        participantID: participantID,
        experimentCode: experimentCode,
        questionTitle: "Time the diary was completed",
        diaryID: diaryID,
        promptID: (promptLength + 2).toString(),
        response: endValue,
        respondedAt: "",
        questionsType: "end_time",
        required: true,);
    entries.add(end);

    // Clean Up!
    ends.removeWhere((key, _) => key == diaryID);
    await preferences.setStringPreference(
        key: "diary_ends", value: jsonEncode(ends));
  }

  return entries;
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
