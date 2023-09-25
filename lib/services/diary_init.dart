import 'package:audio_diaries_flutter/services/preference_service.dart';

import '../core/utils/dummy_data.dart';
import '../core/utils/statuses.dart';
import '../screens/diary/domain/entities/diary_entity.dart';
import '../screens/diary/domain/repository/diary_repository.dart';

/// Initializes diary data if it is the first time the application is launched.
/// This asynchronous function initializes diary data in case it is the first time the application is launched.
/// It checks whether the application is being launched for the first time using the 'isFirstTime' flag from SharedPreferences.
/// If it's the first time, the function sets the flag to false and creates DiaryEntity instances with predefined prompts and due dates.
/// These DiaryEntity instances are added to the repository using `repository.addDiaries(diaries)`.
///
/// Note:
/// The function utilizes SharedPreferences to determine if the application is being launched for the first time.
/// It initializes diary data with predefined prompts and due dates to simulate initial data setup.
///
/// Returns:
/// A Future indicating that the operation may be asynchronous and requires awaiting.
///
Future<void> diaryInit(String code) async {
  final bool isFirstTime =
      await PreferenceService().getBoolPreference(key: 'isFirstTime') ?? true;

  if (isFirstTime) {
    PreferenceService().setBoolPreference(key: 'isFirstTime', value: false);

    final repository = DiaryRepository();
    final start = startDate(code);
    print('start: $start');
    final diaries = <DiaryEntity>[];

    if (start != null) {
    for (var i = 0; i + 1 < fakePrompts.length; i ++) {
      final date = start.add(Duration(days: i));
      final deadline = DateTime(date.year, date.month, date.day);
      final diary = DiaryEntity(
          prompts: [i], due: deadline, deadline: deadline.toString(), status: DiaryStatus.idle);
        diaries.add(diary);

    }
      repository.addDiaries(diaries);
      PreferenceService().setIntPreference(key: 'startDate', value: start.millisecondsSinceEpoch);
  }
 }
}

DateTime? startDate(String code) {
  final today = DateTime.now();
  final nextSunday = today.add(Duration(days: 7 - today.weekday));

  // Assuming that the code have two distinct starting digits
  if (code.startsWith('1')) {
    return DateTime(nextSunday.year, nextSunday.month, nextSunday.day);
  } else if (code.startsWith('2')) {
    final saturday = nextSunday.add(const Duration(days: 6));
    return DateTime(saturday.year, saturday.month, saturday.day);
  }

  return null;
}
