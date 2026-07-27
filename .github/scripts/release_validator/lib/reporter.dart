import 'models/validation.dart';

class ReportGenerator {
  void printSummary(List<SchemaChange> changes, List<ValidationResult> results) {
    print('\n' + '=' * 50);
    print('📦 OBJECTBOX SCHEMA VALIDATION REPORT');
    print('=' * 50);

    if (changes.isEmpty) {
      print('✅ No schema changes detected.');
      return;
    }

    int failures = 0;
    for (int i = 0; i < changes.length; i++) {
      final change = changes[i];
      final result = results[i];

      final status = result.isPass ? '✅ PASS' : '❌ FAIL';
      print('$status: $change');
      if (result.message != null) {
        print('      └─ ${result.message}');
      }
      if (result.isFailure) failures++;
    }

    print('\n' + '-' * 50);
    if (failures == 0) {
      print('🚀 SUCCESS: All changes comply with policy.');
    } else {
      print('🚨 FAILURE: $failures issue(s) found. Please fix or get approval.');
    }
    print('-' * 50 + '\n');
  }
}
