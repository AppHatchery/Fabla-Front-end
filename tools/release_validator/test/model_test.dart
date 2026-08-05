import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:release_validator/models/schema.dart';
import 'package:release_validator/services/schema_loader.dart';

void main() {
  group('Model Tests', () {
    test('ObjectBoxModel.fromJson handles full schema', () {
      final json = {
        'entities': [
          {
            'id': '1:100',
            'name': 'User',
            'properties': [
              {'id': '1:101', 'name': 'id', 'type': 6},
              {'id': '2:102', 'name': 'name', 'type': 9}
            ]
          }
        ],
        'retiredEntityUids': [500, 600]
      };

      final model = ObjectBoxModel.fromJson(json);

      expect(model.entities.length, 1);
      expect(model.entities[0].name, 'User');
      expect(model.entities[0].uid, 100);
      expect(model.entities[0].properties.length, 2);
      expect(model.entities[0].properties[0].uid, 101);
      expect(model.retiredEntityUids, containsAll([500, 600]));
    });

    test('ObjectBoxModel lookup methods', () {
      final entity = Entity(uid: 100, name: 'User', properties: [
        Property(uid: 101, name: 'id', type: 6),
      ]);
      final model = ObjectBoxModel(entities: [entity], retiredEntityUids: []);

      expect(model.findEntityByUid(100), equals(entity));
      expect(model.findEntityByUid(999), isNull);
      expect(model.findEntityByName('User'), equals(entity));
      expect(model.findEntityByName('NonExistent'), isNull);

      expect(entity.findPropertyByUid(101), isNotNull);
      expect(entity.findPropertyByUid(999), isNull);
      expect(entity.findPropertyByName('id'), isNotNull);
      expect(entity.findPropertyByName('none'), isNull);
    });

    test('Property.fromJson handles optional fields', () {
      final json = {
        'id': '1:101',
        'name': 'target',
        'type': 11,
        'flags': 8,
        'relationTarget': 'OtherEntity'
      };

      final prop = Property.fromJson(json);
      expect(prop.uid, 101);
      expect(prop.flags, 8);
      expect(prop.relationTarget, 'OtherEntity');
    });

    test('Property.fromJson handles missing fields', () {
      final json = <String, dynamic>{};
      final prop = Property.fromJson(json);
      expect(prop.uid, 0);
      expect(prop.name, 'unknown');
      expect(prop.type, 0);
      expect(prop.flags, isNull);
      expect(prop.relationTarget, isNull);
    });

    test('SchemaLoader loads from file', () async {
      final tempDir = await Directory.systemTemp.createTemp('loader_test');
      final file = File(p.join(tempDir.path, 'model.json'));
      final data = {
        'entities': [],
        'retiredEntityUids': []
      };
      await file.writeAsString(jsonEncode(data));

      final loader = SchemaLoader();
      final model = await loader.load(file.path);
      expect(model.entities, isEmpty);

      await tempDir.delete(recursive: true);
    });

    test('SchemaLoader throws when file missing', () async {
      final loader = SchemaLoader();
      expect(() => loader.load('non_existent.json'), throwsException);
    });
  });
}
