#!/usr/bin/env dart
/// Cyclomatic complexity audit for this repository.
///
/// Invoked by `.github/workflows/Complexity_Checker.yml`. Metric definition and
/// thresholds come from `.claude/agents/Cyclonmatic-complex-audit.md`.
///
/// Two reports come out of one run:
///   * `--output-path`  concise, scoped to the change, for the PR comment
///   * `--summary-out`  whole repository, for the Actions run Summary page
///
/// The gate is the baseline ratchet: with `--baseline`, only units that are new
/// over threshold or worse than recorded fail. Inherited debt is reported and
/// never blocks, which is what makes the gate adoptable on a repo that already
/// has violations.
library;

import 'dart:io';

import 'src/baseline.dart';
import 'src/diff_scope.dart';
import 'src/discovery.dart';
import 'src/findings.dart';
import 'src/metrics.dart';
import 'src/options.dart';
import 'src/report.dart';

Future<void> main(List<String> args) async {
  // Resolved before the try block: a usage error must still know where to
  // write, because every consumer step in the workflow is `if: always()`.
  final outputPath = AuditOptions.peekOutputPath(args);

  String body;
  String resultLine;
  var code = 0;

  try {
    final options = AuditOptions.parse(args);
    if (options.showHelp) {
      stdout.write(kUsage);
      stdout.writeln('RESULT: help');
      exit(0);
    }

    final units = collectUnits(options);

    if (options.updateBaseline) exit(writeBaseline(units, options));

    final result = buildResult(units, options);
    body = render(result, options, mode: ReportMode.comment);

    if (options.summaryOut.isNotEmpty) {
      File(options.summaryOut).writeAsStringSync(
        '${render(result, options, mode: ReportMode.summary)}\n',
      );
    }

    final gateFailures = result.findings
        .where((f) => f.inScope && _isGateFailure(f, result, options))
        .length;

    if (result.parseFailures.isNotEmpty) {
      // A file that did not parse is not a file with no complexity. Treating
      // it as a pass would be a gate that goes green because it broke.
      code = 3;
      resultLine =
          'RESULT: internal-error — ${result.parseFailures.length} file(s) '
          'failed to parse';
    } else if (options.failOnThreshold && gateFailures > 0) {
      code = 1;
      resultLine = 'RESULT: fail — $gateFailures unit(s) new or worsened';
    } else {
      code = 0;
      resultLine =
          'RESULT: pass — $gateFailures new, ${result.violationCount} total '
          'over threshold ${options.threshold}';
    }

    _printDigest(result, options, gateFailures);
  } on UsageException catch (e) {
    body = renderError('Usage error', '$e\n\n$kUsage');
    code = 2;
    resultLine = 'RESULT: usage-error — $e';
    stderr.writeln('$e\n');
    stderr.writeln(kUsage);
  } catch (e, stack) {
    // Deliberately not `on Exception`: the analyzer throws Error subtypes, and
    // bare non-Exception throws are a known trap in this codebase.
    body = renderError('Internal error', '$e\n\n$stack');
    code = 3;
    resultLine = 'RESULT: internal-error — ${e.runtimeType}';
    stderr.writeln('Complexity audit failed: $e\n$stack');
  }

  // Always, for every exit code — then, and only then, exit.
  try {
    File(outputPath).writeAsStringSync('$body\n');
  } catch (e) {
    stderr.writeln('Could not write report to $outputPath: $e');
    if (code == 0) code = 3;
    resultLine = 'RESULT: internal-error — report not written';
  }

  stdout.writeln(resultLine);
  exit(code);
}

bool _isGateFailure(
  Finding finding,
  AuditResult result,
  AuditOptions options,
) => result.baselineInUse
    ? finding.baselineStatus.isGateFailure
    : finding.complexity > options.threshold;

/// Writes `--baseline` from [units] and returns the exit code.
///
/// Refuses when any file failed to parse: a baseline missing those files would
/// report every unit in them as new on the next run.
int writeBaseline(CollectedUnits units, AuditOptions options) {
  if (units.parseFailures.isNotEmpty) {
    for (final entry in units.parseFailures.entries) {
      stderr.writeln('  ${entry.key}: ${entry.value}');
    }
    stdout.writeln(
      'RESULT: internal-error — ${units.parseFailures.length} file(s) failed '
      'to parse; ${options.baselinePath} not written',
    );
    return 3;
  }

  // Always whole-repo: a baseline written from a diff scope would silently
  // drop every unit the change did not touch, loosening the ratchet.
  Baseline.save(options.baselinePath, units.units, options.threshold);
  final tracked = units.units
      .where((u) => u.complexityInclusive > options.threshold)
      .length;
  stdout.writeln(
    'Wrote ${options.baselinePath} with $tracked unit(s) over '
    'threshold ${options.threshold}.',
  );
  stdout.writeln('RESULT: baseline-updated — $tracked unit(s)');
  return 0;
}

/// Everything measured, before any scoping or baseline comparison.
class CollectedUnits {
  const CollectedUnits({
    required this.units,
    required this.filesAudited,
    required this.filesSkippedGenerated,
    required this.parseFailures,
    required this.conservationMismatches,
    required this.scope,
  });

  final List<UnitMetrics> units;
  final int filesAudited;
  final int filesSkippedGenerated;
  final Map<String, String> parseFailures;
  final List<String> conservationMismatches;

  /// Changed files, or null when the run is not scoped to a diff.
  final Set<String>? scope;
}

