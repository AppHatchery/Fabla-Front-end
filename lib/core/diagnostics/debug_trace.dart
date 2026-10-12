import 'dart:async';

/// A single entry in a [DebugTrace] timeline.
class TraceEvent {
  final DateTime time;
  final String step;
  final String? message;
  final Map<String, String> data;
  final bool isFailure;
  final Object? error;
  final StackTrace? stackTrace;

  const TraceEvent({
    required this.time,
    required this.step,
    this.message,
    this.data = const {},
    this.isFailure = false,
    this.error,
    this.stackTrace,
  });
}

/// Records what happens during a critical operation (e.g. a diary
/// submission) so a failure can be pinpointed: which step failed, why, and
/// what led up to it.
///
/// A trace is bound to the operation with [run], which scopes it to a Zone.
/// Code anywhere inside that operation reports to it through [current]
/// without the trace being passed down; outside a trace, [current] is null
/// and reporting is a no-op.
///
/// Only record metadata (IDs, counts, status codes, step names). Never record
/// participant content such as audio, transcripts or survey answers.
///
/// Usage example:
/// ```dart
/// final trace = DebugTrace('diary_submission', context: {'DiaryID': '42'});
/// final ok = await trace.run(() => repository.submitDiary(diary));
///
/// // Deep inside the upload:
/// DebugTrace.current?.step('presigned_url');
/// DebugTrace.current?.fail('Presigned URL request rejected', statusCode: 403);
/// ```
class DebugTrace {
  static final Object _zoneKey = Object();

  /// Longest response body kept per event, so traces stay readable.
  static const int maxBodyLength = 500;

  final String operation;
  final DateTime startedAt;
  final Map<String, String> context;
  final List<TraceEvent> _events = [];
  String _currentStep = 'start';

  DebugTrace(this.operation, {Map<String, String>? context, DateTime? now})
      : startedAt = now ?? DateTime.now(),
        context = {...?context};

  /// The trace bound to the running operation, if any.
  static DebugTrace? get current => Zone.current[_zoneKey] as DebugTrace?;

  List<TraceEvent> get events => List.unmodifiable(_events);

  List<TraceEvent> get failures =>
      _events.where((e) => e.isFailure).toList(growable: false);

  /// The first failure recorded. Later failures are usually knock-on effects.
  TraceEvent? get rootFailure => _events.where((e) => e.isFailure).firstOrNull;

  bool get hasFailed => rootFailure != null;

  /// The most recent step entered with [step].
  String get currentStep => _currentStep;

  /// Runs [body] with this trace as [current].
  Future<T> run<T>(Future<T> Function() body) =>
      runZoned(body, zoneValues: {_zoneKey: this});

  /// Marks the start of [name]; failures without an explicit step are
  /// attributed to it.
  void step(String name, {String? message, Map<String, String>? data}) {
    _currentStep = name;
    _events.add(TraceEvent(
      time: DateTime.now(),
      step: name,
      message: message,
      data: {...?data},
    ));
  }

  /// Records a failure at [step] (defaults to [currentStep]).
  void fail(
    String reason, {
    String? step,
    int? statusCode,
    String? responseBody,
    Object? error,
    StackTrace? stackTrace,
    Map<String, String>? data,
  }) {
    _events.add(TraceEvent(
      time: DateTime.now(),
      step: step ?? _currentStep,
      message: reason,
      isFailure: true,
      error: error,
      stackTrace: stackTrace,
      data: {
        if (statusCode != null) 'status': statusCode.toString(),
        if (responseBody != null) 'response': _truncate(responseBody),
        if (error != null) 'error': '${error.runtimeType}: $error',
        ...?data,
      },
    ));
  }

  /// A plain-text report for copying into bug reports.
  String toReport() {
    final buffer = StringBuffer()
      ..writeln('Fabla debug trace: $operation')
      ..writeln('Started: ${startedAt.toIso8601String()}');

    final root = rootFailure;
    if (root != null) {
      buffer
        ..writeln()
        ..writeln('FAILED at: ${root.step}')
        ..writeln('Reason: ${root.message}');
      root.data.forEach((k, v) => buffer.writeln('$k: $v'));
    }

    if (context.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Context:');
      context.forEach((k, v) => buffer.writeln('  $k: $v'));
    }

    buffer
      ..writeln()
      ..writeln('Timeline:');
    for (final event in _events) {
      final offset = event.time.difference(startedAt).inMilliseconds;
      buffer.write('  +${offset}ms ${event.isFailure ? 'FAIL' : 'step'} '
          '${event.step}');
      if (event.message != null) buffer.write(' — ${event.message}');
      buffer.writeln();
      event.data.forEach((k, v) => buffer.writeln('      $k: $v'));
    }

    if (root?.stackTrace != null) {
      buffer
        ..writeln()
        ..writeln('Stack trace:')
        ..writeln(root!.stackTrace.toString().trimRight());
    }

    return buffer.toString().trimRight();
  }

  static String _truncate(String value) => value.length <= maxBodyLength
      ? value
      : '${value.substring(0, maxBodyLength)}… (${value.length} chars)';
}
