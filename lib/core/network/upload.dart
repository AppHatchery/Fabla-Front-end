import 'dart:convert';
import 'dart:io';
import 'package:audio_diaries_flutter/core/usecases/diary.dart';
import 'package:audio_diaries_flutter/core/usecases/location.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as dev;
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
    final files = <FileData>[];
    final references =
        <PromptEntry>[]; // for referencing the audio files in Dynamo

    for (final prompt in diary.prompts) {
      if (prompt.answer == null) continue;

      if ((prompt.responseType == ResponseType.textAudio &&
              (prompt.answer?.recordings.isNotEmpty ?? false)) ||
          prompt.responseType == ResponseType.audio ||
          prompt.responseType == ResponseType.image ||
          prompt.responseType == ResponseType.video ||
          prompt.responseType == ResponseType.imageVideo ||
          prompt.responseType == ResponseType.teleprompter) {
        _addFileData(experiment.login, prompt, participantID, diary, dir, files,
            references);

        // If the prompt is textAudio and has a text response, add the text response
        if (prompt.responseType == ResponseType.textAudio &&
            (prompt.answer?.response?.isNotEmpty ?? false)) {
          _addPromptEntry(prompt, participantID, experiment.login,
              diary.id.toString(), promptEntryList);
        }
      } else {
        _addPromptEntry(prompt, participantID, experiment.login,
            diary.id.toString(), promptEntryList);
      }
    }

    //Add Location if Experiment has location
    final location = await appendLocation(
        experimentCode: experiment.login,
        participantID: participantID,
        promptLength: diary.prompts.length,
        diaryID: diary.id.toString());
    if (location != null) promptEntryList.add(location);

    // Submitting the completion time for this diary
    final completionTime = await submitDiaryCompletionTime(
        experimentCode: experiment.login,
        participantID: participantID,
        promptLength: diary.prompts.length,
        diaryID: diary.id.toString());
    promptEntryList.addAll(completionTime);

    promptEntryList.addAll(
        references); // Adding the references to the list going to Dynamo

    final uploaded = await awsUploadResponses(promptEntryList, files);
    return uploaded;
  } catch (e, stackTrace) {
    dev.log("Failed to upload data: $e", name: "Upload");
    dev.log(stackTrace.toString());
    CrashlyticsService().recordError(e, stackTrace,
        context: {
          'ParticipantID': participantID,
          'DiaryID': diary.id.toString()
        },
        reason: 'Failed to upload data in upload function');
    return false;
  }
}

void _addFileData(
  String experimentCode,
  PromptModel prompt,
  String participantID,
  DiaryModel diary,
  Directory dir,
  List<FileData> files,
  List<PromptEntry> references,
) {
  final recordings = prompt.answer?.recordings;
  final data = <FileData>[];

  if (recordings != null) {
    for (final record in recordings) {
      final formattedTime = DateFormat('HH-mm-ss').format(DateTime.now());
      String localPath = p.join(dir.path, record.path);
      String filename =
          "${participantID}_${formatSubmissionDate(diary.start)}_${formattedTime}_${record.id}${p.extension(localPath)}";
      String folder = '${capitalizeFirstLetter(record.type)}s';

      final awsPath = "$experimentCode/$folder/$filename";
      final fileData =
          FileData(localDirectory: localPath, awsS3Directory: awsPath);
      data.add(fileData);

      // Adding references for audio question for transcription
      // if (record.type == 'audio') {
      references.add(
        PromptEntry(
            participantID: participantID,
            experimentCode: experimentCode,
            questionTitle: prompt.question,
            diaryID: diary.id.toString(),
            promptID: prompt.id.toString(),
            response: "",
            respondedAt: record.date.toIso8601String(),
            questionsType: responseTypeValue(prompt.responseType!),
            required: prompt.required,
            reference:
                "${participantID}_${formatSubmissionDate(diary.start)}_${formattedTime}_${record.id}"),
      );
      // }
    }
  }

  files.addAll(data);
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
      response: prompt.answer?.response?.join(' | ') ?? "",
      respondedAt: prompt.answer?.date.toIso8601String() ?? "",
      questionsType: responseTypeValue(prompt.responseType!),
      required: prompt.required,
    ),
  );
}

String formatSubmissionDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

