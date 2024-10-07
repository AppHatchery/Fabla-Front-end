import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary_blueprint.dart';
import 'package:audio_diaries_flutter/screens/diary/data/options.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/prompt_entity.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';

import '../screens/diary/domain/entities/diary_entity.dart';
import '../screens/diary/domain/repository/diary_repository.dart';

final preference = PreferenceService();
final setupRepository = SetupRepository();
final diaryRepository = DiaryRepository();

final DateTime today =
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
final DateTime firstDayMonth = DateTime(today.year, today.month, 1);
final DateTime lastDayMonth = DateTime(today.year, today.month + 1, 0);

/// TODO: Create description
Future<void> diaryInit(String code) async {
  final protocol = setupRepository.getProtocol();

  if (protocol == null) {
    setupRepository.createProtocol();

    return;
  } else {
    // Check if there is no diaries or if there is less than a week of diaries left
    final dateString =
        await preference.getStringPreference(key: "last_daily_diary_day") ?? "";
    final lastDay = DateTime.tryParse(dateString);

    // Only create diaries if there are no diaries or if there are less than a week of diaries left
    if (lastDay == null || lastDay.difference(today).inDays <= 7) {
      // Cycle through the diary blueprints
      for (final blueprint in protocol.diaryBlueprints) {
        final List<PromptModel> prompts = [];

        /// Making the prompts
        for (var question in blueprint.questions) {
          prompts.add(PromptModel(
            question: question.title,
            responseType: question.responseType,
            option: Options(
                type: optionTypeFromResponse(question.responseType),
                choices: question.options,
                minValue: question.min,
                maxValue: question.max,
                defaultValue: question.defaultValue),
            required: question.required,
            subtitle: question.subtitle,
          ));
        }

        // Create the diaries with the start being today or the last day the diaries were created
        // final diaries = makeDiariesTwo(
        //     // start: lastDay ?? today, blueprint: blueprint, prompts: prompts);
        //     start: today,
        //     blueprint: blueprint,
        //     prompts: prompts);
        final diaries =
            makeDiariesThree(blueprint: blueprint, prompts: prompts);

        // Save the diaries
        final entities = diaries.map((model) {
          final prompts =
              model.prompts.map((prompt) => Prompt.fromModel(prompt)).toList();

          final entity = Diary.fromModel(model);
          entity.prompts.addAll(prompts);

          return entity;
        }).toList();
        diaryRepository.addDiaries(entities);
      }
    }
  }
}
// LEGACY CODE
// List<DiaryModel> makeDiaries(
//     DiaryBlueprint blueprint, List<PromptModel> prompts) {
//   final List<DiaryModel> diaries = [];
//   final List<Map<String, DateTime>> dates = [];

//   DateTime currentDate = firstDayMonth;

//   for (var i = 0; i < lastDayMonth.day; i++) {
//     final DateTime endOfDay = currentDate.add(Duration(
//         days: (blueprint.activeDays.length / blueprint.frequency).round() - 1));

//     //Add active days to diary

//     print("Currrent Date: $currentDate");
//     print(
//         "Currrent Date is before end: ${currentDate.isBefore(blueprint.endDate)}");
//     print("Active days: ${blueprint.activeDays}");
//     print(
//         "Currrent Date is in active days: ${blueprint.activeDays.contains(currentDate.weekday)} - the weekday is ${currentDate.weekday}");
//     // print("Endddd Date: $endOfDay");
//     // print(
//     //     "Does it contain???: ${blueprint.activeDays.contains(endOfDay.weekday)} |  ${endOfDay.isBefore(lastDayMonth)} | ${endOfDay.isBefore(blueprint.endDate)}");

//     if (blueprint.activeDays.contains(currentDate.weekday) &&
//         // currentDate.isAfter(blueprint.startDate) &&
//         currentDate.isBefore(blueprint.endDate)) {
//       final isBefore = endOfDay.isBefore(lastDayMonth) &&
//           endOfDay.isBefore(blueprint.endDate);

