import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:audio_diaries_flutter/core/usecases/experiment_manager.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';

class MockDiaryRepository extends Mock implements DiaryRepository {}

class MockSetupRepository extends Mock implements SetupRepository {}

void main() {
  late ExperimentManager experimentManager;
  late MockDiaryRepository mockDiaryRepository;
  late MockSetupRepository mockSetupRepository;

  setUp(() {
    mockDiaryRepository = MockDiaryRepository();
    mockSetupRepository = MockSetupRepository();
    experimentManager = ExperimentManager(
      diaryRepository: mockDiaryRepository,
      setupRepository: mockSetupRepository,
    );
  });

  group('ExperimentManager', () {
    test('update should remove diaries and studies, then upload new questions',
        () async {
      // Arrange
      when(() => mockDiaryRepository.removeDiariesFrom(any())).thenReturn(true);
      when(() => mockSetupRepository.deleteAllStudies())
          .thenAnswer((_) async {});
      when(() => mockSetupRepository.uploadOnBoardingQuestions())
          .thenAnswer((_) async => true);

      // Act
      final result = await experimentManager.update();

      // Assert
      expect(result, true);
      verify(() => mockDiaryRepository.removeDiariesFrom(any())).called(1);
      verify(() => mockSetupRepository.deleteAllStudies()).called(1);
      verify(() => mockSetupRepository.uploadOnBoardingQuestions()).called(1);
    });

    test('update should return false when an error occurs', () async {
      // Arrange
      when(() => mockDiaryRepository.removeDiariesFrom(any()))
          .thenThrow(Exception('Test error'));

      // Act
      final result = await experimentManager.update();

      // Assert
      expect(result, false);
      verify(() => mockDiaryRepository.removeDiariesFrom(any())).called(1);
      verifyNever(() => mockSetupRepository.deleteAllStudies());
      verifyNever(() => mockSetupRepository.uploadOnBoardingQuestions());
    });

    test('update should handle repository errors gracefully', () async {
      // Arrange
      when(() => mockDiaryRepository.removeDiariesFrom(any())).thenReturn(true);
      when(() => mockSetupRepository.deleteAllStudies())
          .thenThrow(Exception('Test error'));

      // Act
      final result = await experimentManager.update();

      // Assert
      expect(result, false);
      verify(() => mockDiaryRepository.removeDiariesFrom(any())).called(1);
      verify(() => mockSetupRepository.deleteAllStudies()).called(1);
      verifyNever(() => mockSetupRepository.uploadOnBoardingQuestions());
    });
  });
}
