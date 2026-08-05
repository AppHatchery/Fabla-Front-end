import 'package:test/test.dart';
import 'package:release_validator/models/schema.dart';
import 'package:release_validator/models/validation.dart';
import 'package:release_validator/services/comparator.dart';

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
      expect(changes.any((c) => c.type == ChangeType.ENTITY_RENAMED && c.entity == 'NewName' && c.oldValue == 'OldName'), isTrue);
    });

    test('Identifies entity UID change', () {
      final oldModel = ObjectBoxModel(
        entities: [
          Entity(uid: 1, name: 'TestEntity', properties: [])
        ],
        retiredEntityUids: [],
      );
      final newModel = ObjectBoxModel(
        entities: [
          Entity(uid: 2, name: 'TestEntity', properties: [])
        ],
        retiredEntityUids: [],
      );

      final changes = comparator.compare(oldModel, newModel);
      expect(changes.any((c) => c.type == ChangeType.ENTITY_UID_CHANGED && c.entity == 'TestEntity' && c.oldValue == '1' && c.newValue == '2'), isTrue);
    });

    test('Identifies deleted entity', () {
      final oldModel = ObjectBoxModel(
        entities: [
          Entity(uid: 1, name: 'DeletedEntity', properties: [])
        ],
        retiredEntityUids: [],
      );
      final newModel = ObjectBoxModel(entities: [], retiredEntityUids: []);

      final changes = comparator.compare(oldModel, newModel);
      expect(changes.any((c) => c.type == ChangeType.ENTITY_DELETED && c.entity == 'DeletedEntity'), isTrue);
    });

    test('Identifies property changes', () {
      final oldModel = ObjectBoxModel(
        entities: [
          Entity(uid: 1, name: 'TestEntity', properties: [
            Property(uid: 10, name: 'OldProp', type: 1),
            Property(uid: 11, name: 'TypeProp', type: 1),
            Property(uid: 12, name: 'FlagProp', type: 1, flags: 0),
            Property(uid: 13, name: 'RelProp', type: 1, relationTarget: 'OldTarget'),
            Property(uid: 14, name: 'DeletedProp', type: 1),
          ])
        ],
        retiredEntityUids: [],
      );
      final newModel = ObjectBoxModel(
        entities: [
          Entity(uid: 1, name: 'TestEntity', properties: [
            Property(uid: 10, name: 'NewProp', type: 1),
            Property(uid: 11, name: 'TypeProp', type: 2),
            Property(uid: 12, name: 'FlagProp', type: 1, flags: 1),
            Property(uid: 13, name: 'RelProp', type: 1, relationTarget: 'NewTarget'),
            Property(uid: 15, name: 'AddedProp', type: 1),
            Property(uid: 16, name: 'UidChangedProp', type: 1), // Actually name match, uid change if we search by name
          ])
        ],
        retiredEntityUids: [],
      );

      // Add a property with same name as DeletedProp but different UID to test PROPERTY_UID_CHANGED
      final newModelWithUidChange = ObjectBoxModel(
        entities: [
          Entity(uid: 1, name: 'TestEntity', properties: [
            Property(uid: 10, name: 'OldProp', type: 1),
            Property(uid: 20, name: 'OldProp', type: 1), // This will trigger PROPERTY_UID_CHANGED if logic allows
          ])
        ],
        retiredEntityUids: [],
      );
      // Wait, let's re-read the logic for property uid change.
      // It tries UID first, then Name.
      
      final changes = comparator.compare(oldModel, newModel);
      
      expect(changes.any((c) => c.type == ChangeType.PROPERTY_RENAMED && c.property == 'NewProp'), isTrue);
      expect(changes.any((c) => c.type == ChangeType.PROPERTY_TYPE_CHANGED && c.property == 'TypeProp'), isTrue);
      expect(changes.any((c) => c.type == ChangeType.PROPERTY_FLAGS_CHANGED && c.property == 'FlagProp'), isTrue);
      expect(changes.any((c) => c.type == ChangeType.RELATIONSHIP_CHANGED && c.property == 'RelProp'), isTrue);
      expect(changes.any((c) => c.type == ChangeType.PROPERTY_ADDED && c.property == 'AddedProp'), isTrue);
      expect(changes.any((c) => c.type == ChangeType.PROPERTY_DELETED && c.property == 'DeletedProp'), isTrue);
    });

    test('Identifies property UID change', () {
      final oldModel = ObjectBoxModel(
        entities: [
          Entity(uid: 1, name: 'TestEntity', properties: [
            Property(uid: 10, name: 'SameName', type: 1),
          ])
        ],
        retiredEntityUids: [],
      );
      final newModel = ObjectBoxModel(
        entities: [
          Entity(uid: 1, name: 'TestEntity', properties: [
            Property(uid: 20, name: 'SameName', type: 1),
          ])
        ],
        retiredEntityUids: [],
      );

      final changes = comparator.compare(oldModel, newModel);
      expect(changes.any((c) => c.type == ChangeType.PROPERTY_UID_CHANGED && c.property == 'SameName' && c.oldValue == '10' && c.newValue == '20'), isTrue);
    });
  });
}
