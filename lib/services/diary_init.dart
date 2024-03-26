import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary_blueprint.dart';
import 'package:audio_diaries_flutter/screens/diary/data/options.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';

import '../core/utils/dummy_data.dart';
import '../screens/diary/domain/entities/diary_entity.dart';
import '../screens/diary/domain/repository/diary_repository.dart';

final DateTime firstDayMonth =
    DateTime(DateTime.now().year, DateTime.now().month, 1);
final DateTime lastDayMonth =
    DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

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
  final repository = SetupRepository();
  final protocol = repository.getProtocol();

  if (protocol == null) {
    repository.createProtocol();

    return;
  } else {
    // calculate days for the month

    // calculate the start of the week
    // final DateTime startWeek = firstDayMonth.subtract(
    //   Duration(days: firstDayMonth.weekday - 1),
    // );

    // check the start of the week and the end of the week

    for (final blueprint in protocol.diaryBlueprints) {
      final List<PromptModel> prompts = [];

      /// Making the prompts
      for (var question in blueprint.questions) {
        prompts.add(PromptModel(
          question: question.title,
          responseType: question.responseType,
          option: Options(type: OptionsType.multiple), //Change this
          required: question.required,
          subtitle: question.subtitle,
        ));
      }

      final diaries = makeDiaries(blueprint, prompts);

      // Save the diaries
    }
  }
}

List<DiaryModel> makeDiaries(
    DiaryBlueprint blueprint, List<PromptModel> prompts) {
  final List<DiaryModel> diaries = [];
  final List<Map<String, DateTime>> dates = [];

  DateTime currentDate = firstDayMonth;

  for (var i = 0; i < lastDayMonth.day; i++) {
    final DateTime endOfDay = currentDate.add(Duration(
        days: (blueprint.activeDays.length / blueprint.frequency).round() - 1));

    //Add active days to diary 

    print("Currrent Date: $currentDate");
    print(
        "Currrent Date is before end: ${currentDate.isBefore(blueprint.endDate)}");
    print("Active days: ${blueprint.activeDays}");
    print(
        "Currrent Date is in active days: ${blueprint.activeDays.contains(currentDate.weekday)} - the weekday is ${currentDate.weekday}");
    // print("Endddd Date: $endOfDay");
    // print(
    //     "Does it contain???: ${blueprint.activeDays.contains(endOfDay.weekday)} |  ${endOfDay.isBefore(lastDayMonth)} | ${endOfDay.isBefore(blueprint.endDate)}");

    if (blueprint.activeDays.contains(currentDate.weekday) &&
        // currentDate.isAfter(blueprint.startDate) &&
        currentDate.isBefore(blueprint.endDate)) {
      final isBefore = endOfDay.isBefore(lastDayMonth) &&
          endOfDay.isBefore(blueprint.endDate);

      dates.add({
        'start': DateTime(currentDate.year, currentDate.month, currentDate.day,
            blueprint.startTime.hour, blueprint.startTime.minute),
        'end': isBefore
            ? DateTime(endOfDay.year, endOfDay.month, endOfDay.day,
                blueprint.endTime.hour, blueprint.endTime.minute)
            : DateTime(
                currentDate.year, currentDate.month, currentDate.day, 23, 59)
      });
    }

    // if (blueprint.activeDays.contains(currentDate.weekday) &&
    //     endOfDay.isBefore(lastDayMonth) &&
    //     endOfDay.isBefore(blueprint.endDate)) {
    //   dates.add({
    //     'start': DateTime(currentDate.year, currentDate.month, currentDate.day,
    //         blueprint.startTime.hour, blueprint.startTime.minute),
    //     'end': blueprint.activeDays.contains(endOfDay.weekday)
    //         ? DateTime(endOfDay.year, endOfDay.month, endOfDay.day,
    //             blueprint.endTime.hour, blueprint.endTime.minute)
    //         : DateTime(
    //             currentDate.year, currentDate.month, currentDate.day, 23, 59)
    //   });
    // }
    currentDate = endOfDay;
  }

  for (var date in dates) {
    final diary = DiaryModel(
        id: 0,
        prompts: prompts,
        start: date['start']!,
        end: date['end']!,
        due: date['end']!,
        entries: blueprint.entries,
        status: DiaryStatus.idle,
        tags: []);

    diaries.add(diary);
  }

  diaries.forEach((element) {
    print("Start: ${element.start}");
    print("End: ${element.end}");
  });
  return diaries;
}
