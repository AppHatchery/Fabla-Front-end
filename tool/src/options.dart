/// Command-line contract for `tool/complexity_audit.dart`.
///
/// The flags and their spellings are fixed by
/// `.github/workflows/Complexity_Checker.yml`. Argument parsing is hand-rolled
/// rather than using `package:args` because the semantics are non-standard: an
/// empty string means "absent" (GitHub Actions passes `""` for a cleared
/// `workflow_dispatch` input) and an unknown flag must fail rather than be
/// tolerated.
library;

/// A usage error. Distinct from an internal error so the two can be told apart
/// in a workflow log, where both render identically red.
class UsageException implements Exception {
  UsageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuditOptions {
  AuditOptions({
    required this.root,
    required this.path,
    required this.threshold,
    required this.excludeGlobs,
    required this.outputPath,
    required this.summaryOut,
    required this.diffBase,
    required this.baselinePath,
    required this.updateBaseline,
    required this.failOnThreshold,
    required this.maxFullBlocks,
    required this.maxCondensed,
    required this.showHelp,
  });

  static const String defaultPath = 'lib';
  static const int defaultThreshold = 10;
  static const String defaultOutputPath = 'complexity-report.md';
  static const int defaultMaxFullBlocks = 25;
  static const int defaultMaxCondensed = 40;

  /// Repository root the audit runs against. Empty means the current
  /// directory.
  ///
  /// The release workflow points this at a checkout of the previous release so
  /// this release's tool measures both trees. [path], [diffBase] and every
  /// path in the report and baseline are relative to it; the output files are
  /// not.
  final String root;

  final String path;
  final int threshold;
  final List<String> excludeGlobs;

  /// Concise report, scoped to changed files when [diffBase] is set. Feeds the
  /// sticky PR comment.
  final String outputPath;

  /// Extended whole-repo report for the Actions run Summary page. Empty to
  /// skip. Mirrors `--summary-out` in `.github/scripts/tests/test_summary.py`.
  final String summaryOut;

  /// Git ref to diff against, e.g. `origin/main`. Empty audits everything.
  ///
  /// This is the only part of the tool that depends on VCS state, and it needs
  /// full history — a shallow checkout has no merge base.
  final String diffBase;

  /// Committed snapshot of known-over-threshold scores. Empty disables the
  /// ratchet and every over-threshold unit counts as a violation.
  final String baselinePath;

  /// Rewrite the baseline from the current whole-repo scores instead of
  /// gating. Always unscoped, so it cannot be narrowed by [diffBase].
  final bool updateBaseline;

  final bool failOnThreshold;
  final int maxFullBlocks;
  final int maxCondensed;
  final bool showHelp;

  bool get isScoped => diffBase.isNotEmpty;

  bool get hasBaseline => baselinePath.isNotEmpty;

  /// Reads `--output-path` out of [args] without validating anything else.
  ///
  /// `main` needs the destination before it enters the block that can throw a
  /// [UsageException], because a usage error must still leave a report behind.
  static String peekOutputPath(List<String> args) {
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg.startsWith('--output-path=')) {
        final value = arg.substring('--output-path='.length);
        if (value.isNotEmpty) return value;
      } else if (arg == '--output-path' && i + 1 < args.length) {
        final value = args[i + 1];
        if (value.isNotEmpty) return value;
      }
    }
    return defaultOutputPath;
  }

  static AuditOptions parse(List<String> args) {
    String? root;
    String? path;
    String? threshold;
    String? exclude;
    String? outputPath;
    String? maxFullBlocks;
    String? maxCondensed;
    String? summaryOut;
    String? diffBase;
    String? baselinePath;
    var updateBaseline = false;
    var failOnThreshold = false;
    var showHelp = false;

    /// Reads the value for [flag], accepting both `--flag value` and
    /// `--flag=value`. Returns the index to continue from.
    int takeValue(
      int i,
      String flag,
      String? inline,
      void Function(String) assign,
    ) {
      if (inline != null) {
        assign(inline);
        return i;
      }
      if (i + 1 >= args.length) {
        throw UsageException('$flag requires a value.');
      }
      assign(args[i + 1]);
      return i + 1;
    }

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      final eq = arg.indexOf('=');
      final name = eq == -1 ? arg : arg.substring(0, eq);
      final inline = eq == -1 ? null : arg.substring(eq + 1);

      switch (name) {
        case '--root':
          i = takeValue(i, name, inline, (v) => root = v);
        case '--path':
          i = takeValue(i, name, inline, (v) => path = v);
        case '--threshold':
          i = takeValue(i, name, inline, (v) => threshold = v);
        case '--exclude':
          i = takeValue(i, name, inline, (v) => exclude = v);
        case '--output-path':
          i = takeValue(i, name, inline, (v) => outputPath = v);
        case '--summary-out':
          i = takeValue(i, name, inline, (v) => summaryOut = v);
        case '--diff-base':
          i = takeValue(i, name, inline, (v) => diffBase = v);
        case '--baseline':
          i = takeValue(i, name, inline, (v) => baselinePath = v);
        case '--update-baseline':
          updateBaseline = true;
        case '--max-full-blocks':
          i = takeValue(i, name, inline, (v) => maxFullBlocks = v);
        case '--max-condensed':
          i = takeValue(i, name, inline, (v) => maxCondensed = v);
        case '--fail-on-threshold':
          failOnThreshold = true;
        case '--help':
        case '-h':
          showHelp = true;
        default:
          // Tolerating an unknown flag would make the workflow's contract
          // unenforceable: a typo'd `--fail-on-thresholds` would silently turn
          // the gate off.
          throw UsageException('Unknown argument: $arg');
      }
    }

    if (updateBaseline && (baselinePath == null || baselinePath!.isEmpty)) {
      throw UsageException('--update-baseline requires --baseline <file>.');
    }

    return AuditOptions(
      root: _orDefault(root, ''),
      path: _orDefault(path, defaultPath),
      threshold: _parseInt(threshold, '--threshold', defaultThreshold),
      excludeGlobs: _splitGlobs(exclude),
      outputPath: _orDefault(outputPath, defaultOutputPath),
      summaryOut: _orDefault(summaryOut, ''),
      diffBase: _orDefault(diffBase, ''),
      baselinePath: _orDefault(baselinePath, ''),
      updateBaseline: updateBaseline,
      failOnThreshold: failOnThreshold,
      maxFullBlocks: _parseInt(
        maxFullBlocks,
        '--max-full-blocks',
        defaultMaxFullBlocks,
      ),
      maxCondensed: _parseInt(
        maxCondensed,
        '--max-condensed',
        defaultMaxCondensed,
      ),
      showHelp: showHelp,
    );
  }

  /// An empty string means the flag was passed but carries no value — which is
  /// what `${{ inputs.path }}` expands to on a `pull_request` event.
  static String _orDefault(String? value, String fallback) =>
      (value == null || value.trim().isEmpty) ? fallback : value.trim();

  static int _parseInt(String? value, String flag, int fallback) {
    if (value == null || value.trim().isEmpty) return fallback;
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      throw UsageException('$flag must be an integer, got "$value".');
    }
    if (parsed < 1) {
      throw UsageException('$flag must be >= 1, got $parsed.');
    }
    return parsed;
  }

  static List<String> _splitGlobs(String? value) {
    if (value == null || value.trim().isEmpty) return const <String>[];
    return value
        .split(',')
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toList(growable: false);
  }
}

