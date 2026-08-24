import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'diary_health_check.dart';

/// Compiles [DiaryHealthIssue]s produced by [DiaryHealthCheck] into a single
/// human-readable report — a summary count by severity, then every issue
/// grouped by study and diary. Study/experiment-agnostic: it only ever
/// reads what's already on the issues it's given.
class DiaryHealthReport {
  const DiaryHealthReport();

  /// Builds the report body as plain text. Pure — no file IO — so it's easy
  /// to unit test and to reuse for anything other than writing a file (e.g.
  /// showing it in-app, or pasting it into a support ticket). [metadata] is
  /// printed verbatim above the summary, in insertion order — use it for
  /// context like participant ID, app version, or device info.
  String build(
    List<DiaryHealthIssue> issues, {
    DateTime? generatedAt,
    Map<String, String>? metadata,
  }) {
    final timestamp = generatedAt ?? DateTime.now();
    final buffer = StringBuffer()
      ..writeln('DIARY HEALTH REPORT')
      ..writeln('Generated: ${timestamp.toIso8601String()}');

    if (metadata != null && metadata.isNotEmpty) {
      for (final entry in metadata.entries) {
        buffer.writeln('${entry.key}: ${entry.value}');
      }
    }
    buffer.writeln();


    if (issues.isEmpty) {
      buffer.writeln('No issues found across all checked diaries.');
      return buffer.toString();
    }

    final counts = <HealthSeverity, int>{
      for (final severity in HealthSeverity.values) severity: 0,
    };
    for (final issue in issues) {
      counts[issue.severity] = counts[issue.severity]! + 1;
    }

    buffer.writeln('SUMMARY');
    buffer.writeln('Total issues: ${issues.length}');
    for (final severity in HealthSeverity.values) {
      buffer.writeln('  ${severity.name}: ${counts[severity]}');
    }
    buffer.writeln();

    buffer.writeln('DETAILS');
    for (final studyIssues in _groupBy(issues, (issue) => issue.studyID).values) {
      final studyID = studyIssues.first.studyID;
      final studyName = studyIssues.first.studyName;
      buffer.writeln(
          '-- ${studyName != null ? '$studyName (study $studyID)' : 'study $studyID'} --');

      for (final diaryIssues
          in _groupBy(studyIssues, (issue) => issue.diaryId).values) {
        final sorted = List<DiaryHealthIssue>.from(diaryIssues)
          ..sort((a, b) => a.severity.index.compareTo(b.severity.index));
        buffer.writeln(
            '  Diary ${sorted.first.diaryId} ("${sorted.first.diaryName}")');
        for (final issue in sorted) {
          buffer.writeln(
              '    [${issue.severity.name.toUpperCase()}] ${issue.ruleId}: ${issue.message}');
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Builds the report and writes it to a timestamped .txt file in the
  /// app's documents directory, returning the written [File].
  Future<File> writeToFile(
    List<DiaryHealthIssue> issues, {
    DateTime? generatedAt,
    Map<String, String>? metadata,
    String? fileName,
  }) async {
    final timestamp = generatedAt ?? DateTime.now();
    final report = build(issues, generatedAt: timestamp, metadata: metadata);
    final directory = await getApplicationDocumentsDirectory();
    final name = fileName ?? 'diary_health_report_${_fileTimestamp(timestamp)}.txt';
    final file = File('${directory.path}/$name');
    return file.writeAsString(report);
  }
}

Map<K, List<T>> _groupBy<T, K>(Iterable<T> items, K Function(T) keyOf) {
  final result = <K, List<T>>{};
  for (final item in items) {
    result.putIfAbsent(keyOf(item), () => []).add(item);
  }
  return result;
}

String _fileTimestamp(DateTime dateTime) {
  String pad(int value) => value.toString().padLeft(2, '0');
  return '${dateTime.year}${pad(dateTime.month)}${pad(dateTime.day)}_'
      '${pad(dateTime.hour)}${pad(dateTime.minute)}${pad(dateTime.second)}';
}
