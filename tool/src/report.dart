/// Markdown rendering for the complexity audit.
///
/// Returns a string; never touches the disk and never decides an exit code.
/// `main` writes the reports first and picks the exit code afterwards, which is
/// the workflow's hard requirement — every consumer step is `if: always()`.
///
/// Two shapes, mirroring `.github/scripts/tests/test_summary.py`:
///   * [ReportMode.comment] — concise, scoped to the change, collapsed by
///     default, sized for a PR comment.
///   * [ReportMode.summary] — the whole repo, for the Actions run Summary page.
library;

import 'findings.dart';
import 'metrics.dart';
import 'options.dart';

/// A PR comment body over 65536 characters is rejected with a 422, and the step
/// that posts it is `always()` — so an oversized report would fail the job on a
/// formatting problem rather than on complexity.
const int kMaxCommentChars = 65000;

/// `$GITHUB_STEP_SUMMARY` accepts 1 MiB per step. The extended report is not
/// pasted anywhere with a tighter limit, so it gets room to be complete.
const int kMaxSummaryChars = 900000;

/// The workflow finds its own comment by searching for this marker. A report
/// containing it could make the workflow hijack an unrelated comment.
const String kWorkflowMarker = '<!-- complexity-audit -->';

enum ReportMode {
  /// Sticky PR comment: only what the change touched.
  comment,

  /// Run Summary page: the whole repository.
  summary,
}

/// Length of [text] once encoded as UTF-8.
///
/// The budget is measured in bytes, not in Dart string length: the report uses
/// `·`, `—` and `–`, each one UTF-16 code unit but two or three bytes on the
/// wire, so a `String.length` budget silently under-measures the payload
/// GitHub sees — by over a kilobyte on a full report.
int utf8Length(String text) {
  var bytes = 0;
  for (final rune in text.runes) {
    bytes += _runeBytes(rune);
  }
  return bytes;
}

int _runeBytes(int rune) {
  if (rune <= 0x7F) return 1;
  if (rune <= 0x7FF) return 2;
  if (rune <= 0xFFFF) return 3;
  return 4;
}

/// Cuts [body] to at most [limit] UTF-8 bytes, at a line break where there is
/// one, and says so at the end.
///
/// The tier budget should make this unreachable. A ragged cut still beats a 422
/// from the comment API, which would fail the job on a formatting problem.
String hardTruncate(String body, int limit) {
  if (utf8Length(body) <= limit) return body;

  const tail = '\n\n_Report hard-truncated at the size limit._\n';
  final budget = limit - utf8Length(tail);

  // Walk forward counting bytes: [limit] is a byte count and string indices
  // are UTF-16 code units, so the two cannot be compared directly.
  var bytes = 0;
  var cut = 0;
  for (final rune in body.runes) {
    bytes += _runeBytes(rune);
    if (bytes > budget) break;
    cut += rune > 0xFFFF ? 2 : 1;
  }

  final newline = body.lastIndexOf('\n', cut);
  return body.substring(0, newline > 0 ? newline : cut) + tail;
}

/// A [StringBuffer] that knows its own encoded size.
///
/// Tracking the count incrementally keeps assembly linear; re-encoding the
/// whole buffer to check the budget before each append would be quadratic.
class _BudgetBuffer {
  _BudgetBuffer(this.limit);

  final int limit;
  final StringBuffer _buffer = StringBuffer();
  int bytes = 0;

  void write(String text) {
    _buffer.write(text);
    bytes += utf8Length(text);
  }

  void writeln([String text = '']) => write('$text\n');

  /// Whether [text] fits with [reserve] bytes left over for the tail.
  bool fits(String text, int reserve) =>
      bytes + utf8Length(text) + reserve <= limit;

  @override
  String toString() => _buffer.toString();
}

