/// Errors the engine reports. None of them is ever thrown into the widget tree: the controller catches them, sets
/// its status to failed, emits [AliveFailed] and the stage shows its fallback.
library;

/// One problem in a file: where (a JSON path such as `clips.greet.tracks.body.tx[3]`), what, and how to fix it.
class AliveProblem {
  /// A problem at [path].
  const AliveProblem(this.path, this.message, [this.hint]);

  /// JSON path inside the file; empty for the file as a whole.
  final String path;

  /// What is wrong.
  final String message;

  /// How to fix it, when there is a usual fix.
  final String? hint;

  @override
  String toString() => '${path.isEmpty ? '(file)' : path}: $message${hint == null ? '' : ' ($hint)'}';
}

/// The base of every error the engine reports.
sealed class AliveError implements Exception {
  const AliveError(this.message);

  /// A readable description.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// A file was read but does not follow the alive/1 schema. [problems] lists every problem found, not only the first.
class AliveSchemaError extends AliveError {
  /// A schema error in [file].
  AliveSchemaError(this.file, this.problems) : super('$file does not follow alive/1:\n${problems.join('\n')}');

  /// The asset path of the file.
  final String file;

  /// Every problem found.
  final List<AliveProblem> problems;
}

/// A file could not be read (missing asset, not JSON).
class AliveLoadError extends AliveError {
  /// A load error for [file].
  const AliveLoadError(this.file, String message, [this.cause]) : super(message);

  /// The asset path that failed.
  final String file;

  /// The underlying exception, if any.
  final Object? cause;
}

/// Drawing a frame failed; the stage falls back and stops painting this scene.
class AliveRenderError extends AliveError {
  /// A render error with its [cause].
  const AliveRenderError(super.message, this.cause, [this.stack]);

  /// The exception thrown while painting.
  final Object cause;

  /// Where it was thrown.
  final StackTrace? stack;
}

/// The app asked for something the scene does not have (an unknown clip, state or event). Reported, then ignored.
class AliveUsageError extends AliveError {
  /// A usage error.
  const AliveUsageError(super.message);
}

/// The variant store failed to read or write; picks still work, only the memory of the last pick is lost.
class AliveStoreError extends AliveError {
  /// A store error.
  const AliveStoreError(super.message, this.cause);

  /// The underlying exception.
  final Object cause;
}
