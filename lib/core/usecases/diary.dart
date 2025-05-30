import 'dart:convert';

import 'package:audio_diaries_flutter/core/network/upload.dart';
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
  final Map<String, String> starts =
      _starts != null ? jsonDecode(_starts).cast<String, String>() : {};
  final now = DateTime.now().toIso8601String();
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
        questionsType: "start_time",
        required: true);

    final end = PromptEntry(
        participantID: participantID,
        experimentCode: experimentCode,
        questionTitle: "Time the diary was completed",
        diaryID: diaryID,
        promptID: (promptLength + 2).toString(),
        response: now,
        questionsType: "end_time",
        required: true);
    entries.addAll([start, end]);

    //Clean Up!
    // To avoid reoccurring diaries from having the same start time
    starts.removeWhere((key, _) => key == diaryID);
    await preferences.setStringPreference(
        key: "diary_starts", value: jsonEncode(starts));
  }

  return entries;
}