/// Renders a report.
String render(
  AuditResult result,
  AuditOptions options, {
  ReportMode mode = ReportMode.summary,
}) {
  final scoped = mode == ReportMode.comment;
  final limit = scoped ? kMaxCommentChars : kMaxSummaryChars;
  final buffer = _BudgetBuffer(limit);

  final visible = scoped
      ? result.findings.where((f) => f.inScope).toList(growable: false)
      : result.findings;

  final gateFailures = visible
      .where((f) => _isGateFailure(f, result, options))
      .toList(growable: false);
  final inherited = visible
      .where(
        (f) =>
            f.complexity > options.threshold &&
            !_isGateFailure(f, result, options),
      )
      .toList(growable: false);

  if (!scoped) buffer.writeln('## Complexity Score and Suggestions\n');
  _writeVerdict(buffer, result, options, gateFailures, inherited, scoped);
  _writeProblems(buffer, result);
  if (!scoped) _writeSummary(buffer, result, options);

  const notice =
      '\n> **Report truncated to fit the size limit.** __N__ finding(s) '
      'omitted — the full ranking is in the `complexity-report` build '
      'artifact.\n';
  // Everything written after the tiers has to fit too, so the reserve covers
  // the truncation notice, the footer and the closing </details> tags.
  final reserve = utf8Length(notice) + utf8Length(kFooter) + 400;

  var omitted = 0;

  omitted += _writeTier(
    buffer: buffer,
    title: gateFailures.isEmpty
        ? 'New or worsened — none'
        : '${gateFailures.length} new or worsened',
    empty: '_Nothing new or worsened._',
    findings: gateFailures,
    cap: options.maxFullBlocks,
    reserve: reserve,
    // The whole point of the gate is these; never hide them behind a click.
    collapsed: false,
    renderOne: (f, i) => _fullBlock(f, i, options),
  );

  omitted += _writeTier(
    buffer: buffer,
    title: scoped
        ? '${inherited.length} pre-existing in the files you touched'
        : '${inherited.length} over threshold (> ${options.threshold})',
    empty: '_None._',
    findings: inherited,
    cap: options.maxFullBlocks,
    reserve: reserve,
    collapsed: true,
    renderOne: (f, i) => _fullBlock(f, i, options),
  );

  final moderate = visible
      .where((f) => f.complexity >= 6 && f.complexity <= options.threshold)
      .toList(growable: false);
  omitted += _writeTier(
    buffer: buffer,
    title: '${moderate.length} moderate (6–${options.threshold})',
    empty: '_None._',
    findings: moderate,
    cap: options.maxCondensed,
    reserve: reserve,
    collapsed: true,
    renderOne: _condensedLine,
  );

  if (omitted > 0) buffer.write(notice.replaceFirst('__N__', '$omitted'));
  buffer.write(kFooter);

  // Defence in depth for the marker: the assertion catches it in development,
  // the replace guarantees it in CI.
  var body = buffer.toString();
  assert(
    !body.contains(kWorkflowMarker),
    'Report must never contain the workflow comment marker.',
  );
  body = body.replaceAll(kWorkflowMarker, '(marker removed)');

  return hardTruncate(body, limit);
}

/// Whether a finding is what the gate fails on.
///
/// With a baseline, only a new or worsened unit counts — inherited debt is
/// reported but never blocks, which is what lets a repo with existing
/// violations adopt the gate at all.
bool _isGateFailure(
  Finding finding,
  AuditResult result,
  AuditOptions options,
) => result.baselineInUse
    ? finding.baselineStatus.isGateFailure
    : finding.complexity > options.threshold;

void _writeVerdict(
  _BudgetBuffer buffer,
  AuditResult result,
  AuditOptions options,
  List<Finding> gateFailures,
  List<Finding> inherited,
  bool scoped,
) {
  final scopeText = result.scopedFileCount == null
      ? 'all of `${options.path}`'
      : '${result.scopedFileCount} changed file(s)';

  if (gateFailures.isEmpty) {
    buffer.writeln(
      '**Complexity gate: PASS** — nothing new or worsened in $scopeText.',
    );
  } else {
    buffer.writeln(
      '**Complexity gate: FAIL** — ${gateFailures.length} unit(s) '
      '${result.baselineInUse ? 'new or worse than the baseline' : 'over the '
            'threshold'} in $scopeText.',
    );
  }
  buffer.writeln();

  if (scoped && inherited.isNotEmpty) {
    buffer.writeln(
      '${inherited.length} pre-existing issue(s) in those files are listed '
      'below for context and are **not** blocking this PR.',
    );
    buffer.writeln();
  }
  if (scoped && result.scopedFileCount == 0) {
    buffer.writeln('_No Dart files changed._\n');
  }
}

