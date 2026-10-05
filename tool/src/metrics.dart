/// Cyclomatic complexity measurement over a Dart AST.
///
/// This library holds the metric core. It has no `dart:io`, no markdown and no
/// knowledge of thresholds — it turns source text into raw numbers so the
/// counting rules can be tested from string fixtures with no filesystem.
///
/// Counting rules come from `.claude/agents/Cyclonmatic-complex-audit.md`.
library;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

/// Where a source file sits relative to the audit.
enum CodeCategory { production, test, generated }

/// The decision-point constructs we count, in report order.
enum Construct {
  ifStatement('if'),
  collectionIf('collection-if'),
  forLoop('for'),
  collectionFor('collection-for'),
  whileLoop('while'),
  doWhile('do-while'),
  caseLabel('case'),
  switchExpressionArm('switch-arm'),
  whenGuard('when'),
  catchClause('catch'),
  ternary('?:'),
  ifNull('??'),
  logicalAnd('&&'),
  logicalOr('||'),
  nullAware('?.'),
  patternOr('pattern-||'),
  patternAnd('pattern-&&');

  const Construct(this.label);

  /// How the construct is named in the report.
  final String label;
}

/// Constructs that are presentational rather than imperative control flow.
///
/// Used to explain why a widget-building method scores high.
const Set<Construct> kPresentationalConstructs = {
  Construct.ternary,
  Construct.ifNull,
  Construct.nullAware,
  Construct.collectionIf,
};

/// Per-construct tallies for one executable unit.
class DecisionPoints {
  DecisionPoints();

  final Map<Construct, int> _counts = <Construct, int>{};

  void bump(Construct c) => _counts[c] = (_counts[c] ?? 0) + 1;

  int operator [](Construct c) => _counts[c] ?? 0;

  int get total => _counts.values.fold(0, (a, b) => a + b);

  void addAll(DecisionPoints other) {
    other._counts.forEach((k, v) => _counts[k] = (_counts[k] ?? 0) + v);
  }

  /// Non-zero counts in enum declaration order.
  ///
  /// Iterating the backing map directly would order by insertion, which varies
  /// with the shape of the file and makes the report non-deterministic.
  Iterable<MapEntry<Construct, int>> get nonZero => Construct.values
      .map((c) => MapEntry(c, this[c]))
      .where((e) => e.value > 0);

  /// How many decision points come from presentational constructs.
  int get presentational => kPresentationalConstructs.fold(
    0,
    (sum, c) => sum + this[c],
  );
}

/// One executable unit: a method, function, constructor, accessor, operator,
/// closure, or a synthetic unit holding field/library initializers.
class UnitMetrics {
  const UnitMetrics({
    required this.path,
    required this.qualifiedName,
    required this.startLine,
    required this.endLine,
    required this.locNonBlank,
    required this.category,
    required this.complexityInclusive,
    required this.complexitySelf,
    required this.nestingDepth,
    required this.points,
    required this.selfPoints,
    required this.returnTypeSource,
    required this.parameterCount,
    required this.hasAwaitInOwnBody,
    required this.hasEmptyCatch,
    required this.hasBooleanSelectorParam,
    required this.closures,
  });

  /// Repo-root-relative POSIX path, e.g. `lib/services/route_service.dart`.
  final String path;

  /// `RouteService.navigate`, `Foo.get bar`, `Foo.<initializers>`,
  /// `Foo.nav.<closure@L412>`.
  final String qualifiedName;

  final int startLine;
  final int endLine;
  final int locNonBlank;
  final CodeCategory category;

  /// Closures folded in. This is the metric `--threshold` gates on: in Flutter
  /// the branching lives in `itemBuilder`/`builder`/`onPressed`, so a `build()`
  /// hosting ten branchy callbacks must not score 1.
  final int complexityInclusive;

  /// Closures excluded — distinguishes "this method branches" from "this method
  /// hosts branchy callbacks".
  final int complexitySelf;

