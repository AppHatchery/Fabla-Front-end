import 'package:audio_diaries_flutter/core/database/dao/experiment_dao.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/experiment.dart';
import 'package:mocktail/mocktail.dart';
import 'package:objectbox/objectbox.dart';

import '../../../dummy_data.dart';

void main() {
  // The DAO under test and its dependencies. These are re-initialized in `setUp`.
  late ExperimentDAO experimentDAO;
  late MockExperimentBox mockBox;

  // Runs **before each** individual test to ensure isolation.
  setUp(() {
    mockBox = MockExperimentBox();
    experimentDAO = ExperimentDAO(box: mockBox);
    registerFallbackValue(createTestExperiment());
  });

  group('ExperimentDAO', () {
    test('getExperiment retrieves the first experiment from the database', () {
      // ───── Arrange ─────
      final expectedExperiment = createTestExperiment();
      when(() => mockBox.getAll()).thenReturn([expectedExperiment]);

      // ───── Act ─────
      final result = experimentDAO.getExperiment();

      // ───── Assert ─────
      expect(result, expectedExperiment);
      verify(() => mockBox.getAll()).called(1);
    });

    test('addExperiment persists a new experiment via box.put', () {
      // ───── Arrange ─────
      final experiment = createTestExperiment(id: 2, name: 'New Experiment');
      when(() => mockBox.put(any())).thenReturn(experiment.id);

      // ───── Act ─────
      experimentDAO.addExperiment(experiment);

      // ───── Assert ─────
      verify(() => mockBox.put(experiment)).called(1);
    });

    test('replaceExperiment deletes all experiments and adds a new one', () {
      // ───── Arrange ─────
      final experiment =
          createTestExperiment(id: 3, name: 'Replaced Experiment');
      when(() => mockBox.removeAll()).thenReturn(0);
      when(() => mockBox.put(any())).thenReturn(experiment.id);

      // ───── Act ─────
      experimentDAO.replaceExperiment(experiment);

      // ───── Assert ─────
      verify(() => mockBox.removeAll()).called(1);
      verify(() => mockBox.put(experiment)).called(1);
    });

    group('updateOwnerEmail', () {
      test('changes only the owner email and keeps the same id', () {
        final stored = createTestExperiment(
          id: 7,
          name: 'Keep Me',
          login: 'ABC123',
          version: '3',
          ownerEmail: 'old@test.com',
        );
        when(() => mockBox.getAll()).thenReturn([stored]);
        when(() => mockBox.put(any())).thenReturn(stored.id);

        final wrote = experimentDAO.updateOwnerEmail('ABC123', 'new@test.com');

        expect(wrote, isTrue);
        final captured = verify(() => mockBox.put(captureAny())).captured.single
            as Experiment;
        expect(captured.id, 7);
        expect(captured.ownerEmail, 'new@test.com');
        expect(captured.name, 'Keep Me');
        expect(captured.version, '3');
        verifyNever(() => mockBox.removeAll());
      });

      test('matches the login case-insensitively', () {
        final stored = createTestExperiment(login: 'ABC123');
        when(() => mockBox.getAll()).thenReturn([stored]);
        when(() => mockBox.put(any())).thenReturn(stored.id);

        expect(
            experimentDAO.updateOwnerEmail('abc123', 'new@test.com'), isTrue);
      });

      test('does not write onto a different study than the one requested', () {
        final stored = createTestExperiment(
            login: 'NEW_STUDY', ownerEmail: 'keep@test.com');
        when(() => mockBox.getAll()).thenReturn([stored]);

        final wrote =
            experimentDAO.updateOwnerEmail('OLD_STUDY', 'new@test.com');

        expect(wrote, isFalse);
        expect(stored.ownerEmail, 'keep@test.com');
        verifyNever(() => mockBox.put(any()));
      });

      test('does nothing when no experiment is stored', () {
        when(() => mockBox.getAll()).thenReturn([]);

        expect(
            experimentDAO.updateOwnerEmail('ABC123', 'new@test.com'), isFalse);
        verifyNever(() => mockBox.put(any()));
      });
    });

    test('deleteExperiment removes all experiments from the database', () {
      // ───── Arrange ─────
      when(() => mockBox.removeAll()).thenReturn(0);

      // ───── Act ─────
      experimentDAO.deleteExperiment();

      // ───── Assert ─────
      verify(() => mockBox.removeAll()).called(1);
    });
  });
}

// -----------------------------------------------------------------------------
// Mock classes for ObjectBox components used in ExperimentDAO
// -----------------------------------------------------------------------------

class MockExperimentBox extends Mock implements Box<Experiment> {}
