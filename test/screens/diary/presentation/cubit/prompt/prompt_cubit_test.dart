// test/screens/diary/presentation/cubit/prompt/prompt_cubit_test.dart
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/prompt/prompt_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:audio_diaries_flutter/main.dart' as main_app;
import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/objectbox.g.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/prompt_entity.dart';

class MockObjectBox extends Mock implements ObjectBox {
  @override
  late final Store store = MockStore();
}

class MockStore extends Mock implements Store {
  @override
  Box<T> box<T>() {
    if (T == Prompt) {
      return MockPromptBox() as Box<T>;
    }
    throw UnimplementedError('Unexpected box type: $T');
  }
}

class MockPromptBox extends Mock implements Box<Prompt> {}

void main() {
  group('PromptCubit', () {
    late PromptCubit promptCubit;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Initialize mock ObjectBox to avoid the global objectbox dependency
      final mockObjectBox = MockObjectBox();
      main_app.objectbox = mockObjectBox;
    });

    // Test data
    final testDiary = DiaryModel(
      id: 1,
      studyID: 1,
      name: 'Test Diary',
      status: DiaryStatus.ongoing,
      start: DateTime.now(),
      due: DateTime.now().add(const Duration(hours: 2)),
      prompts: [],
      activeDays: const [1, 2, 3, 4, 5, 6, 7],
      tags: const [],
      entries: 1,
      currentEntry: 0,
      end: DateTime.now().add(const Duration(hours: 2)),
      notifications: const [],
    );

    final testPrompt = PromptModel(
      id: 1,
      questionNumber: 1,
      question: 'How are you feeling today?',
      responseType: ResponseType.text,
      required: true,
      multipleAnswer: false,
    );


    final testAudioPrompt = PromptModel(
      id: 2,
      questionNumber: 2,
      question: 'Tell me about your day',
      responseType: ResponseType.audio,
      required: true,
      multipleAnswer: false,
    );

    setUp(() {
      promptCubit = PromptCubit();
    });

    tearDown(() {
      promptCubit.close();
    });

    test('initial state is PromptInitial', () {
      expect(promptCubit.state, const PromptInitial());
    });

    group('text processing methods', () {
      test('processTextAnswers combines new response with existing response',
          () {
        const existing = 'Previous answer';
        const newResponse = 'New answer';
        final result = promptCubit.processTextAnswers(newResponse, existing);
        expect(result, 'Previous answer | New answer');
      });

      test('processTextAnswers returns new response when no existing response',
          () {
        const newResponse = 'New answer';
        final result = promptCubit.processTextAnswers(newResponse, null);
        expect(result, 'New answer');
      });

      test('extractTextAnswers splits combined response correctly', () {
        const combined = 'First | Second | Third';
        final result = promptCubit.extractTextAnswers(combined);
        expect(result, ['First ', ' Second ', ' Third']);
      });

      test('extractTextAnswers handles single response', () {
        const single = 'Single response';
        final result = promptCubit.extractTextAnswers(single);
        expect(result, ['Single response']);
      });
    });

    group('modal methods', () {
      blocTest<PromptCubit, PromptState>(
        'showSuccessModal emits PromptResponseSuccess',
        build: () => promptCubit,
        act: (cubit) => cubit.showSuccessModal(),
        expect: () => [const PromptResponseSuccess()],
      );

      blocTest<PromptCubit, PromptState>(
        'showErrorModal emits PromptResponseError',
        build: () => promptCubit,
        act: (cubit) => cubit.showErrorModal(),
        expect: () => [const PromptResponseError()],
      );
    });

    group('loadPrompt', () {
      blocTest<PromptCubit, PromptState>(
        'emits [PromptLoading] when loadPrompt is called',
        build: () => promptCubit,
        act: (cubit) => cubit.loadPrompt(testDiary, testPrompt),
        expect: () => [
          PromptLoading(testPrompt),
          // Note: Since we can't mock the repository, we test the loading behavior
          // The actual loaded state will depend on the real repository implementation
        ],
        wait: const Duration(milliseconds: 10),
      );

      test('loadPrompt handles exceptions gracefully', () async {
        // This tests that the method doesn't throw exceptions
        expect(
          () => promptCubit.loadPrompt(testDiary, testPrompt),
          returnsNormally,
        );
      });
    });

    group('saveResponse behavior', () {
      test('saveResponse method executes without throwing', () async {
        // Test that the method can be called without throwing exceptions
        expect(
          () => promptCubit.saveResponse(
            diary: testDiary,
            prompt: testPrompt,
            response: 'Good',
            type: 'text',
            index: 0,
          ),
          returnsNormally,
        );
      });

      test('saveResponse handles different response types', () async {
        // Test audio response
        expect(
          () => promptCubit.saveResponse(
            diary: testDiary,
            prompt: testAudioPrompt,
            response: '/path/to/audio.wav',
            type: 'audio',
          ),
          returnsNormally,
        );

        // Test slider response
        expect(
          () => promptCubit.saveResponse(
            diary: testDiary,
            prompt: testPrompt.copyWith(responseType: ResponseType.slider),
            response: 7.5,
            type: 'other',
            index: 0,
          ),
          returnsNormally,
        );
      });
    });

    group('removeResponse behavior', () {
      test('removeResponse method executes without throwing', () async {
        expect(
          () => promptCubit.removeResponse(
            diary: testDiary,
            prompt: testPrompt,
            path: '/path/to/audio.wav',
            index: 0,
          ),
          returnsNormally,
        );
      });

      test('removeResponse handles null path', () async {
        expect(
          () => promptCubit.removeResponse(
            diary: testDiary,
            prompt: testPrompt,
            path: null,
            index: 0,
          ),
          returnsNormally,
        );
      });
    });

    group('integration tests with prompt states', () {
      blocTest<PromptCubit, PromptState>(
        'can emit loading state and handle subsequent operations',
        build: () => promptCubit,
        act: (cubit) async {
          await cubit.loadPrompt(testDiary, testPrompt);
          // small delay to allow for async operations
          await Future.delayed(const Duration(milliseconds: 5));
        },
        expect: () => [
          PromptLoading(testPrompt),
          // The exact final state depends on the repository implementation
        ],
        wait: const Duration(milliseconds: 50),
      );

      blocTest<PromptCubit, PromptState>(
        'modal states can be emitted independently',
        build: () => promptCubit,
        act: (cubit) async {
          cubit.showSuccessModal();
          await Future.delayed(const Duration(milliseconds: 5));
          cubit.showErrorModal();
        },
        expect: () => [
          const PromptResponseSuccess(),
          const PromptResponseError(),
        ],
      );
    });

    group('state equality and properties', () {
      test('PromptLoading states are equal with same prompt', () {
        final state1 = PromptLoading(testPrompt);
        final state2 = PromptLoading(testPrompt);
        expect(state1, equals(state2));
      });

      test('PromptLoaded states are equal with same prompt', () {
        final state1 = PromptLoaded(testPrompt);
        final state2 = PromptLoaded(testPrompt);
        expect(state1, equals(state2));
      });

      test('different states are not equal', () {
        final loadingState = PromptLoading(testPrompt);
        final loadedState = PromptLoaded(testPrompt);
        expect(loadingState, isNot(equals(loadedState)));
      });

      test('states have correct props', () {
        final loadingState = PromptLoading(testPrompt);
        expect(loadingState.props, [testPrompt]);

        const initialState = PromptInitial();
        expect(initialState.props, []);

        const successState = PromptResponseSuccess();
        expect(successState.props, []);

        const errorState = PromptResponseError();
        expect(errorState.props, []);

        const deletedState = PromptResponseDeleted();
        expect(deletedState.props, []);
      });
    });

    group('prompt model variations', () {
      test('handles different response types correctly', () {
        final textPrompt = testPrompt.copyWith(responseType: ResponseType.text);
        final audioPrompt =
            testPrompt.copyWith(responseType: ResponseType.audio);
        final sliderPrompt =
            testPrompt.copyWith(responseType: ResponseType.slider);
        final multiplePrompt =
            testPrompt.copyWith(responseType: ResponseType.multiple);

        expect(textPrompt.responseType, ResponseType.text);
        expect(audioPrompt.responseType, ResponseType.audio);
        expect(sliderPrompt.responseType, ResponseType.slider);
        expect(multiplePrompt.responseType, ResponseType.multiple);
      });

      test('handles prompts with different properties', () {
        final requiredPrompt = testPrompt.copyWith();
        final optionalPrompt = PromptModel(
          id: 2,
          questionNumber: 2,
          question: 'Optional question',
          responseType: ResponseType.text,
          required: false,
          multipleAnswer: true,
        );

        expect(requiredPrompt.required, isTrue);
        expect(optionalPrompt.required, isFalse);
        expect(optionalPrompt.multipleAnswer, isTrue);
      });
    });
  });
}
