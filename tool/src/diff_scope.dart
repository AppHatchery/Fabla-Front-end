/// Which files a change actually touched.
///
/// The only part of the audit that depends on VCS state, and it is used only
/// when `--diff-base` is passed. Everything else works on a bare directory.
library;

import 'dart:io';

/// Raised when the diff base cannot be resolved.
///
/// Almost always a shallow checkout: `actions/checkout` defaults to
/// `fetch-depth: 1`, which has no merge base to diff against.
class DiffScopeException implements Exception {
  DiffScopeException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Repo-root-relative POSIX paths of the `.dart` files changed against [base].
///
/// The union of two things:
///   * `base...HEAD` (three dots) — the change's own commits measured from the
///     merge base, not everything that landed on the base branch since.
///   * the working tree, including untracked files.
///
/// In CI the working tree is clean, so the second half is a no-op. Locally it
/// is what stops the tool reporting a confident PASS on work you have not
/// committed yet.
Set<String> changedDartFiles(String base, {String? workingDirectory}) {
  final committed = _run(
    ['diff', '--name-only', '--diff-filter=d', '$base...HEAD'],
    workingDirectory,
    onError: (stderr) =>
        'Could not diff against "$base": $stderr\n'
        'A shallow checkout has no merge base — set `fetch-depth: 0` on '
        'actions/checkout, or drop --diff-base to audit everything.',
  );

  final working = _run(
    ['status', '--porcelain', '--untracked-files=all'],
    workingDirectory,
    onError: (stderr) => 'Could not read the working tree: $stderr',
  );

  final paths = <String>{};
  for (final line in committed.split('\n')) {
    _addIfDart(paths, line.trim());
  }
  for (final line in working.split('\n')) {
    if (line.length < 4) continue;
    // Porcelain v1: two status characters, a space, then the path. A rename
    // reads `R  old -> new`; only the destination exists to be audited.
    var path = line.substring(3).trim();
    final arrow = path.indexOf(' -> ');
    if (arrow != -1) path = path.substring(arrow + 4);
    _addIfDart(paths, _unquote(path));
  }
  return paths;
}

void _addIfDart(Set<String> into, String path) {
  if (path.endsWith('.dart')) into.add(path.replaceAll(r'\', '/'));
}

/// Porcelain quotes paths containing unusual characters.
String _unquote(String path) {
  if (path.length < 2 || !path.startsWith('"') || !path.endsWith('"')) {
    return path;
  }
  return path.substring(1, path.length - 1).replaceAll(r'\"', '"');
}

String _run(
  List<String> args,
  String? workingDirectory, {
  required String Function(String stderr) onError,
}) {
  final result = Process.runSync(
    'git',
    args,
    workingDirectory: workingDirectory,
  );
  if (result.exitCode != 0) {
    throw DiffScopeException(onError('${result.stderr}'.trim()));
  }
  return '${result.stdout}';
}
