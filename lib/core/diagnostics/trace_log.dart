import 'dart:convert';
import 'dart:developer' as dev;

import '../../services/developer_mode_service.dart';
import '../../services/preference_service.dart';
import 'debug_trace.dart';

/// A failed [DebugTrace], flattened so it can be stored and listed.
class TraceRecord {
  /// When the failure happened.
  final DateTime time;
  final String operation;

  /// The step the root failure happened at, and why.
  final String step;
  final String reason;

  /// The diary being submitted, if the trace recorded one.
  final String? diary;
  final bool simulated;

  /// [DebugTrace.toReport], for the detail view and copying.
  final String report;

  const TraceRecord({
    required this.time,
    required this.operation,
    required this.step,
    required this.reason,
    this.diary,
    this.simulated = false,
    required this.report,
  });

  factory TraceRecord.fromTrace(DebugTrace trace) {
    final root = trace.rootFailure;
    return TraceRecord(
      time: root?.time ?? trace.startedAt,
      operation: trace.operation,
      step: root?.step ?? trace.currentStep,
      reason: root?.message ?? 'Unknown',
      diary: trace.context['Diary'],
      simulated: DeveloperModeService.isSimulated(trace),
      report: trace.toReport(),
    );
  }

  factory TraceRecord.fromJson(Map<String, dynamic> json) => TraceRecord(
        time: DateTime.parse(json['time'] as String),
        operation: json['operation'] as String,
        step: json['step'] as String,
        reason: json['reason'] as String,
        diary: json['diary'] as String?,
        simulated: json['simulated'] as bool? ?? false,
        report: json['report'] as String,
      );

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'operation': operation,
        'step': step,
        'reason': reason,
        if (diary != null) 'diary': diary,
        'simulated': simulated,
        'report': report,
      };
}

/// The most recent failed traces, kept on the device so developer mode can
/// show failures from before it was turned on, or from an earlier session.
///
/// Recorded for every participant but never sent anywhere. Traces hold
/// metadata only (see [DebugTrace]), and the log lives in shared preferences,
/// so leaving the study clears it.
///
/// Usage example:
/// ```dart
/// await TraceLog().add(trace);
/// final records = await TraceLog().load(); // newest first
/// ```
class TraceLog {
  static final TraceLog _instance = TraceLog._internal();
  factory TraceLog() => _instance;
  TraceLog._internal();

  static const String preferenceKey = 'debug_trace_log';

  /// Oldest records are dropped beyond this, to bound storage.
  static const int maxRecords = 20;

  final PreferenceService _preferences = PreferenceService();

  /// The write in flight, if any. Writes are serialized so two failures
  /// close together both land.
  Future<void>? _pending;

  /// Stored records, newest first. Unreadable entries are skipped.
  Future<List<TraceRecord>> load() async {
    await _pending;
    return _read();
  }

  /// Stores [trace] if it failed. Never throws: losing a log entry must not
  /// affect the submission it describes.
  Future<void> add(DebugTrace trace) {
    if (!trace.hasFailed) return Future.value();
    return _enqueue(() async {
      try {
        final records = [TraceRecord.fromTrace(trace), ...await _read()];
        await _write(records.take(maxRecords));
      } catch (e) {
        dev.log('Could not store trace: $e', name: 'TraceLog');
      }
    });
  }

  Future<void> clear() =>
      _enqueue(() => _preferences.removePreference(key: preferenceKey));

  /// Runs [write] after any write in flight. Only a running write is held, so
  /// nothing waits on a future from an earlier, finished zone (e.g. a test).
  Future<void> _enqueue(Future<void> Function() write) {
    final previous = _pending;
    late final Future<void> current;
    current = () async {
      await previous;
      await write();
    }()
        .whenComplete(() {
      if (identical(_pending, current)) _pending = null;
    });
    return _pending = current;
  }

  Future<List<TraceRecord>> _read() async {
    final stored =
        await _preferences.getStringListPreference(key: preferenceKey) ?? [];
    final records = <TraceRecord>[];
    for (final entry in stored) {
      try {
        records.add(
            TraceRecord.fromJson(jsonDecode(entry) as Map<String, dynamic>));
      } catch (_) {
        // A record from an incompatible version; drop it.
      }
    }
    return records;
  }

  Future<void> _write(Iterable<TraceRecord> records) =>
      _preferences.setStringListPreference(
        key: preferenceKey,
        value: records.map((r) => jsonEncode(r.toJson())).toList(),
      );
}
