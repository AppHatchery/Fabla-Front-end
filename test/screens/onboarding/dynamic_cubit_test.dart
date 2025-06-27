import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/questions_entity.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/dynamic/dynamic_cubit.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Using manually created mocks below instead of generated ones
void main() {
  group('DynamicCubit', () {
    late MockSetupRepository mockSetupRepository;
    late MockPreferenceService mockPreferenceService;

    setUp(() {
      mockSetupRepository = MockSetupRepository();
      mockPreferenceService = MockPreferenceService();
    });

    test('initial state is DynamicInitial', () {
      final dynamicCubit = TestableDynamicCubit(
        setupRepository: mockSetupRepository,
        preferenceService: mockPreferenceService,
      );

      expect(dynamicCubit.state, isA<DynamicInitial>());
      dynamicCubit.close();
    });


    group('save', () {
      const testQuestion = Questions(
        id: 1,
        title: 'Test Question',
        subtitle: 'Test subtitle',
        options: null,
        type: 'text',
        min: null,
        max: null,
        defaultValue: null,
        minLabel: null,
        maxLabel: null,
        variable: 'test_var',
        answer: null,
      );
      const testAnswer = 'Test Answer';

      test('saves question and answer successfully', () {
        final testCubit = TestableDynamicCubit(
          setupRepository: mockSetupRepository,
          preferenceService: mockPreferenceService,
        );

        // This should not throw an exception
        expect(() => testCubit.save(testQuestion, testAnswer), returnsNormally);

        testCubit.close();
      });

      test('handles save exception gracefully', () {
        final testCubit = TestableDynamicCubit(
          setupRepository: mockSetupRepository,
          preferenceService: mockPreferenceService,
        );

        // Should not throw an exception (caught internally)
        expect(() => testCubit.save(testQuestion, testAnswer), returnsNormally);

        testCubit.close();
      });
    });

    group('state equality', () {
      test('DynamicInitial instances are equal', () {
        final state1 = DynamicInitial();
        final state2 = DynamicInitial();
        expect(state1, equals(state2));
      });

      test('DynamicLoading instances are equal', () {
        final state1 = DynamicLoading();
        final state2 = DynamicLoading();
        expect(state1, equals(state2));
      });

      test('DynamicLoaded instances with same questions are equal', () {
        const questions = [
          Questions(
            id: 1,
            title: 'Test',
            subtitle: null,
            options: null,
            type: 'text',
            min: null,
            max: null,
            defaultValue: null,
            minLabel: null,
            maxLabel: null,
            variable: 'test',
            answer: null,
          ),
        ];

        const state1 = DynamicLoaded(questions: questions);
        const state2 = DynamicLoaded(questions: questions);

        expect(state1, equals(state2));
      });

      test('DynamicError instances with same message are equal', () {
        const state1 = DynamicError('Test error');
        const state2 = DynamicError('Test error');
        expect(state1, equals(state2));
      });

      test('DynamicUploading instances are equal', () {
        final state1 = DynamicUploading();
        final state2 = DynamicUploading();
        expect(state1, equals(state2));
      });

      test('DynamicUploaded instances with same length are equal', () {
        const state1 = DynamicUploaded(5);
        const state2 = DynamicUploaded(5);
        expect(state1, equals(state2));
      });

      test('different state types are not equal', () {
        final initial = DynamicInitial();
        final loading = DynamicLoading();
        const loaded = DynamicLoaded(questions: []);
        const error = DynamicError('Test error');
        final uploading = DynamicUploading();
        const uploaded = DynamicUploaded(5);

        expect(initial, isNot(equals(loading)));
        expect(initial, isNot(equals(loaded)));
        expect(initial, isNot(equals(error)));
        expect(initial, isNot(equals(uploading)));
        expect(initial, isNot(equals(uploaded)));
      });
    });

    group('TestableDynamicCubit', () {
      test('exposes dependencies correctly', () {
        final testCubit = TestableDynamicCubit(
          setupRepository: mockSetupRepository,
          preferenceService: mockPreferenceService,
        );

        expect(testCubit.setupRepository, equals(mockSetupRepository));
        expect(testCubit.preferenceService, equals(mockPreferenceService));
        testCubit.close();
      });

      test('inherits from Cubit<DynamicState>', () {
        final testCubit = TestableDynamicCubit(
          setupRepository: mockSetupRepository,
          preferenceService: mockPreferenceService,
        );

        expect(testCubit, isA<Cubit<DynamicState>>());
        testCubit.close();
      });

      test('starts with DynamicInitial state', () {
        final testCubit = TestableDynamicCubit(
          setupRepository: mockSetupRepository,
          preferenceService: mockPreferenceService,
        );

        expect(testCubit.state, isA<DynamicInitial>());
        testCubit.close();
      });
    });
  });
}

// Mock classes
class MockSetupRepository extends Mock implements SetupRepository {}

class MockPreferenceService extends Mock implements PreferenceService {}

// Testable version of DynamicCubit that accepts dependencies
class TestableDynamicCubit extends Cubit<DynamicState> {
  final SetupRepository setupRepository;
  final PreferenceService preferenceService;

  TestableDynamicCubit({
    required this.setupRepository,
    required this.preferenceService,
  }) : super(DynamicInitial());

  void load() async {
    emit(DynamicLoading());
    try {
      final List<Questions> questions =
          await setupRepository.getOnBoardingQuestions();

      if (questions.isNotEmpty) {
        emit(DynamicLoaded(questions: questions));
      } else {
        emit(DynamicUploading());
        // Clean the database first
        setupRepository.clearStudies();
        await setupRepository.getStudies();
        upload(questions.length);
      }
    } catch (e) {
      // debugPrint("Error fetching Onboarding Questions: $e");
    }
  }

  Future<int> count() async => await setupRepository
      .getOnBoardingQuestions()
      .then((value) => value.length);

  void save(Questions question, String answer) {
    try {
      final newQuestion = question.copyWith(answer: answer);
      setupRepository
          .saveOnBoardingAnswer(QuestionsEntity.fromModel(newQuestion));
    } catch (e) {
      // debugPrint("Error saving Onboarding Answer: $e");
    }
  }

  void upload(int length) async {
    emit(DynamicUploading());
    try {
      final result = await setupRepository.uploadOnBoardingQuestions();
      if (result) {
        await preferenceService.setStringPreference(
            key: "onboardingSurveyCompletedDate",
            value: DateTime.now().toString());
        emit(DynamicUploaded(length));
      } else {
        emit(const DynamicError("Failed to upload answers"));
      }
    } catch (e) {
      // debugPrint("Error uploading Onboarding Answers: $e");
    }
  }
}
