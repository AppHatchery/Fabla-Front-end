import 'package:audio_diaries_flutter/core/database/dao/questions_dao.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/questions_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:objectbox/objectbox.dart';

void main() {
  // The DAO under test and its dependencies
  late QuestionsDAO questionsDAO;
  late MockQuestionsBox mockBox;
  late MockQuestionsQueryBuilder mockQueryBuilder;
  late MockQuestionsQuery mockQuery;

  // Helper function to create a test question
  QuestionsEntity createTestQuestion({
    int id = 1,
    String title = 'Test Question',
    String? subtitle = 'Test Subtitle',
    String? options,
    String type = 'text',
    int? min,
    int? max,
    int? defaultValue,
    String? minLabel,
    String? maxLabel,
    String variable = 'test_variable',
    String? answer,
  }) {
    return QuestionsEntity(
      id: id,
      title: title,
      subtitle: subtitle,
      options: options,
      type: type,
      min: min,
      max: max,
      defaultValue: defaultValue,
      minLabel: minLabel,
      maxLabel: maxLabel,
      variable: variable,
      answer: answer,
    );
  }

  setUp(() {
    mockBox = MockQuestionsBox();
    mockQueryBuilder = MockQuestionsQueryBuilder();
    mockQuery = MockQuestionsQuery();
    questionsDAO = QuestionsDAO(box: mockBox);
    registerFallbackValue(createTestQuestion());
  });

  group('QuestionsDAO', () {
    test('getQuestion returns question with specified ID', () {
      // ───── Arrange ─────
      final expectedQuestion = createTestQuestion(id: 1);
      final allQuestions = [
        createTestQuestion(id: 1),
        createTestQuestion(id: 2),
      ];

      when(() => mockBox.query()).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.build()).thenReturn(mockQuery);
      when(() => mockQuery.find()).thenReturn(allQuestions);

      // ───── Act ─────
      final result = questionsDAO.getQuestion(1);

      // ───── Assert ─────
      expect(result.id, expectedQuestion.id);
      expect(result.title, expectedQuestion.title);
      expect(result.subtitle, expectedQuestion.subtitle);
      expect(result.type, expectedQuestion.type);
      expect(result.variable, expectedQuestion.variable);

      verify(() => mockBox.query()).called(1);
      verify(() => mockQueryBuilder.build()).called(1);
      verify(() => mockQuery.find()).called(1);
    });

    test('getAllQuestions returns all questions', () {
      // ───── Arrange ─────
      final expectedQuestions = [
        createTestQuestion(id: 1),
        createTestQuestion(id: 2),
      ];
      when(() => mockBox.getAll()).thenReturn(expectedQuestions);

      // ───── Act ─────
      final result = questionsDAO.getAllQuestions();

      // ───── Assert ─────
      expect(result.length, expectedQuestions.length);
      for (var i = 0; i < result.length; i++) {
        expect(result[i].id, expectedQuestions[i].id);
        expect(result[i].title, expectedQuestions[i].title);
        expect(result[i].type, expectedQuestions[i].type);
        expect(result[i].variable, expectedQuestions[i].variable);
      }

      verify(() => mockBox.getAll()).called(1);
    });

    test('updateQuestion updates existing question', () {
      // ───── Arrange ─────
      final question = createTestQuestion();
      when(() => mockBox.put(any())).thenReturn(question.id);

      // ───── Act ─────
      final result = questionsDAO.updateQuestion(question);

      // ───── Assert ─────
      expect(result, question.id);
      verify(() => mockBox.put(question)).called(1);
    });

    test('addManyQuestions stores multiple questions', () {
      // ───── Arrange ─────
      final questions = [
        createTestQuestion(id: 1),
        createTestQuestion(id: 2),
      ];
      final expectedIds = [1, 2];
      when(() => mockBox.putMany(any())).thenReturn(expectedIds);

      // ───── Act ─────
      final result = questionsDAO.addManyQuestions(questions);

      // ───── Assert ─────
      expect(result, expectedIds);
      verify(() => mockBox.putMany(questions)).called(1);
    });

    test('removeAllQuestions deletes all questions', () {
      // ───── Arrange ─────
      when(() => mockBox.removeAll()).thenReturn(2);

      // ───── Act ─────
      final result = questionsDAO.removeAllQuestions();

      // ───── Assert ─────
      expect(result, 2);
      verify(() => mockBox.removeAll()).called(1);
    });
  });
}

// -----------------------------------------------------------------------------
// Mock classes for ObjectBox components
// -----------------------------------------------------------------------------

class MockQuestionsBox extends Mock implements Box<QuestionsEntity> {}

class MockQuestionsQueryBuilder extends Mock
    implements QueryBuilder<QuestionsEntity> {}

class MockQuestionsQuery extends Mock implements Query<QuestionsEntity> {}