  /// Maximum nesting over the unit's own body, and over each closure's own body
  /// measured independently (a closure body resets the counter to 0).
  ///
  /// Counting closure nesting cumulatively would report depth 6 for a
  /// `LayoutBuilder` > `GestureDetector` > `LayoutBuilder` widget tree that has
  /// no imperative nesting at all.
  final int nestingDepth;

  /// Inclusive per-construct counts.
  final DecisionPoints points;

  /// Own-body per-construct counts, closures excluded.
  final DecisionPoints selfPoints;

  /// Source text of the return type annotation, or `''` when absent.
  final String returnTypeSource;

  final int parameterCount;
  final bool hasAwaitInOwnBody;

  /// A `catch` with no statements and no explanatory comment.
  final bool hasEmptyCatch;

  /// A `bool` parameter that selects behaviour, e.g. `doSomething(bool fast)`.
  final bool hasBooleanSelectorParam;

  /// Nested closures, at any depth, scored on their own bodies.
  final List<UnitMetrics> closures;

  bool get isSynthetic => qualifiedName.contains('<initializers>');

  bool get isClosure => qualifiedName.contains('<closure@');
}

/// The result of measuring one file.
class FileMetrics {
  const FileMetrics({
    required this.path,
    required this.units,
    required this.parseErrors,
    required this.totalDecisionPoints,
  });

  final String path;

  /// Named units only. Closures hang off their parent's [UnitMetrics.closures].
  final List<UnitMetrics> units;

  final List<String> parseErrors;

  /// Every decision point in the file, counted by an independent flat walk.
  ///
  /// The conservation test asserts this equals the sum of self-counts across
  /// all collected units. A mismatch means unit collection has a gap — a
  /// branchy field initializer or local function that never made it into the
  /// report. This is the single most valuable check in the suite, because the
  /// failure it catches is silent.
  final int totalDecisionPoints;
}

/// Parses [source] and measures every executable unit in it.
FileMetrics analyzeSource(
  String source,
  String relPath, {
  CodeCategory category = CodeCategory.production,
}) {
  final result = parseString(
    content: source,
    path: relPath,
    featureSet: FeatureSet.latestLanguageVersion(),
    throwIfDiagnostics: false,
  );

  final errors = result.errors
      .map(
        (e) =>
            '${result.lineInfo.getLocation(e.offset).lineNumber}: ${e.message}',
      )
      .toList(growable: false);

  final collector = _UnitCollector(
    path: relPath,
    category: category,
    lineInfo: result.lineInfo,
    source: source,
  );
  result.unit.accept(collector);

  final flat = _FlatCounter();
  result.unit.accept(flat);

  return FileMetrics(
    path: relPath,
    units: collector.units,
    parseErrors: errors,
    totalDecisionPoints: flat.count,
  );
}

/// Line numbers of every non-blank line in [source] within `[start, end]`.
int _countNonBlankLines(List<String> lines, int startLine, int endLine) {
  var count = 0;
  for (var i = startLine; i <= endLine && i <= lines.length; i++) {
    if (lines[i - 1].trim().isNotEmpty) count++;
  }
  return count;
}

/// Walks a declaration's body and tallies decision points, nesting and flags.
///
/// One instance measures one unit's own body. Nested [FunctionExpression]s are
/// handed to a fresh instance and are never walked by this one — see the
/// double-counting note in [visitFunctionExpression].
class _BodyVisitor extends RecursiveAstVisitor<void> {
  _BodyVisitor({
    required this.path,
    required this.category,
    required this.lineInfo,
    required this.lines,
    required this.parentName,
  });

  final String path;
  final CodeCategory category;
  final LineInfo lineInfo;
  final List<String> lines;
  final String parentName;

  final DecisionPoints points = DecisionPoints();
  final List<UnitMetrics> closures = <UnitMetrics>[];

  int _depth = 0;
  int maxDepth = 0;
  bool hasAwait = false;
  bool hasEmptyCatch = false;

  /// Decision points contributed by nested closures.
  ///
  /// [closures] is already flattened to every depth, so this sums each
  /// closure's OWN body. Summing `complexityInclusive` instead would count a
  /// doubly-nested closure once through its parent and again directly — the
  /// same silent doubling that walking a closure body twice would cause.
  int get closureDecisionPoints =>
      closures.fold(0, (sum, c) => sum + c.selfPoints.total);

