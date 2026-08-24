import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';

import 'diary_health_check.dart';
import 'diary_health_report.dart';

/// Runs [DiaryHealthCheck] against everything currently stored on-device and
/// surfaces the result without any UI
///
/// This has no screen of its own — it's meant to be triggered from an
/// existing app lifecycle hook (e.g. cold start / resume) so the diary
/// schedule stays "in check" continuously, rather than something a
/// participant or support person has to run by hand.
class DiaryHealthMonitor {
  final DiaryHealthCheck _checker;
  final DiaryHealthReport _reporter;
  final List<DiaryModel> Function() _loadDiaries;
  final List<StudyModel> Function() _loadStudies;

  DiaryHealthMonitor({
    DiaryHealthCheck checker = const DiaryHealthCheck(),
    DiaryHealthReport reporter = const DiaryHealthReport(),
    List<DiaryModel> Function()? loadDiaries,
    List<StudyModel> Function()? loadStudies,
  })  : _checker = checker,
        _reporter = reporter,
        _loadDiaries = loadDiaries ?? (() => DiaryRepository().getAllDiaries()),
        _loadStudies = loadStudies ?? (() => DiaryRepository().getAllStudies());

  /// The evaluation step, with no IO — takes what's already been loaded and
  /// runs every rule, so it can be unit-tested without touching ObjectBox.
  List<DiaryHealthIssue> evaluate(
      List<DiaryModel> diaries, List<StudyModel> studies) {
    final studiesById = {for (final study in studies) study.studyId: study};
    return _checker.checkAll(diaries, studiesById: studiesById);
  }

  /// Loads everything currently on-device, evaluates it, and — only when
  /// issues are found — logs a breadcrumb and writes a report file.
  ///
  /// Never throws: this is a background diagnostic, not a participant-facing
  /// feature, so a failure here must not affect the rest of the app.
  Future<List<DiaryHealthIssue>> run({Map<String, String>? metadata}) async {
    try {
      final issues = evaluate(_loadDiaries(), _loadStudies());
      if (issues.isEmpty) return issues;

      final counts = <HealthSeverity, int>{
        for (final severity in HealthSeverity.values) severity: 0,
      };
      for (final issue in issues) {
        counts[issue.severity] = counts[issue.severity]! + 1;
      }

      await CrashlyticsService().log(
          'DiaryHealthMonitor: ${issues.length} issue(s) found '
          '(critical: ${counts[HealthSeverity.critical]}, '
          'warning: ${counts[HealthSeverity.warning]}, '
          'info: ${counts[HealthSeverity.info]})');

      await _reporter.writeToFile(issues, metadata: metadata);

      return issues;
    } catch (e, stackTrace) {
      await CrashlyticsService().recordError(e, stackTrace,
          reason: 'DiaryHealthMonitor failed to run');
      return [];
    }
  }
}
