/// Defines types and results for the validation process, including change categories and pass/fail statuses.
enum ChangeType {
  ENTITY_ADDED,
  PROPERTY_ADDED,
  ENTITY_RENAMED,
  PROPERTY_RENAMED,
  ENTITY_UID_CHANGED,
  PROPERTY_UID_CHANGED,
  RELATIONSHIP_CHANGED,
  PROPERTY_DELETED,
  ENTITY_DELETED,
}

class SchemaChange {
  final ChangeType type;
  final String entity;
  final String? property;
  final int? uid;
  final String? oldValue;
  final String? newValue;

  SchemaChange({
    required this.type,
    required this.entity,
    this.property,
    this.uid,
    this.oldValue,
    this.newValue,
  });

  @override
  String toString() {
    final buffer = StringBuffer("[${type.name}] $entity");
    if (property != null) buffer.write(".$property");
    if (oldValue != null) buffer.write(" (Changed: $oldValue -> $newValue)");
    return buffer.toString();
  }
}

class ValidationResult {
  final bool isPass;
  final String? message;

  ValidationResult({required this.isPass, this.message});

  factory ValidationResult.pass([String? msg]) => ValidationResult(isPass: true, message: msg);
  factory ValidationResult.fail(String msg) => ValidationResult(isPass: false, message: msg);

  bool get isFailure => !isPass;
}