/// Parse failures and conservation gaps: both mean the report is incomplete,
/// which must never read as a pass.
void _writeProblems(_BudgetBuffer buffer, AuditResult result) {
  if (result.parseFailures.isNotEmpty) {
    buffer.writeln(
      '> **${result.parseFailures.length} file(s) failed to parse** and were '
      'not measured. This is an internal error, not a pass:',
    );
    for (final entry in result.parseFailures.entries.take(10)) {
      buffer.writeln('> - `${entry.key}` — ${_escape(entry.value)}');
    }
    buffer.writeln();
  }
  if (result.conservationMismatches.isNotEmpty) {
    buffer.writeln(
      '> **Warning:** decision points did not reconcile in '
      '${result.conservationMismatches.length} file(s), so some units may be '
      'missing: '
      '${result.conservationMismatches.take(5).map((p) => '`$p`').join(', ')}',
    );
    buffer.writeln();
  }
}

/// Emits one tier, refusing any block that would breach the budget.
///
/// Findings arrive already sorted descending, so appending in order means the
/// budget can only ever refuse a *later*, lower-scoring block — the sort is the
/// truncation order, and the top finding can never be dropped. `continue`
/// rather than `break` means one unusually long block does not discard every
/// shorter one after it.
int _writeTier({
  required _BudgetBuffer buffer,
  required String title,
  required String empty,
  required Iterable<Finding> findings,
  required int cap,
  required int reserve,
  required bool collapsed,
  required String Function(Finding, int) renderOne,
}) {
  final items = findings.toList(growable: false);
  if (items.isEmpty) {
    buffer.writeln('\n### $title\n');
    buffer.writeln(empty);
    return 0;
  }

  if (collapsed) {
    buffer.writeln(
      '\n<details>\n<summary><b>$title</b> — click to expand</summary>\n',
    );
  } else {
    buffer.writeln('\n### $title\n');
  }

  var emitted = 0;
  var omitted = 0;
  for (final finding in items) {
    if (emitted >= cap) {
      omitted++;
      continue;
    }
    final block = renderOne(finding, emitted + 1);
    if (!buffer.fits(block, reserve)) {
      omitted++;
      continue;
    }
    buffer.write(block);
    emitted++;
  }

  if (collapsed) buffer.writeln('\n</details>\n');
  return omitted;
}

void _writeSummary(
  _BudgetBuffer buffer,
  AuditResult result,
  AuditOptions options,
) {
  buffer.writeln('\n### Repository totals\n');
  buffer.writeln('| Metric | Count |');
  buffer.writeln('| --- | ---: |');
  buffer.writeln('| Files audited | ${result.filesAudited} |');
  if (result.filesSkippedGenerated > 0) {
    buffer.writeln(
      '| Files skipped (generated) | ${result.filesSkippedGenerated} |',
    );
  }
  buffer.writeln('| Executable units | ${result.totalUnits} |');
  for (final band in ComplexityBand.values.reversed) {
    buffer.writeln(
      '| ${band.label} ${_bandRange(band)} | ${result.histogram[band] ?? 0} |',
    );
  }
  buffer.writeln(
    '| **Over threshold (> ${options.threshold})** | '
    '**${result.violationCount}** |',
  );
  buffer.writeln();

  final top = result.findings
      .where((f) => f.complexity > options.threshold)
      .take(10)
      .toList();
  if (top.isEmpty) return;

  buffer.writeln('**Top offenders**\n');
  buffer.writeln('| # | Unit | Complexity | Nesting | Location |');
  buffer.writeln('| ---: | --- | ---: | ---: | --- |');
  for (var i = 0; i < top.length; i++) {
    final u = top[i].unit;
    final tag = top[i].isWidgetTree ? ' `[WIDGET-TREE]`' : '';
    buffer.writeln(
      '| ${i + 1} | `${_escape(u.qualifiedName)}`$tag | '
      '${u.complexityInclusive} | ${u.nestingDepth} | '
      '`${u.path}:${u.startLine}` |',
    );
  }
  buffer.writeln();
}

String _bandRange(ComplexityBand band) => switch (band) {
  ComplexityBand.low => '(1–5)',
  ComplexityBand.moderate => '(6–10)',
  ComplexityBand.high => '(11–15)',
  ComplexityBand.veryHigh => '(16–20)',
  ComplexityBand.critical => '(> 20)',
};