//       dates.add({
//         'start': DateTime(currentDate.year, currentDate.month, currentDate.day,
//             blueprint.startTime.hour, blueprint.startTime.minute),
//         'end': isBefore
//             ? DateTime(endOfDay.year, endOfDay.month, endOfDay.day,
//                 blueprint.endTime.hour, blueprint.endTime.minute)
//             : DateTime(
//                 currentDate.year, currentDate.month, currentDate.day, 23, 59)
//       });
//     }

//     // if (blueprint.activeDays.contains(currentDate.weekday) &&
//     //     endOfDay.isBefore(lastDayMonth) &&
//     //     endOfDay.isBefore(blueprint.endDate)) {
//     //   dates.add({
//     //     'start': DateTime(currentDate.year, currentDate.month, currentDate.day,
//     //         blueprint.startTime.hour, blueprint.startTime.minute),
//     //     'end': blueprint.activeDays.contains(endOfDay.weekday)
//     //         ? DateTime(endOfDay.year, endOfDay.month, endOfDay.day,
//     //             blueprint.endTime.hour, blueprint.endTime.minute)
//     //         : DateTime(
//     //             currentDate.year, currentDate.month, currentDate.day, 23, 59)
//     //   });
//     // }
//     currentDate = endOfDay;
//   }

//   for (var date in dates) {
//     final diary = DiaryModel(
//         id: 0,
//         prompts: prompts,
//         start: date['start']!,
//         end: date['end']!,
//         due: date['end']!,
//         entries: blueprint.entries,
//         status: DiaryStatus.idle,
//         tags: []);

//     diaries.add(diary);
//   }

//   diaries.forEach((element) {
//     print("Start: ${element.start}");
//     print("End: ${element.end}");
//   });
//   return diaries;
// }

/// Making diaries on a four week basis
List<DiaryModel> makeDiariesTwo(
    {required DateTime start,
    required DiaryBlueprint blueprint,
    required List<PromptModel> prompts}) {
  final monday = start.subtract(
      Duration(days: today.weekday - 1)); // Getting the start of the week

  final List<DiaryModel> diaries = [];

  // Get the current weeks monday or if the start date is after the current week, get the start date
  DateTime currentDate = monday.isAfter(blueprint.startDate)
      ? monday
      : blueprint
          .startDate; // Get the monday of the week or the start of the study

  // Calculate the date 4 weeks later
  // We'll use this to save in shared preference as the last date of the diary creation
  DateTime fourWeeksLater = currentDate
      .add(const Duration(days: 28)); // Get the date 4 weeks later - 4 * 7days

  // Check if the end date is before the 4 weeks later date and set the end date to the 4 weeks later date or the end date of the study
  DateTime endRange = fourWeeksLater.isBefore(blueprint.endDate) ||
          fourWeeksLater.isAtSameMomentAs(blueprint.endDate)
      ? fourWeeksLater
      : blueprint.endDate;

  // Loop through the weeks
  while (currentDate.isBefore(endRange) ||
      currentDate.isAtSameMomentAs(endRange)) {
    final DateTime endOfWeek = currentDate.add(const Duration(
        days: 6)); // Used to get the end of the week and jump to next week

    final start = DateTime(currentDate.year, currentDate.month, currentDate.day,
        blueprint.startTime.hour, blueprint.startTime.minute);

    if (blueprint.activeDays.contains(start.weekday)) {
      // check how many days to add to the end of the diary from the blueprint frequency
      final int daysToAdd = (blueprint.activeDays.length / blueprint.frequency)
          .round(); // Get the number of days to add to the end of the diary

      // Get the possible end date of the diary
      // Checking if the proposed end date is before the end date of the study
      final possibleEnd = blueprint.endDate.isBefore(DateTime(
                      currentDate.year,
                      currentDate.month,
                      currentDate.day,
                      blueprint.endTime.hour,
                      blueprint.endTime.minute)
                  .add(Duration(days: daysToAdd - 1))) ||
              blueprint.endDate.isAtSameMomentAs(DateTime(
                      currentDate.year,
                      currentDate.month,
                      currentDate.day,
                      blueprint.endTime.hour,
                      blueprint.endTime.minute)
                  .add(Duration(days: daysToAdd - 1)))
          ? blueprint.endDate
          : DateTime(
                  currentDate.year, currentDate.month, currentDate.day, blueprint.endTime.hour, blueprint.endTime.minute)
              .add(Duration(days: daysToAdd - 1));
      final end = getLastPossibleActiveDay(
          currentDate, possibleEnd, blueprint.activeDays);

      final diary = DiaryModel(
          id: 0,
          studyID: 0,
          name: "Diary",
          prompts: prompts,
          start: start,
          end: end,
          due: end,
          entries: blueprint.entries,
          currentEntry: 0,
          status: DiaryStatus.idle,
          notifications: [],
          tags: []);

      diaries.add(diary);
    }

    // Jump to the next week
    currentDate = endOfWeek.add(const Duration(days: 1));
  }

  diaries.forEach((element) {
    print("Diary Start: ${element.start}");
    print("Diary End: ${element.end}");
    print("---------------------------------------");
  });

  //Saving the last diary day to shared preference
  //TODO: Define keys for other types of diaries
  preference.setStringPreference(
      key: "last_daily_diary_day", value: currentDate.toString());
  return diaries;
}

