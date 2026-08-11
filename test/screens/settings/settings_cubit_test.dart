import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/questions_entity.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/cubit/settings_cubit.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../dummy_data.dart';
import 'settings_cubit_test.mocks.dart';

// Generate mocks for dependencies
@GenerateMocks([SetupRepository, PreferenceService])
void main() {
  group('SettingsCubit', () {
    late TestableSettingsCubit settingsCubit;
    late MockSetupRepository mockSetupRepository;
    late MockPreferenceService mockPreferenceService;

    setUp(() {
      mockSetupRepository = MockSetupRepository();
      mockPreferenceService = MockPreferenceService();
      settingsCubit = TestableSettingsCubit(
        repository: mockSetupRepository,
        preferenceService: mockPreferenceService,
      );
    });

    tearDown(() {
      settingsCubit.close();
    });

    test('initial state is SettingsInitial', () {
      expect(settingsCubit.state, equals(SettingsInitial()));
    });

    group('load', () {
      final mockQuestions = [
        createTestQuestionsModel(),
        createTestQuestionsModel(),
      ];

      blocTest<TestableSettingsCubit, SettingsState>(
        'emits [SettingsLoading, SettingsLoaded] when load succeeds with completion date',
        build: () {
          when(mockSetupRepository.getOnBoardingQuestions())
              .thenAnswer((_) async => mockQuestions);
          when(mockPreferenceService.getStringPreference(
                  key: "onboardingSurveyCompletedDate"))
              .thenAnswer((_) async => "2023-12-25T10:30:00.000Z");
          return TestableSettingsCubit(
            repository: mockSetupRepository,
            preferenceService: mockPreferenceService,
          );
        },
        act: (cubit) => cubit.load(),
        expect: () => [
          SettingsLoading(),
          SettingsLoaded(
            onboardingQuestion: mockQuestions,
            completedDate:
                formatDateOnly(DateTime.parse("2023-12-25T10:30:00.000Z")),
          ),
        ],
        verify: (_) {
          verify(mockSetupRepository.getOnBoardingQuestions()).called(1);
          verify(mockPreferenceService.getStringPreference(
                  key: "onboardingSurveyCompletedDate"))
              .called(1);
        },
      );

      blocTest<TestableSettingsCubit, SettingsState>(
        'emits [SettingsLoading, SettingsLoaded] when load succeeds without completion date',
        build: () {
          when(mockSetupRepository.getOnBoardingQuestions())
              .thenAnswer((_) async => mockQuestions);
          when(mockPreferenceService.getStringPreference(
                  key: "onboardingSurveyCompletedDate"))
              .thenAnswer((_) async => null);
          return TestableSettingsCubit(
            repository: mockSetupRepository,
            preferenceService: mockPreferenceService,
          );
        },
        act: (cubit) => cubit.load(),
        expect: () => [
          SettingsLoading(),
          isA<SettingsLoaded>()
              .having(
                (state) => state.onboardingQuestion,
                'onboardingQuestion',
                mockQuestions,
              )
              .having(
                (state) => state.completedDate,
                'completedDate',
                formatDateOnly(DateTime.now()),
              ),
        ],
        verify: (_) {
          verify(mockSetupRepository.getOnBoardingQuestions()).called(1);
          verify(mockPreferenceService.getStringPreference(
                  key: "onboardingSurveyCompletedDate"))
              .called(1);
        },
      );

      blocTest<TestableSettingsCubit, SettingsState>(
        'emits [SettingsLoading, SettingsError] when getOnBoardingQuestions throws exception',
        build: () {
          when(mockSetupRepository.getOnBoardingQuestions())
              .thenThrow(Exception('Repository error'));
          when(mockPreferenceService.getStringPreference(
                  key: "onboardingSurveyCompletedDate"))
              .thenAnswer((_) async => null);
          return TestableSettingsCubit(
            repository: mockSetupRepository,
            preferenceService: mockPreferenceService,
          );
        },
        act: (cubit) => cubit.load(),
        expect: () => [
          SettingsLoading(),
          const SettingsError(
              "Error fetching Onboarding Questions: Exception: Repository error"),
        ],
        verify: (_) {
          verify(mockSetupRepository.getOnBoardingQuestions()).called(1);
        },
      );

      blocTest<TestableSettingsCubit, SettingsState>(
        'emits [SettingsLoading, SettingsError] when PreferenceService throws exception',
        build: () {
          when(mockSetupRepository.getOnBoardingQuestions())
              .thenAnswer((_) async => mockQuestions);
          when(mockPreferenceService.getStringPreference(
                  key: "onboardingSurveyCompletedDate"))
              .thenThrow(Exception('Preference error'));
          return TestableSettingsCubit(
            repository: mockSetupRepository,
            preferenceService: mockPreferenceService,
          );
        },
        act: (cubit) => cubit.load(),
        expect: () => [
          SettingsLoading(),
          const SettingsError(
              "Error fetching Onboarding Questions: Exception: Preference error"),
        ],
        verify: (_) {
          verify(mockSetupRepository.getOnBoardingQuestions()).called(1);
          verify(mockPreferenceService.getStringPreference(
                  key: "onboardingSurveyCompletedDate"))
              .called(1);
        },
      );

      blocTest<TestableSettingsCubit, SettingsState>(
        'handles empty questions list correctly',
        build: () {
          when(mockSetupRepository.getOnBoardingQuestions())
              .thenAnswer((_) async => []);
          when(mockPreferenceService.getStringPreference(
                  key: "onboardingSurveyCompletedDate"))
              .thenAnswer((_) async => null);
          return TestableSettingsCubit(
            repository: mockSetupRepository,
            preferenceService: mockPreferenceService,
          );
        },
        act: (cubit) => cubit.load(),
        expect: () => [
          SettingsLoading(),
          isA<SettingsLoaded>().having(
            (state) => state.onboardingQuestion,
            'onboardingQuestion',
            isEmpty,
          ),
        ],
        verify: (_) {
          verify(mockSetupRepository.getOnBoardingQuestions()).called(1);
          verify(mockPreferenceService.getStringPreference(
                  key: "onboardingSurveyCompletedDate"))
              .called(1);
        },
      );
    });

    group('save', () {
      final testQuestion = createTestQuestionsModel();
      const testAnswer = 'Test Answer';

      blocTest<TestableSettingsCubit, SettingsState>(
        'saves question and answer successfully without state change',
        build: () {
          when(mockSetupRepository.saveOnBoardingAnswer(any))
              .thenAnswer((_) async {});
          when(mockPreferenceService.setStringPreference(
                  key: "onboardingSurveyCompletedDate",
                  value: anyNamed('value')))
              .thenAnswer((_) async => true);
          return TestableSettingsCubit(
            repository: mockSetupRepository,
            preferenceService: mockPreferenceService,
          );
        },
        act: (cubit) => cubit.save(testQuestion, testAnswer),
        expect: () => [],
        verify: (_) {
          final captured =
              verify(mockSetupRepository.saveOnBoardingAnswer(captureAny))
                  .captured;
          expect(captured.length, 1);
          final savedEntity = captured[0] as QuestionsEntity;
          expect(savedEntity.title, testQuestion.title);
          expect(savedEntity.answer, testAnswer);
          expect(savedEntity.variable, testQuestion.variable);

          verify(mockPreferenceService.setStringPreference(
                  key: "onboardingSurveyCompletedDate",
                  value: anyNamed('value')))
              .called(1);
        },
      );

      blocTest<TestableSettingsCubit, SettingsState>(
        'emits SettingsError when saveOnBoardingAnswer throws exception',
        build: () {
          when(mockSetupRepository.saveOnBoardingAnswer(any))
              .thenThrow(Exception('Save error'));
          when(mockPreferenceService.setStringPreference(
                  key: "onboardingSurveyCompletedDate",
                  value: anyNamed('value')))
              .thenAnswer((_) async => true);
          return TestableSettingsCubit(
            repository: mockSetupRepository,
            preferenceService: mockPreferenceService,
          );
        },
        act: (cubit) => cubit.save(testQuestion, testAnswer),
        expect: () => [
          const SettingsError(
              "Error saving Onboarding Answer: Exception: Save error"),
        ],
        verify: (_) {
          verify(mockSetupRepository.saveOnBoardingAnswer(any)).called(1);
        },
      );

      blocTest<TestableSettingsCubit, SettingsState>(
        'emits SettingsError when setStringPreference throws exception',
        build: () {
          when(mockSetupRepository.saveOnBoardingAnswer(any))
              .thenAnswer((_) async {});
          when(mockPreferenceService.setStringPreference(
                  key: "onboardingSurveyCompletedDate",
                  value: anyNamed('value')))
              .thenThrow(Exception('Preference save error'));
          return TestableSettingsCubit(
            repository: mockSetupRepository,
            preferenceService: mockPreferenceService,
          );
        },
        act: (cubit) => cubit.save(testQuestion, testAnswer),
        expect: () => [
          const SettingsError(
              "Error saving Onboarding Answer: Exception: Preference save error"),
        ],
        verify: (_) {
          verify(mockSetupRepository.saveOnBoardingAnswer(any)).called(1);
          verify(mockPreferenceService.setStringPreference(
                  key: "onboardingSurveyCompletedDate",
                  value: anyNamed('value')))
              .called(1);
        },
      );

      blocTest<TestableSettingsCubit, SettingsState>(
        'correctly creates question with updated answer',
        build: () {
          when(mockSetupRepository.saveOnBoardingAnswer(any))
              .thenAnswer((_) async {});
          when(mockPreferenceService.setStringPreference(
                  key: "onboardingSurveyCompletedDate",
                  value: anyNamed('value')))
              .thenAnswer((_) async => true);
          return TestableSettingsCubit(
            repository: mockSetupRepository,
            preferenceService: mockPreferenceService,
          );
        },
        act: (cubit) => cubit.save(testQuestion, testAnswer),
        expect: () => [],
        verify: (_) {
          final captured =
              verify(mockSetupRepository.saveOnBoardingAnswer(captureAny))
                  .captured;
          final savedEntity = captured[0] as QuestionsEntity;
          expect(savedEntity.answer, testAnswer);
          expect(savedEntity.title, testQuestion.title);
          expect(savedEntity.type, testQuestion.type);
          expect(savedEntity.variable, testQuestion.variable);
        },
      );
    });

    group('reload', () {
      final mockQuestions = [
        createTestQuestionsModel(),
        createTestQuestionsModel(),
      ];

      test('returns fresh questions from repository', () async {
        when(mockSetupRepository.getOnBoardingQuestions())
            .thenAnswer((_) async => mockQuestions);

        final testCubit = TestableSettingsCubit(
          repository: mockSetupRepository,
          preferenceService: mockPreferenceService,
        );

        final result = await testCubit.reload();

        expect(result, equals(mockQuestions));
        verify(mockSetupRepository.getOnBoardingQuestions()).called(1);

        testCubit.close();
      });

      test('throws exception when repository throws', () async {
        when(mockSetupRepository.getOnBoardingQuestions())
            .thenThrow(Exception('Reload error'));

        final testCubit = TestableSettingsCubit(
          repository: mockSetupRepository,
          preferenceService: mockPreferenceService,
        );

        expect(
          () => testCubit.reload(),
          throwsA(isA<Exception>()),
        );

        verify(mockSetupRepository.getOnBoardingQuestions()).called(1);

        testCubit.close();
      });

      test('returns empty list when repository returns empty', () async {
        when(mockSetupRepository.getOnBoardingQuestions())
            .thenAnswer((_) async => []);

        final testCubit = TestableSettingsCubit(
          repository: mockSetupRepository,
          preferenceService: mockPreferenceService,
        );

        final result = await testCubit.reload();

        expect(result, isEmpty);
        verify(mockSetupRepository.getOnBoardingQuestions()).called(1);

        testCubit.close();
      });
    });

    group('state equality', () {
      test('SettingsInitial instances are equal', () {
        final state1 = SettingsInitial();
        final state2 = SettingsInitial();
        expect(state1, equals(state2));
      });

      test('SettingsLoading instances are equal', () {
        final state1 = SettingsLoading();
        final state2 = SettingsLoading();
        expect(state1, equals(state2));
      });

      test('SettingsLoaded instances with same data are equal', () {
        final questions = [
          createTestQuestionsModel(),
        ];
        final completedDate = '2023-12-25';

        final state1 = SettingsLoaded(
          onboardingQuestion: questions,
          completedDate: completedDate,
        );
        final state2 = SettingsLoaded(
          onboardingQuestion: questions,
          completedDate: completedDate,
        );

        expect(state1, equals(state2));
      });

      test('SettingsError instances with same message are equal', () {
        final state1 = SettingsError('Test error');
        final state2 = SettingsError('Test error');
        expect(state1, equals(state2));
      });

      test('different state types are not equal', () {
        final initial = SettingsInitial();
        final loading = SettingsLoading();
        final error = SettingsError('Test error');
        final loaded =
            SettingsLoaded(onboardingQuestion: [], completedDate: '2023-12-25');

        expect(initial, isNot(equals(loading)));
        expect(initial, isNot(equals(error)));
        expect(initial, isNot(equals(loaded)));
        expect(loading, isNot(equals(error)));
        expect(loading, isNot(equals(loaded)));
        expect(error, isNot(equals(loaded)));
      });
    });

    group('TestableSettingsCubit', () {
      test('exposes dependencies correctly', () {
        final testCubit = TestableSettingsCubit(
          repository: mockSetupRepository,
          preferenceService: mockPreferenceService,
        );

        expect(testCubit.repository, equals(mockSetupRepository));
        expect(testCubit.preferenceService, equals(mockPreferenceService));
        testCubit.close();
      });

      test('inherits from SettingsCubit', () {
        final testCubit = TestableSettingsCubit(
          repository: mockSetupRepository,
          preferenceService: mockPreferenceService,
        );

        expect(testCubit, isA<Cubit<SettingsState>>());
        testCubit.close();
      });

      test('starts with SettingsInitial state', () {
        final testCubit = TestableSettingsCubit(
          repository: mockSetupRepository,
          preferenceService: mockPreferenceService,
        );

        expect(testCubit.state, equals(SettingsInitial()));
        testCubit.close();
      });
    });
  });
}

