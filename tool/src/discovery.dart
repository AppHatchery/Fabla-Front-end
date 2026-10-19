/// Source file discovery and exclusion.
///
/// The only place in the audit that reads the filesystem for input.
library;

import 'dart:io';

import 'metrics.dart' show CodeCategory;

class SourceFile {
  const SourceFile({
    required this.relPath,
    required this.absPath,
    required this.category,
  });

  /// Repo-root-relative POSIX path, e.g. `lib/services/route_service.dart`.
  final String relPath;
  final String absPath;
  final CodeCategory category;
}

/// Directories never audited, whatever `--exclude` says.
///
/// `--path` is caller-controlled on `workflow_dispatch` and can be `.`, so a
/// missing glob must not be able to make the tool walk build output.
const Set<String> kAlwaysExcludedDirs = {
  '.git',
  '.dart_tool',
  '.idea',
  '.vscode',
  'build',
  'node_modules',
  'vendor',
  'coverage',
  'ios',
  'android',
  'macos',
  'windows',
  'linux',
  'web',
  'functions',
};

/// Filename suffixes that always mark generated output.
const List<String> kGeneratedSuffixes = [
  '.g.dart',
  '.freezed.dart',
  '.gr.dart',
  '.gen.dart',
  '.mocks.dart',
  '.pb.dart',
  '.pbenum.dart',
  '.pbgrpc.dart',
  '.pbjson.dart',
  '.config.dart',
];

/// Header markers that identify generated code regardless of filename.
///
/// Belt and braces: `lib/objectbox.g.dart` is gitignored and so absent in CI,
/// but present in every local run. Header detection costs six lines and makes
/// the glob a performance optimisation rather than a correctness dependency.
///
/// Only the exact banners generators write. Looser text such as
/// `coverage:ignore-file` or "auto-generated" also appears in hand-written
/// files, and matching it would drop them from the audit without a trace.
const List<String> kGeneratedHeaders = [
  'GENERATED CODE - DO NOT MODIFY BY HAND',
  'AUTO GENERATED FILE, DO NOT EDIT',
];

class Discovery {
  Discovery({
    required this.repoRoot,
    required List<String> excludeGlobs,
  }) : _excludePatterns = excludeGlobs
           .map(globToRegExp)
           .toList(growable: false);

  final String repoRoot;

  /// Compiled once at construction. Compiling inside the walk would turn an
  /// O(files x patterns) match into O(files x patterns) regex *compiles*.
  final List<RegExp> _excludePatterns;

  /// Walks [dir] and returns every auditable `.dart` file.
  List<SourceFile> discover(String dir) {
    final root = Directory(_join(repoRoot, dir));
    if (!root.existsSync()) {
      throw FileSystemException('Audit path does not exist', root.path);
    }

    final found = <SourceFile>[];
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final rel = _relative(entity.path);
      if (_inExcludedDir(rel)) continue;
      if (_excludePatterns.any((p) => p.hasMatch(rel))) continue;

      found.add(
        SourceFile(
          relPath: rel,
          absPath: entity.path,
          category: classify(rel, entity),
        ),
      );
    }

    // listSync order is filesystem-dependent; sort so the report is identical
    // across machines and reruns.
    found.sort((a, b) => a.relPath.compareTo(b.relPath));
    return found;
  }

  /// Classifies a file as production, test or generated.
  static CodeCategory classify(String relPath, File file) {
    for (final suffix in kGeneratedSuffixes) {
      if (relPath.endsWith(suffix)) return CodeCategory.generated;
    }
    if (_hasGeneratedHeader(file)) return CodeCategory.generated;

    if (relPath.startsWith('test/') ||
        relPath.startsWith('integration_test/') ||
        relPath.endsWith('_test.dart')) {
      return CodeCategory.test;
    }
    return CodeCategory.production;
  }

  static bool _hasGeneratedHeader(File file) {
    try {
      final head = file
          .readAsLinesSync()
          .take(5)
          .join('\n');
      return kGeneratedHeaders.any(head.contains);
    } on Object {
      // Unreadable or non-UTF8: let the parse step report it properly.
      return false;
    }
  }

  bool _inExcludedDir(String relPath) =>
      relPath.split('/').any(kAlwaysExcludedDirs.contains);

  String _relative(String absPath) {
    var rel = absPath.replaceAll(r'\', '/');
    final root = repoRoot.replaceAll(r'\', '/');
    if (rel.startsWith(root)) {
      rel = rel.substring(root.length);
    }
    while (rel.startsWith('/')) {
      rel = rel.substring(1);
    }
    if (rel.startsWith('./')) rel = rel.substring(2);
    return rel;
  }

  static String _join(String a, String b) {
    if (b.startsWith('/')) return b;
    final left = a.endsWith('/') ? a.substring(0, a.length - 1) : a;
    return '$left/$b';
  }
}

/// Translates a glob to an anchored regex over repo-root-relative POSIX paths.
///
/// `**/` is optional rather than mandatory, so `**/*.g.dart` matches both
/// `lib/objectbox.g.dart` and a hypothetical `objectbox.g.dart` at the root.
/// Matching `--path`-relative paths instead would make the workflow's default
/// exclude silently miss top-level generated files.
RegExp globToRegExp(String glob) {
  final buffer = StringBuffer('^');
  var i = 0;
  while (i < glob.length) {
    final c = glob[i];
    if (c == '*') {
      final isDouble = i + 1 < glob.length && glob[i + 1] == '*';
      if (isDouble) {
        final followedBySlash = i + 2 < glob.length && glob[i + 2] == '/';
        if (followedBySlash) {
          buffer.write('(?:.*/)?');
          i += 3;
        } else {
          buffer.write('.*');
          i += 2;
        }
      } else {
        // A single `*` does not cross a path separator.
        buffer.write('[^/]*');
        i++;
      }
      continue;
    }
    if (c == '?') {
      buffer.write('[^/]');
      i++;
      continue;
    }
    buffer.write(RegExp.escape(c));
    i++;
  }
  buffer.write(r'$');
  return RegExp(buffer.toString());
}