List<DiaryModel> makeDiariesThree(
    {required DiaryBlueprint blueprint, required List<PromptModel> prompts}) {
  final List<DiaryModel> diaries = [];

  DateTime currentDate =
      today.isAfter(blueprint.startDate) ? today : blueprint.startDate;

  while (currentDate.isBefore(blueprint.endDate) ||
      currentDate.isAtSameMomentAs(blueprint.endDate)) {
    final endDate = currentDate.add(Duration(days: blueprint.frequency));

    if (!endDate.isAfter(blueprint.endDate)) {
      if (blueprint.activeDays.contains(currentDate.weekday)) {
        final start = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            blueprint.startTime.hour,
            blueprint.startTime.minute);
        final end = DateTime(
            endDate.subtract(const Duration(days: 1)).year,
            endDate.subtract(const Duration(days: 1)).month,
            endDate.subtract(const Duration(days: 1)).day,
            blueprint.endTime.hour,
            blueprint.endTime.minute);
        final diary = DiaryModel(
            id: 0,
            studyID: 0,
            name: "Diary",
            prompts: prompts,
            start: start,
            end: end,
            due: end,
            entries: blueprint.entries,
            currentEntry: 0,
            status: DiaryStatus.idle,
          notifications: [],
            tags: []);

        diaries.add(diary);
      }
    }
    currentDate = endDate;
  }

  diaries.forEach((element) {
    print("Diary Start: ${element.start}");
    print("Diary End: ${element.end}");
    element.prompts.forEach((prompt) {
      print("Diary Prompts: ${prompt.question} | type: ${prompt.responseType}");
      print(
          "Diary Prompts: ${prompt.question} | options: ${prompt.option?.toJson().toString()}");
    });
    print("---------------------------------------");
  });

  return diaries;
}

/// Returns the last possible active day for a given date.
/// This function returns the last possible active day for a given date.
/// It checks if the given date is an active day and returns it if it is.
DateTime getLastPossibleActiveDay(
    DateTime current, DateTime possible, List<int> activeDays) {
  DateTime day = current;

  // If the possible date is an active day, return it
  if (activeDays.contains(possible.weekday)) {
    return possible;
  }

  // If the current date is an active day, return it
  // If the current date is not an active day, find the next active day
  while (activeDays.contains(day.weekday)) {
    final newDay = day.add(const Duration(days: 1));
    if (activeDays.contains(newDay.weekday)) {
      day = newDay;
    } else {
      break;
    }
  }

  return day;
}
