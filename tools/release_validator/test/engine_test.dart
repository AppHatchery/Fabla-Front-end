import 'package:test/test.dart';
import 'package:release_validator/models/schema.dart';
import 'package:release_validator/models/validation.dart';
import 'package:release_validator/services/engine.dart';
import 'package:release_validator/services/config_service.dart';

class MockConfigService extends ConfigService {
  final Map<String, String> mockPolicy;
  final List<Map<dynamic, dynamic>> mockApprovals;
  final List<int> mockRetired;

  MockConfigService({
    required this.mockPolicy,
    required this.mockApprovals,
    required this.mockRetired,
  }) {
    policy = mockPolicy;
    approvals = mockApprovals;
    retiredAudit = mockRetired;
  }

  @override
  String getAction(String type) => mockPolicy[type] ?? 'approval';
}

void main() {
  group('ValidationEngine Tests', () {
    test('Passes when policy is set to pass', () {
      final config = MockConfigService(
        mockPolicy: {'ENTITY_ADDED': 'pass'},
        mockApprovals: [],
        mockRetired: [],
      );
      final engine = ValidationEngine(config, ObjectBoxModel(entities: [], retiredEntityUids: []));
      
      final change = SchemaChange(type: ChangeType.ENTITY_ADDED, entity: 'Test');
      final result = engine.validate(change);
      
      expect(result.isPass, isTrue);
    });

    test('Fails on unknown policy action', () {
      final config = MockConfigService(
        mockPolicy: {'ENTITY_ADDED': 'invalid'},
        mockApprovals: [],
        mockRetired: [],
      );
      final engine = ValidationEngine(config, ObjectBoxModel(entities: [], retiredEntityUids: []));
      
      final change = SchemaChange(type: ChangeType.ENTITY_ADDED, entity: 'Test');
      final result = engine.validate(change);
      
      expect(result.isFailure, isTrue);
      expect(result.message, contains('Unknown policy action'));
    });

    test('Validates approved changes', () {
      final config = MockConfigService(
        mockPolicy: {'ENTITY_RENAMED': 'approval'},
        mockApprovals: [
          {'type': 'ENTITY_RENAMED', 'entity': 'NewName'}
        ],
        mockRetired: [],
      );
      final engine = ValidationEngine(config, ObjectBoxModel(entities: [], retiredEntityUids: []));
      
      final change = SchemaChange(type: ChangeType.ENTITY_RENAMED, entity: 'NewName');
      final result = engine.validate(change);
      
      expect(result.isPass, isTrue);
      expect(result.message, contains('Approved in audit.yaml'));
    });

    test('Fails unapproved changes requiring approval', () {
      final config = MockConfigService(
        mockPolicy: {'ENTITY_RENAMED': 'approval'},
        mockApprovals: [],
        mockRetired: [],
      );
      final engine = ValidationEngine(config, ObjectBoxModel(entities: [], retiredEntityUids: []));
      
      final change = SchemaChange(type: ChangeType.ENTITY_RENAMED, entity: 'NewName');
      final result = engine.validate(change);
      
      expect(result.isFailure, isTrue);
      expect(result.message, contains('requires entry in audit.yaml'));
    });

    test('Validates retirement in model', () {
      final config = MockConfigService(
        mockPolicy: {'ENTITY_DELETED': 'retirement'},
        mockApprovals: [],
        mockRetired: [],
      );
      final model = ObjectBoxModel(entities: [], retiredEntityUids: [123]);
      final engine = ValidationEngine(config, model);
      
      final change = SchemaChange(type: ChangeType.ENTITY_DELETED, entity: 'Test', uid: 123);
      final result = engine.validate(change);
      
      expect(result.isPass, isTrue);
      expect(result.message, contains('Correctly retired in objectbox-model.json'));
    });

    test('Validates retirement in audit', () {
      final config = MockConfigService(
        mockPolicy: {'ENTITY_DELETED': 'retirement'},
        mockApprovals: [],
        mockRetired: [123],
      );
      final model = ObjectBoxModel(entities: [], retiredEntityUids: []);
      final engine = ValidationEngine(config, model);
      
      final change = SchemaChange(type: ChangeType.ENTITY_DELETED, entity: 'Test', uid: 123);
      final result = engine.validate(change);
      
      expect(result.isPass, isTrue);
      expect(result.message, contains('Marked as retired in audit.yaml'));
    });

    test('Fails when retirement is missing everywhere', () {
      final config = MockConfigService(
        mockPolicy: {'ENTITY_DELETED': 'retirement'},
        mockApprovals: [],
        mockRetired: [],
      );
      final model = ObjectBoxModel(entities: [], retiredEntityUids: []);
      final engine = ValidationEngine(config, model);
      
      final change = SchemaChange(type: ChangeType.ENTITY_DELETED, entity: 'Test', uid: 123);
      final result = engine.validate(change);
      
      expect(result.isFailure, isTrue);
      expect(result.message, contains('but not added to \'retiredEntityUids\''));
    });

    test('Fails retirement check if UID is missing', () {
       final config = MockConfigService(
        mockPolicy: {'ENTITY_DELETED': 'retirement'},
        mockApprovals: [],
        mockRetired: [],
      );
      final engine = ValidationEngine(config, ObjectBoxModel(entities: [], retiredEntityUids: []));
      
      final change = SchemaChange(type: ChangeType.ENTITY_DELETED, entity: 'Test', uid: null);
      final result = engine.validate(change);
      
      expect(result.isFailure, isTrue);
      expect(result.message, contains('Missing UID'));
    });
  });
}