  void _nest(void Function() body) {
    _depth++;
    if (_depth > maxDepth) maxDepth = _depth;
    body();
    _depth--;
  }

  // ---------------------------------------------------------------- branches

  @override
  void visitIfStatement(IfStatement node) {
    points.bump(Construct.ifStatement);
    node.expression.accept(this);
    // `if (x case P when g)`: the pattern and guard are decisions too, and a
    // closure in the guard is a unit of its own.
    node.caseClause?.accept(this);
    _nest(() => node.thenStatement.accept(this));

    final elseStatement = node.elseStatement;
    if (elseStatement == null) return;
    if (elseStatement is IfStatement) {
      // An `else if` chain is a sequence of siblings, not a ladder. Nesting it
      // would report depth 10 for the ~10-arm chain in core/utils/formatter.dart
      // and drown every genuinely nested function in the ranking.
      elseStatement.accept(this);
    } else {
      _nest(() => elseStatement.accept(this));
    }
  }

  @override
  void visitIfElement(IfElement node) {
    points.bump(Construct.collectionIf);
    super.visitIfElement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    points.bump(Construct.forLoop);
    _nest(() => super.visitForStatement(node));
  }

  @override
  void visitForElement(ForElement node) {
    points.bump(Construct.collectionFor);
    super.visitForElement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    points.bump(Construct.whileLoop);
    _nest(() => super.visitWhileStatement(node));
  }

  @override
  void visitDoStatement(DoStatement node) {
    points.bump(Construct.doWhile);
    _nest(() => super.visitDoStatement(node));
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _nest(() => super.visitSwitchStatement(node));
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    // Stacked labels (`case A: case B: body`) are separate SwitchCase nodes, so
    // each counts — matching the spec's "each `case` label".
    points.bump(Construct.caseLabel);
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    points.bump(Construct.caseLabel);
    super.visitSwitchPatternCase(node);
  }

  // `visitSwitchDefault` is deliberately not overridden: `default:` is the
  // fall-through, not a decision.

  @override
  void visitSwitchExpression(SwitchExpression node) {
    _nest(() => super.visitSwitchExpression(node));
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    // A `_` wildcard arm is the default arm and is not a decision.
    if (node.guardedPattern.pattern is! WildcardPattern) {
      points.bump(Construct.switchExpressionArm);
    }
    super.visitSwitchExpressionCase(node);
  }

  @override
  void visitWhenClause(WhenClause node) {
    // Counted on top of its arm — the spec lists them as separate rows.
    points.bump(Construct.whenGuard);
    super.visitWhenClause(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    // `try` and `finally` are not decisions, but they do nest.
    _nest(() {
      node.body.accept(this);
      node.finallyBlock?.accept(this);
    });
    for (final clause in node.catchClauses) {
      clause.accept(this);
    }
  }

  @override
  void visitCatchClause(CatchClause node) {
    points.bump(Construct.catchClause);
    if (node.body.statements.isEmpty && !_hasComment(node.body.rightBracket)) {
      hasEmptyCatch = true;
    }
    _nest(() => super.visitCatchClause(node));
  }

  @override
  void visitLogicalOrPattern(LogicalOrPattern node) {
    // A genuine alternative branch, distinct from the `||` operator.
    points.bump(Construct.patternOr);
    super.visitLogicalOrPattern(node);
  }

  @override
  void visitLogicalAndPattern(LogicalAndPattern node) {
    points.bump(Construct.patternAnd);
    super.visitLogicalAndPattern(node);
  }

  // ------------------------------------------------------------- expressions

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    points.bump(Construct.ternary);
    super.visitConditionalExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    switch (node.operator.type) {
      case TokenType.QUESTION_QUESTION:
        points.bump(Construct.ifNull);
      case TokenType.AMPERSAND_AMPERSAND:
        points.bump(Construct.logicalAnd);
      case TokenType.BAR_BAR:
        points.bump(Construct.logicalOr);
      default:
        break;
    }
    super.visitBinaryExpression(node);
  }

