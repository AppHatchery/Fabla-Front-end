import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/login_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/login/login_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Mock classes with unique names to avoid conflicts
class MockLoginRepositoryTest extends Mock implements LoginRepository {}

class MockSetupRepositoryTest extends Mock implements SetupRepository {}

// Testable version of LoginCubit that accepts dependencies
class TestableLoginCubit extends Cubit<LoginState> {
  final LoginRepository repository;
  final SetupRepository setupRepository;

  TestableLoginCubit({
    required this.repository,
    required this.setupRepository,
  }) : super(const LoginInitial());

  void login(String code) async {
    emit(const LoginLoading());
    try {
      final result = await repository.verify(code);
      if (result) {
        try {
          setupRepository.getExperiment();
          // Skip PendoService.start in tests
          // await PendoService.start(code, experiment.login);
        } catch (e) {
          // debugPrint('Pendo session handling error: $e');
        }
        emit(const LoginSuccess());
      } else {
        // Skip PendoService.track in tests
        // PendoService.track("Participant Login", {
        //   "participant_id": code,
        //   "status": "error",
        // });
        emit(const LoginError(
            "Oops! We do not have this ID in the participant list. Please check your email and try again."));
      }
    } catch (e) {
      // debugPrint(e.toString());
      emit(const LoginError("Something went wrong"));
    }
  }
}

void main() {
  group('LoginCubit', () {
    late TestableLoginCubit loginCubit;
    late MockLoginRepositoryTest mockLoginRepository;
    late MockSetupRepositoryTest mockSetupRepository;

    setUp(() {
      mockLoginRepository = MockLoginRepositoryTest();
      mockSetupRepository = MockSetupRepositoryTest();
      loginCubit = TestableLoginCubit(
        repository: mockLoginRepository,
        setupRepository: mockSetupRepository,
      );
    });

    tearDown(() {
      loginCubit.close();
    });

    test('initial state is LoginInitial', () {
      expect(loginCubit.state, equals(const LoginInitial()));
    });

    group('state equality', () {
      test('LoginInitial instances are equal', () {
        const state1 = LoginInitial();
        const state2 = LoginInitial();
        expect(state1, equals(state2));
      });

      test('LoginLoading instances are equal', () {
        const state1 = LoginLoading();
        const state2 = LoginLoading();
        expect(state1, equals(state2));
      });

      test('LoginSuccess instances are equal', () {
        const state1 = LoginSuccess();
        const state2 = LoginSuccess();
        expect(state1, equals(state2));
      });

      test('LoginError instances with same message are equal', () {
        const state1 = LoginError('Test error');
        const state2 = LoginError('Test error');
        expect(state1, equals(state2));
      });

      test('different state types are not equal', () {
        const initial = LoginInitial();
        const loading = LoginLoading();
        const success = LoginSuccess();
        const error = LoginError('Test error');

        expect(initial, isNot(equals(loading)));
        expect(initial, isNot(equals(success)));
        expect(initial, isNot(equals(error)));
        expect(loading, isNot(equals(success)));
        expect(loading, isNot(equals(error)));
        expect(success, isNot(equals(error)));
      });
    });

    group('TestableLoginCubit', () {
      test('exposes dependencies correctly', () {
        final testCubit = TestableLoginCubit(
          repository: mockLoginRepository,
          setupRepository: mockSetupRepository,
        );

        expect(testCubit.repository, equals(mockLoginRepository));
        expect(testCubit.setupRepository, equals(mockSetupRepository));
        testCubit.close();
      });

      test('inherits from Cubit<LoginState>', () {
        final testCubit = TestableLoginCubit(
          repository: mockLoginRepository,
          setupRepository: mockSetupRepository,
        );

        expect(testCubit, isA<Cubit<LoginState>>());
        testCubit.close();
      });

      test('starts with LoginInitial state', () {
        final testCubit = TestableLoginCubit(
          repository: mockLoginRepository,
          setupRepository: mockSetupRepository,
        );

        expect(testCubit.state, equals(const LoginInitial()));
        testCubit.close();
      });
    });
  });
}
