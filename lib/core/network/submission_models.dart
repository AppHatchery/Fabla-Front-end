import 'package:flutter/foundation.dart';

class FileData {
  String localDirectory;
  String awsS3Directory;

  FileData({required this.localDirectory, required this.awsS3Directory});
}

///Class representing audio entry in the dynamo db once an object is created
///
class PromptEntry {
  /// Sent as [reference] for a recording whose file was gone at upload. The
  /// row still shows the prompt was answered; S3 gets nothing for it.
  static const missingFileReference = 'null';

  String participantID;
  String experimentCode;
  String questionTitle;
  String diaryID;
  String promptID;
  String diaryName;
  String study;
  String response;
  String respondedAt;
  String questionsType;
  bool required;
  String transcript;
  String reference;

  PromptEntry({
    required this.participantID,
    required this.experimentCode,
    required this.questionTitle,
    required this.diaryID,
    required this.promptID,
    required this.diaryName,
    required this.study,
    required this.response,
    required this.respondedAt,
    required this.questionsType,
    required this.required,
    this.transcript = "",
    this.reference = "",
  });

  static List<Map<String, dynamic>> promptListToMap(
      List<PromptEntry> promptEntryList) {
    List<Map<String, dynamic>> items = [];

    for (var entry in promptEntryList) {
      Map<String, dynamic> map = {
        "ParticipantID": entry.participantID,
        "ExperimentCode": entry.experimentCode,
        "QuestionTitle": entry.questionTitle,
        "DiaryID": entry.diaryID,
        "PromptID": entry.promptID,
        "DiaryName": entry.diaryName,
        "Study": entry.study,
        "Response": entry.response,
        "RespondedAt": entry.respondedAt,
        "QuestionsType": entry.questionsType,
        "Required": entry.required.toString(),
        "Transcript": entry.transcript,
        "Reference": entry.reference,
        "Environment": kDebugMode ? "Dev" : "Prod"
      };
      items.add(map);
    }

    return items;
  }
}