  // `??=` is an AssignmentExpression, never a BinaryExpression, so it is not
  // counted here — which is what the spec asks for. Nothing to override.

  // Null-aware access spans four node types and only the node carrying the
  // operator may count: `a?.b.c` is nested PropertyAccess where just the outer
  // one is null-aware. Checking a subtree for a `?` token double-counts;
  // checking one node type misses three quarters of the sites.

  // A cascade section's `isNullAware` reports the *cascade's* flag rather than
  // an operator of its own, so `a?..b()..c()` would count three null checks
  // where the language performs one. The CascadeExpression counts it; the
  // sections defer.

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.isNullAware && !node.isCascaded) points.bump(Construct.nullAware);
    super.visitMethodInvocation(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.isNullAware && !node.isCascaded) points.bump(Construct.nullAware);
    super.visitPropertyAccess(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    if (node.isNullAware && !node.isCascaded) points.bump(Construct.nullAware);
    super.visitIndexExpression(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    if (node.isNullAware) points.bump(Construct.nullAware);
    super.visitCascadeExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    hasAwait = true;
    super.visitAwaitExpression(node);
  }

  // ------------------------------------------------------------- exclusions

  @override
  void visitAssertStatement(AssertStatement node) {
    // Debug-only. Descending would leak any `&&` in the condition into the
    // score.
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {}

  // ---------------------------------------------------------------- closures

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Measured by a fresh visitor, then deliberately NOT walked here.
    // `super.visitFunctionExpression` would walk the body a second time and
    // silently double every score inside closures.
    final closure = _measureClosure(node);
    closures.add(closure);
    closures.addAll(closure.closures);
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    // A named local function is a closure by another name.
    final closure = _measureClosure(
      node.functionDeclaration.functionExpression,
      name: node.functionDeclaration.name.lexeme,
    );
    closures.add(closure);
    closures.addAll(closure.closures);
  }

  UnitMetrics _measureClosure(FunctionExpression node, {String? name}) {
    final start = lineInfo.getLocation(node.offset).lineNumber;
    final end = lineInfo.getLocation(node.end).lineNumber;
    final inner = _BodyVisitor(
      path: path,
      category: category,
      lineInfo: lineInfo,
      lines: lines,
      parentName: parentName,
    );
    node.body.accept(inner);

    final label = name == null ? '<closure@L$start>' : '$name()@L$start';
    return UnitMetrics(
      path: path,
      qualifiedName: '$parentName.$label',
      startLine: start,
      endLine: end,
      locNonBlank: _countNonBlankLines(lines, start, end),
      category: category,
      complexityInclusive:
          1 + inner.points.total + inner.closureDecisionPoints,
      complexitySelf: 1 + inner.points.total,
      nestingDepth: inner.effectiveDepth,
      points: inner.inclusivePoints,
      selfPoints: inner.points,
      returnTypeSource: '',
      parameterCount: node.parameters?.parameters.length ?? 0,
      hasAwaitInOwnBody: inner.hasAwait,
      hasEmptyCatch: inner.hasEmptyCatch,
      hasBooleanSelectorParam: false,
      closures: inner.closures,
    );
  }

  /// Own-body depth, or a nested closure's own depth, whichever is deeper.
  int get effectiveDepth {
    var deepest = maxDepth;
    for (final c in closures) {
      if (c.nestingDepth > deepest) deepest = c.nestingDepth;
    }
    return deepest;
  }

  /// Inclusive per-construct counts: this body plus every nested closure.
  DecisionPoints get inclusivePoints {
    final merged = DecisionPoints()..addAll(points);
    for (final c in closures) {
      merged.addAll(c.selfPoints);
    }
    return merged;
  }

  bool _hasComment(Token token) => token.precedingComments != null;
}

/// Counts every decision point in a subtree, flat, ignoring unit boundaries.
///
/// The independent side of the conservation test.
class _FlatCounter extends RecursiveAstVisitor<void> {
  int count = 0;

