/// Defines the data structures for representing an ObjectBox model, including entities and properties.
class ObjectBoxModel {
  final List<Entity> entities;
  final List<int> retiredEntityUids;

  ObjectBoxModel({required this.entities, required this.retiredEntityUids});

  factory ObjectBoxModel.fromJson(Map<String, dynamic> json) {
    return ObjectBoxModel(
      entities: (json['entities'] as List).map((e) => Entity.fromJson(e)).toList(),
      retiredEntityUids: List<int>.from(json['retiredEntityUids'] ?? []),
    );
  }

  Entity? findEntityByUid(int uid) {
    for (var entity in entities) {
      if (entity.uid == uid) return entity;
    }
    return null;
  }

  Entity? findEntityByName(String name) {
    for (var entity in entities) {
      if (entity.name == name) return entity;
    }
    return null;
  }
}

class Entity {
  final int uid;
  final String name;
  final List<Property> properties;

  Entity({required this.uid, required this.name, required this.properties});

  factory Entity.fromJson(Map<String, dynamic> json) {
    return Entity(
      uid: int.parse((json['id'] as String).split(':')[1]),
      name: json['name'],
      properties: (json['properties'] as List).map((p) => Property.fromJson(p)).toList(),
    );
  }

  Property? findPropertyByUid(int uid) {
    for (var prop in properties) {
      if (prop.uid == uid) return prop;
    }
    return null;
  }

  Property? findPropertyByName(String name) {
    for (var prop in properties) {
      if (prop.name == name) return prop;
    }
    return null;
  }
}

class Property {
  final int uid;
  final String name;
  final int type;
  final int? flags;
  final String? relationTarget;

  Property({
    required this.uid,
    required this.name,
    required this.type,
    this.flags,
    this.relationTarget,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      uid: int.parse((json['id'] as String).split(':')[1]),
      name: json['name'],
      type: json['type'],
      flags: json['flags'],
      relationTarget: json['relationTarget'],
    );
  }
}
