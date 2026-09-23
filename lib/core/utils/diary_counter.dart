import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:intl/intl.dart';

import '../../screens/diary/domain/repository/diary_repository.dart';

/// Fires a Pendo "unsubmitted entry" track event, one per diary that is
/// completed but not yet submitted, tagged with that diary's due date.
Future<void> trackUnsubmittedDiaries() async {
  final pending = DiaryRepository()
      .getAllDiaries()
      .where((diary) => diary.status == DiaryStatus.complete);

  for (final diary in pending) {
    dev.log("'unsubmitted entry', 'date_of_entry: ${DateFormat('MM/dd/yyyy').format(diary.due)}");
    await PendoService.track('unsubmitted entry', {
      'date_of_entry': DateFormat('MM/dd/yyyy').format(diary.due),
    });
  }
}
