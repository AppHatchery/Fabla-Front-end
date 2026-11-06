/// The complexity ratchet.
///
/// A snapshot of every unit already over a limit, so the gate can fail on what
/// a change made worse rather than on debt the change inherited. Two limits are
/// ratcheted the same way: complexity and nesting depth. Without it, a repo with existing violations can never go green
/// and the workflow gets deleted.
library;

import 'dart:convert';
import 'dart:io';

import 'metrics.dart';

/// Identity of a unit across commits.
///
/// Deliberately excludes line numbers: they churn on every edit above the unit,
/// which would make the whole baseline look regressed after an import change.
/// `qualifiedName` already disambiguates getters (`Class.get x`), setters,
/// named constructors and the synthetic `Class.<initializers>`.
String baselineKey(UnitMetrics unit) => '${unit.path}::${unit.qualifiedName}';

class Baseline {
  const Baseline({
    required this.threshold,
    required this.scores,
    this.nestingThreshold = 0,
    this.nesting = const {},
  });

  const Baseline.empty()
    : threshold = 0,
      scores = const {},
      nestingThreshold = 0,
      nesting = const {};

  /// The threshold the snapshot was taken at, recorded so a later run can warn
  /// when the two disagree.
  final int threshold;

  /// `path::qualifiedName` -> recorded complexity. Only units over the
  /// threshold are stored, so the file stays reviewable in a diff.
  final Map<String, int> scores;

  /// The nesting threshold the snapshot was taken at.
  final int nestingThreshold;

  /// `path::qualifiedName` -> recorded nesting depth, for units deeper than
  /// [nestingThreshold]. Absent in older snapshots, which then track nothing.
  final Map<String, int> nesting;

  bool get isEmpty => scores.isEmpty && nesting.isEmpty;

  /// Null when the unit is not tracked, i.e. it is new or was previously under
  /// the threshold.
  int? scoreFor(UnitMetrics unit) => scores[baselineKey(unit)];

  /// Null when the unit's nesting is not tracked.
  int? nestingFor(UnitMetrics unit) => nesting[baselineKey(unit)];

  /// Whether [unit] is a violation the gate should fail on.
  ///
  /// New over threshold, or worse than recorded. A unit recorded at the same
  /// or a higher score is inherited debt and passes.
  bool isRegression(UnitMetrics unit, int threshold) {
    if (unit.complexityInclusive <= threshold) return false;
    final recorded = scores[baselineKey(unit)];
    if (recorded == null) return true;
    return unit.complexityInclusive > recorded;
  }

  static Baseline load(String path) {
    final file = File(path);
    if (!file.existsSync()) return const Baseline.empty();

    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Baseline $path is not a JSON object.');
    }
    final units = decoded['units'];
    if (units is! Map<String, dynamic>) {
      throw FormatException('Baseline $path has no "units" object.');
    }
    final nesting = decoded['nesting'];
    return Baseline(
      threshold: (decoded['threshold'] as num?)?.toInt() ?? 0,
      scores: _intMap(units),
      nestingThreshold: (decoded['nestingThreshold'] as num?)?.toInt() ?? 0,
      nesting: nesting is Map<String, dynamic> ? _intMap(nesting) : const {},
    );
  }

  static Map<String, int> _intMap(Map<String, dynamic> json) => {
    for (final entry in json.entries) entry.key: (entry.value as num).toInt(),
  };

  /// Writes the snapshot with sorted keys so a rewrite produces a reviewable
  /// diff rather than a reshuffle.
  static void save(
    String path,
    Iterable<UnitMetrics> units,
    int threshold, {
    required int nestingThreshold,
  }) {
    final scores = <String, int>{};
    final nesting = <String, int>{};
    for (final unit in units) {
      final key = baselineKey(unit);
      if (unit.complexityInclusive > threshold) {
        _keepWorst(scores, key, unit.complexityInclusive);
      }
      if (unit.nestingDepth > nestingThreshold) {
        _keepWorst(nesting, key, unit.nestingDepth);
      }
    }

    final payload = <String, Object>{
      'version': 2,
      'generatedBy': 'tool/complexity_audit.dart',
      'threshold': threshold,
      'units': _sorted(scores),
      'nestingThreshold': nestingThreshold,
      'nesting': _sorted(nesting),
    };
    File(path).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
    );
  }

  /// Overloaded keys are possible (e.g. two same-named local declarations);
  /// keep the worst so the ratchet can never loosen.
  static void _keepWorst(Map<String, int> into, String key, int value) {
    final existing = into[key];
    if (existing == null || value > existing) into[key] = value;
  }

  static Map<String, int> _sorted(Map<String, int> values) {
    final keys = values.keys.toList()..sort();
    return {for (final key in keys) key: values[key]!};
  }
}
