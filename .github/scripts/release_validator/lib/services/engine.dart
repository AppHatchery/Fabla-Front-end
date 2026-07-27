/// Evaluates schema changes against defined policies and audit approvals to determine if they are safe for release.
import '../models/schema.dart';
import '../models/validation.dart';
import 'config_service.dart';

class ValidationEngine {
  final ConfigService config;
  final ObjectBoxModel currentModel;

  ValidationEngine(this.config, this.currentModel);

  ValidationResult validate(SchemaChange change) {
    final action = config.getAction(change.type.name);

    switch (action) {
      case 'pass':
        return ValidationResult.pass();
      case 'approval':
        return _checkApproval(change);
      case 'retirement':
        return _checkRetirement(change);
      default:
        return ValidationResult.fail("Unknown policy action: $action");
    }
  }

  ValidationResult _checkApproval(SchemaChange change) {
    final isApproved = config.approvals.any((a) =>
        a['type'] == change.type.name &&
        a['entity'] == change.entity &&
        (change.property == null || a['property'] == change.property));

    if (isApproved) {
      return ValidationResult.pass("Approved in audit.yaml");
    }
    return ValidationResult.fail("Action '${change.type.name}' requires entry in audit.yaml");
  }

  ValidationResult _checkRetirement(SchemaChange change) {
    if (change.uid == null) return ValidationResult.fail("Missing UID for retirement check");

    final isRetiredInModel = currentModel.retiredEntityUids.contains(change.uid);
    final isRetiredInAudit = config.retiredAudit.contains(change.uid);

    if (isRetiredInModel) {
      return ValidationResult.pass("Correctly retired in objectbox-model.json");
    }
    if (isRetiredInAudit) {
      return ValidationResult.pass("Marked as retired in audit.yaml");
    }

    return ValidationResult.fail("Entity '${change.entity}' was deleted but not added to 'retiredEntityUids'. Please add UID: ${change.uid} to the model file.");
  }
}
