/// Turns raw metrics into classified, actionable findings.
///
/// Pure functions only: no IO, no markdown. Every predicate here is a one-line
/// unit test.
library;

import 'baseline.dart';
import 'metrics.dart';

enum ComplexityBand {
  low('Low'),
  moderate('Moderate'),
  high('High'),
  veryHigh('Very High'),
  critical('Critical');

  const ComplexityBand(this.label);
  final String label;
}

enum NestingBand {
  acceptable('Acceptable'),
  caution('Caution'),
  high('High'),
  critical('Critical');

  const NestingBand(this.label);
  final String label;
}

enum RefactorPattern {
  widgetExtraction,
  mapDispatch,
  inherentAddTests,
  polymorphismOrStateMachine,
  lookupTable,
  earlyReturn,
  guardClauses,
  nullObject,
  extractMethod,
  none,
}

enum AntiPattern {
  deepNesting('nesting depth >= 4'),
  longFunction('over 80 non-blank lines'),
  tooManyParams('more than 4 parameters'),
  booleanSelector('boolean parameter selects behaviour'),
  emptyCatch('empty catch with no explanatory comment');

  const AntiPattern(this.label);
  final String label;
}

/// Return types that mark a unit as building a widget tree.
const Set<String> kWidgetReturnTypes = {
  'Widget',
  'Widget?',
  'List<Widget>',
  'List<Widget>?',
  'PreferredSizeWidget',
  'PreferredSizeWidget?',
  'SliverGridDelegate',
};

/// Names that signal complexity inherent to parsing or serialisation.
final RegExp _inherentNamePattern = RegExp(
  r'(parse|format|decode|encode|serial|fromJson|toJson|toMap|fromMap)',
  caseSensitive: false,
);

/// Names for which a long `??` chain is idiomatic rather than a defect.
final RegExp _idiomaticNullChainPattern = RegExp(
  r'(copyWith|fromJson|fromMap|toJson|toMap)',
  caseSensitive: false,
);

/// How a finding relates to the committed baseline.
enum BaselineStatus {
  /// Over threshold and not in the baseline — introduced by this change.
  newViolation('New'),

  /// Over threshold and scored worse than the baseline recorded.
  worsened('Worse'),

  /// Over threshold but already recorded at this score or higher. Inherited
  /// debt: reported, never gated on.
  inherited('Known'),

  /// At or under threshold.
  clean('OK'),

  /// No baseline in use.
  untracked('');

  const BaselineStatus(this.label);
  final String label;

  bool get isGateFailure =>
      this == BaselineStatus.newViolation || this == BaselineStatus.worsened;
}

class Finding {
  const Finding({
    required this.unit,
    required this.band,
    required this.nestingBand,
    required this.isWidgetTree,
    required this.antiPatterns,
    required this.pattern,
    required this.rootCause,
    required this.suggestion,
    required this.branchyClosures,
    required this.inScope,
    required this.baselineStatus,
    required this.baselineScore,
  });

  /// Whether the unit's file was touched by the change under audit. Always
  /// true when the run is not scoped to a diff.
  final bool inScope;

  final BaselineStatus baselineStatus;

  /// The score the baseline recorded, when it tracked this unit.
  final int? baselineScore;

  final UnitMetrics unit;
  final ComplexityBand band;
  final NestingBand nestingBand;
  final bool isWidgetTree;
  final Set<AntiPattern> antiPatterns;
  final RefactorPattern pattern;
  final String rootCause;
  final String suggestion;

  /// Closures whose own complexity exceeds the threshold, surfaced as
  /// sub-findings so the reader is pointed at the callback rather than the
  /// method that merely hosts it.
  final List<UnitMetrics> branchyClosures;

  int get complexity => unit.complexityInclusive;
}

class AuditResult {
  const AuditResult({
    required this.filesAudited,
    required this.filesSkippedGenerated,
    required this.parseFailures,
    required this.findings,
    required this.histogram,
    required this.totalUnits,
    required this.violationCount,
    required this.conservationMismatches,
    this.scopedFileCount,
    this.baselineInUse = false,
  });

  /// Number of changed files the run was scoped to, or null when unscoped.
  final int? scopedFileCount;

  final bool baselineInUse;

  final int filesAudited;
  final int filesSkippedGenerated;