String _fullBlock(Finding f, int index, AuditOptions options) {
  final u = f.unit;
  final buffer = StringBuffer();
  final tags = <String>[
    if (u.category == CodeCategory.generated) '`[GENERATED]`',
    if (f.isWidgetTree) '`[WIDGET-TREE]`',
    if (f.baselineStatus == BaselineStatus.newViolation) '`[NEW]`',
    if (f.baselineStatus == BaselineStatus.worsened)
      '`[WORSE: was ${f.baselineScore}]`',
  ].join(' ');

  buffer.writeln(
    '#### $index. `${_escape(u.qualifiedName)}` '
    '${tags.isEmpty ? '' : '$tags '}— complexity ${u.complexityInclusive}',
  );
  buffer.writeln();
  buffer.writeln(
    '`${u.path}:${u.startLine}`–`${u.endLine}` · ${u.locNonBlank} LOC · '
    '${f.band.label} · nesting ${u.nestingDepth} (${f.nestingBand.label}) · '
    'self ${u.complexitySelf}',
  );
  buffer.writeln();
  buffer.writeln('Decision points: ${_breakdown(u.points)}');
  buffer.writeln();

  if (f.antiPatterns.isNotEmpty) {
    buffer.writeln(
      'Also flagged: ${f.antiPatterns.map((a) => a.label).join('; ')}.',
    );
    buffer.writeln();
  }

  buffer.writeln('**Root cause.** ${f.rootCause}');
  buffer.writeln();
  buffer.writeln('**Suggested refactor.** ${f.suggestion}');
  buffer.writeln();

  if (f.branchyClosures.isNotEmpty) {
    buffer.writeln('Branchy closures inside this unit:');
    buffer.writeln();
    for (final c in f.branchyClosures.take(5)) {
      buffer.writeln(
        '- `${_escape(c.qualifiedName)}` — complexity ${c.complexitySelf}, '
        'nesting ${c.nestingDepth}, `${c.path}:${c.startLine}`',
      );
    }
    buffer.writeln();
  }

  if (u.category == CodeCategory.generated) {
    buffer.writeln(
      '_Generated code — reported for completeness; do not refactor._',
    );
    buffer.writeln();
  }

  return buffer.toString();
}

String _condensedLine(Finding f, int index) {
  final u = f.unit;
  final tag = f.isWidgetTree ? ' `[WIDGET-TREE]`' : '';
  return '- `${_escape(u.qualifiedName)}`$tag — complexity '
      '${u.complexityInclusive}, nesting ${u.nestingDepth} — '
      '`${u.path}:${u.startLine}` — ${_topConstructs(u.points)}\n';
}

/// Written verbatim after the tiers, so its length is part of the reserve.
const String kFooter =
    '\n---\n\n'
    '<sub>Cyclomatic complexity = decision points + 1. Closures are folded '
    'into the enclosing unit (`self` shows the body alone). Nesting is '
    'measured per body, so `else if` chains and nested widget builders do not '
    'inflate it. `[WIDGET-TREE]` marks declarative widget construction, where '
    'a high score reflects presentational `?:`/`??`/`?.` rather than logic. '
    'Generated code and the configured excludes are skipped. Produced by '
    '`tool/complexity_audit.dart`.</sub>\n';

/// Renders the per-construct breakdown. Construct labels include `||`, which
/// splits a table row into phantom columns unless escaped — so every label is
/// wrapped in a code span and every literal pipe is escaped.
String _breakdown(DecisionPoints points) {
  final parts = points.nonZero
      .map((e) => '`${_escape(e.key.label)}`&nbsp;${e.value}')
      .toList();
  if (parts.isEmpty) return '_none_';
  return '${parts.join(' · ')} — total ${points.total} (+1 = '
      '${points.total + 1})';
}

String _topConstructs(DecisionPoints points) {
  final sorted = points.nonZero.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (sorted.isEmpty) return '_none_';
  return sorted
      .take(3)
      .map((e) => '`${_escape(e.key.label)}`&nbsp;${e.value}')
      .join(' · ');
}

/// Escapes markdown that would corrupt a table row or italicise a symbol.
///
/// A leading `_` on a private Dart member renders as emphasis, and this repo's
/// highest-scoring units are all `_`-prefixed State classes.
String _escape(String text) =>
    text.replaceAll('|', r'\|').replaceAll('*', r'\*');

/// The report written when the audit could not run at all.
String renderError(String title, String detail) {
  final buffer = StringBuffer();
  buffer.writeln('### $title\n');
  buffer.writeln('The complexity audit did not complete.\n');
  buffer.writeln('```');
  buffer.writeln(detail.length > 4000 ? detail.substring(0, 4000) : detail);
  buffer.writeln('```');
  return buffer.toString();
}
