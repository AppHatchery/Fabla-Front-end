import 'package:audio_diaries_flutter/core/database/dao/prompt_dao.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/prompt_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:objectbox/objectbox.dart';

import '../../../dummy_data.dart';

void main() {
  // The DAO under test and its dependencies
  late PromptDAO promptDAO;
  late MockPromptBox mockBox;
  late MockPromptQueryBuilder mockQueryBuilder;
  late MockPromptQuery mockQuery;

  setUp(() {
    mockBox = MockPromptBox();
    mockQueryBuilder = MockPromptQueryBuilder();
    mockQuery = MockPromptQuery();
    promptDAO = PromptDAO(box: mockBox);
    registerFallbackValue(createTestPrompt());
  });

  group('PromptDAO', () {
    test('getPrompt returns prompt with specified ID', () {
      // ───── Arrange ─────
      final expectedPrompt = createTestPrompt(id: 1);
      final allPrompts = [createTestPrompt(id: 1), createTestPrompt(id: 2)];

      when(() => mockBox.query()).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.build()).thenReturn(mockQuery);
      when(() => mockQuery.find()).thenReturn(allPrompts);

      // ───── Act ─────
      final result = promptDAO.getPrompt(1);

      // ───── Assert ─────
      expect(result.id, expectedPrompt.id);
      expect(result.questionNumber, expectedPrompt.questionNumber);
      expect(result.question, expectedPrompt.question);
      expect(result.responseType, expectedPrompt.responseType);
      expect(result.option, expectedPrompt.option);
      expect(result.subtitle, expectedPrompt.subtitle);
      expect(result.required, expectedPrompt.required);
      expect(result.multipleAnswer, expectedPrompt.multipleAnswer);
      expect(result.diary.target?.id, expectedPrompt.diary.target?.id);

      verify(() => mockBox.query()).called(1);
      verify(() => mockQueryBuilder.build()).called(1);
      verify(() => mockQuery.find()).called(1);
    });

    test('getPrompts returns prompts for specific diary ID', () {
      // ───── Arrange ─────
      final diaryId = 1;
      final expectedPrompts = [
        createTestPrompt(id: 1, diaryId: diaryId),
        createTestPrompt(id: 2, diaryId: diaryId),
      ];
      final allPrompts = [
        ...expectedPrompts,
        createTestPrompt(id: 3, diaryId: 2),
      ];

      when(() => mockBox.query()).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.build()).thenReturn(mockQuery);
      when(() => mockQuery.find()).thenReturn(allPrompts);

      // ───── Act ─────
      final result = promptDAO.getPrompts(id: diaryId);

      // ───── Assert ─────
      expect(result.length, expectedPrompts.length);
      for (var i = 0; i < result.length; i++) {
        expect(result[i].id, expectedPrompts[i].id);
        expect(result[i].diary.target?.id, expectedPrompts[i].diary.target?.id);
      }

      verify(() => mockBox.query()).called(1);
      verify(() => mockQueryBuilder.build()).called(1);
      verify(() => mockQuery.find()).called(1);
    });

    test('getAllPrompts returns all prompts', () {
      // ───── Arrange ─────
      final expectedPrompts = [
        createTestPrompt(id: 1),
        createTestPrompt(id: 2),
      ];
      when(() => mockBox.getAll()).thenReturn(expectedPrompts);

      // ───── Act ─────
      final result = promptDAO.getAllPrompts();

      // ───── Assert ─────
      expect(result.length, expectedPrompts.length);
      for (var i = 0; i < result.length; i++) {
        expect(result[i].id, expectedPrompts[i].id);
        expect(result[i].questionNumber, expectedPrompts[i].questionNumber);
        expect(result[i].question, expectedPrompts[i].question);
      }

      verify(() => mockBox.getAll()).called(1);
    });

    test('updatePrompt updates existing prompt', () {
      // ───── Arrange ─────
      final prompt = createTestPrompt();
      when(() => mockBox.put(any())).thenReturn(prompt.id);

      // ───── Act ─────
      promptDAO.updatePrompt(prompt);

      // ───── Assert ─────
      verify(() => mockBox.put(prompt)).called(1);
    });

    test('remove deletes prompt by ID', () {
      // ───── Arrange ─────
      final promptId = 1;
      when(() => mockBox.remove(promptId)).thenReturn(true);

      // ───── Act ─────
      promptDAO.remove(promptId);

      // ───── Assert ─────
      verify(() => mockBox.remove(promptId)).called(1);
    });

    test('removeAllPrompts deletes all prompts', () {
      // ───── Arrange ─────
      when(() => mockBox.removeAll()).thenReturn(2);

      // ───── Act ─────
      promptDAO.removeAllPrompts();

      // ───── Assert ─────
      verify(() => mockBox.removeAll()).called(1);
    });
  });
}

// -----------------------------------------------------------------------------
// Mock classes for ObjectBox components
// -----------------------------------------------------------------------------

class MockPromptBox extends Mock implements Box<Prompt> {}

class MockPromptQueryBuilder extends Mock implements QueryBuilder<Prompt> {}

class MockPromptQuery extends Mock implements Query<Prompt> {}
