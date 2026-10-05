@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/complexity_audit.dart' as audit;
import '../../tool/src/baseline.dart';
import '../../tool/src/discovery.dart';
import '../../tool/src/findings.dart';
import '../../tool/src/metrics.dart';
import '../../tool/src/options.dart';
import '../../tool/src/report.dart';

UnitMetrics _unit(String source, {String name = 'f'}) {
  final result = analyzeSource(source, 'test_fixture.dart');
  expect(result.parseErrors, isEmpty, reason: 'fixture must parse');
  return result.units.firstWhere(
    (u) => u.qualifiedName == name,
    orElse: () => throw StateError(
      'No unit "$name" in ${result.units.map((u) => u.qualifiedName)}',
    ),
  );
}

int _complexity(String body, {String name = 'f'}) =>
    _unit('void f() { $body }', name: name).complexityInclusive;

void main() {
  group('decision points — counted', () {
    test('a unit with no branches scores 1', () {
      expect(_complexity('var x = 1;'), 1);
    });

    test('if adds one, a bare else adds none', () {
      expect(_complexity('if (a) { b(); }'), 2);
      expect(_complexity('if (a) { b(); } else { c(); }'), 2);
    });

    test('else if adds one each', () {
      expect(_complexity('if (a) {} else if (b) {} else if (c) {}'), 4);
    });

    test('loops each add one', () {
      expect(_complexity('for (final x in y) {}'), 2);
      expect(_complexity('for (var i = 0; i < 3; i++) {}'), 2);
      expect(_complexity('while (a) {}'), 2);
      expect(_complexity('do {} while (a);'), 2);
    });

    test('each case label counts, default does not', () {
      expect(
        _complexity('switch (x) { case 1: break; case 2: break; }'),
        3,
      );
      expect(
        _complexity('switch (x) { case 1: break; default: break; }'),
        2,
      );
    });

    test('stacked case labels count separately', () {
      expect(
        _complexity('switch (x) { case 1: case 2: break; default: break; }'),
        3,
      );
    });

    test('each catch counts; try and finally do not', () {
      expect(_complexity('try { a(); } finally { b(); }'), 1);
      expect(_complexity('try { a(); } catch (e) { b(); }'), 2);
      expect(
        _complexity('try { a(); } on A catch (e) {} on B catch (e) {}'),
        3,
      );
    });

    test('logical and null-coalescing operators count', () {
      expect(_complexity('var x = a ? b : c;'), 2);
      expect(_complexity('var x = a ?? b;'), 2);
      expect(_complexity('var x = a && b;'), 2);
      expect(_complexity('var x = a || b;'), 2);
      expect(_complexity('var x = a && b || c;'), 3);
    });

    test('collection-if and collection-for count', () {
      expect(_complexity('var x = [if (a) 1];'), 2);
      expect(_complexity('var x = [for (final y in z) y];'), 2);
    });

    test('a switch expression arm counts; the wildcard arm does not', () {
      final source = '''
int f(int x) => switch (x) {
  1 => 10,
  2 => 20,
  _ => 0,
};
''';
      expect(analyzeSource(source, 'f.dart').units.single.complexityInclusive,
          3);
    });

    test('a when guard counts on top of its arm', () {
      final source = '''
int f(Object x) {
  switch (x) {
    case int i when i > 0:
      return 1;
    default:
      return 0;
  }
}
''';
      // base 1 + case 1 + when 1
      expect(analyzeSource(source, 'f.dart').units.single.complexityInclusive,
          3);
    });

    test('logical patterns count', () {
      final source = '''
int f(Object x) {
  switch (x) {
    case int() || String():
      return 1;
    default:
      return 0;
  }
}
''';
      // base 1 + case 1 + pattern-|| 1
      expect(analyzeSource(source, 'f.dart').units.single.complexityInclusive,
          3);
    });

    test('an if-case pattern and its when guard count', () {
      // base 1 + if 1 + when 1 + && 1
      expect(_complexity('if (x case int v when v > 0 && v < 10) {}'), 4);
      // base 1 + if 1 + pattern-|| 1
      expect(_complexity('if (x case int() || String()) {}'), 3);
    });
  });

  group('decision points — not counted', () {
    test('??= does not count', () {
      expect(_complexity('a ??= b;'), 1);
    });

    test('assert does not count, and its condition is not descended into', () {
      expect(_complexity('assert(a && b || c);'), 1);
    });

    test('nullable type annotations do not count', () {
      expect(
        analyzeSource(
          'void f(String? a, List<int>? b) { String? c; }',
          'f.dart',
        ).units.single.complexityInclusive,
        1,
      );
    });

    test('null assertion, is and as do not count', () {
      expect(_complexity('var x = a!; var y = b is C; var z = d as E;'), 1);
    });
  });

  group('null-aware access', () {
    // Only the node carrying the operator may count. Checking one node type
    // misses most sites; checking a subtree for a `?` token double-counts.
    test('a?.b.c counts once', () {
      expect(_complexity('var x = a?.b.c;'), 2);
    });

    test('a?.b.c?.d() counts twice', () {
      expect(_complexity('var x = a?.b.c?.d();'), 3);
    });

    test('null-aware index counts', () {
      expect(_complexity('var x = a?[0];'), 2);
    });

    test('null-aware cascade counts once regardless of section count', () {
      expect(_complexity('a?..b()..c();'), 2);
    });
  });

  group('strings', () {
    test('operators inside string literals do not count', () {
      expect(_complexity(r"var x = 'a && b || c ?? d';"), 1);
      expect(_complexity(r"var x = r'MaterialPageRoute<.*?>\((.*?)\)';"), 1);
    });

    test('operators inside an interpolation do count', () {
      // The case that defeats both regex (over-counts literals) and
      // strip-all-strings (under-counts interpolations).
      expect(_complexity(r'var x = "${a ?? b}";'), 2);
      expect(_complexity(r'var x = "${a ?? ""} && literal";'), 2);
    });
  });

  group('closures', () {
    test('a closure folds into the enclosing unit, once', () {
      final u = _unit('void f() { g((e) => e == null ? 0 : 1); }');
      expect(u.complexitySelf, 1, reason: 'the body itself has no branch');
      expect(u.complexityInclusive, 2, reason: 'the ternary folds in');
    });

    test('a doubly-nested closure is counted once, not twice', () {
      final u = _unit('void f() { g((a) => h((b) => a ?? b)); }');
      expect(u.complexityInclusive, 2);
    });

    test('closures are surfaced as sub-units', () {
      final u = _unit('void f() { g((e) => e ?? 1); }');
      expect(u.closures, hasLength(1));
      expect(u.closures.single.complexitySelf, 2);
      expect(u.closures.single.qualifiedName, contains('<closure@L'));
    });

    test('a named local function is measured like a closure', () {
      final u = _unit('void f() { void inner() { if (a) {} } inner(); }');
      expect(u.complexitySelf, 1);
      expect(u.complexityInclusive, 2);
    });
  });

  group('nesting depth', () {
    test('an else-if chain stays flat', () {
      // Treating the else-position `if` as a child rather than a sibling would
      // report depth 4 here and depth 10 for the chain in core/utils/formatter.
      final u = _unit('void f() { if (a) {} else if (b) {} else if (c) {} }');
      expect(u.nestingDepth, 1);
    });

    test('genuine nesting accumulates', () {
      final u = _unit('void f() { if (a) { for (var x in y) { if (b) {} } } }');
      expect(u.nestingDepth, 3);
    });

    test('nested closures do not accumulate depth', () {
      // Three nested builders is the canonical Flutter widget tree and has no
      // imperative nesting at all.
      final u = _unit('void f() { g((a) => h((b) => i((c) => 1))); }');
      expect(u.nestingDepth, 0);
    });

    test('a closure reports its own depth', () {
      final u = _unit('void f() { g((a) { if (x) { if (y) {} } }); }');
      expect(u.nestingDepth, 2, reason: 'deepest closure body wins');
    });

    test('try and catch bodies nest', () {
      final u = _unit('void f() { try { if (a) {} } catch (e) { if (b) {} } }');
      expect(u.nestingDepth, 2);
    });
  });

  group('unit collection', () {
    test('accessors, operators and constructors are named distinctly', () {
      final source = '''
class A {
  A(this.x) : y = x ?? 0;
  A.named() : x = 0, y = 0;
  factory A.make() => A(1);
  final int x;
  final int y;
  int get v => x ?? 0;
  set v(int n) { if (n > 0) x = n; }
  bool operator ==(Object other) => other is A && other.x == x;
  int get hashCode => x;
}
''';
      final names = analyzeSource(source, 'a.dart')
          .units
          .map((u) => u.qualifiedName)
          .toSet();
      expect(names, contains('A.A'));
      expect(names, contains('A.named'));
      expect(names, contains('A.make'));
      expect(names, contains('A.get v'));
      expect(names, contains('A.set v'));
      expect(names, contains('A.operator =='));
    });

    test('a constructor initializer list is measured', () {
      final source = 'class A { A(int? x) : y = x ?? 0; final int y; }';
      final ctor = analyzeSource(source, 'a.dart')
          .units
          .firstWhere((u) => u.qualifiedName == 'A.A');
      expect(ctor.complexityInclusive, 2);
    });

    test('an assert initializer is not measured', () {
      final source = 'class A { A(int x) : assert(x > 0 && x < 9); }';
      final ctor = analyzeSource(source, 'a.dart')
          .units
          .firstWhere((u) => u.qualifiedName == 'A.A');
      expect(ctor.complexityInclusive, 1);
    });

    test('branchy field initializers become a synthetic unit', () {
      final source = 'class A { final x = a ?? b; }';
      final unit = analyzeSource(source, 'a.dart')
          .units
          .firstWhere((u) => u.qualifiedName == 'A.<initializers>');
      expect(unit.complexityInclusive, 2);
    });

    test('branchless field initializers produce no unit', () {
      final source = 'class A { final x = 1; }';
      expect(analyzeSource(source, 'a.dart').units, isEmpty);
    });

    test('branchy top-level initializers become a synthetic unit', () {
      final source = 'final x = a ?? b;';
      final unit = analyzeSource(source, 'a.dart').units.single;
      expect(unit.qualifiedName, '<library initializers>');
      expect(unit.complexityInclusive, 2);
    });
  });

  group('conservation', () {
    // The single most valuable check: an independent flat count of the whole
    // file must equal the sum of per-unit own-body counts. A mismatch means a
    // branchy declaration form never made it into a unit — a gap that would
    // otherwise show up only as a finding that silently never appears.
    test('per-unit counts reconcile with a flat count of the file', () {
      const source = '''
final top = a ?? b;
void free() { if (a) {} }
class A {
  A(int? x) : y = x ?? 0;
  final int y;
  final z = p ?? q;
  int get v => y > 0 ? 1 : 2;
  void m() {
    for (final e in list) {
      if (e != null && e.ok) { g((x) => x ?? 1); }
    }
    try { h(); } catch (_) {}
  }
}
''';
      final metrics = analyzeSource(source, 'a.dart');
      final collected = metrics.units.fold<int>(
        0,
        (sum, u) =>
            sum +
            u.selfPoints.total +
            u.closures.fold<int>(0, (s, c) => s + c.selfPoints.total),
      );
      expect(collected, metrics.totalDecisionPoints);
    });

    test('a closure inside an if-case guard is collected', () {
      const source = '''
void f() {
  if (x case int v when list.any((e) => e == v || e > 2)) {}
}
''';
      final metrics = analyzeSource(source, 'a.dart');
      final unit = metrics.units.single;
      expect(unit.closures, hasLength(1));
      expect(
        unit.selfPoints.total +
            unit.closures.fold<int>(0, (s, c) => s + c.selfPoints.total),
        metrics.totalDecisionPoints,
      );
    });
  });

  group('generated-file detection', () {
    late Directory tmp;

    setUp(() => tmp = Directory.systemTemp.createTempSync('discovery_'));
    tearDown(() => tmp.deleteSync(recursive: true));

    CodeCategory classifyWithHeader(String header) {
      final file = File('${tmp.path}/a.dart')
        ..writeAsStringSync('$header\nvoid f() {}\n');
      return Discovery.classify('lib/a.dart', file);
    }

    test('a generator banner marks the file generated', () {
      expect(
        classifyWithHeader('// GENERATED CODE - DO NOT MODIFY BY HAND'),
        CodeCategory.generated,
      );
    });

    test('loose header text does not hide a hand-written file', () {
      expect(
        classifyWithHeader('// coverage:ignore-file'),
        CodeCategory.production,
      );
      expect(
        classifyWithHeader('/// Handles auto-generated IDs.'),
        CodeCategory.production,
      );
    });
  });

  group('banding', () {
    test('bands follow the spec thresholds', () {
      expect(bandFor(5), ComplexityBand.low);
      expect(bandFor(6), ComplexityBand.moderate);
      expect(bandFor(10), ComplexityBand.moderate);
      expect(bandFor(11), ComplexityBand.high);
      expect(bandFor(16), ComplexityBand.veryHigh);
      expect(bandFor(21), ComplexityBand.critical);
    });

    test('nesting bands follow the spec thresholds', () {
      expect(nestingBandFor(2), NestingBand.acceptable);
      expect(nestingBandFor(3), NestingBand.caution);
      expect(nestingBandFor(4), NestingBand.high);
      expect(nestingBandFor(5), NestingBand.critical);
    });
  });

  group('glob translation', () {
    test('**/ is optional, so a root-level file still matches', () {
      final re = globToRegExp('**/*.g.dart');
      expect(re.hasMatch('lib/objectbox.g.dart'), isTrue);
      expect(re.hasMatch('objectbox.g.dart'), isTrue);
      expect(re.hasMatch('lib/deep/nested/x.g.dart'), isTrue);
    });

    test('a single star does not cross a path separator', () {
      final re = globToRegExp('lib/*.dart');
      expect(re.hasMatch('lib/main.dart'), isTrue);
      expect(re.hasMatch('lib/sub/main.dart'), isFalse);
    });

    test('patterns are anchored', () {
      final re = globToRegExp('**/*.dart');
      expect(re.hasMatch('lib/foo.darts'), isFalse);
      expect(re.hasMatch('lib/foo.dart'), isTrue);
    });
  });

  group('argument parsing', () {
    test('defaults match the workflow', () {
      final o = AuditOptions.parse([]);
      expect(o.path, 'lib');
      expect(o.threshold, 10);
      expect(o.outputPath, 'complexity-report.md');
      expect(o.failOnThreshold, isFalse);
    });

    test('both --flag value and --flag=value are accepted', () {
      expect(AuditOptions.parse(['--threshold', '7']).threshold, 7);
      expect(AuditOptions.parse(['--threshold=7']).threshold, 7);
    });

    test('an empty value means absent', () {
      // `${{ inputs.path }}` expands to "" on a pull_request event.
      expect(AuditOptions.parse(['--path', '']).path, 'lib');
      expect(AuditOptions.parse(['--threshold', '']).threshold, 10);
    });

    test('--exclude is one comma-separated string', () {
      final o = AuditOptions.parse(['--exclude', '**/*.g.dart, **/*.pb.dart']);
      expect(o.excludeGlobs, ['**/*.g.dart', '**/*.pb.dart']);
    });

    test('an unknown flag is a usage error', () {
      // Tolerating it would let a typo'd --fail-on-thresholds disable the gate.
      expect(
        () => AuditOptions.parse(['--fail-on-thresholds']),
        throwsA(isA<UsageException>()),
      );
    });

    test('a non-integer threshold is a usage error', () {
      expect(
        () => AuditOptions.parse(['--threshold', 'ten']),
        throwsA(isA<UsageException>()),
      );
    });

    test('peekOutputPath reads the destination without validating', () {
      expect(
        AuditOptions.peekOutputPath(['--bogus', '--output-path', 'x.md']),
        'x.md',
      );
      expect(AuditOptions.peekOutputPath([]), 'complexity-report.md');
    });
  });

  group('baseline ratchet', () {
    UnitMetrics unitAt(int complexity, {String name = 'A.m'}) => UnitMetrics(
      path: 'lib/a.dart',
      qualifiedName: name,
      startLine: 1,
      endLine: 2,
      locNonBlank: 2,
      category: CodeCategory.production,
      complexityInclusive: complexity,
      complexitySelf: complexity,
      nestingDepth: 1,
      points: DecisionPoints(),
      selfPoints: DecisionPoints(),
      returnTypeSource: '',
      parameterCount: 0,
      hasAwaitInOwnBody: false,
      hasEmptyCatch: false,
      hasBooleanSelectorParam: false,
      closures: const [],
    );

    const baseline = Baseline(
      threshold: 10,
      scores: {'lib/a.dart::A.m': 20},
    );

    test('the key excludes line numbers, which churn on every edit above', () {
      expect(baselineKey(unitAt(20)), 'lib/a.dart::A.m');
    });

    test('inherited debt at the same score does not fail the gate', () {
      expect(baseline.isRegression(unitAt(20), 10), isFalse);
    });

    test('an improvement does not fail the gate', () {
      expect(baseline.isRegression(unitAt(15), 10), isFalse);
    });

    test('a worsened unit fails the gate', () {
      expect(baseline.isRegression(unitAt(21), 10), isTrue);
    });

    test('a new unit over threshold fails the gate', () {
      expect(baseline.isRegression(unitAt(11, name: 'A.other'), 10), isTrue);
    });

    test('a new unit under threshold does not fail the gate', () {
      expect(baseline.isRegression(unitAt(10, name: 'A.other'), 10), isFalse);
    });

    test('status is reported distinctly for each case', () {
      expect(
        buildFinding(unitAt(21), 10, baseline: baseline).baselineStatus,
        BaselineStatus.worsened,
      );
      expect(
        buildFinding(unitAt(20), 10, baseline: baseline).baselineStatus,
        BaselineStatus.inherited,
      );
      expect(
        buildFinding(
          unitAt(11, name: 'A.new'),
          10,
          baseline: baseline,
        ).baselineStatus,
        BaselineStatus.newViolation,
      );
      expect(
        buildFinding(unitAt(3), 10, baseline: baseline).baselineStatus,
        BaselineStatus.clean,
      );
      expect(
        buildFinding(unitAt(99), 10).baselineStatus,
        BaselineStatus.untracked,
      );
    });

    test('only new and worsened are gate failures', () {
      expect(BaselineStatus.newViolation.isGateFailure, isTrue);
      expect(BaselineStatus.worsened.isGateFailure, isTrue);
      expect(BaselineStatus.inherited.isGateFailure, isFalse);
      expect(BaselineStatus.clean.isGateFailure, isFalse);
    });

    test('a missing baseline file loads as empty rather than throwing', () {
      expect(Baseline.load('no_such_baseline.json').isEmpty, isTrue);
    });
  });

  group('options for scoping and the ratchet', () {
    test('--update-baseline without --baseline is a usage error', () {
      expect(
        () => AuditOptions.parse(['--update-baseline']),
        throwsA(isA<UsageException>()),
      );
    });

    test('scoping and baseline are off by default', () {
      final o = AuditOptions.parse([]);
      expect(o.isScoped, isFalse);
      expect(o.hasBaseline, isFalse);
      expect(o.summaryOut, isEmpty);
    });

    test('the new flags parse', () {
      final o = AuditOptions.parse([
        '--diff-base=origin/main',
        '--baseline',
        'b.json',
        '--summary-out=s.md',
      ]);
      expect(o.diffBase, 'origin/main');
      expect(o.baselinePath, 'b.json');
      expect(o.summaryOut, 's.md');
      expect(o.isScoped, isTrue);
    });
  });

  group('auditing another tree', () {
    // The release workflow measures the previous release by pointing --root at
    // a checkout of it and writing a baseline with --update-baseline.
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('audit_root_');
      Directory('${tmp.path}/lib').createSync();
      // Complexity 12: base 1 + 11 ifs.
      File('${tmp.path}/lib/branchy.dart').writeAsStringSync(
        'void f() { ${List.filled(11, 'if (a) {}').join(' ')} }\n',
      );
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    AuditOptions optionsFor(String baseline) => AuditOptions.parse([
      '--root',
      tmp.path,
      '--baseline',
      baseline,
      '--update-baseline',
    ]);

    test('defaults to the current directory', () {
      expect(AuditOptions.parse([]).root, isEmpty);
    });

    test('paths are relative to --root, so baselines from two trees match', () {
      final baseline = '${tmp.path}/baseline.json';
      final options = optionsFor(baseline);

      expect(audit.writeBaseline(audit.collectUnits(options), options), 0);

      final units = (jsonDecode(File(baseline).readAsStringSync())
          as Map<String, dynamic>)['units'] as Map<String, dynamic>;
      expect(units, {'lib/branchy.dart::f': 12});
    });

    test('a missing --root is a usage error', () {
      expect(
        () => audit.collectUnits(
          AuditOptions.parse(['--root', '${tmp.path}/nope']),
        ),
        throwsA(isA<UsageException>()),
      );
    });

    test('--update-baseline refuses to write when a file fails to parse', () {
      // A partial baseline would report every unit in the skipped file as new.
      File('${tmp.path}/lib/broken.dart').writeAsStringSync('void g( {\n');
      final baseline = '${tmp.path}/baseline.json';
      final options = optionsFor(baseline);

      expect(audit.writeBaseline(audit.collectUnits(options), options), 3);
      expect(File(baseline).existsSync(), isFalse);
    });
  });

  group('report budget', () {
    AuditResult synthetic(int count) {
      final findings = List.generate(count, (i) {
        final unit = _unit(
          'void f() { ${List.filled(98, 'if (a) {}').join(' ')} }',
        );
        return buildFinding(
          UnitMetrics(
            path: 'lib/very/deeply/nested/path/to/file_$i.dart',
            qualifiedName: '_SomeLongishStateClassName$i.someMethodName',
            startLine: i,
            endLine: i + 200,
            locNonBlank: 180,
            category: CodeCategory.production,
            complexityInclusive: 99,
            complexitySelf: 99,
            nestingDepth: 5,
            points: unit.points,
            selfPoints: unit.selfPoints,
            returnTypeSource: 'Future<void>',
            parameterCount: 6,
            hasAwaitInOwnBody: true,
            hasEmptyCatch: true,
            hasBooleanSelectorParam: true,
            closures: const [],
          ),
          10,
        );
      });
      return AuditResult(
        filesAudited: count,
        filesSkippedGenerated: 0,
        parseFailures: const {},
        findings: findings,
        histogram: {for (final b in ComplexityBand.values) b: 0},
        totalUnits: count,
        violationCount: count,
        conservationMismatches: const [],
      );
    }

    test('the body stays within the PR comment limit', () {
      // The limit is what GitHub rejects at, and the step that posts the
      // comment is `always()` — so an oversized report would fail the job on a
      // formatting problem rather than on complexity.
      final body = render(
        synthetic(500),
        AuditOptions.parse(['--max-full-blocks=5000']),
        mode: ReportMode.comment,
      );
      expect(utf8Length(body), lessThanOrEqualTo(kMaxCommentChars));
    });

    test('truncation drops the tail, never the top finding', () {
      final body = render(
        synthetic(500),
        AuditOptions.parse(['--max-full-blocks=5000']),
        mode: ReportMode.comment,
      );
      expect(body, contains('_SomeLongishStateClassName0.someMethodName'));
      expect(body, contains('Report truncated'));
    });

    test('the comment collapses context but never the gate failures', () {
      final body = render(
        synthetic(6),
        AuditOptions.parse([]),
        mode: ReportMode.comment,
      );
      // Findings that fail the gate must be visible without a click.
      final gateHeading = body.indexOf('new or worsened');
      final firstDetails = body.indexOf('<details>');
      expect(gateHeading, greaterThan(-1));
      expect(
        firstDetails == -1 || gateHeading < firstDetails,
        isTrue,
        reason: 'gate failures appear before any collapsed section',
      );
    });

    test('the summary report is headed for the run Summary page', () {
      final body = render(
        synthetic(3),
        AuditOptions.parse([]),
        mode: ReportMode.summary,
      );
      expect(body, startsWith('## Complexity Score and Suggestions'));
      expect(body, contains('Repository totals'));
    });

    test('the workflow comment marker is never emitted', () {
      // The workflow finds its own comment by this substring; emitting it could
      // make the workflow hijack an unrelated comment.
      expect(render(synthetic(3), AuditOptions.parse([])),
          isNot(contains(kWorkflowMarker)));
    });

    test('hard truncation fits the byte limit with multi-byte text', () {
      // Every line carries an em dash, as the verdict line does. The old loop
      // compared bytes to a character index, walked back to nothing and threw.
      final body = List.filled(2000, 'line — with a dash').join('\n');
      final cut = hardTruncate(body, 1000);
      expect(utf8Length(cut), lessThanOrEqualTo(1000));
      expect(utf8Length(cut), greaterThan(900), reason: 'keeps most of it');
      expect(cut, endsWith('_Report hard-truncated at the size limit._\n'));
    });

    test('hard truncation handles text shorter in characters than bytes', () {
      // 500 characters, 1500 bytes: a character index of the byte budget
      // would run past the end of the string.
      final cut = hardTruncate('—' * 500, 1000);
      expect(utf8Length(cut), lessThanOrEqualTo(1000));
    });

    test('a body within the limit is returned unchanged', () {
      expect(hardTruncate('short — body', 1000), 'short — body');
    });

    test('utf8Length counts the encoded size, not code units', () {
      expect('·—–'.length, 3, reason: 'three UTF-16 code units');
      expect(utf8Length('·'), 2);
      expect(utf8Length('—–'), 6);
      expect(utf8Length('·—–'), 8, reason: 'but eight bytes on the wire');
      expect(utf8Length('abc'), 3);
    });
  });

  group('widget-tree tagging', () {
    UnitMetrics buildUnit(String source, String name) =>
        analyzeSource(source, 'w.dart')
            .units
            .firstWhere((u) => u.qualifiedName == name);

    test('a widget-returning switch dispatch is tagged', () {
      // Deliberately NOT excluded by the presence of a switch: a switch on a
      // type returning widgets is the canonical Flutter widget-factory shape
      // and accounts for the highest-scoring units in this repo.
      const source = '''
class A {
  Widget pick(int x) {
    switch (x) {
      case 1: return a != null ? B() : C();
      case 2: return D();
      default: return E();
    }
  }
}
''';
      expect(isWidgetTree(buildUnit(source, 'A.pick')), isTrue);
    });

    test('an async method with a switch is not tagged', () {
      const source = '''
class A {
  Future<void> go(int x) async {
    switch (x) { case 1: await a(); break; default: break; }
  }
}
''';
      expect(isWidgetTree(buildUnit(source, 'A.go')), isFalse);
    });

    test('a widget-returning method with a loop is not tagged', () {
      const source = '''
class A {
  Widget build(c) { for (final x in y) { z(); } return B(); }
}
''';
      expect(isWidgetTree(buildUnit(source, 'A.build')), isFalse);
    });

    test('a widget-returning method with a catch is not tagged', () {
      const source = '''
class A {
  Widget build(c) { try { z(); } catch (e) {} return B(); }
}
''';
      expect(isWidgetTree(buildUnit(source, 'A.build')), isFalse);
    });
  });
}
