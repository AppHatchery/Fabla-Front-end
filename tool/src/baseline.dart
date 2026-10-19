/// The complexity ratchet.
///
/// A committed snapshot of every unit already over the threshold, so the gate
/// can fail on what a change made worse rather than on debt the change
/// inherited. Without it, a repo with existing violations can never go green
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
  const Baseline({required this.threshold, required this.scores});

  const Baseline.empty() : threshold = 0, scores = const {};

  /// The threshold the snapshot was taken at, recorded so a later run can warn
  /// when the two disagree.
  final int threshold;

  /// `path::qualifiedName` -> recorded complexity. Only units over the
  /// threshold are stored, so the file stays reviewable in a diff.
  final Map<String, int> scores;

  bool get isEmpty => scores.isEmpty;

  /// Null when the unit is not tracked, i.e. it is new or was previously under
  /// the threshold.
  int? scoreFor(UnitMetrics unit) => scores[baselineKey(unit)];

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
    return Baseline(
      threshold: (decoded['threshold'] as num?)?.toInt() ?? 0,
      scores: {
        for (final entry in units.entries)
          entry.key: (entry.value as num).toInt(),
      },
    );
  }

  /// Writes the snapshot with sorted keys so a rewrite produces a reviewable
  /// diff rather than a reshuffle.
  static void save(
    String path,
    Iterable<UnitMetrics> units,
    int threshold,
  ) {
    final scores = <String, int>{};
    for (final unit in units) {
      if (unit.complexityInclusive <= threshold) continue;
      final key = baselineKey(unit);
      final existing = scores[key];
      // Overloaded keys are possible (e.g. two same-named local declarations);
      // keep the worst so the ratchet can never loosen.
      if (existing == null || unit.complexityInclusive > existing) {
        scores[key] = unit.complexityInclusive;
      }
    }

    final sorted = scores.keys.toList()..sort();
    final payload = <String, Object>{
      'version': 1,
      'generatedBy': 'tool/complexity_audit.dart',
      'threshold': threshold,
      'units': {for (final key in sorted) key: scores[key]!},
    };
    File(path).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
    );
  }
}
