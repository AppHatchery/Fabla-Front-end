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

    test('Identifies property type change', () {
      final oldModel = ObjectBoxModel(
        entities: [
          Entity(uid: 1, name: 'TestEntity', properties: [
            Property(uid: 1, name: 'prop', type: 6)
          ])
        ],
        retiredEntityUids: [],
      );
      final newModel = ObjectBoxModel(
        entities: [
          Entity(uid: 1, name: 'TestEntity', properties: [
            Property(uid: 1, name: 'prop', type: 9)
          ])
        ],
        retiredEntityUids: [],
      );

      final changes = comparator.compare(oldModel, newModel);
      expect(changes.any((c) => c.type == ChangeType.PROPERTY_TYPE_CHANGED && c.property == 'prop'), isTrue);
    });

    test('Identifies property flags change', () {
      final oldModel = ObjectBoxModel(
        entities: [
          Entity(uid: 1, name: 'TestEntity', properties: [
            Property(uid: 1, name: 'prop', type: 6, flags: 0)
          ])
        ],
        retiredEntityUids: [],
      );
      final newModel = ObjectBoxModel(
        entities: [
          Entity(uid: 1, name: 'TestEntity', properties: [
            Property(uid: 1, name: 'prop', type: 6, flags: 1)
          ])
        ],
        retiredEntityUids: [],
      );

      final changes = comparator.compare(oldModel, newModel);
      expect(changes.any((c) => c.type == ChangeType.PROPERTY_FLAGS_CHANGED && c.property == 'prop'), isTrue);
    });

    test('Order independence: same content, different order', () {
      final oldModel = ObjectBoxModel(
        entities: [
          Entity(uid: 1, name: 'E1', properties: [
            Property(uid: 1, name: 'P1', type: 6),
            Property(uid: 2, name: 'P2', type: 6),
          ]),
          Entity(uid: 2, name: 'E2', properties: []),
        ],
        retiredEntityUids: [],
      );
      final newModel = ObjectBoxModel(
        entities: [
          Entity(uid: 2, name: 'E2', properties: []),
          Entity(uid: 1, name: 'E1', properties: [
            Property(uid: 2, name: 'P2', type: 6),
            Property(uid: 1, name: 'P1', type: 6),
          ]),
        ],
        retiredEntityUids: [],
      );

      final changes = comparator.compare(oldModel, newModel);
      expect(changes, isEmpty);
    });
  });
}
