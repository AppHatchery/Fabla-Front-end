// AnswerDAO Unit Test
// -----------------------------------------------------------------------------
// This file contains a complete, self-contained unit test suite for the
// `AnswerDAO` class.  The aim is to validate that the DAO correctly issues
// the expected ObjectBox calls for each CRUD operation *without* ever touching
// a real database.  To achieve this we:
//   • Use `mocktail` to create mocks for the ObjectBox `Box`, `QueryBuilder`,
//     and `Query` classes.
//   • Inject those mocks into the DAO under test.
//   • Exercise each public method and assert that the right ObjectBox APIs are
//     invoked with the right arguments.
//
// The Arrange–Act–Assert pattern is followed inside every test so that each
// section's intent is crystal-clear.
// -----------------------------------------------------------------------------

import 'package:audio_diaries_flutter/core/database/dao/answer_dao.dart';

// We alias the generated `Answer` entity to `entity.Answer` to distinguish it
// from the unrelated `Answer` typedef re-exported by `mocktail`.  The `hide`
// keyword ensures that only the ObjectBox entity is visible below.
import 'package:audio_diaries_flutter/screens/diary/domain/entities/answer.dart'
    as entity;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart' hide Answer;
import 'package:objectbox/objectbox.dart';

void main() {
  // The DAO under test and all of its dependencies.  They are re-initialised
  // in `setUp` so each individual test starts from a clean state.
  late AnswerDAO answerDAO;
  late MockAnswerBox mockBox;
  late MockAnswerQueryBuilder mockQueryBuilder;
  late MockAnswerQuery mockQuery;

  // Runs **once** before the entire test suite.
  setUpAll(() {
    // Here we could register global fallback values for `mocktail` if needed
    // (e.g. when a stub expects a complex generic parameter).  For this
    // particular DAO no such configuration is necessary, so the callback
    // remains intentionally empty.
  });

  // Runs **before each** individual test.  This guarantees isolation: a failing
  // test cannot influence another one because every test gets a fresh set of
  // mocks and a brand-new DAO instance.
  setUp(() {
    mockBox = MockAnswerBox();
    mockQueryBuilder = MockAnswerQueryBuilder();
    mockQuery = MockAnswerQuery();

    // Inject the mocked `Box` into the DAO so that all database touches are
    // captured by `mocktail`.
    answerDAO = AnswerDAO(box: mockBox);
  });

  group('AnswerDAO', () {
    test('getAnswers returns the list of answers retrieved via ObjectBox', () {
      // ───── Arrange ─────
      // Stub the entire query chain `box.query() -> build() -> find()` so that
      // it ultimately yields a predefined list of entities.
      final expectedAnswers = [entity.Answer(id: 1, date: DateTime.now())];

      when(() => mockBox.query()).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.build()).thenReturn(mockQuery);
      when(() => mockQuery.find()).thenReturn(expectedAnswers);

      // ───── Act ─────
      final result = answerDAO.getAnswers(1);

      // ───── Assert ─────
      // 1. The DAO returns exactly what the (mocked) database returned.
      // 2. Every intermediate ObjectBox call we expected actually happened.
      expect(result, expectedAnswers);
      verify(() => mockBox.query()).called(1);
      verify(() => mockQueryBuilder.build()).called(1);
      verify(() => mockQuery.find()).called(1);
    });

    test('addResponse persists a new answer via box.put', () {
      // Arrange:  A brand-new answer + a stubbed return value for `put()`.
      final answer = entity.Answer(id: 2, date: DateTime.now());
      when(() => mockBox.put(answer)).thenReturn(answer.id);

      // Act: Call the method under test.
      answerDAO.addResponse(answer);

      // Assert: Ensure the DAO delegated directly to `box.put()`.
      verify(() => mockBox.put(answer)).called(1);
    });

    test('updateResponse overwrites an existing answer via box.put', () {
      // Arrange
      final answer = entity.Answer(id: 3, date: DateTime.now());
      when(() => mockBox.put(answer)).thenReturn(answer.id);

      // Act
      answerDAO.updateResponse(answer);

      // Assert
      verify(() => mockBox.put(answer)).called(1);
    });

    test('removeResponse deletes a single answer via box.remove', () {
      // Arrange
      const id = 4;
      when(() => mockBox.remove(id)).thenReturn(true);

      // Act
      answerDAO.removeResponse(id);

      // Assert
      verify(() => mockBox.remove(id)).called(1);
    });

    test('removeAll wipes the entire box via box.removeAll', () {
      // Arrange
      when(() => mockBox.removeAll()).thenReturn(0);

      // Act
      answerDAO.removeAll();

      // Assert
      verify(() => mockBox.removeAll()).called(1);
    });
  });
}

// -----------------------------------------------------------------------------
// Mock classes for ObjectBox components used in AnswerDAO
// -----------------------------------------------------------------------------

// Each mock class is a lightweight shell generated at runtime by `mocktail`.
// They allow us to intercept and stub method calls that would otherwise hit
// the database.

class MockAnswerBox extends Mock implements Box<entity.Answer> {}

class MockAnswerQueryBuilder extends Mock
    implements QueryBuilder<entity.Answer> {}

class MockAnswerQuery extends Mock implements Query<entity.Answer> {}
