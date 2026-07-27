import 'dart:io';
import 'package:path/path.dart' as p;
import '../lib/models/schema.dart';
import '../lib/services/comparator.dart';
import '../lib/services/config_service.dart';
import '../lib/services/schema_loader.dart';
import '../lib/services/engine.dart';
import '../lib/reporter.dart';

void main(List<String> args) async {
  if (args.length < 2) {
    print('Usage: dart bin/validator.dart <base-model.json> <current-model.json>');
    exit(1);
  }

  try {
    // 1. Setup Paths
    final scriptDir = p.dirname(p.fromUri(Platform.script));
    final projectRoot = p.dirname(scriptDir);
    final policyPath = p.join(projectRoot, 'config', 'policy.yaml');
    final auditPath = p.join(projectRoot, 'config', 'audit.yaml');

    // 2. Load Schemas
    final loader = SchemaLoader();
    final oldModel = await loader.load(args[0]);
    final newModel = await loader.load(args[1]);

    // 3. Load Configurations
    final config = ConfigService();
    await config.load(policyPath, auditPath);

    // 4. Compare
    final comparator = SchemaComparator();
    final changes = comparator.compare(oldModel, newModel);

    // 5. Validate
    final engine = ValidationEngine(config, newModel);
    final results = changes.map((c) => engine.validate(c)).toList();

    // 6. Report
    final reporter = ReportGenerator();
    reporter.printSummary(changes, results);

    // 7. Exit
    final hasFailures = results.any((r) => r.isFailure);
    exit(hasFailures ? 1 : 0);

  } catch (e, stack) {
    print('Critical Error during validation: $e');
    print(stack);
    exit(1);
  }
}
