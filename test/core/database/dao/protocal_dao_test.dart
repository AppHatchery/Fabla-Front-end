import 'package:audio_diaries_flutter/core/database/dao/protocal_dao.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/protocol_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:objectbox/objectbox.dart';

void main() {
  // The DAO under test and its dependencies
  late ProtocolDAO protocolDAO;
  late MockProtocolBox mockBox;

  // Helper function to create a test protocol
  ProtocolEntity createTestProtocol({
    int id = 1,
    int version = 1,
    int weeklyGoal = 5,
    int dailyGoal = 1,
    List<String> diaryBlueprints = const ['blueprint1', 'blueprint2'],
  }) {
    return ProtocolEntity(
      id: id,
      version: version,
      weeklyGoal: weeklyGoal,
      dailyGoal: dailyGoal,
      diaryBlueprints: diaryBlueprints,
    );
  }

  setUp(() {
    mockBox = MockProtocolBox();
    protocolDAO = ProtocolDAO(box: mockBox);
    registerFallbackValue(createTestProtocol());
  });

  group('ProtocolDAO', () {
    test('getProtocol returns first protocol when box is not empty', () {
      // ───── Arrange ─────
      final expectedProtocol = createTestProtocol();
      when(() => mockBox.isEmpty()).thenReturn(false);
      when(() => mockBox.getAll()).thenReturn([expectedProtocol]);

      // ───── Act ─────
      final result = protocolDAO.getProtocol();

      // ───── Assert ─────
      expect(result?.id, expectedProtocol.id);
      expect(result?.version, expectedProtocol.version);
      expect(result?.weeklyGoal, expectedProtocol.weeklyGoal);
      expect(result?.dailyGoal, expectedProtocol.dailyGoal);
      expect(result?.diaryBlueprints, expectedProtocol.diaryBlueprints);

      verify(() => mockBox.isEmpty()).called(1);
      verify(() => mockBox.getAll()).called(1);
    });

    test('getProtocol returns null when box is empty', () {
      // ───── Arrange ─────
      when(() => mockBox.isEmpty()).thenReturn(true);

      // ───── Act ─────
      final result = protocolDAO.getProtocol();

      // ───── Assert ─────
      expect(result, null);
      verify(() => mockBox.isEmpty()).called(1);
      verifyNever(() => mockBox.getAll());
    });

    test('addProtocol stores protocol in the database', () {
      // ───── Arrange ─────
      final protocol = createTestProtocol();
      when(() => mockBox.put(any())).thenReturn(protocol.id);

      // ───── Act ─────
      protocolDAO.addProtocol(protocol);

      // ───── Assert ─────
      verify(() => mockBox.put(protocol)).called(1);
    });

    test('deleteProtocol removes all protocols from the database', () {
      // ───── Arrange ─────
      when(() => mockBox.removeAll()).thenReturn(1);

      // ───── Act ─────
      protocolDAO.deleteProtocol();

      // ───── Assert ─────
      verify(() => mockBox.removeAll()).called(1);
    });
  });
}

// -----------------------------------------------------------------------------
// Mock classes for ObjectBox components
// -----------------------------------------------------------------------------

class MockProtocolBox extends Mock implements Box<ProtocolEntity> {}