  /// `path -> first error`. A parse failure must not read as "no complexity
  /// here" — that is a gate that passes because it broke.
  final Map<String, String> parseFailures;

  /// Sorted descending by inclusive complexity, once. Every downstream consumer
  /// is a prefix or a filtered scan of this list; nothing re-sorts.
  final List<Finding> findings;

  final Map<ComplexityBand, int> histogram;
  final int totalUnits;
  final int violationCount;

  /// Files where the sum of per-unit counts did not match an independent flat
  /// count of the whole file — i.e. unit collection has a gap.
  final List<String> conservationMismatches;
}

ComplexityBand bandFor(int complexity) {
  if (complexity <= 5) return ComplexityBand.low;
  if (complexity <= 10) return ComplexityBand.moderate;
  if (complexity <= 15) return ComplexityBand.high;
  if (complexity <= 20) return ComplexityBand.veryHigh;
  return ComplexityBand.critical;
}

NestingBand nestingBandFor(int depth) {
  if (depth <= 2) return NestingBand.acceptable;
  if (depth == 3) return NestingBand.caution;
  if (depth == 4) return NestingBand.high;
  return NestingBand.critical;
}

/// Whether a unit builds a widget tree rather than running imperative logic.
///
/// A 300-line declarative tree with 15 styling ternaries scores ~30 and lands
/// in "Critical" while containing nothing extractable. The tag does not change
/// the score — it changes the advice.
///
/// Deliberately does NOT exclude `switch`: a `switch` on a type returning
/// widgets is the canonical Flutter widget-factory shape, and excluding it
/// would blind the tag to the highest-scoring units in this repo.
bool isWidgetTree(UnitMetrics unit) {
  final returnsWidget =
      kWidgetReturnTypes.contains(unit.returnTypeSource) ||
      unit.returnTypeSource.endsWith('Widget') ||
      unit.returnTypeSource.endsWith('Widget?');
  final isBuild =
      unit.qualifiedName == 'build' || unit.qualifiedName.endsWith('.build');
  if (!returnsWidget && !isBuild) return false;

  final loops =
      unit.points[Construct.forLoop] +
      unit.points[Construct.whileLoop] +
      unit.points[Construct.doWhile];
  return loops == 0 &&
      unit.points[Construct.catchClause] == 0 &&
      !unit.hasAwaitInOwnBody;
}

Set<AntiPattern> antiPatternsFor(UnitMetrics unit) {
  return {
    if (unit.nestingDepth >= 4) AntiPattern.deepNesting,
    if (unit.locNonBlank > 80) AntiPattern.longFunction,
    if (unit.parameterCount > 4) AntiPattern.tooManyParams,
    if (unit.hasBooleanSelectorParam) AntiPattern.booleanSelector,
    if (unit.hasEmptyCatch) AntiPattern.emptyCatch,
  };
}