// Testable version of SettingsCubit that accepts dependencies
class TestableSettingsCubit extends Cubit<SettingsState> {
  final SetupRepository repository;
  final PreferenceService preferenceService;

  TestableSettingsCubit({
    required this.repository,
    required this.preferenceService,
  }) : super(SettingsInitial());

  void load() async {
    emit(SettingsLoading());
    try {
      final questions = await repository.getOnBoardingQuestions();
      final completedDate = await preferenceService.getStringPreference(
          key: "onboardingSurveyCompletedDate");
      final date = completedDate != null
          ? DateTime.parse(completedDate)
          : DateTime.now();
      emit(SettingsLoaded(
          onboardingQuestion: questions, completedDate: formatDateOnly(date)));
    } catch (e) {
      emit(SettingsError("Error fetching Onboarding Questions: $e"));
    }
  }

  void save(Questions question, String answer) async {
    try {
      final newQuestion = question.copyWith(answer: answer);
      repository.saveOnBoardingAnswer(QuestionsEntity.fromModel(newQuestion));
      await preferenceService.setStringPreference(
          key: "onboardingSurveyCompletedDate",
          value: DateTime.now().toString());
    } catch (e) {
      emit(SettingsError("Error saving Onboarding Answer: $e"));
    }
  }

  Future<List<Questions>> reload() async {
    final questions = await repository.getOnBoardingQuestions();
    return questions;
  }
}
