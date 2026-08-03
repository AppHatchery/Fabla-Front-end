import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:location/location.dart';

/// Appends the current location to the diary entry.
/// This function appends the current location to the diary entry by retrieving the location data
/// and creating a new prompt entry with the location information.
/// The function first checks if the location requirements are in the scope of the experiment.
/// If the location is required, the function checks for the permissions granted by the user.
/// If the permissions are granted, the function retrieves the location data and creates a new prompt entry
/// with the location information. If the permissions are not granted, the function returns `null`.
///
/// Modified to support dependency injection for better testability.
/// Added optional parameters for Location and PreferenceService.
/// Default values maintain backward compatibility.
///
/// Parameters:
/// - [experimentCode]: The code of the experiment.
/// - [participantID]: The ID of the participant.
/// - [promptLength]: The length of the prompt.
/// - [diaryID]: The ID of the diary entry.
/// - [location]: Optional Location instance for dependency injection.
/// - [preferenceService]: Optional PreferenceService instance for dependency injection.
///
/// Returns:
/// A `PromptEntry` object containing the current location information, or `null` if the location permissions are not granted.
Future<PromptEntry?> appendLocation({
  required String experimentCode,
  required String participantID,
  required int promptLength,
  required DiaryModel diary,
  required StudyModel? study,
  Location? location,
  PreferenceService? preferenceService,
}) async {
  // Use injected dependencies or create default instances
  final locationService = location ?? Location();
  final prefService = preferenceService ?? PreferenceService();

  final extraPermissions = await prefService.getStringListPreference(
        key: 'extra_permissions',
      ) ??
      [];

  if (extraPermissions.contains('location')) {
    // Updated to use injected location service instead of global instance
    final permission = await locationService.hasPermission();
    if (permission == PermissionStatus.granted) {
      try {
        final data = await locationService.getLocation();
        return PromptEntry(
            participantID: participantID,
            experimentCode: experimentCode,
            questionTitle: "Current location",
            diaryID: diary.id.toString(),
            diaryName: diary.name,
            study: study?.name ?? 'unknown',
            promptID: (promptLength + 1).toString(),
            response:
                "latitude: ${data.latitude}, longitude: ${data.longitude}",
            respondedAt: "",
            questionsType: "location",
            required: true);
      } catch (e, stackTrace) {
        CrashlyticsService().recordError(e, stackTrace,
            context: {
              'DiaryID': diary.id.toString(),
              'ParticipantID': participantID,
              'Diary': diary.name
            },
            reason:
                'Location fetch failed during submission — submission will continue without location');
        return PromptEntry(
            participantID: participantID,
            experimentCode: experimentCode,
            questionTitle: "Current location",
            diaryID: diary.id.toString(),
            diaryName: diary.name,
            study: study?.name ?? 'unknown',
            promptID: (promptLength + 1).toString(),
            response: "Location fetch failed: ${e.runtimeType}",
            respondedAt: "",
            questionsType: "location",
            required: true);
      }
    } else {
      final response = PromptEntry(
          participantID: participantID,
          experimentCode: experimentCode,
          questionTitle: "Current location",
          diaryID: diary.id.toString(),
          diaryName: diary.name,
          study: study?.name ?? 'unknown',
          promptID: (promptLength + 1).toString(),
          response: "Location permission not granted",
          respondedAt: "",
          questionsType: "location",
          required: true);
      return response;
    }
  }

  return null;
}