const String kUsage = '''
Cyclomatic complexity audit for Dart/Flutter sources.

Usage: dart run tool/complexity_audit.dart [options]

  --root <dir>              Repository root to audit. --path, --diff-base and
                            the paths in the report and baseline are relative
                            to it. Default: the current directory
  --path <dir>              Directory to audit. Default: lib
  --threshold <int>         Fail above this complexity. Default: 10
  --exclude "<globs>"       Comma-separated globs, matched against the
                            repo-root-relative path.
  --output-path <file>      Concise report for the PR comment, scoped to
                            changed files when --diff-base is set.
                            Default: complexity-report.md
  --summary-out <file>      Extended whole-repo report for the Actions run
                            Summary page. Omit to skip.
  --diff-base <ref>         Scope the report and the gate to files changed
                            against this ref, e.g. origin/main. Needs full
                            history (actions/checkout fetch-depth: 0).
  --baseline <file>         Snapshot of known scores, e.g. the previous
                            release written with --update-baseline. The gate
                            then fails only on units that are new over
                            threshold or scored worse than the snapshot.
  --update-baseline         Rewrite --baseline from current whole-repo scores
                            instead of gating. Ignores --diff-base.
  --fail-on-threshold       Exit 1 when the gate finds a violation.
  --max-full-blocks <int>   Cap on full finding blocks. Default: 25
  --max-condensed <int>     Cap on condensed findings. Default: 40
  -h, --help                Show this message.

A unit fails when its complexity is strictly greater than the threshold, so
the default fails at 11 and above. With --baseline, a unit already recorded at
the same or a higher score does not fail — only regressions and new violations
do.

Exit codes:
  0  pass            2  usage error
  1  gate violation  3  internal error

The report is written for every exit code.
''';
