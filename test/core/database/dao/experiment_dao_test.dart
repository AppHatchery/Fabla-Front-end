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

    group('updateExperiment', () {
      test('overwrites the stored experiment but keeps its id', () {
        final stored = createTestExperiment(id: 7, login: 'ABC123');
        final updated = createTestExperiment(
          id: 0,
          login: 'ABC123',
          name: 'Renamed',
          ownerEmail: 'new@test.com',
          version: '9',
        );
        when(() => mockBox.getAll()).thenReturn([stored]);
        when(() => mockBox.put(any())).thenReturn(7);

        final wrote = experimentDAO.updateExperiment('ABC123', updated);

        expect(wrote, isTrue);
        final captured = verify(() => mockBox.put(captureAny())).captured.single
            as Experiment;
        expect(captured.id, 7);
        expect(captured.name, 'Renamed');
        expect(captured.ownerEmail, 'new@test.com');
        expect(captured.version, '9');
        verifyNever(() => mockBox.removeAll());
      });

      test('matches the login case-insensitively', () {
        when(() => mockBox.getAll())
            .thenReturn([createTestExperiment(login: 'ABC123')]);
        when(() => mockBox.put(any())).thenReturn(1);

        expect(
            experimentDAO.updateExperiment(
                'abc123', createTestExperiment(login: 'ABC123')),
            isTrue);
      });

      test('does not write onto a different study than the one requested', () {
        when(() => mockBox.getAll())
            .thenReturn([createTestExperiment(login: 'NEW_STUDY')]);

        final wrote = experimentDAO.updateExperiment(
            'OLD_STUDY', createTestExperiment(login: 'OLD_STUDY'));

        expect(wrote, isFalse);
        verifyNever(() => mockBox.put(any()));
      });

      test('does nothing when no experiment is stored', () {
        when(() => mockBox.getAll()).thenReturn([]);

        expect(experimentDAO.updateExperiment('ABC123', createTestExperiment()),
            isFalse);
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
