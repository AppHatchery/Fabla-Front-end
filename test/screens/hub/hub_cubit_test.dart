import 'package:audio_diaries_flutter/core/usecases/experiment_manager.dart';
import 'package:audio_diaries_flutter/screens/hub/presentation/cubit/hub_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock class using mocktail
class MockExperimentManager extends Mock implements ExperimentManager {}

void main() {
  group('HubCubit', () {
    late HubCubit hubCubit;
    late MockExperimentManager mockExperimentManager;

    setUp(() {
      mockExperimentManager = MockExperimentManager();
      // Create HubCubit with injected mock
      hubCubit = HubCubit(experimentManager: mockExperimentManager);
    });

    tearDown(() {
      hubCubit.close();
    });

    test('initial state is HubInitial', () {
      expect(hubCubit.state, equals(const HubInitial()));
    });

    group('update', () {
      blocTest<HubCubit, HubState>(
        'emits [HubUpdating, HubUpdated(false), HubInitial] when ExperimentManager.update() returns false',
        build: () {
          when(() => mockExperimentManager.update())
              .thenAnswer((_) async => false);
          return HubCubit(experimentManager: mockExperimentManager);
        },
        act: (cubit) => cubit.update(),
        expect: () => [
          const HubUpdating(),
          const HubUpdated(false),
          const HubInitial(),
        ],
        verify: (_) {
          verify(() => mockExperimentManager.update()).called(1);
        },
      );

      blocTest<HubCubit, HubState>(
        'emits [HubUpdating, HubUpdated(true), HubInitial] when ExperimentManager.update() returns true',
        build: () {
          when(() => mockExperimentManager.update())
              .thenAnswer((_) async => true);
          return HubCubit(experimentManager: mockExperimentManager);
        },
        act: (cubit) => cubit.update(),
        expect: () => [
          const HubUpdating(),
          const HubUpdated(true),
          const HubInitial(),
        ],
        verify: (_) {
          verify(() => mockExperimentManager.update()).called(1);
        },
      );

      blocTest<HubCubit, HubState>(
        'handles exceptions by throwing the exception after emitting HubUpdating',
        build: () {
          when(() => mockExperimentManager.update())
              .thenThrow(Exception('Test exception'));
          return HubCubit(experimentManager: mockExperimentManager);
        },
        act: (cubit) => cubit.update(),
        expect: () => [
          const HubUpdating(),
        ],
        errors: () => [
          isA<Exception>(),
        ],
        verify: (_) {
          verify(() => mockExperimentManager.update()).called(1);
        },
      );

      blocTest<HubCubit, HubState>(
        'can be called multiple times without issues',
        build: () {
          when(() => mockExperimentManager.update())
              .thenAnswer((_) async => false);
          return HubCubit(experimentManager: mockExperimentManager);
        },
        act: (cubit) async {
          await cubit.update();
          await cubit.update();
          await cubit.update();
        },
        expect: () => [
          const HubUpdating(),
          const HubUpdated(false),
          const HubInitial(),
          const HubUpdating(),
          const HubUpdated(false),
          const HubInitial(),
          const HubUpdating(),
          const HubUpdated(false),
          const HubInitial(),
        ],
        verify: (_) {
          verify(() => mockExperimentManager.update()).called(3);
        },
      );

      blocTest<HubCubit, HubState>(
        'handles concurrent calls correctly',
        build: () {
          when(() => mockExperimentManager.update()).thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 10));
            return true;
          });
          return HubCubit(experimentManager: mockExperimentManager);
        },
        act: (cubit) async {
          // Start multiple concurrent calls
          final futures = <Future<void>>[
            cubit.update(),
            cubit.update(),
          ];
          await Future.wait(futures);
        },
        expect: () => [
          const HubUpdating(),
          const HubUpdated(true),
          const HubInitial(),
          const HubUpdated(true),
          const HubInitial(),
        ],
        verify: (_) {
          verify(() => mockExperimentManager.update()).called(2);
        },
      );
    });

    group('state equality', () {
      test('HubInitial instances are equal', () {
        const state1 = HubInitial();
        const state2 = HubInitial();
        expect(state1, equals(state2));
      });

      test('HubUpdating instances are equal', () {
        const state1 = HubUpdating();
        const state2 = HubUpdating();
        expect(state1, equals(state2));
      });

      test('HubUpdated instances are equal when complete values match', () {
        const state1 = HubUpdated(true);
        const state2 = HubUpdated(true);
        expect(state1, equals(state2));
      });

      test('HubUpdated instances are not equal when complete values differ',
          () {
        const state1 = HubUpdated(true);
        const state2 = HubUpdated(false);
        expect(state1, isNot(equals(state2)));
      });

      test('different state types are not equal', () {
        const initial = HubInitial();
        const updating = HubUpdating();
        const updated = HubUpdated(true);

        expect(initial, isNot(equals(updating)));
        expect(initial, isNot(equals(updated)));
        expect(updating, isNot(equals(updated)));
      });
    });
  });
}