/// Picks a refactoring pattern from the construct mix. Ordered table, first
/// match wins — the order encodes which root cause dominates when several
/// predicates would fire.
RefactorPattern selectPattern(
  UnitMetrics unit,
  bool widgetTree,
  int threshold,
) {
  final p = unit.points;

  // 1. A widget tree has no imperative logic to extract, so this must pre-empt
  //    every other rule.
  if (widgetTree) {
    final dispatching =
        p[Construct.caseLabel] + p[Construct.switchExpressionArm] >= 3 ||
        p[Construct.ifStatement] >= 5;
    return dispatching
        ? RefactorPattern.mapDispatch
        : RefactorPattern.widgetExtraction;
  }

  // 2. Complexity inherent to the domain: a parser or serialiser is branchy
  //    because the format is. The spec says to say so and ask for tests.
  final looksInherent =
      _inherentNamePattern.hasMatch(unit.qualifiedName) ||
      unit.path.contains('/utils/');
  if (looksInherent &&
      p[Construct.caseLabel] + p[Construct.ifStatement] >= 8 &&
      unit.nestingDepth <= 3) {
    return RefactorPattern.inherentAddTests;
  }

  // 3. Long dispatch on a type or state.
  if (p[Construct.caseLabel] >= 5 || p[Construct.switchExpressionArm] >= 5) {
    return RefactorPattern.polymorphismOrStateMachine;
  }

  // 4. A flat chain of independent equality tests — the shape a Map replaces.
  //    The &&/|| ceiling separates repeated `if (x == A)` from compound
  //    predicates, and the depth ceiling separates it from rule 5.
  if (p[Construct.ifStatement] >= 6 &&
      p[Construct.logicalAnd] + p[Construct.logicalOr] <=
          p[Construct.ifStatement] ~/ 2 &&
      unit.nestingDepth <= 2) {
    return RefactorPattern.lookupTable;
  }

  // 5. Deep nesting from sequential validation. Ordered before guard clauses
  //    because at depth >= 4 flattening is the dominant win.
  if (unit.nestingDepth >= 4 && p[Construct.catchClause] == 0) {
    return RefactorPattern.earlyReturn;
  }

  // 6. Early-exit conditions mixed with core logic.
  if (p[Construct.ifStatement] >= 4 &&
      unit.nestingDepth <= 3 &&
      (unit.hasAwaitInOwnBody || p[Construct.catchClause] > 0)) {
    return RefactorPattern.guardClauses;
  }

  // 7. Null-check chains.
  final nullish = p[Construct.nullAware] + p[Construct.ifNull];
  if (unit.complexityInclusive > 1 &&
      nullish * 2 >= unit.complexityInclusive - 1) {
    return RefactorPattern.nullObject;
  }

  // 8. General decomposition.
  if (unit.locNonBlank > 80 || unit.complexitySelf > threshold) {
    return RefactorPattern.extractMethod;
  }

  return RefactorPattern.none;
}

/// A template, not prose: the top two constructs plus depth.
String rootCauseFor(UnitMetrics unit) {
  final top = unit.points.nonZero.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final dominant = top
      .take(2)
      .map((e) => '`${e.key.label}`(${e.value})')
      .join(' and ');
  final total = unit.points.total;
  if (dominant.isEmpty) {
    return 'No decision points; complexity comes from the unit itself.';
  }
  return '$total decision points, dominated by $dominant, '
      'at nesting depth ${unit.nestingDepth}.';
}

