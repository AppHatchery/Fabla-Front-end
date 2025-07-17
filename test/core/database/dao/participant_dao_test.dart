import 'package:audio_diaries_flutter/core/database/dao/participant_dao.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/participant.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:objectbox/objectbox.dart';

import '../../../dummy_data.dart';

void main() {
  // The DAO under test and its dependencies
  late ParticipantDAO participantDAO;
  late MockParticipantBox mockBox;
  late MockParticipantQueryBuilder mockQueryBuilder;
  late MockParticipantQuery mockQuery;

  setUp(() {
    mockBox = MockParticipantBox();
    mockQueryBuilder = MockParticipantQueryBuilder();
    mockQuery = MockParticipantQuery();
    participantDAO = ParticipantDAO(box: mockBox);
    registerFallbackValue(createTestParticipant());
  });

  group('ParticipantDAO', () {
    test('get returns the first participant from the database', () {
      // ───── Arrange ─────
      final expectedParticipant = createTestParticipant();
      when(() => mockBox.query()).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.build()).thenReturn(mockQuery);
      when(() => mockQuery.findFirst()).thenReturn(expectedParticipant);

      // ───── Act ─────
      final result = participantDAO.get();

      // ───── Assert ─────
      expect(result, expectedParticipant);
      verify(() => mockBox.query()).called(1);
      verify(() => mockQueryBuilder.build()).called(1);
      verify(() => mockQuery.findFirst()).called(1);
    });

    test('get returns null when no participant exists', () {
      // ───── Arrange ─────
      when(() => mockBox.query()).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.build()).thenReturn(mockQuery);
      when(() => mockQuery.findFirst()).thenReturn(null);

      // ───── Act ─────
      final result = participantDAO.get();

      // ───── Assert ─────
      expect(result, null);
      verify(() => mockBox.query()).called(1);
      verify(() => mockQueryBuilder.build()).called(1);
      verify(() => mockQuery.findFirst()).called(1);
    });

    test('add removes existing participants and adds a new one', () {
      // ───── Arrange ─────
      final participant = createTestParticipant();
      when(() => mockBox.removeAll()).thenReturn(0);
      when(() => mockBox.put(any())).thenReturn(participant.id);

      // ───── Act ─────
      participantDAO.add(participant);

      // ───── Assert ─────
      verify(() => mockBox.removeAll()).called(1);
      verify(() => mockBox.put(participant)).called(1);
    });

    test('update modifies existing participant name', () {
      // ───── Arrange ─────
      final existingParticipant = createTestParticipant();
      final newName = 'Updated Name';

      when(() => mockBox.query()).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.build()).thenReturn(mockQuery);
      when(() => mockQuery.findFirst()).thenReturn(existingParticipant);
      when(() => mockBox.put(any())).thenReturn(existingParticipant.id);

      // ───── Act ─────
      participantDAO.update(newName);

      // ───── Assert ─────
      verify(() => mockBox.query()).called(1);
      verify(() => mockQueryBuilder.build()).called(1);
      verify(() => mockQuery.findFirst()).called(1);
      verify(() => mockBox.put(any())).called(1);
    });

    test('update does nothing when no participant exists', () {
      // ───── Arrange ─────
      when(() => mockBox.query()).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.build()).thenReturn(mockQuery);
      when(() => mockQuery.findFirst()).thenReturn(null);

      // ───── Act ─────
      participantDAO.update('New Name');

      // ───── Assert ─────
      verify(() => mockBox.query()).called(1);
      verify(() => mockQueryBuilder.build()).called(1);
      verify(() => mockQuery.findFirst()).called(1);
      verifyNever(() => mockBox.put(any()));
    });

    test('remove deletes all participants', () {
      // ───── Arrange ─────
      when(() => mockBox.removeAll()).thenReturn(1);

      // ───── Act ─────
      participantDAO.remove();

      // ───── Assert ─────
      verify(() => mockBox.removeAll()).called(1);
    });
  });
}

// -----------------------------------------------------------------------------
// Mock classes for ObjectBox components
// -----------------------------------------------------------------------------

class MockParticipantBox extends Mock implements Box<Participant> {}

class MockParticipantQueryBuilder extends Mock
    implements QueryBuilder<Participant> {}

class MockParticipantQuery extends Mock implements Query<Participant> {}
