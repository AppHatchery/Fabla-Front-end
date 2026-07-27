/// Loads and manages validation policies and audit configurations from YAML files.
import 'dart:io';
import 'package:yaml/yaml.dart';

class ConfigService {
  late Map<String, String> policy;
  late List<Map<dynamic, dynamic>> approvals;
  late List<int> retiredAudit;

  Future<void> load(String policyPath, String auditPath) async {
    final policyYaml = loadYaml(await File(policyPath).readAsString());
    policy = Map<String, String>.from(policyYaml['validation_policy']);

    final auditYaml = loadYaml(await File(auditPath).readAsString());
    approvals = List<Map<dynamic, dynamic>>.from(auditYaml['approved_changes'] ?? []);
    retiredAudit = List<int>.from(auditYaml['retired_entities'] ?? []);
  }

  String getAction(String type) => policy[type] ?? 'approval';
}
