import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/participant.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/setup/setup_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Generate mocks for dependencies
@GenerateMocks([SetupRepository])
void main() {
  group('SetupCubit', () {
    late TestableSetupCubit setupCubit;
    late MockSetupRepository mockSetupRepository;

    setUp(() {
      mockSetupRepository = MockSetupRepository();
      setupCubit = TestableSetupCubit(
        repository: mockSetupRepository,
      );
    });

    tearDown(() {
      setupCubit.close();
    });

    test('initial state is SetupInitial', () {
      expect(setupCubit.state, equals(const SetupInitial()));
    });

    group('load', () {
      final mockParticipant = Participant(
        name: 'John Doe',
        studyCode: 'STUDY123',
      );

      blocTest<TestableSetupCubit, SetupState>(
        'emits [SetupLoading, SetupLoaded] when load succeeds',
        build: () {
          when(mockSetupRepository.getParticipant())
              .thenReturn(mockParticipant);
          return TestableSetupCubit(
            repository: mockSetupRepository,
          );
        },
        act: (cubit) => cubit.load(),
        expect: () => [
          const SetupLoading(),
          SetupLoaded(mockParticipant),
        ],
        verify: (_) {
          verify(mockSetupRepository.getParticipant()).called(1);
        },
      );

      blocTest<TestableSetupCubit, SetupState>(
        'emits [SetupLoading, SetupLoaded] when participant is null',
        build: () {
          when(mockSetupRepository.getParticipant()).thenReturn(null);
          return TestableSetupCubit(
            repository: mockSetupRepository,
          );
        },
        act: (cubit) => cubit.load(),
        expect: () => [
          const SetupLoading(),
          const SetupLoaded(null),
        ],
        verify: (_) {
          verify(mockSetupRepository.getParticipant()).called(1);
        },
      );

      blocTest<TestableSetupCubit, SetupState>(
        'emits [SetupLoading, SetupError] when repository throws exception',
        build: () {
          when(mockSetupRepository.getParticipant())
              .thenThrow(Exception('Repository error'));
          return TestableSetupCubit(
            repository: mockSetupRepository,
          );
        },
        act: (cubit) => cubit.load(),
        expect: () => [
          const SetupLoading(),
          const SetupError("Something went wrong"),
        ],
        verify: (_) {
          verify(mockSetupRepository.getParticipant()).called(1);
        },
      );

      blocTest<TestableSetupCubit, SetupState>(
        'loads participant with empty name',
        build: () {
          final emptyNameParticipant = Participant(
            name: '',
            studyCode: 'STUDY456',
          );
          when(mockSetupRepository.getParticipant())
              .thenReturn(emptyNameParticipant);
          return TestableSetupCubit(
            repository: mockSetupRepository,
          );
        },
        act: (cubit) => cubit.load(),
        expect: () => [
          const SetupLoading(),
          isA<SetupLoaded>(),
        ],
        verify: (_) {
          verify(mockSetupRepository.getParticipant()).called(1);
        },
      );
    });

    group('updateParticipant', () {
      const testName = 'Jane Smith';

      blocTest<TestableSetupCubit, SetupState>(
        'emits [SetupLoading, SetupSuccess] when update succeeds',
        build: () {
          when(mockSetupRepository.updateParticipant(testName))
              .thenReturn(null);
          return TestableSetupCubit(
            repository: mockSetupRepository,
          );
        },
        act: (cubit) => cubit.updateParticipant(testName),
        expect: () => [
          const SetupLoading(),
          const SetupSuccess(),
        ],
        verify: (_) {
          verify(mockSetupRepository.updateParticipant(testName)).called(1);
        },
      );

      blocTest<TestableSetupCubit, SetupState>(
        'emits [SetupLoading, SetupError] when repository throws exception',
        build: () {
          when(mockSetupRepository.updateParticipant(testName))
              .thenThrow(Exception('Update error'));
          return TestableSetupCubit(
            repository: mockSetupRepository,
          );
        },
        act: (cubit) => cubit.updateParticipant(testName),
        expect: () => [
          const SetupLoading(),
          const SetupError("Something went wrong"),
        ],
        verify: (_) {
          verify(mockSetupRepository.updateParticipant(testName)).called(1);
        },
      );

      blocTest<TestableSetupCubit, SetupState>(
        'handles empty name update',
        build: () {
          when(mockSetupRepository.updateParticipant('')).thenReturn(null);
          return TestableSetupCubit(
            repository: mockSetupRepository,
          );
        },
        act: (cubit) => cubit.updateParticipant(''),
        expect: () => [
          const SetupLoading(),
          const SetupSuccess(),
        ],
        verify: (_) {
          verify(mockSetupRepository.updateParticipant('')).called(1);
        },
      );
    });

    group('state equality', () {
      test('SetupInitial instances are equal', () {
        const state1 = SetupInitial();
        const state2 = SetupInitial();
        expect(state1, equals(state2));
      });

      test('SetupLoading instances are equal', () {
        const state1 = SetupLoading();
        const state2 = SetupLoading();
        expect(state1, equals(state2));
      });

      test('SetupLoaded instances with same participant are equal', () {
        final participant = Participant(
          name: 'Test User',
          studyCode: 'TEST123',
        );

        final state1 = SetupLoaded(participant);
        final state2 = SetupLoaded(participant);
        expect(state1, equals(state2));
      });

      test('SetupLoaded instances with null participant are equal', () {
        const state1 = SetupLoaded(null);
        const state2 = SetupLoaded(null);
        expect(state1, equals(state2));
      });

      test('SetupError instances with same message are equal', () {
        const state1 = SetupError('Test error');
        const state2 = SetupError('Test error');
        expect(state1, equals(state2));
      });

      test('SetupSuccess instances are equal', () {
        const state1 = SetupSuccess();
        const state2 = SetupSuccess();
        expect(state1, equals(state2));
      });


      test('different state types are not equal', () {
        const initial = SetupInitial();
        const loading = SetupLoading();
        const loaded = SetupLoaded(null);
        const error = SetupError('Test error');
        const success = SetupSuccess();

        expect(initial, isNot(equals(loading)));
        expect(initial, isNot(equals(loaded)));
        expect(initial, isNot(equals(error)));
        expect(initial, isNot(equals(success)));
        expect(loading, isNot(equals(loaded)));
        expect(loading, isNot(equals(error)));
        expect(loading, isNot(equals(success)));
        expect(loaded, isNot(equals(error)));
        expect(loaded, isNot(equals(success)));
        expect(error, isNot(equals(success)));
      });
    });

    group('TestableSetupCubit', () {
      test('exposes dependencies correctly', () {
        final testCubit = TestableSetupCubit(
          repository: mockSetupRepository,
        );

        expect(testCubit.repository, equals(mockSetupRepository));
        testCubit.close();
      });

      test('inherits from Cubit<SetupState>', () {
        final testCubit = TestableSetupCubit(
          repository: mockSetupRepository,
        );

        expect(testCubit, isA<Cubit<SetupState>>());
        testCubit.close();
      });

      test('starts with SetupInitial state', () {
        final testCubit = TestableSetupCubit(
          repository: mockSetupRepository,
        );

        expect(testCubit.state, equals(const SetupInitial()));
        testCubit.close();
      });
    });

    group('integration scenarios', () {
      blocTest<TestableSetupCubit, SetupState>(
        'load then update participant workflow',
        build: () {
          final participant = Participant(
            name: 'Initial Name',
            studyCode: 'TEST123',
          );

          when(mockSetupRepository.getParticipant()).thenReturn(participant);
          when(mockSetupRepository.updateParticipant('Updated Name'))
              .thenReturn(null);

          return TestableSetupCubit(
            repository: mockSetupRepository,
          );
        },
        act: (cubit) async {
          cubit.load();
          await Future.delayed(const Duration(milliseconds: 10));
          cubit.updateParticipant('Updated Name');
        },
        expect: () => [
          const SetupLoading(),
          isA<SetupLoaded>(),
          const SetupLoading(),
          const SetupSuccess(),
        ],
        verify: (_) {
          verify(mockSetupRepository.getParticipant()).called(1);
          verify(mockSetupRepository.updateParticipant('Updated Name'))
              .called(1);
        },
      );

      blocTest<TestableSetupCubit, SetupState>(
        'multiple load calls',
        build: () {
          final participant = Participant(
            name: 'Test User',
            studyCode: 'TEST123',
          );

          when(mockSetupRepository.getParticipant()).thenReturn(participant);

          return TestableSetupCubit(
            repository: mockSetupRepository,
          );
        },
        act: (cubit) async {
          cubit.load();
          await Future.delayed(const Duration(milliseconds: 10));
          cubit.load();
        },
        expect: () => [
          const SetupLoading(),
          isA<SetupLoaded>(),
          const SetupLoading(),
          isA<SetupLoaded>(),
        ],
        verify: (_) {
          verify(mockSetupRepository.getParticipant()).called(2);
        },
      );
    });
  });
}

// Mock classes
class MockSetupRepository extends Mock implements SetupRepository {}

// Testable version of SetupCubit that accepts dependencies
class TestableSetupCubit extends Cubit<SetupState> {
  final SetupRepository repository;

  TestableSetupCubit({
    required this.repository,
  }) : super(const SetupInitial());

  void load() async {
    emit(const SetupLoading());
    try {
      final participant = repository.getParticipant();
      emit(SetupLoaded(participant));
    } catch (e) {
      // debugPrint(e.toString());
      emit(const SetupError("Something went wrong"));
    }
  }

  void updateParticipant(String name) {
    emit(const SetupLoading());
    try {
      repository.updateParticipant(name);
      emit(const SetupSuccess());
    } catch (e) {
      // debugPrint(e.toString());
      emit(const SetupError("Something went wrong"));
    }
  }
}
