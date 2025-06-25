import 'dart:convert';
import 'dart:io';
import 'package:audio_diaries_flutter/core/usecases/diary.dart';
import 'package:audio_diaries_flutter/core/usecases/location.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
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
          prompt.responseType == ResponseType.imageVideo) {
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
      questionsType: responseTypeValue(prompt.responseType!),
      required: prompt.required,
    ),
  );
}

String formatSubmissionDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

/// Uploads non-audio data to the server.
///
/// [promptEntries] is the list of prompt entries to upload.
/// [secureSave] is an optional SecureSave instance for testing.
/// [client] is an optional HTTP client for testing.
Future<bool> uploadNonAudioData(
  List<PromptEntry> promptEntries, {
  SecureSave? secureSave,
  http.Client? client,
}) async {
  final _secureSave = secureSave ?? SecureSave();
  final _client = client ?? http.Client();

  try {
    final credentials = await _secureSave.read();
    if (credentials == null) {
      return false;
    }

    // Convert PromptEntry objects to the correct format
    final promptListItems = PromptEntry.promptListToMap(promptEntries);
    final jsonBody = json.encode(promptListItems);

    final response = await _client.post(
      Uri.parse(credentials.dynamo_url!),
      headers: {
        'Authorization': credentials.authorization!,
        'x-api-key': credentials.xapikey!,
        'Content-Type': 'application/json',
      },
      body: jsonBody,
    );

    return response.statusCode == 200;
  } catch (e) {
    dev.log('Error uploading non-audio data: $e',
        name: 'Upload - Non-Audio Data');
    return false;
  }
}

/// Gets a presigned URL for uploading a file.
///
/// [apiUrl] is the API endpoint URL.
/// [filename] is the name of the file to upload.
/// [client] is an optional HTTP client for testing.
Future<String?> getPresignedUrl(
  String apiUrl,
  String filename, {
  http.Client? client,
}) async {
  final _client = client ?? http.Client();

  try {
    final response = await _client.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'filename': filename}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url'];
    }
    return null;
  } catch (e) {
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
  } catch (e) {
    dev.log('S3 Storage: Error uploading file: $e',
        name: 'Upload - S3 Storage');
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
        "QuestionsType": entry.questionsType,
        "Required": entry.required.toString(), // Convert bool to string
        "Transcript": entry.transcript,
        "Reference": entry.reference
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
  } catch (e) {
    dev.log("EXCEPTION: $e", name: "Upload - AWS Upload Responses");
    return false;
  }
}
