import 'dart:convert';
import 'dart:io';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../utils/formatter.dart';
import 'secrets_handler.dart';

/// Uploads audio files associated with a diary to an S3 storage and returns the result.
///
/// This function prepares a list of audio files from the provided [diary]
/// object, including the associated prompts and recordings. It then proceeds
/// to upload these audio files to an S3 storage destination using the
/// [uploadFilesToS3] function. The function returns a boolean value indicating
/// the success or failure of the upload process. It is typically used to handle
/// the uploading of audio files for diary entries and to check the upload result.
///
/// Parameters:
/// - [diary]: The diary object containing prompts and associated recordings.
/// - [studycode]: The study code to be used as the S3 storage destination.
///
/// Returns:
/// - `true` if all audio files were successfully uploaded.
/// - `false` if any part of the upload process failed.
///
/// Example usage:
/// ```dart
/// Diary myDiary = ... // Initialize your diary object.
/// bool uploadResult = await upload(myDiary); // Upload audio files and check result.
/// if (uploadResult) {
///   // Handle successful upload.
/// } else {
///   // Handle upload failure.
/// }
/// ```
Future<bool> upload(String participantID, DiaryModel diary) async {
  final dir = await getApplicationDocumentsDirectory();
  final repository = SetupRepository();
  final experiment = repository.getExperiment();

  try {
    final promptEntryList = <PromptEntry>[];
    final audioDataList = <AudioData>[];

    int promptNumber = 0;

    for (final prompt in diary.prompts) {
      if (prompt.answer == null) continue;

      promptNumber++;

      if (prompt.responseType == ResponseType.recording &&
          prompt.answer!.recordings.isNotEmpty) {
        _addAudioData(experiment.login, prompt, participantID, diary, dir,
            promptNumber, audioDataList);
      } else {
        _addPromptEntry(prompt, participantID, experiment.login,
            diary.id.toString(), promptEntryList);
      }
    }
    final uploaded = await awsUploadResponses(promptEntryList, audioDataList);
    return uploaded;
  } catch (e, stackTrace) {
    debugPrint("Failed to upload data: $e");
    debugPrint(stackTrace.toString());
    return false;
  }
}

void _addAudioData(
    String experimentCode,
    PromptModel prompt,
    String participantID,
    DiaryModel diary,
    Directory dir,
    int promptNumber,
    List<AudioData> audioDataList) {
  final localPath =
      p.join(dir.path, 'recordings', prompt.answer?.recordings.first.path);
  final date = getPostDate(diary.start);
  final formattedTime = DateFormat('HH-mm-ss').format(DateTime.now());
  final filename =
      "${participantID}_${formatSubmissionDate(diary.start)}_$formattedTime.aac";
  final awsPath =
      "$experimentCode/$participantID/$date/prompt_$promptNumber/$filename";

  audioDataList
      .add(AudioData(localDirectory: localPath, awsS3Directory: awsPath));
}

void _addPromptEntry(PromptModel prompt, String participantID,
    String experimentCode, String diaryID, List<PromptEntry> promptEntryList) {
  promptEntryList.add(
    PromptEntry(
      participantID: participantID,
      experimentCode: experimentCode,
      questionTitle: prompt.question,
      diaryID: diaryID,
      promptID: prompt.id.toString(),
      response: prompt.answer!.response!,
      questionsType: AwsUtils.getResponseType(prompt.responseType.toString()),
      required: prompt.required,
    ),
  );
}

String formatSubmissionDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

//Upload functions
Future<bool> uploadNonAudioData(List<PromptEntry> promptEntryList) async {
  final cred = await SecureSave().read();
  // List of items to be sent in the request body
  List<Map<String, dynamic>> promptListItems =
      PromptEntry.promptListToMap(promptEntryList);
  // Encode the list of items to JSON
  String jsonBody = json.encode(promptListItems);

  // Set up the HTTP POST request
  // var url = Uri.parse(
  //     'https://r79428yn1l.execute-api.us-east-1.amazonaws.com/live/dynsendresponse'); // Replace with your API endpoint
  var url = Uri.parse(cred?.dynamo_url ?? "");

  var headers = {
    'Content-Type': 'application/json',
    'Authorization': "${cred?.authorization ?? ""}[0]",
    'x-api-key': cred?.xapikey ?? ""
  };

  try {
    var response = await http.post(url, headers: headers, body: jsonBody);

    if (response.statusCode == 200) {
      // Request successful
      debugPrint('Dynamo DB: All items processed successfully');
      return true; // Submission successful
    } else {
      // Request failed
      debugPrint('Dynamo DB: Request failed with status: ${response.body}');
      return false; // Submission failed
    }
  } catch (e) {
    // An error occurred
    debugPrint('Error sending request: $e');
    return false; // Submission failed due to error
  }
}

