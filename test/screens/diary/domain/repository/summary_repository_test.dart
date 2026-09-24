import 'package:audio_diaries_flutter/screens/diary/domain/repository/answer_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/prompt_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/summary_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../dummy_data.dart';

class MockAnswerRepository extends Mock implements AnswerRepository {}

class MockPromptRepository extends Mock implements PromptRepository {}

class MockDiaryRepository extends Mock implements DiaryRepository {}

class MockSetupRepository extends Mock implements SetupRepository {}

void main() {
  late MockDiaryRepository diaryRepository;
  late MockSetupRepository setupRepository;
  late SummaryRepository repository;

  setUpAll(() {
    registerFallbackValue(createTestDiaryModel());
  });

  setUp(() {
    diaryRepository = MockDiaryRepository();
    setupRepository = MockSetupRepository();
    repository = SummaryRepository(
      answerRepository: MockAnswerRepository(),
      promptRepository: MockPromptRepository(),
      diaryRepository: diaryRepository,
      setupRepository: setupRepository,
    );
    // Every test here stops before the upload. Returning no participant is the
    // cheapest way to make submitDiary bail once the guard has let it past,
    // which is exactly what distinguishes "guard fired" from "guard did not".
    when(() => setupRepository.getParticipant()).thenReturn(null);
  });

  group('submitDiary duplicate guard', () {
    test('an entry the stored diary has moved past is not re-uploaded',
        () async {
      // The shape of a real retry: the caller holds the model as it was before
      // the first run recorded itself, while storage has already advanced.
      final staleSnapshot = createTestDiaryModel(id: 7, currentEntry: 0);
      when(() => diaryRepository.getDiaryByID(7))
          .thenReturn(createTestDiaryModel(id: 7, currentEntry: 1));

      final result = await repository.submitDiary(staleSnapshot);

      expect(result, isTrue);
      verifyNever(() => diaryRepository.updateDiary(any()));
      // Short-circuited before the participant lookup, so it never reached the
      // upload path at all.
      verifyNever(() => setupRepository.getParticipant());
    });

    test('a diary that has not advanced still submits', () async {
      final snapshot = createTestDiaryModel(id: 7, currentEntry: 0);
      when(() => diaryRepository.getDiaryByID(7))
          .thenReturn(createTestDiaryModel(id: 7, currentEntry: 0));

      final result = await repository.submitDiary(snapshot);

      // Reaching the participant lookup proves the guard let it through; the
      // null participant is what turns it into false.
      expect(result, isFalse);
      verify(() => setupRepository.getParticipant()).called(1);
    });

    test('a later entry of a multi-entry diary is not mistaken for a duplicate',
        () async {
      // Stored and snapshot agree at entry 1 of 3 — this is the ordinary
      // second submission, not a repeat of the first.
      final snapshot = createTestDiaryModel(id: 7, entries: 3, currentEntry: 1);
      when(() => diaryRepository.getDiaryByID(7))
          .thenReturn(createTestDiaryModel(id: 7, entries: 3, currentEntry: 1));

      final result = await repository.submitDiary(snapshot);

      expect(result, isFalse);
      verify(() => setupRepository.getParticipant()).called(1);
    });

    test('a missing local record does not silently swallow the submission',
        () async {
      final snapshot = createTestDiaryModel(id: 7, currentEntry: 0);
      when(() => diaryRepository.getDiaryByID(7)).thenReturn(null);

      final result = await repository.submitDiary(snapshot);

      expect(result, isFalse);
      verify(() => setupRepository.getParticipant()).called(1);
    });
  });
}