//Upload functions
// Modified to support dependency injection for better testability
// Added optional parameters for SecureSave and http.Client
// Default values maintain backward compatibility
Future<bool> uploadNonAudioData(
  List<PromptEntry> promptEntryList, {
  SecureSave? secureSave,
  http.Client? client,
}) async {
  // Use injected dependencies or create default instances
  final secureStorage = secureSave ?? SecureSave();
  final httpClient = client ?? http.Client();

  final cred = await secureStorage.read();
  // List of items to be sent in the request body
  List<Map<String, dynamic>> promptListItems =
      PromptEntry.promptListToMap(promptEntryList);
  // Encode the list of items to JSON
  String jsonBody = json.encode(promptListItems);

  var url = Uri.parse(cred?.dynamo_url ?? "");

  var headers = {
    'Content-Type': 'application/json',
    'Authorization': "${cred?.authorization ?? ""}[0]",
    'x-api-key': cred?.xapikey ?? ""
  };

  try {
    // Updated to use injected http client instead of static http.post
    var response = await httpClient.post(url, headers: headers, body: jsonBody);

    return response.statusCode == 200;
  } catch (e, stackTrace) {
    // An error occurred
    dev.log('Error sending request: $e', name: 'Upload - Non-Audio Data');
    CrashlyticsService().recordError(e, stackTrace,
        reason: 'Error sending request in uploadNonAudioData');
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
/// Modified to support dependency injection for better testability.
/// Added optional parameters for SecureSave and http.Client.
/// Default values maintain backward compatibility.
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
Future<String?> getPresignedUrl(
  String apiUrl,
  String filename, {
  SecureSave? secureSave,
  http.Client? client,
}) async {
  // Use injected dependencies or create default instances
  final secureStorage = secureSave ?? SecureSave();
  final httpClient = client ?? http.Client();

  final cred = await secureStorage.read();
  try {
    var requestBody = jsonEncode({'filename': filename});

    // Updated to use injected http client instead of static http.post
    var response = await httpClient.post(
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
      return uploadUrl;
    } else {
      CrashlyticsService().recordApiError(
          'Failed to get presigned URL: ${response.body}', apiUrl,
          statusCode: response.statusCode,
          method: 'POST',
          requestData: {'filename': filename});
      dev.log(
          'Failed to get presigned URL: ${response.statusCode}, ${response.body}',
          name: 'Upload - Get Presigned URL');
      return null;
    }
  } catch (e, stackTrace) {
    dev.log('Error getting presigned URL: $e',
        name: 'Upload - Get Presigned URL');
    CrashlyticsService().recordError(e, stackTrace,
        reason: 'Error getting presigned URL in getPresignedUrl');
    return null;
  }
}

Future<bool> uploadFileToS3(String presignedUrl, String filePath) async {
  try {
    var file = File(filePath);
    var fileStream = file.openRead();

    var request = http.Request('PUT', Uri.parse(presignedUrl))
      ..headers['Content-Type'] = extentionToContentType(p.extension(filePath));

    // Collect bytes from the file stream into a single list
    List<int> bytes = [];
    await for (var chunk in fileStream) {
      bytes.addAll(chunk);
    }

    // Set the body bytes of the request
    request.bodyBytes = bytes;

    var response = await http.Client().send(request);

    return response.statusCode == 200;
  } catch (e, stackTrace) {
    dev.log('S3 Storage: Error uploading file: $e',
        name: 'Upload - S3 Storage');
    CrashlyticsService().recordError(e, stackTrace,
        reason: 'Error uploading file in uploadFileToS3');
    return false; // Return false if an error occurred
  }
}

String extentionToContentType(String extension) {
  final type = {
    '.aac': 'audio/aac',
    '.jpg': 'image/jpeg',
    '.mp4': 'video/mp4',
  };

  return type[extension] ?? 'audio/mpeg';
}

Future<bool> uploadFiles(List<FileData> files) async {
  final cred = await SecureSave().read();

  final apiUrl = cred?.presigned_url ?? "";
  // List to store the results of each file upload
  final results = <bool>[];
  dev.log('Starting Files Upload - ${DateTime.now()}');
  for (var file in files) {
    var presignedUrl = await getPresignedUrl(apiUrl, file.awsS3Directory);
    if (presignedUrl != null) {
      final result = await uploadFileToS3(presignedUrl, file.localDirectory);
      dev.log(
          'File uploaded: $result | File: ${file.awsS3Directory} | Time: ${DateTime.now()}',
          name: 'Upload - Upload Files');
      results.add(result);
    }
  }
  // Return true if all files were uploaded successfully
  return results.every((element) => element);
}

//Upload Models

class FileData {
  String localDirectory;
  String awsS3Directory;
  // Constructor
  FileData({required this.localDirectory, required this.awsS3Directory});
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
  String respondedAt; // Added to store the response time
  String questionsType; // Corrected parameter name
  bool required;
  String transcript;
  String reference;

  PromptEntry({
    required this.participantID,
    required this.experimentCode,
    required this.questionTitle,
    required this.diaryID,
    required this.promptID,
    required this.response,
    required this.respondedAt, // Added to store the response time
    required this.questionsType, // Corrected parameter name
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
        "Response": entry.response,
        "RespondedAt": entry.respondedAt, // Added to store the response time
        "QuestionsType": entry.questionsType,
        "Required": entry.required.toString(), // Convert bool to string
        "Transcript": entry.transcript,
        "Reference": entry.reference,
        "Environment": kDebugMode ? "Dev" : "Prod"
      };
      items.add(map);
    }

    return items;
  }
}

Future<bool> awsUploadResponses(
    List<PromptEntry> promptEntryList, List<FileData> files) async {
  try {
    final filesResult = files.isNotEmpty ? await uploadFiles(files) : true;
    final dataSent = await uploadNonAudioData(promptEntryList);
    return filesResult && dataSent;
  } catch (e, stackTrace) {
    dev.log("EXCEPTION: $e", name: "Upload - AWS Upload Responses");
    CrashlyticsService()
        .recordError(e, stackTrace, reason: 'Exception in awsUploadResponses');
    return false;
  }
}