/// Retrieves a presigned URL for uploading a file to an S3 storage location.
///
/// The function takes an [apiUrl] and a [filename] as input parameters. It sends
/// a POST request to the specified API endpoint ([apiUrl]) with a JSON body
/// containing the filename. Upon successful response with status code 200,
/// it parses the response body to extract the presigned URL and returns it.
/// If there's an error during the process, or the response status code is not
/// 200, it returns null.
///
/// Example:
/// ```dart
/// String apiUrl = 'https://example.com/api/upload';
/// String filename = 'example_file.jpg';
/// String? presignedUrl = await getPresignedUrl(apiUrl, filename);
/// if (presignedUrl != null) {
///   // Use the presigned URL to upload the file to S3
/// } else {
///   // Handle error
/// }
/// ```
///
/// Throws an error if there's any issue during the process.
///
Future<String?> getPresignedUrl(String apiUrl, String filename) async {
  final cred = await SecureSave().read();
  try {
    var requestBody = jsonEncode({'filename': filename});

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            "${cred?.authorization ?? ""}[1]", // password [ AWS ARN FOR THE CALL ]
        'x-api-key': cred?.xapikey ?? ""
      },
      body: requestBody,
    );

    if (response.statusCode == 200) {
      // Parse the response body (which is a string containing JSON)
      var responseBody = response.body;
      var jsonResponse = jsonDecode(responseBody);
      // Parse the 'body' field from the JSON response
      var body = jsonDecode(jsonResponse['body']);

      // Extract the 'uploadURL' from the parsed 'body' JSON
      var uploadUrl = body['uploadURL'];
      debugPrint("presigned URL is generated");
      return uploadUrl;
    } else {
      debugPrint(
          'Failed to get presigned URL: ${response.statusCode}, ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('Error getting presigned URL: $e');
    return null;
  }
}

Future<bool> uploadFileToS3(String presignedUrl, String filePath) async {
  try {
    var file = File(filePath);
    var fileStream = file.openRead();

    var request = http.Request('PUT', Uri.parse(presignedUrl))
      ..headers['Content-Type'] = 'audio/mpeg';

    // Collect bytes from the file stream into a single list
    List<int> bytes = [];
    await for (var chunk in fileStream) {
      bytes.addAll(chunk);
    }

    // Set the body bytes of the request
    request.bodyBytes = bytes;

    var response = await http.Client().send(request);

    if (response.statusCode == 200) {
      debugPrint('S3 Storage: File uploaded successfully');
      return true; // Return true if upload successful
    } else {
      debugPrint(
          'S3 Storage: Failed to upload file. Status code: ${response.statusCode}');
      return false; // Return false if upload failed
    }
  } catch (e) {
    debugPrint('S3 Storage: Error uploading file: $e');
    return false; // Return false if an error occurred
  }
}

Future<bool> uploadAudios(List<AudioData> audioFileData) async {
  final cred = await SecureSave().read();
  // var apiUrl =
  //     'https://r79428yn1l.execute-api.us-east-1.amazonaws.com/live/s3upload';
  var apiUrl = cred?.presigned_url ?? "";
  var sent = false;
  for (var data in audioFileData) {
    var presignedUrl = await getPresignedUrl(apiUrl, data.awsS3Directory);
    //print("PRESIGNED URL: " + presignedUrl!);
    if (presignedUrl != null) {
      sent = await uploadFileToS3(presignedUrl, data.localDirectory);
    }
  }
  debugPrint("uploaded in array $sent");
  return sent;
}

//Upload Models

class AudioData {
  String localDirectory;
  String awsS3Directory;
  // Constructor
  AudioData({required this.localDirectory, required this.awsS3Directory});
}

///Class representing audio entry in the dynamo db once an object is created
///
class PromptEntry {
  String participantID;
  String experimentCode;
  String questionTitle;
  String diaryID;
  String promptID;
  String response;
  String questionsType; // Corrected parameter name
  bool required;

  PromptEntry(
      {required this.participantID,
      required this.experimentCode,
      required this.questionTitle,
      required this.diaryID,
      required this.promptID,
      required this.response,
      required this.questionsType, // Corrected parameter name
      required this.required});

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
        "Response": entry.response,
        "QuestionsType": entry.questionsType,
        "Required": entry.required.toString() // Convert bool to string
      };
      items.add(map);
    }

    return items;
  }
}

/// Utils functions Classes and objects for functionality

class AwsUtils {
  static getResponseType(String inputString) {
    List<String> parts = inputString.split('.');
    return parts.length > 1 ? parts[1] : inputString;
  }
}

Future<bool> awsUploadResponses(
    List<PromptEntry> promptEntryList, List<AudioData> audioData) async {
  try {
    if (audioData.isNotEmpty) {
      var audioDataSent = await uploadAudios(audioData);
      if (!audioDataSent) {
        return false;
      }
    }
    var nonAudioDataSent = await uploadNonAudioData(promptEntryList);
    return nonAudioDataSent;
  } catch (e) {
    debugPrint("EXCEPTION: $e");
    return false;
  }
}