  @override
  void visitIfStatement(IfStatement node) {
    count++;
    super.visitIfStatement(node);
  }

  @override
  void visitIfElement(IfElement node) {
    count++;
    super.visitIfElement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    count++;
    super.visitForStatement(node);
  }

  @override
  void visitForElement(ForElement node) {
    count++;
    super.visitForElement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    count++;
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    count++;
    super.visitDoStatement(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    count++;
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    count++;
    super.visitSwitchPatternCase(node);
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    if (node.guardedPattern.pattern is! WildcardPattern) count++;
    super.visitSwitchExpressionCase(node);
  }

  @override
  void visitWhenClause(WhenClause node) {
    count++;
    super.visitWhenClause(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    count++;
    super.visitCatchClause(node);
  }

  @override
  void visitLogicalOrPattern(LogicalOrPattern node) {
    count++;
    super.visitLogicalOrPattern(node);
  }

  @override
  void visitLogicalAndPattern(LogicalAndPattern node) {
    count++;
    super.visitLogicalAndPattern(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    count++;
    super.visitConditionalExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final t = node.operator.type;
    if (t == TokenType.QUESTION_QUESTION ||
        t == TokenType.AMPERSAND_AMPERSAND ||
        t == TokenType.BAR_BAR) {
      count++;
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.isNullAware && !node.isCascaded) count++;
    super.visitMethodInvocation(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.isNullAware && !node.isCascaded) count++;
    super.visitPropertyAccess(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    if (node.isNullAware && !node.isCascaded) count++;
    super.visitIndexExpression(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    if (node.isNullAware) count++;
    super.visitCascadeExpression(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {}

  @override
  void visitAssertInitializer(AssertInitializer node) {}
}

/// Walks a compilation unit and emits one [UnitMetrics] per named unit.
class _UnitCollector extends RecursiveAstVisitor<void> {
  _UnitCollector({
    required this.path,
    required this.category,
    required this.lineInfo,
    required String source,
  }) : lines = source.split('\n');

  final String path;
  final CodeCategory category;
  final LineInfo lineInfo;
  final List<String> lines;

  final List<UnitMetrics> units = <UnitMetrics>[];

  String _enclosing = '';

  @override
  void visitClassDeclaration(ClassDeclaration node) =>
      _withScope(node.name.lexeme, node, node.members);

  @override
  void visitMixinDeclaration(MixinDeclaration node) =>
      _withScope(node.name.lexeme, node, node.members);

  @override
  void visitEnumDeclaration(EnumDeclaration node) =>
      _withScope(node.name.lexeme, node, node.members);

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) => _withScope(
    node.name?.lexeme ?? 'extension@${_line(node.offset)}',
    node,
    node.members,
  );

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) =>
      _withScope(node.name.lexeme, node, node.members);

  void _withScope(
    String name,
    AstNode node,
    List<ClassMember> members,
  ) {
    final previous = _enclosing;
    _enclosing = name;
    _collectInitializers(node, members, '$name.<initializers>');
    for (final member in members) {
      member.accept(this);
    }
    _enclosing = previous;
  }

  /// Field initializers live outside every method, so a branchy
  /// `final x = a ?? b;` would otherwise vanish from the audit entirely.
  void _collectInitializers(
    AstNode owner,
    List<AstNode> members,
    String name,
  ) {
    final fields = members.whereType<FieldDeclaration>().toList();
    if (fields.isEmpty) return;

    final visitor = _body(name);
    for (final field in fields) {
      for (final v in field.fields.variables) {
        v.initializer?.accept(visitor);
      }
    }
    if (visitor.points.total == 0 && visitor.closures.isEmpty) return;

    _emit(
      name: name,
      node: fields.first,
      endNode: fields.last,
      visitor: visitor,
      returnType: '',
      parameterCount: 0,
      hasBooleanSelector: false,
    );
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final owner = _enclosing.isEmpty ? '' : '$_enclosing.';
    final String name;
    if (node.isGetter) {
      name = '${owner}get ${node.name.lexeme}';
    } else if (node.isSetter) {
      name = '${owner}set ${node.name.lexeme}';
    } else if (node.isOperator) {
      name = '${owner}operator ${node.name.lexeme}';
    } else {
      name = '$owner${node.name.lexeme}';
    }

    final visitor = _body(name);
    node.body.accept(visitor);
    _emit(
      name: name,
      node: node,
      endNode: node,
      visitor: visitor,
      returnType: node.returnType?.toSource() ?? '',
      parameterCount: node.parameters?.parameters.length ?? 0,
      hasBooleanSelector: _hasBooleanSelector(node.parameters),
    );
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Nested functions are handled as closures by _BodyVisitor; only top-level
    // declarations reach here.
    if (node.parent is! CompilationUnit) return;

    final base = node.name.lexeme;
    final String name;
    if (node.isGetter) {
      name = 'get $base';
    } else if (node.isSetter) {
      name = 'set $base';
    } else {
      name = base;
    }

    final visitor = _body(name);
    node.functionExpression.body.accept(visitor);
    _emit(
      name: name,
      node: node,
      endNode: node,
      visitor: visitor,
      returnType: node.returnType?.toSource() ?? '',
      parameterCount:
          node.functionExpression.parameters?.parameters.length ?? 0,
      hasBooleanSelector:
          _hasBooleanSelector(node.functionExpression.parameters),
    );
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final base = node.name == null
        ? _enclosing
        : '$_enclosing.${node.name!.lexeme}';
    final name = node.name == null ? '$_enclosing.$_enclosing' : base;

    final visitor = _body(name);
    // The initializer list is real code: `: x = a ?? b` is a branch.
    // AssertInitializer is skipped by the visitor itself.
    for (final initializer in node.initializers) {
      initializer.accept(visitor);
    }
    node.body.accept(visitor);

    _emit(
      name: name,
      node: node,
      endNode: node,
      visitor: visitor,
      returnType: '',
      parameterCount: node.parameters.parameters.length,
      hasBooleanSelector: _hasBooleanSelector(node.parameters),
    );
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    const name = '<library initializers>';
    final visitor = _body(name);
    for (final v in node.variables.variables) {
      v.initializer?.accept(visitor);
    }
    if (visitor.points.total == 0 && visitor.closures.isEmpty) return;

    _emit(
      name: name,
      node: node,
      endNode: node,
      visitor: visitor,
      returnType: '',
      parameterCount: 0,
      hasBooleanSelector: false,
    );
  }

  _BodyVisitor _body(String parentName) => _BodyVisitor(
    path: path,
    category: category,
    lineInfo: lineInfo,
    lines: lines,
    parentName: parentName,
  );

  void _emit({
    required String name,
    required AstNode node,
    required AstNode endNode,
    required _BodyVisitor visitor,
    required String returnType,
    required int parameterCount,
    required bool hasBooleanSelector,
  }) {
    final start = _line(node.offset);
    final end = _line(endNode.end);
    units.add(
      UnitMetrics(
        path: path,
        qualifiedName: name,
        startLine: start,
        endLine: end,
        locNonBlank: _countNonBlankLines(lines, start, end),
        category: category,
        complexityInclusive:
            1 + visitor.points.total + visitor.closureDecisionPoints,
        complexitySelf: 1 + visitor.points.total,
        nestingDepth: visitor.effectiveDepth,
        points: visitor.inclusivePoints,
        selfPoints: visitor.points,
        returnTypeSource: returnType,
        parameterCount: parameterCount,
        hasAwaitInOwnBody: visitor.hasAwait,
        hasEmptyCatch: visitor.hasEmptyCatch,
        hasBooleanSelectorParam: hasBooleanSelector,
        closures: visitor.closures,
      ),
    );
  }

  int _line(int offset) => lineInfo.getLocation(offset).lineNumber;

  bool _hasBooleanSelector(FormalParameterList? params) {
    if (params == null) return false;
    for (final p in params.parameters) {
      final inner = p is DefaultFormalParameter ? p.parameter : p;
      if (inner is SimpleFormalParameter && inner.type?.toSource() == 'bool') {
        return true;
      }
    }
    return false;
  }
}
