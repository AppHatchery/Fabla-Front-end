import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/notification.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:rive/rive.dart';

extension _TextExtension on Artboard {
  TextValueRun? textRun(String name) => component<TextValueRun>(name);
}

// Extension to handle PromptModel comparison
extension PromptModelComparison on PromptModel {
  // Compares two prompts while ignoring the ID field
  bool isEffectivelyEqual(PromptModel other) {
    // Compare basic properties
    final sameBasics = question == other.question &&
        required == other.required &&
        subtitle == other.subtitle &&
        responseType == other.responseType;

    // Compare options if they exist
    final sameOptions = (option == null && other.option == null) ||
        (option != null &&
            other.option != null &&
            option!.toString() == other.option!.toString());

    return sameBasics && sameOptions;
  }
}

// Extension to handle Notification comparison
extension NotificationComparison on Notification {
  bool isEffectivelyEqual(Notification other) {
    return title == other.title &&
        body == other.body &&
        date.isAtSameMomentAs(other.date);
  }
}

// Extension on DiaryModel to handle equality comparison
extension DiaryModelComparison on DiaryModel {
  // Returns true if two diaries are effectively the same, ignoring IDs
  bool isEffectivelyEqual(DiaryModel other) {
    // Compare core diary properties
    final sameTimeFrame = start.isAtSameMomentAs(other.start) &&
        end.isAtSameMomentAs(other.end) &&
        due.isAtSameMomentAs(other.due);

    final sameStructure = entries == other.entries &&
        name == other.name &&
        studyID == other.studyID;

    // Compare prompts (order matters)
    final samePrompts = prompts.length == other.prompts.length &&
        List.generate(prompts.length, (i) {
          return prompts[i].isEffectivelyEqual(other.prompts[i]);
        }).every((equal) => equal);

    // Compare notifications (order matters for scheduled notifications)
    final sameNotifications =
        notifications.length == other.notifications.length &&
            List.generate(notifications.length, (i) {
              return notifications[i]
                  .isEffectivelyEqual(other.notifications[i]);
            }).every((equal) => equal);

    return sameTimeFrame && sameStructure && samePrompts && sameNotifications;
  }
}
