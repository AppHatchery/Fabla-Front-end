import 'package:test/test.dart';
import '../lib/models/schema.dart';
import '../lib/models/validation.dart';
import '../lib/services/comparator.dart';

void main() {
  group('SchemaComparator Tests', () {
    late SchemaComparator comparator;

    setUp(() {
      comparator = SchemaComparator();
    });

    test('Identifies new entity', () {
      final oldModel = ObjectBoxModel(entities: [], retiredEntityUids: []);
      final newModel = ObjectBoxModel(
        entities: [
          Entity(uid: 1, name: 'TestEntity', properties: [])
        ],
        retiredEntityUids: [],
      );

      final changes = comparator.compare(oldModel, newModel);
      expect(changes.any((c) => c.type == ChangeType.ENTITY_ADDED && c.entity == 'TestEntity'), isTrue);
    });

    test('Identifies renamed entity', () {
      final oldModel = ObjectBoxModel(
        entities: [
          Entity(uid: 1, name: 'OldName', properties: [])
        ],
        retiredEntityUids: [],
      );
      final newModel = ObjectBoxModel(
        entities: [
          Entity(uid: 1, name: 'NewName', properties: [])
        ],
        retiredEntityUids: [],
      );

      final changes = comparator.compare(oldModel, newModel);
      expect(changes.any((c) => c.type == ChangeType.ENTITY_RENAMED && c.entity == 'NewName'), isTrue);
    });
  });
}
