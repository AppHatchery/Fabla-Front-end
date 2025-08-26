import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:audio_diaries_flutter/core/usecases/experiment_manager.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';

class MockSetupRepository extends Mock implements SetupRepository {}

void main() {
  late ExperimentManager experimentManager;
  late MockSetupRepository mockSetupRepository;

  setUp(() {
    mockSetupRepository = MockSetupRepository();
    experimentManager = ExperimentManager(
      setupRepository: mockSetupRepository,
    );
  });

  group('ExperimentManager', () {
    test('update should upload onboarding questions with partialCleanDB true',
        () async {
      // Arrange
      when(() => mockSetupRepository.uploadOnBoardingQuestions(
          partialCleanDB: true)).thenAnswer((_) async => true);

      // Act
      final result = await experimentManager.update();

      // Assert
      expect(result, true);
      verify(() => mockSetupRepository.uploadOnBoardingQuestions(
          partialCleanDB: true)).called(1);
    });

    test(
        'update should return false when uploadOnBoardingQuestions returns false',
        () async {
      // Arrange
      when(() => mockSetupRepository.uploadOnBoardingQuestions(
          partialCleanDB: true)).thenAnswer((_) async => false);

      // Act
      final result = await experimentManager.update();

      // Assert
      expect(result, false);
      verify(() => mockSetupRepository.uploadOnBoardingQuestions(
          partialCleanDB: true)).called(1);
    });

    test('update should return false when an error occurs', () async {
      // Arrange
      when(() => mockSetupRepository.uploadOnBoardingQuestions(
          partialCleanDB: true)).thenThrow(Exception('Test error'));

      // Act
      final result = await experimentManager.update();

      // Assert
      expect(result, false);
      verify(() => mockSetupRepository.uploadOnBoardingQuestions(
          partialCleanDB: true)).called(1);
    });
  });
}
