import 'dart:async';
import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:intl/intl.dart';

import '../../screens/diary/domain/repository/diary_repository.dart';
import '../../services/preference_service.dart';

/// Fires a Pendo "unsubmitted entry" track event, one per diary that is
/// completed but not yet submitted, tagged with that diary's due date.
Future<void> trackUnsubmittedDiaries() async {
  try {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final lastRun = await PreferenceService().getStringPreference(
      key: 'unsubmitted_diaries_last_run',
    );

    if (lastRun == today) {
      return;
    }

    final pending = DiaryRepository()
        .getAllDiaries()
        .where((diary) => diary.status == DiaryStatus.complete);

    for (final diary in pending) {
      final dateOfEntry = DateFormat('MM/dd/yyyy').format(diary.due);

      dev.log(
        "Tracking 'unsubmitted entry', date_of_entry: $dateOfEntry",
      );

      await PendoService.track(
        'Unsubmitted Entry',
        {
          'date_of_entry': dateOfEntry,
        },
      );
    }

    await PreferenceService().setStringPreference(
      key: 'unsubmitted_diaries_last_run',
      value: today,
    );
  } catch (e, stackTrace) {
    dev.log(
      'Failed to track unsubmitted diary events',
      error: e,
      stackTrace: stackTrace,
    );
    CrashlyticsService().recordError(e, stackTrace,
        reason: 'Failed to upload pending diaries to pendo');
  }
}
