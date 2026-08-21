import 'package:test/test.dart';
import 'package:release_validator/models/validation.dart';
import 'package:release_validator/reporter.dart';

void main() {
  group('ReportGenerator Tests', () {
    late ReportGenerator reporter;

    setUp(() {
      reporter = ReportGenerator();
    });

    test('generateMarkdown with no changes', () {
      final markdown = reporter.generateMarkdown([], []);
      expect(markdown, contains('No schema changes detected'));
    });

    test('generateMarkdown with failures', () {
      final changes = [
        SchemaChange(type: ChangeType.ENTITY_ADDED, entity: 'NewEntity'),
        SchemaChange(type: ChangeType.ENTITY_DELETED, entity: 'OldEntity', uid: 123),
      ];
      final results = [
        ValidationResult.pass('OK'),
        ValidationResult.fail('Error'),
      ];

      final markdown = reporter.generateMarkdown(changes, results);
      expect(markdown, contains('✅ PASS'));
      expect(markdown, contains('❌ FAIL'));
      expect(markdown, contains('1 issue(s) detected'));
    });

    test('generateMarkdown with success', () {
      final changes = [
        SchemaChange(type: ChangeType.ENTITY_ADDED, entity: 'NewEntity'),
      ];
      final results = [
        ValidationResult.pass('OK'),
      ];

      final markdown = reporter.generateMarkdown(changes, results);
      expect(markdown, contains('✨ SUCCESS'));
    });

    test('printSummary runs without error', () {

      final changes = [
        SchemaChange(type: ChangeType.ENTITY_ADDED, entity: 'NewEntity'),
      ];
      final results = [
        ValidationResult.pass('OK'),
      ];

      expect(() => reporter.printSummary(changes, results), returnsNormally);
      expect(() => reporter.printSummary([], []), returnsNormally);
    });

    test('printSummary with long text to trigger wrapping', () {
       final changes = [
        SchemaChange(
          type: ChangeType.ENTITY_ADDED, 
          entity: 'A' * 100,
        ),
      ];
      final results = [
        ValidationResult.fail('F' * 100),
      ];

      expect(() => reporter.printSummary(changes, results), returnsNormally);
    });
  });
}
