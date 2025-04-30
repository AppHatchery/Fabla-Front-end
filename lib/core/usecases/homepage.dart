import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';

final allMediaTypes = [
  ResponseType.audio,
  ResponseType.textAudio,
  ResponseType.image,
  ResponseType.video,
  ResponseType.imageVideo
];

String determineDiaryIcon(DiaryModel diary) {
  final responseTypes = diary.prompts
      .where((p) => p.responseType != null)
      .map((p) => p.responseType!)
      .toSet();

  final hasAudio = responseTypes.contains(ResponseType.audio) ||
      responseTypes.contains(ResponseType.textAudio);

  final hasCamera = responseTypes.contains(ResponseType.image) ||
      responseTypes.contains(ResponseType.video) ||
      responseTypes.contains(ResponseType.imageVideo);

  final hasTimer = responseTypes.contains(ResponseType.timer);

  // Doesn’t have audio/video/timer questions
  if (!hasAudio && !hasCamera && !hasTimer) {
    return "assets/images/icons/survey.png";
  }

  // has audio question(s), doesn’t have video/timer questions.
  // if (hasAudio && !hasCamera && !hasTimer) {
  //   return "assets/images/icons/survey.png";
  // }

  // has question(s) requires camera usage, doesn’t have audio/timer questions.
  if (hasCamera && !hasAudio && !hasTimer) {
    return "assets/images/icons/camera.png";
  }

  // has timer question(s), doesn’t have video/audio questions.
  if (hasTimer && !hasAudio && !hasCamera) {
    return "assets/images/icons/timer.png";
  }

  return "assets/images/icons/mic.png";
}

/// Asynchronous method to load and organize Diary objects for display on the home screen.
/// This function initiates the loading process of Diary objects and their organization for display on the home screen.
///
/// Order:
/// 1.  first due comes first
/// 2. if there are more than one entries due at the same time, display the new ones on top.
/// 3. if there are more than one entries due at the same time and opens at the same time, display in orders of: audio diary, survey diary, video diary, timer diary
List<DiaryModel> prioritySort(List<DiaryModel> diaries) {
  final now = DateTime.now();

  return List<DiaryModel>.from(diaries)
    ..sort((a, b) {
      // Determine priority category for each diary (0=high, 1=medium, 2=low)
      final aPriority = getPriorityCategory(a, now);
      final bPriority = getPriorityCategory(b, now);

      // If different categories, sort by category
      if (aPriority != bPriority) {
        return aPriority - bPriority;
      }

      if (aPriority == 0) {
        // High priority: sort by due date
        return a.due.compareTo(b.due);
      } else {
        // Medium and low: sort by start date
        return a.start.compareTo(b.start);
      }
    });
}

// Helper method for _prioritySort to determine priority category
int getPriorityCategory(DiaryModel diary, DateTime now) {
  if (diary.start.isBefore(now) && diary.due.isAfter(now)) {
    return 0; // High priority
  } else if (diary.start.isAfter(now) && diary.due.isAfter(now)) {
    return 1; // Medium priority
  } else {
    return 2; // Low priority
  }
}
