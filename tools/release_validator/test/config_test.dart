import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:release_validator/services/config_service.dart';

void main() {
  group('ConfigService Tests', () {
    late Directory tempDir;
    late ConfigService configService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('validator_config_test');
      configService = ConfigService();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('Loads policy and audit files', () async {
      final policyFile = File(p.join(tempDir.path, 'policy.yaml'));
      await policyFile.writeAsString('''
validation_policy:
  ENTITY_ADDED: pass
  ENTITY_RENAMED: approval
''');

      final auditFile = File(p.join(tempDir.path, 'audit.yaml'));
      await auditFile.writeAsString('''
approved_changes:
  - type: ENTITY_RENAMED
    entity: TestEntity
retired_entities:
  - 12345
''');

      await configService.load(policyFile.path, auditFile.path);

      expect(configService.getAction('ENTITY_ADDED'), equals('pass'));
      expect(configService.getAction('ENTITY_RENAMED'), equals('approval'));
      expect(configService.getAction('UNKNOWN'), equals('approval')); // Default
      
      expect(configService.approvals.length, 1);
      expect(configService.approvals[0]['entity'], equals('TestEntity'));
      expect(configService.retiredAudit, contains(12345));
    });
  });
}
