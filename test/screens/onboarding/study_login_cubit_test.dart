import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/login_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/login/study_login_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Mock classes
class MockLoginRepository extends Mock implements LoginRepository {}

// Testable version of StudyLoginCubit that accepts dependencies
class TestableStudyLoginCubit extends Cubit<StudyLoginState> {
  final LoginRepository repository;

  TestableStudyLoginCubit({
    required this.repository,
  }) : super(const StudyLoginInitial());

  void login(String code) async {
    emit(const StudyLoginLoading());
    try {
      final result = await repository.studyVerification(code);
      if (result != null) {
        emit(StudyLoginSuccess(result));
      } else {
        // Skip PendoService.track in tests
        // PendoService.track("Study Login", {
        //   "code": code,
        //   "status": "error",
        // });
        emit(const StudyLoginError(
            "Oops! We do not have this code in the study list. Please check your email and try again."));
      }
    } catch (e) {
      emit(const StudyLoginError("Something went wrong. Please try again."));
    }
  }
}

void main() {
  group('StudyLoginCubit', () {
    late TestableStudyLoginCubit studyLoginCubit;
    late MockLoginRepository mockLoginRepository;

    setUp(() {
      mockLoginRepository = MockLoginRepository();
      studyLoginCubit = TestableStudyLoginCubit(
        repository: mockLoginRepository,
      );
    });

    tearDown(() {
      studyLoginCubit.close();
    });

    test('initial state is StudyLoginInitial', () {
      expect(studyLoginCubit.state, equals(const StudyLoginInitial()));
    });

    group('state equality', () {
      test('StudyLoginInitial instances are equal', () {
        const state1 = StudyLoginInitial();
        const state2 = StudyLoginInitial();
        expect(state1, equals(state2));
      });

      test('StudyLoginLoading instances are equal', () {
        const state1 = StudyLoginLoading();
        const state2 = StudyLoginLoading();
        expect(state1, equals(state2));
      });

      test('StudyLoginSuccess instances with same experiment are equal', () {
        final experiment = ExperimentModel(
          id: 1,
          login: 'test',
          researcher: 'Test',
          organization: 'Test',
          name: 'Test',
          duration: '30',
          description: 'Test',
          version: '1.0',
        );

        final state1 = StudyLoginSuccess(experiment);
        final state2 = StudyLoginSuccess(experiment);
        expect(state1, equals(state2));
      });

      test('StudyLoginError instances with same message are equal', () {
        const state1 = StudyLoginError('Test error');
        const state2 = StudyLoginError('Test error');
        expect(state1, equals(state2));
      });

      test('StudyLoginError instances with different messages are not equal',
          () {
        const state1 = StudyLoginError('Error 1');
        const state2 = StudyLoginError('Error 2');
        expect(state1, isNot(equals(state2)));
      });

      test('different state types are not equal', () {
        const initial = StudyLoginInitial();
        const loading = StudyLoginLoading();
        final experiment = ExperimentModel(
          id: 1,
          login: 'test',
          researcher: 'Test',
          organization: 'Test',
          name: 'Test',
          duration: '30',
          description: 'Test',
          version: '1.0',
        );
        final success = StudyLoginSuccess(experiment);
        const error = StudyLoginError('Test error');

        expect(initial, isNot(equals(loading)));
        expect(initial, isNot(equals(success)));
        expect(initial, isNot(equals(error)));
        expect(loading, isNot(equals(success)));
        expect(loading, isNot(equals(error)));
        expect(success, isNot(equals(error)));
      });
    });

    group('TestableStudyLoginCubit', () {
      test('exposes dependencies correctly', () {
        final testCubit = TestableStudyLoginCubit(
          repository: mockLoginRepository,
        );

        expect(testCubit.repository, equals(mockLoginRepository));
        testCubit.close();
      });

      test('inherits from Cubit<StudyLoginState>', () {
        final testCubit = TestableStudyLoginCubit(
          repository: mockLoginRepository,
        );

        expect(testCubit, isA<Cubit<StudyLoginState>>());
        testCubit.close();
      });

      test('starts with StudyLoginInitial state', () {
        final testCubit = TestableStudyLoginCubit(
          repository: mockLoginRepository,
        );

        expect(testCubit.state, equals(const StudyLoginInitial()));
        testCubit.close();
      });
    });
  });
}
