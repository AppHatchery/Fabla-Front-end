/// Compares two ObjectBox models to identify added, removed, renamed, or modified entities and properties.
import '../models/schema.dart';
import '../models/validation.dart';

class SchemaComparator {
  List<SchemaChange> compare(ObjectBoxModel oldModel, ObjectBoxModel newModel) {
    final changes = <SchemaChange>[];
    final handledOldEntities = <int>{};

    // 1. Check for New/Renamed/UID-Changed Entities
    for (var newEntity in newModel.entities) {
      // Try UID first
      var oldEntity = oldModel.findEntityByUid(newEntity.uid);
      if (oldEntity != null) {
        handledOldEntities.add(oldEntity.uid);
        if (oldEntity.name != newEntity.name) {
          changes.add(SchemaChange(
            type: ChangeType.ENTITY_RENAMED,
            entity: newEntity.name,
            oldValue: oldEntity.name,
            newValue: newEntity.name,
          ));
        }
        _compareProperties(oldEntity, newEntity, changes);
        continue;
      }

      // Try Name (UID Change)
      oldEntity = oldModel.findEntityByName(newEntity.name);
      if (oldEntity != null) {
        handledOldEntities.add(oldEntity.uid);
        changes.add(SchemaChange(
          type: ChangeType.ENTITY_UID_CHANGED,
          entity: newEntity.name,
          oldValue: oldEntity.uid.toString(),
          newValue: newEntity.uid.toString(),
        ));
        _compareProperties(oldEntity, newEntity, changes);
        continue;
      }

      changes.add(SchemaChange(type: ChangeType.ENTITY_ADDED, entity: newEntity.name, uid: newEntity.uid));
      for (var p in newEntity.properties) {
        changes.add(SchemaChange(type: ChangeType.PROPERTY_ADDED, entity: newEntity.name, property: p.name, uid: p.uid));
      }
    }

    // 2. Check for Deleted Entities
    for (var oldEntity in oldModel.entities) {
      if (!handledOldEntities.contains(oldEntity.uid)) {
        changes.add(SchemaChange(type: ChangeType.ENTITY_DELETED, entity: oldEntity.name, uid: oldEntity.uid));
      }
    }

    return changes;
  }

  void _compareProperties(Entity oldEntity, Entity newEntity, List<SchemaChange> changes) {
    final handledOldProps = <int>{};

    for (var newProp in newEntity.properties) {
      Property? oldProp = oldEntity.findPropertyByUid(newProp.uid);
      
      if (oldProp != null) {
        handledOldProps.add(oldProp.uid);
        if (oldProp.name != newProp.name) {
          changes.add(SchemaChange(
            type: ChangeType.PROPERTY_RENAMED,
            entity: newEntity.name,
            property: newProp.name,
            oldValue: oldProp.name,
            newValue: newProp.name,
          ));
        }
        _checkPropertyInternalChanges(oldProp, newProp, newEntity.name, changes);
      } else {
        oldProp = oldEntity.findPropertyByName(newProp.name);
        if (oldProp != null) {
          handledOldProps.add(oldProp.uid);
          changes.add(SchemaChange(
            type: ChangeType.PROPERTY_UID_CHANGED,
            entity: newEntity.name,
            property: newProp.name,
            oldValue: oldProp.uid.toString(),
            newValue: newProp.uid.toString(),
          ));
          _checkPropertyInternalChanges(oldProp, newProp, newEntity.name, changes);
        } else {
          changes.add(SchemaChange(
            type: ChangeType.PROPERTY_ADDED, 
            entity: newEntity.name, 
            property: newProp.name, 
            uid: newProp.uid,
          ));
        }
      }
    }

    for (var oldProp in oldEntity.properties) {
      if (!handledOldProps.contains(oldProp.uid)) {
        changes.add(SchemaChange(
          type: ChangeType.PROPERTY_DELETED, 
          entity: oldEntity.name, 
          property: oldProp.name, 
          uid: oldProp.uid,
        ));
      }
    }
  }

  void _checkPropertyInternalChanges(Property oldProp, Property newProp, String entityName, List<SchemaChange> changes) {
    if (oldProp.relationTarget != newProp.relationTarget) {
      changes.add(SchemaChange(
        type: ChangeType.RELATIONSHIP_CHANGED,
        entity: entityName,
        property: newProp.name,
        oldValue: oldProp.relationTarget,
        newValue: newProp.relationTarget,
      ));
    }
    if (oldProp.type != newProp.type) {
      changes.add(SchemaChange(
        type: ChangeType.PROPERTY_TYPE_CHANGED,
        entity: entityName,
        property: newProp.name,
        oldValue: oldProp.type.toString(),
        newValue: newProp.type.toString(),
      ));
    }
    if (oldProp.flags != newProp.flags) {
      changes.add(SchemaChange(
        type: ChangeType.PROPERTY_FLAGS_CHANGED,
        entity: entityName,
        property: newProp.name,
        oldValue: oldProp.flags?.toString() ?? 'none',
        newValue: newProp.flags?.toString() ?? 'none',
      ));
    }
  }
}
