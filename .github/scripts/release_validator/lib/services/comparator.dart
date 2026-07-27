import '../models/schema.dart';
import '../models/validation.dart';

class SchemaComparator {
  List<SchemaChange> compare(ObjectBoxModel oldModel, ObjectBoxModel newModel) {
    final changes = <SchemaChange>[];

    // 1. Check for New/Renamed Entities
    for (var newEntity in newModel.entities) {
      final oldEntity = oldModel.findEntityByUid(newEntity.uid);

      if (oldEntity == null) {
        changes.add(SchemaChange(type: ChangeType.ENTITY_ADDED, entity: newEntity.name, uid: newEntity.uid));
        // Also consider properties in new entity as added
        for (var p in newEntity.properties) {
          changes.add(SchemaChange(type: ChangeType.PROPERTY_ADDED, entity: newEntity.name, property: p.name, uid: p.uid));
        }
      } else {
        if (oldEntity.name != newEntity.name) {
          changes.add(SchemaChange(
            type: ChangeType.ENTITY_RENAMED,
            entity: newEntity.name,
            oldValue: oldEntity.name,
            newValue: newEntity.name,
          ));
        }

        // Compare properties
        _compareProperties(oldEntity, newEntity, changes);
      }
    }

    // 2. Check for Deleted Entities
    for (var oldEntity in oldModel.entities) {
      if (newModel.findEntityByUid(oldEntity.uid) == null) {
        changes.add(SchemaChange(type: ChangeType.ENTITY_DELETED, entity: oldEntity.name, uid: oldEntity.uid));
      }
    }

    return changes;
  }

  void _compareProperties(Entity oldEntity, Entity newEntity, List<SchemaChange> changes) {
    for (var newProp in newEntity.properties) {
      final oldProp = oldEntity.findPropertyByUid(newProp.uid);

      if (oldProp == null) {
        changes.add(SchemaChange(type: ChangeType.PROPERTY_ADDED, entity: newEntity.name, property: newProp.name, uid: newProp.uid));
      } else {
        if (oldProp.name != newProp.name) {
          changes.add(SchemaChange(
            type: ChangeType.PROPERTY_RENAMED,
            entity: newEntity.name,
            property: newProp.name,
            oldValue: oldProp.name,
            newValue: newProp.name,
          ));
        }
        if (oldProp.relationTarget != newProp.relationTarget) {
          changes.add(SchemaChange(
            type: ChangeType.RELATIONSHIP_CHANGED,
            entity: newEntity.name,
            property: newProp.name,
            oldValue: oldProp.relationTarget,
            newValue: newProp.relationTarget,
          ));
        }
      }
    }

    // Check for deleted properties
    for (var oldProp in oldEntity.properties) {
      if (newEntity.findPropertyByUid(oldProp.uid) == null) {
        changes.add(SchemaChange(type: ChangeType.PROPERTY_DELETED, entity: oldEntity.name, property: oldProp.name, uid: oldProp.uid));
      }
    }
  }
}
