import 'package:audio_diaries_flutter/core/services/remote_config_service.dart';
import 'package:audio_diaries_flutter/core/usecases/experiment_manager.dart';
import 'package:audio_diaries_flutter/screens/hub/presentation/cubit/hub_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// -----------------------------------------------------------------------------
// Mock classes
// -----------------------------------------------------------------------------
class MockExperimentManager extends Mock implements ExperimentManager {}

class MockRemoteConfigService extends Mock implements RemoteConfigService {}

class MockValueNotifier extends Mock implements ValueNotifier<int> {}

void main() {
  group('HubCubit', () {
    late HubCubit hubCubit;
    late MockExperimentManager mockExperimentManager;
    late MockRemoteConfigService mockRemoteConfigService;
    late ValueNotifier<int> mockVersionCounter;

    setUp(() {
      mockExperimentManager = MockExperimentManager();
      mockRemoteConfigService = MockRemoteConfigService();
      mockVersionCounter = ValueNotifier<int>(0);

      when(() => mockRemoteConfigService.versionUpdateCounter)
          .thenReturn(mockVersionCounter);

      hubCubit = HubCubit(
        experimentManager: mockExperimentManager,
        remoteConfigService: mockRemoteConfigService,
      );
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
          return HubCubit(
            experimentManager: mockExperimentManager,
            remoteConfigService: mockRemoteConfigService,
          );
        },
        act: (cubit) => cubit.update(),
        expect: () => [
          const HubUpdating(),
          const HubUpdated(false),
          const HubInitial(),
        ],
      );

      blocTest<HubCubit, HubState>(
        'emits [HubUpdating, HubUpdated(true), HubInitial] when ExperimentManager.update() returns true',
        build: () {
          when(() => mockExperimentManager.update())
              .thenAnswer((_) async => true);
          return HubCubit(
            experimentManager: mockExperimentManager,
            remoteConfigService: mockRemoteConfigService,
          );
        },
        act: (cubit) => cubit.update(),
        expect: () => [
          const HubUpdating(),
          const HubUpdated(true),
          const HubInitial(),
        ],
      );
    });

    group('refresh', () {
      blocTest<HubCubit, HubState>(
        'emits HubRefreshing when refresh is called',
        build: () => hubCubit,
        act: (cubit) => cubit.refresh(),
        expect: () => [isA<HubRefreshing>()],
      );
    });

    group('remote config listener', () {
      blocTest<HubCubit, HubState>(
        'triggers update when versionUpdateCounter changes',
        build: () {
          when(() => mockExperimentManager.update())
              .thenAnswer((_) async => true);
          return hubCubit;
        },
        act: (cubit) async {
          mockVersionCounter.value++;
          // allow async listener to process
          await Future.delayed(const Duration(milliseconds: 10));
        },
        expect: () => [
          const HubUpdating(),
          const HubUpdated(true),
          const HubInitial(),
        ],
      );
    });

    test('close removes listener from versionUpdateCounter', () async {

      // Assert initial state
      expect(mockVersionCounter.hasListeners, isTrue,
          reason: 'Listener should be present after initialization');

      // Act: Close the cubit
      await hubCubit.close();

      // Assert final state
      expect(mockVersionCounter.hasListeners, isFalse,
          reason: 'Expected listener to be removed on close()');
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

      test('HubUpdated equality depends on complete', () {
        expect(const HubUpdated(true), equals(const HubUpdated(true)));
        expect(const HubUpdated(true), isNot(equals(const HubUpdated(false))));
      });

      test('different state types are not equal', () {
        expect(const HubInitial(), isNot(equals(const HubUpdating())));
        expect(const HubInitial(), isNot(equals(const HubUpdated(true))));
        expect(const HubUpdating(), isNot(equals(const HubUpdated(true))));
      });
    });
  });
}