/// The concrete refactoring advice. Every branch states the expected complexity
/// of the result, per the spec's Step 5.
String suggestionFor(
  UnitMetrics unit,
  RefactorPattern pattern,
  int threshold,
) {
  final p = unit.points;
  final buffer = StringBuffer();

  switch (pattern) {
    case RefactorPattern.mapDispatch:
      final arms =
          p[Construct.caseLabel] + p[Construct.switchExpressionArm];
      final perArm = arms == 0
          ? unit.complexityInclusive
          : 1 + (unit.points.total - arms) ~/ arms;
      buffer.write(
        'Type-dispatch widget factory, not branching logic. Replace the '
        'dispatch with a `Map<Enum, Widget Function(...)>` built once as a '
        '`static final`, or move each arm onto the type itself via a sealed '
        'hierarchy or an extension. Expected complexity per entry: ~$perArm.',
      );
    case RefactorPattern.widgetExtraction:
      final pres = p.presentational;
      buffer.write(
        'Complexity is presentational: $pres of ${unit.points.total} decision '
        'points are `?:`/`??`/`?.`/collection-`if`. Extract the conditional '
        'subtrees into named `StatelessWidget`s, or lift the styling ternaries '
        'into one computed value above the `return`. Do not extract methods '
        'returning `Widget` — that moves the score without improving '
        'readability or rebuild scope.',
      );
    case RefactorPattern.inherentAddTests:
      buffer.write(
        'Complexity is inherent to the format being parsed or serialised, not '
        'a structural defect. Add table-driven unit tests covering each branch '
        'rather than restructuring. Expected complexity: unchanged.',
      );
    case RefactorPattern.polymorphismOrStateMachine:
      final arms =
          p[Construct.caseLabel] + p[Construct.switchExpressionArm];
      final perArm = arms == 0 ? unit.complexityInclusive : 1 + (
        (unit.points.total - arms) ~/ arms
      );
      buffer.write(
        'A $arms-way dispatch on a type or state. Move each arm behind a '
        'sealed class or an explicit state machine so the branch disappears '
        'into dispatch. Expected complexity per arm: ~$perArm.',
      );
    case RefactorPattern.lookupTable:
      buffer.write(
        'A flat chain of ${p[Construct.ifStatement]} independent equality '
        'tests. Replace with a `Map` from key to value or handler, built once. '
        'Expected complexity: ~2.',
      );
    case RefactorPattern.earlyReturn:
      buffer.write(
        'Deep nesting (depth ${unit.nestingDepth}) from sequential '
        'validation. Invert each condition and return early so the happy path '
        'stays at the top level. Complexity is unchanged; expected nesting '
        'depth: <= 2.',
      );
    case RefactorPattern.guardClauses:
      buffer.write(
        'Early-exit conditions mixed with core logic. Hoist the '
        '${p[Construct.ifStatement]} precondition checks into guard clauses at '
        'the top, then extract the remaining body. Expected complexity: '
        '<= ${(unit.complexitySelf / 2).ceil()} per unit.',
      );
    case RefactorPattern.nullObject:
      final idiomatic = _idiomaticNullChainPattern.hasMatch(
        unit.qualifiedName,
      );
      if (idiomatic) {
        buffer.write(
          'The score is a chain of `??`/`?.` defaults, which is idiomatic for '
          'this kind of method rather than a defect. No refactor recommended — '
          'the metric is counting null-awareness, not branching.',
        );
      } else {
        buffer.write(
          'Repeated null handling: '
          '${p[Construct.nullAware] + p[Construct.ifNull]} of '
          '${unit.points.total} decision points are `?.`/`??`. Resolve nullity '
          'once at the boundary — a non-nullable local, or a null-object '
          'default — so the body does not re-test it. Expected complexity: '
          '~${unit.complexityInclusive - p[Construct.nullAware]}.',
        );
      }
    case RefactorPattern.extractMethod:
      buffer.write(
        'One unit doing several distinct things across ${unit.locNonBlank} '
        'lines. Split along the responsibility boundary, not to reduce line '
        'count. Expected complexity: '
        '~${(unit.complexitySelf / 2).ceil()} per unit.',
      );
    case RefactorPattern.none:
      buffer.write(
        'Complexity is distributed; no single structural pattern dominates. '
        'Review the breakdown above and split along a visible responsibility '
        'boundary, otherwise add tests covering each branch.',
      );
  }

  // Overrides that adjust the advice without changing the pattern.
  if (unit.complexitySelf <= threshold &&
      unit.complexityInclusive > threshold) {
    final delta = unit.complexityInclusive - unit.complexitySelf;
    buffer.write(
      '\n\n    Note: the named body scores only ${unit.complexitySelf}; '
      '$delta decision points sit inside closures. The refactor target is the '
      'callback, not this method.',
    );
  }
  if (unit.hasEmptyCatch) {
    buffer.write(
      '\n\n    Note: contains an empty `catch` with no explanatory comment. '
      'Either handle the error or comment why it is safe to swallow.',
    );
  }

  return buffer.toString();
}

Finding buildFinding(
  UnitMetrics unit,
  int threshold, {
  bool inScope = true,
  Baseline? baseline,
}) {
  final widgetTree = isWidgetTree(unit);
  final pattern = selectPattern(unit, widgetTree, threshold);

  final BaselineStatus status;
  final int? recorded;
  if (baseline == null) {
    status = BaselineStatus.untracked;
    recorded = null;
  } else {
    recorded = baseline.scoreFor(unit);
    if (unit.complexityInclusive <= threshold) {
      status = BaselineStatus.clean;
    } else if (recorded == null) {
      status = BaselineStatus.newViolation;
    } else if (unit.complexityInclusive > recorded) {
      status = BaselineStatus.worsened;
    } else {
      status = BaselineStatus.inherited;
    }
  }

  return Finding(
    unit: unit,
    band: bandFor(unit.complexityInclusive),
    nestingBand: nestingBandFor(unit.nestingDepth),
    isWidgetTree: widgetTree,
    antiPatterns: antiPatternsFor(unit),
    pattern: pattern,
    rootCause: rootCauseFor(unit),
    suggestion: suggestionFor(unit, pattern, threshold),
    branchyClosures: unit.closures
        .where((c) => c.complexitySelf > threshold)
        .toList(growable: false),
    inScope: inScope,
    baselineStatus: status,
    baselineScore: recorded,
  );
}
