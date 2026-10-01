import 'dart:async';

import 'package:audio_diaries_flutter/screens/diary/domain/repository/answer_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/prompt_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/summary_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:fake_async/fake_async.dart';
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
    // No participant makes submitDiary stop before the upload; tests that
    // reach the upload override this.
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
      // Short-circuited before it could reach the upload.
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

  group('submitDiary result', () {
    late int uploads;
    late Completer<bool> upload;
    late SummaryRepository uploading;

    setUp(() {
      uploads = 0;
      upload = Completer<bool>();
      uploading = SummaryRepository(
        answerRepository: MockAnswerRepository(),
        promptRepository: MockPromptRepository(),
        diaryRepository: diaryRepository,
        setupRepository: setupRepository,
        uploader: (_, __) {
          uploads++;
          return upload.future;
        },
      );
      when(() => setupRepository.getParticipant())
          .thenReturn(createTestParticipant());
      when(() => diaryRepository.getDiaryByID(any()))
          .thenReturn(createTestDiaryModel(currentEntry: 0));
    });

    // Each test uses its own diary id: a test that fails before completing
    // [upload] leaves its entry in the static in-flight map.

    // A deadline here would fire after an iOS suspension and report failure
    // for a diary the upload then records.
    test('waits for the upload however long it takes', () {
      fakeAsync((async) {
        // Created inside the fake zone, or completing it would schedule on
        // the real event loop and flushMicrotasks would never see it.
        upload = Completer<bool>();
        bool? result;
        var settled = false;
        uploading
            .submitDiary(createTestDiaryModel(id: 7, currentEntry: 0))
            .then((r) {
          result = r;
          settled = true;
        });

        async.elapse(const Duration(minutes: 30));
        expect(settled, isFalse);

        upload.complete(false);
        async.flushMicrotasks();
        expect(settled, isTrue);
        expect(result, isFalse);
      });
    });

    test('a second submit while one is uploading joins it', () async {
      final snapshot = createTestDiaryModel(id: 8, currentEntry: 0);

      final first = uploading.submitDiary(snapshot);
      final second = uploading.submitDiary(snapshot);
      upload.complete(false);

      expect(await first, isFalse);
      expect(await second, isFalse);
      expect(uploads, 1);
    });
  });
}
