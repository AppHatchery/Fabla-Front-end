import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/developer_mode_service.dart';
import '../../services/notification_service.dart';
import '../../services/preference_service.dart';
import '../usecases/time_travel.dart';
import '../utils/app_clock.dart';
import '../utils/device_appInfo.dart';
import '../utils/statuses.dart';
import 'local_data.dart';
import 'trace_log.dart';

/// One file for the study team describing this device's state: app and
/// device, the participant's stored protocol and diaries, the pending queue,
/// recent failed submissions and the last network sweep.
///
/// Metadata only, like [LocalData]: no answers, transcripts or audio. It
/// does include the participant ID, as the support email does, so the team
/// knows whose device it is.
///
/// Usage example:
/// ```dart
/// final file = await DiagnosticsBundle.write();
/// await DiagnosticsBundle.share(file);
/// ```
class DiagnosticsBundle {
  DiagnosticsBundle._();

  static const String lastSweepKey = 'developer_last_network_sweep';

  /// Diaries starting this many days either side of the app date are
  /// included in full; the rest only as one-line rows.
  static const int recentDaysBefore = 14;
  static const int recentDaysAfter = 7;

  /// Keeps [report] so the next bundle can include it.
  static Future<void> rememberSweep(Map<String, dynamic> report) async {
    try {
      await PreferenceService().setStringPreference(
        key: lastSweepKey,
        value: jsonEncode({
          'ran_at': DateTime.now().toIso8601String(),
          'report': report,
        }),
      );
    } catch (_) {
      // Not worth failing the sweep over.
    }
  }

  /// Gathers everything and returns the bundle. Each section that fails is
  /// replaced with its error, so one broken source never loses the rest.
  static Future<Map<String, dynamic>> collect() async {
    final developerMode = DeveloperModeService();
    final preferences = PreferenceService();

    Future<Object?> section(Future<Object?> Function() read) async {
      try {
        return await read();
      } catch (e) {
        return {'error': '$e'};
      }
    }

    final appDate = AppClock.now();
    final data = await LocalData.read(
      withPrompts: (d) =>
          _inFull(d.status ?? DiaryStatus.idle, d.start, appDate),
    );

    return build(
      generatedAt: DateTime.now(),
      appDate: appDate,
      data: data,
      app: await section(() async {
        final info = await PackageInfo.fromPlatform();
        return {
          'version': info.version,
          'build': info.buildNumber,
          'platform': defaultTargetPlatform.name,
          'debug_build': kDebugMode,
        };
      }),
      device: await section(() async => {
            'model': await getDeviceInfo(),
            'low_storage': await checkLowStorage(),
            'low_battery': await checkLowBattery(),
            'permissions': {
              'microphone': (await Permission.microphone.status).name,
              'notifications': (await Permission.notification.status).name,
              'camera': (await Permission.camera.status).name,
            },
          }),
      developer: await section(() async => {
            'skip_connectivity_check':
                developerMode.skipConnectivityCheck.value,
            'armed_failure': developerMode.simulatedFailure.value.name,
            'time_travel_minutes': developerMode.timeTravel.value.inMinutes,
            'time_travel_snapshot': await TimeTravel().hasSnapshot(),
          }),
      studyDates: await section(() async => {
            'date_joined':
                await preferences.getStringPreference(key: 'date_joined'),
            'last_updated':
                await preferences.getStringPreference(key: 'last_Updated'),
            'network_error_flag':
                await preferences.getBoolPreference(key: 'network_error'),
          }),
      notifications: await section(() async {
        final scheduled = await NotificationService.getScheduledNotifications();
        return {'scheduled': scheduled.length};
      }),
      failures: await section(() async =>
          [for (final record in await TraceLog().load()) record.toJson()]),
      lastSweep: await section(() async {
        final stored = await preferences.getStringPreference(key: lastSweepKey);
        return stored == null ? null : jsonDecode(stored);
      }),
    );
  }

  /// Assembles the bundle from already-gathered parts. Pure, for testing.
  static Map<String, dynamic> build({
    required DateTime generatedAt,
    required DateTime appDate,
    required LocalData data,
    Object? app,
    Object? device,
    Object? developer,
    Object? studyDates,
    Object? notifications,
    Object? failures,
    Object? lastSweep,
  }) {
    return {
      'format': 'fabla-diagnostics/1',
      'generated_at': generatedAt.toIso8601String(),
      'app_date': appDate.toIso8601String(),
      'app': app,
      'device': device,
      'developer': developer,
      'participant_id': data.participantId,
      'experiment': data.experiment,
      'protocol': data.protocol,
      'study_dates': studyDates,
      'notifications': notifications,
      'studies': [
        for (final study in data.studies)
          _studySummary(study, [
            for (final d in data.diaries)
              if (d.studyID == study.id) d,
          ]),
      ],
      'status_counts': {
        for (final entry in data.statusCounts.entries)
          entry.key.name: entry.value,
      },
      'pending': [
        for (final diary in data.pending)
          {
            'id': diary.id,
            'name': diary.name,
            'entry': '${diary.currentEntry + 1}/${diary.entries}',
            'recordings': diary.recordings.length,
            'recording_bytes': diary.recordingBytes,
            'missing_recordings': diary.missingRecordings,
          },
      ],
      'diaries_recent': [
        for (final diary in data.diaries)
          if (_inFull(diary.status, diary.start, appDate)) diary.toJson(),
      ],
      // id, study, start, status, entry/entries: every row, to spot gaps.
      'diaries_all': [
        for (final d in data.diaries)
          [
            d.id,
            d.studyID,
            d.start.toIso8601String(),
            d.status.name,
            '${d.currentEntry}/${d.entries}',
          ],
      ],
      'failed_submissions': failures,
      'last_network_sweep': lastSweep,
    };
  }

  /// Whether a diary goes in `diaries_recent`: pending, in progress, or
  /// starting near [appDate].
  static bool _inFull(DiaryStatus status, DateTime start, DateTime appDate) {
    if (status == DiaryStatus.complete || status == DiaryStatus.ongoing) {
      return true;
    }
    return start.isAfter(
            appDate.subtract(const Duration(days: recentDaysBefore))) &&
        start.isBefore(appDate.add(const Duration(days: recentDaysAfter)));
  }

  static Map<String, dynamic> _studySummary(
      StudySummary study, List<DiarySummary> diaries) {
    return {
      ...study.toJson(),
      'rows': diaries.length,
      if (diaries.isNotEmpty) ...{
        'first_start': diaries.first.start.toIso8601String(),
        'last_due': diaries
            .map((d) => d.due)
            .reduce((a, b) => a.isAfter(b) ? a : b)
            .toIso8601String(),
      },
      'status_counts': {
        for (final status in DiaryStatus.values)
          if (diaries.any((d) => d.status == status))
            status.name: diaries.where((d) => d.status == status).length,
      },
    };
  }

  /// Writes the bundle to a temporary file named after the participant and
  /// time, and returns it.
  static Future<File> write() async {
    final bundle = await collect();
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final participant = bundle['participant_id'] ?? 'unknown';
    final file =
        File(p.join(dir.path, 'fabla-diagnostics-$participant-$stamp.json'));
    await file.writeAsString(const JsonEncoder.withIndent(' ').convert(bundle));
    return file;
  }

  /// Opens the share sheet for [file]. [origin] anchors the sheet on iPad.
  static Future<ShareResult> share(File file, {Rect? origin}) {
    return SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/json')],
      subject: 'Fabla diagnostics',
      sharePositionOrigin: origin,
    ));
  }
}
