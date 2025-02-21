import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:location/location.dart';

final Location location = Location();

/// Appends the current location to the diary entry.
/// This function appends the current location to the diary entry by retrieving the location data
/// and creating a new prompt entry with the location information.
/// The function first checks if the location requirements are in the scope of the experiment.
/// If the location is required, the function checks for the permissions granted by the user.
/// If the permissions are granted, the function retrieves the location data and creates a new prompt entry
/// with the location information. If the permissions are not granted, the function returns `null`.
///
/// Parameters:
/// - [experimentCode]: The code of the experiment.
/// - [participantID]: The ID of the participant.
/// - [promptLength]: The length of the prompt.
/// - [diaryID]: The ID of the diary entry.
///
/// Returns:
/// A `PromptEntry` object containing the current location information, or `null` if the location permissions are not granted.
Future<PromptEntry?> appendLocation(
    {required String experimentCode,
    required String participantID,
    required int promptLength,
    required String diaryID}) async {
  final extraPermissions = await PreferenceService().getStringListPreference(
        key: 'extra_permissions',
      ) ??
      [];

  if (extraPermissions.contains('location')) {
    final permission = await location.hasPermission();
    if (permission == PermissionStatus.granted) {
      final data = await location.getLocation();

      final response = PromptEntry(
          participantID: participantID,
          experimentCode: experimentCode,
          questionTitle: "Current location",
          diaryID: diaryID,
          promptID: (promptLength + 1).toString(),
          response: "latitude: ${data.latitude}, longitude: ${data.longitude}",
          questionsType: "location",
          required: true);
      return response;
    }
  }

  return null;
}
