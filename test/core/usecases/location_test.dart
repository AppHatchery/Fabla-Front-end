import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:location/location.dart';
import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/core/usecases/location.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';

import '../../dummy_data.dart';

class MockLocation extends Mock implements Location {}

class MockPreferenceService extends Mock implements PreferenceService {}

void main() {
  late MockLocation mockLocation;
  late MockPreferenceService mockPreferenceService;

  setUp(() {
    mockLocation = MockLocation();
    mockPreferenceService = MockPreferenceService();
  });

  group('captureLocation + locationEntry', () {
    final testExperimentCode = TestValues.testExperimentCode;
    final testParticipantID = TestValues.testParticipantId;
    final testDiaryName =
        '${TestValues.testName.toLowerCase().replaceAll(' ', '_')}_diary';
    final testDiary = createTestDiaryModel(name: testDiaryName);
    final testStudy = createTestStudyModel();

    // What upload() does: one capture, then the flat row built from it.
    Future<PromptEntry?> appendLocation({
      required String experimentCode,
      required String participantID,
      required DiaryModel diary,
      required StudyModel? study,
      required Location location,
      required PreferenceService preferenceService,
    }) async {
      final snapshot = await captureLocation(
          diary: diary,
          participantID: participantID,
          location: location,
          preferenceService: preferenceService);
      if (snapshot == null) return null;
      return locationEntry(snapshot,
          experimentCode: experimentCode,
          participantID: participantID,
          diary: diary,
          study: study);
    }

    test('should return location data when permissions are granted', () async {
      // Arrange
      when(() => mockPreferenceService.getStringListPreference(
          key: 'extra_permissions')).thenAnswer((_) async => ['location']);
      when(() => mockLocation.hasPermission())
          .thenAnswer((_) async => PermissionStatus.granted);
      when(() => mockLocation.getLocation())
          .thenAnswer((_) async => LocationData.fromMap({
                'latitude': TestValues.testLatitude,
                'longitude': TestValues.testLongitude,
              }));

      // Act
      final result = await appendLocation(
        experimentCode: testExperimentCode,
        participantID: testParticipantID,
        diary: testDiary,
        study: testStudy,
        location: mockLocation,
        preferenceService: mockPreferenceService,
      );

      // Assert
      expect(result, isNotNull);
      expect(result?.participantID, equals(testParticipantID));
      expect(result?.experimentCode, equals(testExperimentCode));
      expect(result?.questionTitle, equals('Current location'));
      expect(result?.diaryID, equals(testDiary.id.toString()));
      expect(result?.diaryName, equals(testDiary.name));
      expect(result?.study, equals(testStudy.name));
      expect(result?.promptID, isEmpty);
      expect(
          result?.response, equals('latitude: 37.7749, longitude: -122.4194'));
      expect(result?.questionsType, equals('location'));
      expect(result?.required, isTrue);
    });

    test(
        'should return permission denied message when permissions are not granted',
        () async {
      // Arrange
      when(() => mockPreferenceService.getStringListPreference(
          key: 'extra_permissions')).thenAnswer((_) async => ['location']);
      when(() => mockLocation.hasPermission())
          .thenAnswer((_) async => PermissionStatus.denied);

      // Act
      final result = await appendLocation(
        experimentCode: testExperimentCode,
        participantID: testParticipantID,
        diary: testDiary,
        study: testStudy,
        location: mockLocation,
        preferenceService: mockPreferenceService,
      );

      // Assert
      expect(result, isNotNull);
      expect(result?.participantID, equals(testParticipantID));
      expect(result?.experimentCode, equals(testExperimentCode));
      expect(result?.questionTitle, equals('Current location'));
      expect(result?.diaryID, equals(testDiary.id.toString()));
      expect(result?.diaryName, equals(testDiary.name));
      expect(result?.study, equals(testStudy.name));
      expect(result?.promptID, isEmpty);
      expect(result?.response, equals('Location permission not granted'));
      expect(result?.questionsType, equals('location'));
      expect(result?.required, isTrue);
    });

    test('should return null when location is not in extra permissions',
        () async {
      // Arrange
      when(() => mockPreferenceService.getStringListPreference(
          key: 'extra_permissions')).thenAnswer((_) async => []);

      // Act
      final result = await appendLocation(
        experimentCode: testExperimentCode,
        participantID: testParticipantID,
        diary: testDiary,
        study: testStudy,
        location: mockLocation,
        preferenceService: mockPreferenceService,
      );

      // Assert
      expect(result, isNull);
    });

    test('should handle null extra permissions gracefully', () async {
      // Arrange
      when(() => mockPreferenceService.getStringListPreference(
          key: 'extra_permissions')).thenAnswer((_) async => null);

      // Act
      final result = await appendLocation(
        experimentCode: testExperimentCode,
        participantID: testParticipantID,
        diary: testDiary,
        study: testStudy,
        location: mockLocation,
        preferenceService: mockPreferenceService,
      );

      // Assert
      expect(result, isNull);
    });

    test('should fall back to "unknown" study name when study is null',
        () async {
      // Arrange
      when(() => mockPreferenceService.getStringListPreference(
          key: 'extra_permissions')).thenAnswer((_) async => ['location']);
      when(() => mockLocation.hasPermission())
          .thenAnswer((_) async => PermissionStatus.denied);

      // Act
      final result = await appendLocation(
        experimentCode: testExperimentCode,
        participantID: testParticipantID,
        diary: testDiary,
        study: null,
        location: mockLocation,
        preferenceService: mockPreferenceService,
      );

      // Assert
      expect(result?.study, equals('unknown'));
    });
  });

  group('LocationSnapshot', () {
    final testDiary = createTestDiaryModel();

    void locationEnabled() =>
        when(() => mockPreferenceService.getStringListPreference(
            key: 'extra_permissions')).thenAnswer((_) async => ['location']);

    test('a captured fix carries its coordinates, accuracy and fix time',
        () async {
      locationEnabled();
      when(() => mockLocation.hasPermission())
          .thenAnswer((_) async => PermissionStatus.granted);
      final fixTime = DateTime.utc(2026, 11, 4, 9, 15);
      when(() => mockLocation.getLocation())
          .thenAnswer((_) async => LocationData.fromMap({
                'latitude': 33.79,
                'longitude': -84.32,
                'accuracy': 12.5,
                'time': fixTime.millisecondsSinceEpoch.toDouble(),
              }));

      final snapshot = await captureLocation(
          diary: testDiary,
          participantID: TestValues.testParticipantId,
          location: mockLocation,
          preferenceService: mockPreferenceService);

      expect(snapshot!.toJson(), {
        'Status': 'Captured',
        'Latitude': 33.79,
        'Longitude': -84.32,
        'AccuracyMeters': 12.5,
        'CapturedAt': '2026-11-04T09:15:00.000Z',
        'Error': null,
      });
    });

    test('a failed fetch is reported with its error type', () async {
      locationEnabled();
      when(() => mockLocation.hasPermission())
          .thenAnswer((_) async => PermissionStatus.granted);
      when(() => mockLocation.getLocation())
          .thenThrow(const FormatException('no fix'));

      final snapshot = await captureLocation(
          diary: testDiary,
          participantID: TestValues.testParticipantId,
          location: mockLocation,
          preferenceService: mockPreferenceService);

      expect(snapshot!.toJson()['Status'], 'FetchFailed');
      expect(snapshot.toJson()['Error'], 'FormatException');
      expect(snapshot.toJson()['Latitude'], isNull);
    });

    test('a denied permission has no coordinates', () async {
      locationEnabled();
      when(() => mockLocation.hasPermission())
          .thenAnswer((_) async => PermissionStatus.denied);

      final snapshot = await captureLocation(
          diary: testDiary,
          participantID: TestValues.testParticipantId,
          location: mockLocation,
          preferenceService: mockPreferenceService);

      expect(snapshot!.toJson()['Status'], 'PermissionDenied');
      expect(snapshot.toJson()['Latitude'], isNull);
      expect(snapshot.toJson()['CapturedAt'], isNull);
    });
  });

  group('locationResponse', () {
    test('is a response entry with the reading under Location', () {
      final snapshot = LocationSnapshot(
          status: LocationStatus.captured,
          latitude: 33.79,
          longitude: -84.32,
          accuracyMeters: 12.5,
          capturedAt: DateTime.utc(2026, 11, 4, 9, 15));

      final response = locationResponse(snapshot);

      expect(response.containsKey('PromptID'), isFalse);
      expect(response['QuestionTitle'], 'Current location');
      expect(response['QuestionType'], 'location');
      expect(response['Required'], isTrue);
      expect(response['Response'], ['latitude: 33.79, longitude: -84.32']);
      expect(response['RespondedAt'], '2026-11-04T09:15:00.000Z');
      expect(response['Location'], snapshot.toJson());
    });

    test('a denied permission still gets an entry, with no time', () {
      final response = locationResponse(
          const LocationSnapshot(status: LocationStatus.permissionDenied));

      expect(response['Response'], ['Location permission not granted']);
      expect(response['RespondedAt'], isNull);
      expect(response['Location']['Status'], 'PermissionDenied');
    });
  });
}
