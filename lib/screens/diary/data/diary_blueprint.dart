import 'package:audio_diaries_flutter/screens/diary/data/question.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/formatter.dart';

/// The blueprint for a diary, containing all the necessary information to create a diary.
class DiaryBlueprint {
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int frequency;
  final List<int> activeDays;
  final int entries;
  // final reminders;
  final List<QuestionModel> questions;

  DiaryBlueprint({
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.frequency,
    required this.activeDays,
    required this.entries,
    // required this.reminders,
    required this.questions,
  });

  factory DiaryBlueprint.fromJson(Map<String, dynamic> json) {
    return DiaryBlueprint(
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      startTime: timeOfDayFromString(json['start_time']),
      endTime: timeOfDayFromString(json['end_time']),
      frequency: json['frequency'],
      activeDays: List<int>.from(json['active_days']),
      entries: json['entries'],
      // reminders: json['reminders'],
      questions: (json['questions'] as List<dynamic>)
          .map<QuestionModel>((e) => QuestionModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toString(),
      'end_date': endDate.toString(),
      'start_time': "${startTime.hour}:${startTime.minute}",
      'end_time': "${endTime.hour}:${endTime.minute}",
      'frequency': frequency,
      'active_days': activeDays,
      'entries': entries,
      // 'reminders': reminders,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }
}