/// Walks and measures the whole `--path`, regardless of any diff scope.
///
/// Measuring everything costs ~600ms for this repo and buys two things scoping
/// would lose: a complete Summary-page report, and a baseline that cannot be
/// accidentally narrowed.
CollectedUnits collectUnits(AuditOptions options) {
  final String repoRoot;
  if (options.root.isEmpty) {
    repoRoot = Directory.current.path;
  } else {
    final dir = Directory(options.root);
    if (!dir.existsSync()) {
      throw UsageException('--root ${options.root} does not exist.');
    }
    repoRoot = dir.absolute.path;
  }

  final discovery = Discovery(
    repoRoot: repoRoot,
    excludeGlobs: options.excludeGlobs,
  );
  final files = discovery.discover(options.path);

  final scope = options.isScoped
      ? changedDartFiles(options.diffBase, workingDirectory: repoRoot)
      : null;

  final units = <UnitMetrics>[];
  final parseFailures = <String, String>{};
  final conservationMismatches = <String>[];
  var skippedGenerated = 0;
  var audited = 0;

  for (final file in files) {
    if (file.category == CodeCategory.generated) {
      skippedGenerated++;
      continue;
    }

    final FileMetrics metrics;
    try {
      metrics = analyzeSource(
        File(file.absPath).readAsStringSync(),
        file.relPath,
        category: file.category,
      );
    } catch (e) {
      parseFailures[file.relPath] = '$e';
      continue;
    }

    if (metrics.parseErrors.isNotEmpty) {
      parseFailures[file.relPath] = metrics.parseErrors.first;
      continue;
    }

    // Conservation check: the sum of per-unit own-body counts must equal an
    // independent flat count of the whole file. A mismatch means a branchy
    // declaration form never made it into a unit — a silent gap that would
    // otherwise show up only as a missing finding.
    final collected = metrics.units.fold<int>(
      0,
      (sum, u) => sum + u.selfPoints.total + _closureTotal(u.closures),
    );
    if (collected != metrics.totalDecisionPoints) {
      conservationMismatches.add(
        '${file.relPath} (units $collected vs file '
        '${metrics.totalDecisionPoints})',
      );
    }

    audited++;
    units.addAll(metrics.units);
  }

  return CollectedUnits(
    units: units,
    filesAudited: audited,
    filesSkippedGenerated: skippedGenerated,
    parseFailures: parseFailures,
    conservationMismatches: conservationMismatches,
    scope: scope,
  );
}

AuditResult buildResult(CollectedUnits collected, AuditOptions options) {
  final baseline = options.hasBaseline
      ? Baseline.load(options.baselinePath)
      : null;
  final scope = collected.scope;

  final findings =
      collected.units
          .map(
            (u) => buildFinding(
              u,
              options.threshold,
              inScope: scope == null || scope.contains(u.path),
              baseline: baseline,
            ),
          )
          .toList()
        // Sorted once. Every downstream consumer — the top-offenders list, each
        // report tier, the truncation order — is a prefix or filtered scan.
        ..sort((a, b) {
          final byComplexity = b.complexity.compareTo(a.complexity);
          if (byComplexity != 0) return byComplexity;
          final byNesting = b.unit.nestingDepth.compareTo(a.unit.nestingDepth);
          if (byNesting != 0) return byNesting;
          // Stable tiebreak so reruns produce byte-identical reports.
          return '${a.unit.path}:${a.unit.startLine}'.compareTo(
            '${b.unit.path}:${b.unit.startLine}',
          );
        });

  final histogram = <ComplexityBand, int>{
    for (final band in ComplexityBand.values) band: 0,
  };
  for (final finding in findings) {
    histogram[finding.band] = histogram[finding.band]! + 1;
  }

  // Count only the Dart files the audit actually covers, so a PR that edits a
  // workflow or a test is not reported as touching audited source.
  final scopedFileCount = scope == null
      ? null
      : collected.units
            .map((u) => u.path)
            .toSet()
            .where(scope.contains)
            .length;

  return AuditResult(
    filesAudited: collected.filesAudited,
    filesSkippedGenerated: collected.filesSkippedGenerated,
    parseFailures: collected.parseFailures,
    findings: findings,
    histogram: histogram,
    totalUnits: collected.units.length,
    violationCount: findings
        .where((f) => f.complexity > options.threshold)
        .length,
    conservationMismatches: collected.conservationMismatches,
    scopedFileCount: scopedFileCount,
    baselineInUse: baseline != null,
  );
}

int _closureTotal(List<UnitMetrics> closures) =>
    closures.fold(0, (sum, c) => sum + c.selfPoints.total);

/// A short digest on stdout. The runner log is the only surface that survives a
/// crash, so it stays greppable rather than duplicating the markdown.
void _printDigest(
  AuditResult result,
  AuditOptions options,
  int gateFailures,
) {
  stdout.writeln(
    'Audited ${result.filesAudited} file(s), ${result.totalUnits} unit(s); '
    'skipped ${result.filesSkippedGenerated} generated.',
  );
  if (result.scopedFileCount != null) {
    stdout.writeln(
      'Scoped to ${result.scopedFileCount} changed file(s) against '
      '${options.diffBase}.',
    );
  }
  if (result.baselineInUse) {
    stdout.writeln('Baseline: ${options.baselinePath}');
  }
  stdout.writeln(
    'Over threshold ${options.threshold}: ${result.violationCount} total, '
    '$gateFailures new or worsened in scope.',
  );
  for (final f in result.findings.where(
    (f) => f.inScope && _isGateFailure(f, result, options),
  )) {
    stdout.writeln(
      '  ${f.complexity.toString().padLeft(3)}  ${f.unit.qualifiedName} '
      '(${f.unit.path}:${f.unit.startLine})',
    );
  }
}
