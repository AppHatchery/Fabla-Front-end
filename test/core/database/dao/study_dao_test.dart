import 'package:audio_diaries_flutter/core/database/dao/study_dao.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/study.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:objectbox/objectbox.dart';

void main() {
  // The DAO under test and its dependencies
  late StudyDAO studyDAO;
  late MockStudyBox mockBox;

  // Helper function to create a test study
  Study createTestStudy({
    int id = 1,
    int studyId = 101,
    String name = 'Test Study',
    String experimentCode = 'TEST001',
    String goals = '{"goal1": "Test Goal 1", "goal2": "Test Goal 2"}',
    String incentive = '{"amount": 100, "currency": "USD"}',
  }) {
    return Study(
      id: id,
      studyId: studyId,
      name: name,
      experimentCode: experimentCode,
      goals: goals,
      incentive: incentive,
    );
  }

  setUp(() {
    mockBox = MockStudyBox();
    studyDAO = StudyDAO(box: mockBox);
    registerFallbackValue(createTestStudy());
  });

  group('StudyDAO', () {
    test('getStudy returns study with specified studyId', () {
      // ───── Arrange ─────
      final expectedStudy = createTestStudy(studyId: 101);
      final allStudies = [
        createTestStudy(studyId: 101),
        createTestStudy(studyId: 102),
      ];
      when(() => mockBox.getAll()).thenReturn(allStudies);

      // ───── Act ─────
      final result = studyDAO.getStudy(101);

      // ───── Assert ─────
      expect(result?.id, expectedStudy.id);
      expect(result?.studyId, expectedStudy.studyId);
      expect(result?.name, expectedStudy.name);
      expect(result?.experimentCode, expectedStudy.experimentCode);
      expect(result?.goals, expectedStudy.goals);
      expect(result?.incentive, expectedStudy.incentive);

      verify(() => mockBox.getAll()).called(1);
    });

    test('getStudy returns null when study not found', () {
      // ───── Arrange ─────
      final allStudies = [
        createTestStudy(studyId: 101),
        createTestStudy(studyId: 102),
      ];
      when(() => mockBox.getAll()).thenReturn(allStudies);

      // ───── Act ─────
      final result = studyDAO.getStudy(999);

      // ───── Assert ─────
      expect(result, null);
      verify(() => mockBox.getAll()).called(1);
    });

    test('getStudies returns empty list', () {
      // ───── Arrange ─────
      final allStudies = [
        createTestStudy(studyId: 101),
        createTestStudy(studyId: 102),
      ];
      when(() => mockBox.getAll()).thenReturn(allStudies);

      // ───── Act ─────
      final result = studyDAO.getStudies();

      // ───── Assert ─────
      expect(result, isEmpty);
      verify(() => mockBox.getAll()).called(1);
    });

    test('getAllStudies returns all studies', () {
      // ───── Arrange ─────
      final expectedStudies = [
        createTestStudy(studyId: 101),
        createTestStudy(studyId: 102),
      ];
      when(() => mockBox.getAll()).thenReturn(expectedStudies);

      // ───── Act ─────
      final result = studyDAO.getAllStudies();

      // ───── Assert ─────
      expect(result.length, expectedStudies.length);
      for (var i = 0; i < result.length; i++) {
        expect(result[i].id, expectedStudies[i].id);
        expect(result[i].studyId, expectedStudies[i].studyId);
        expect(result[i].name, expectedStudies[i].name);
        expect(result[i].experimentCode, expectedStudies[i].experimentCode);
      }

      verify(() => mockBox.getAll()).called(1);
    });

    test('addStudy successfully adds a study', () {
      // ───── Arrange ─────
      final study = createTestStudy();
      when(() => mockBox.put(any())).thenReturn(study.id);

      // ───── Act ─────
      final result = studyDAO.addStudy(study);

      // ───── Assert ─────
      expect(result, study.id);
      verify(() => mockBox.put(study)).called(1);
    });

    test('addStudy returns null on error', () {
      // ───── Arrange ─────
      final study = createTestStudy();
      when(() => mockBox.put(any())).thenThrow(Exception('Database error'));

      // ───── Act ─────
      final result = studyDAO.addStudy(study);

      // ───── Assert ─────
      expect(result, null);
      verify(() => mockBox.put(study)).called(1);
    });

    test('addStudies successfully adds multiple studies', () {
      // ───── Arrange ─────
      final studies = [
        createTestStudy(id: 1, studyId: 101),
        createTestStudy(id: 2, studyId: 102),
      ];
      final expectedIds = [1, 2];
      when(() => mockBox.putMany(any())).thenReturn(expectedIds);

      // ───── Act ─────
      final result = studyDAO.addStudies(studies);

      // ───── Assert ─────
      expect(result, expectedIds);
      verify(() => mockBox.putMany(studies)).called(1);
    });

    test('deleteStudy successfully deletes a study', () {
      // ───── Arrange ─────
      final studyId = 1;
      when(() => mockBox.remove(studyId)).thenReturn(true);

      // ───── Act ─────
      final result = studyDAO.deleteStudy(studyId);

      // ───── Assert ─────
      expect(result, true);
      verify(() => mockBox.remove(studyId)).called(1);
    });

    test('deleteStudy returns false on error', () {
      // ───── Arrange ─────
      final studyId = 1;
      when(() => mockBox.remove(studyId))
          .thenThrow(Exception('Database error'));

      // ───── Act ─────
      final result = studyDAO.deleteStudy(studyId);

      // ───── Assert ─────
      expect(result, false);
      verify(() => mockBox.remove(studyId)).called(1);
    });

    test('deleteAllStudies successfully deletes all studies', () {
      // ───── Arrange ─────
      when(() => mockBox.removeAll()).thenReturn(2);

      // ───── Act ─────
      final result = studyDAO.deleteAllStudies();

      // ───── Assert ─────
      expect(result, true);
      verify(() => mockBox.removeAll()).called(1);
    });

    test('deleteAllStudies returns false on error', () {
      // ───── Arrange ─────
      when(() => mockBox.removeAll()).thenThrow(Exception('Database error'));

      // ───── Act ─────
      final result = studyDAO.deleteAllStudies();

      // ───── Assert ─────
      expect(result, false);
      verify(() => mockBox.removeAll()).called(1);
    });
  });
}

// -----------------------------------------------------------------------------
// Mock classes for ObjectBox components
// -----------------------------------------------------------------------------

class MockStudyBox extends Mock implements Box<Study> {}
