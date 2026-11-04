import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:location/location.dart';

enum LocationStatus { captured, permissionDenied, fetchFailed }

/// One location reading for a submission, shared by the flat Dynamo row
/// ([locationEntry]) and the nested payload's location response
/// ([locationResponse]), so both describe the same reading.
class LocationSnapshot {
  final LocationStatus status;
  final double? latitude;
  final double? longitude;

  /// Horizontal accuracy radius in meters, as reported by the platform.
  final double? accuracyMeters;

  /// When the fix was taken. Can be earlier than the submission if the
  /// platform returned a cached fix.
  final DateTime? capturedAt;

  /// The exception type when [status] is [LocationStatus.fetchFailed].
  final String? error;

  const LocationSnapshot({
    required this.status,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.capturedAt,
    this.error,
  });

  /// The text answer both payloads carry.
  String get description => switch (status) {
        LocationStatus.captured => "latitude: $latitude, longitude: $longitude",
        LocationStatus.permissionDenied => "Location permission not granted",
        LocationStatus.fetchFailed => "Location fetch failed: $error",
      };

  Map<String, dynamic> toJson() => {
        'Status': switch (status) {
          LocationStatus.captured => 'Captured',
          LocationStatus.permissionDenied => 'PermissionDenied',
          LocationStatus.fetchFailed => 'FetchFailed',
        },
        'Latitude': latitude,
        'Longitude': longitude,
        'AccuracyMeters': accuracyMeters,
        'CapturedAt': capturedAt?.toUtc().toIso8601String(),
        'Error': error,
      };
}

/// Reads the current location if the experiment collects it.
///
/// Returns `null` when location is not in the experiment's extra permissions.
/// A denied permission or a failed fetch still returns a snapshot, so the
/// backend can tell "not collected" from "collected but unavailable".
///
/// [location] and [preferenceService] can be injected for testing.
Future<LocationSnapshot?> captureLocation({
  required DiaryModel diary,
  required String participantID,
  Location? location,
  PreferenceService? preferenceService,
}) async {
  final locationService = location ?? Location();
  final prefService = preferenceService ?? PreferenceService();

  final extraPermissions = await prefService.getStringListPreference(
        key: 'extra_permissions',
      ) ??
      [];
  if (!extraPermissions.contains('location')) return null;

  final permission = await locationService.hasPermission();
  if (permission != PermissionStatus.granted) {
    return const LocationSnapshot(status: LocationStatus.permissionDenied);
  }

  try {
    final data = await locationService.getLocation();
    final time = data.time;
    return LocationSnapshot(
      status: LocationStatus.captured,
      latitude: data.latitude,
      longitude: data.longitude,
      accuracyMeters: data.accuracy,
      capturedAt: time == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(time.toInt()),
    );
  } catch (e, stackTrace) {
    CrashlyticsService().recordError(e, stackTrace,
        context: {
          'DiaryID': diary.id.toString(),
          'ParticipantID': participantID,
          'Diary': diary.name
        },
        reason:
            'Location fetch failed during submission — submission will continue without location');
    return LocationSnapshot(
        status: LocationStatus.fetchFailed, error: e.runtimeType.toString());
  }
}

/// The flat Dynamo row for [snapshot].
///
/// Parameters:
/// - [promptLength]: the diary's prompt count; the row's PromptID is placed
///   after the start and end time rows.
PromptEntry locationEntry(
  LocationSnapshot snapshot, {
  required String experimentCode,
  required String participantID,
  required int promptLength,
  required DiaryModel diary,
  required StudyModel? study,
}) {
  return PromptEntry(
      participantID: participantID,
      experimentCode: experimentCode,
      questionTitle: "Current location",
      diaryID: diary.id.toString(),
      diaryName: diary.name,
      study: study?.name ?? 'unknown',
      // +1 and +2 are the start and end time rows from submitDiaryCompletionTime.
      promptID: (promptLength + 3).toString(),
      response: snapshot.description,
      respondedAt: "",
      questionsType: "location",
      required: true);
}

/// The nested payload's response entry for [snapshot], shaped like a prompt
/// response with the structured reading under `Location`, the way recordings
/// sit under `Files`.
///
/// The PromptID follows the diary's prompts directly: start and end times are
/// `Diary` fields in the nested payload, not rows, so nothing else uses
/// `promptLength + 1` there.
Map<String, dynamic> locationResponse(LocationSnapshot snapshot,
        {required int promptLength}) =>
    {
      'PromptID': (promptLength + 1).toString(),
      'QuestionTitle': 'Current location',
      'QuestionType': 'location',
      'Required': true,
      'Response': [snapshot.description],
      'RespondedAt': snapshot.capturedAt?.toUtc().toIso8601String(),
      'Location': snapshot.toJson(),
    };
