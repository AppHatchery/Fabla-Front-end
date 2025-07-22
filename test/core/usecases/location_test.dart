import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:location/location.dart';
import 'package:audio_diaries_flutter/core/usecases/location.dart';
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

  group('appendLocation', () {
    final testExperimentCode = TestValues.testExperimentCode;
    final testParticipantID = TestValues.testParticipantId;
    const testPromptLength = 5;
    final testDiaryID =
        '${TestValues.testName.toLowerCase().replaceAll(' ', '_')}_diary';

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
        promptLength: testPromptLength,
        diaryID: testDiaryID,
        location: mockLocation,
        preferenceService: mockPreferenceService,
      );

      // Assert
      expect(result, isNotNull);
      expect(result?.participantID, equals(testParticipantID));
      expect(result?.experimentCode, equals(testExperimentCode));
      expect(result?.questionTitle, equals('Current location'));
      expect(result?.diaryID, equals(testDiaryID));
      expect(result?.promptID, equals('6')); // promptLength + 1
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
        promptLength: testPromptLength,
        diaryID: testDiaryID,
        location: mockLocation,
        preferenceService: mockPreferenceService,
      );

      // Assert
      expect(result, isNotNull);
      expect(result?.participantID, equals(testParticipantID));
      expect(result?.experimentCode, equals(testExperimentCode));
      expect(result?.questionTitle, equals('Current location'));
      expect(result?.diaryID, equals(testDiaryID));
      expect(result?.promptID, equals('6')); // promptLength + 1
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
        promptLength: testPromptLength,
        diaryID: testDiaryID,
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
        promptLength: testPromptLength,
        diaryID: testDiaryID,
        location: mockLocation,
        preferenceService: mockPreferenceService,
      );

      // Assert
      expect(result, isNull);
    });
  });
}
