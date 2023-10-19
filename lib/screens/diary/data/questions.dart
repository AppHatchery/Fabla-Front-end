import 'package:audio_diaries_flutter/core/utils/types.dart';

class Question {
  final QuestionType? questionType;
  final dynamic answer;
  const Question({required this.questionType, required this.answer});
}