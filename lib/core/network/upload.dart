import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audio_diaries_flutter/core/usecases/diary.dart';
import 'package:audio_diaries_flutter/core/usecases/location.dart';
import 'package:audio_diaries_flutter/core/usecases/video_compression.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
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
  final compressedPaths = <String>[];
  try {
    final dir = await getApplicationDocumentsDirectory();
    final repository = SetupRepository();
    final experiment = repository.getExperiment();
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

    CrashlyticsService().setCustomKeys({
      'submitting_diary': diary.name.toString(),
      'submitting_diary_id': diary.id.toString(),
      'submitting_participant_id': participantID,
      'submitting_entry': diary.currentEntry.toString(),
      'submitting_file_count': files.length.toString(),
    });

    await PendoService.track('Submission Started', {
      'Diary': diary.name.toString(),
      'DiaryID': diary.id.toString(),
      'Entry': diary.currentEntry.toString(),
      'FileCount': files.length.toString(),
      'HasFiles': files.isNotEmpty.toString(),
    });

    // Use background-compressed videos where ready; upload raw otherwise (no
    // wait). Then stop any compression still running — its output won't be used.
    _useCompressedVideos(files, compressedPaths);
    VideoCompressionQueue.instance.cancelAll();

    final uploaded = await awsUploadResponses(promptEntryList, files);

    await PendoService.track('Submission Completed', {
      'Diary': diary.name.toString(),
      'DiaryID': diary.id.toString(),
      'Entry': diary.currentEntry.toString(),
      'Success': uploaded.toString(),
    });

    return uploaded;
  } catch (e, stackTrace) {
    dev.log("Failed to upload data: $e", name: "Upload");
    dev.log(stackTrace.toString());
    CrashlyticsService().recordError(e, stackTrace,
        context: {
          'ParticipantID': participantID,
          'Diary': diary.name.toString(),
          'DiaryID': diary.id.toString(),
          'CurrentEntry': diary.currentEntry.toString(),
        },
        reason: 'Failed to upload data in upload function');
    return false;
  } finally {
    await _deleteTempFiles(compressedPaths);
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
            questionsType: responseTypeValue(prompt.responseType),
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
      questionsType: responseTypeValue(prompt.responseType),
      required: prompt.required,
    ),
  );
}

String formatSubmissionDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

/// Points each video [files] entry at its background-compressed copy when one
/// is ready, recording the temp path in [compressedPaths] for later cleanup.
/// Videos whose compression hasn't finished are left as-is and uploaded raw. O(n).
void _useCompressedVideos(List<FileData> files, List<String> compressedPaths) {
  final queue = VideoCompressionQueue.instance;
  for (final file in files) {
    if (p.extension(file.localDirectory).toLowerCase() != '.mp4') continue;
    final compressedPath = queue.compressedPathFor(file.localDirectory);
    if (compressedPath != null) {
      file.localDirectory = compressedPath;
      compressedPaths.add(compressedPath);
    }
  }
}

/// Deletes the temporary compressed files used for upload. Best-effort.
Future<void> _deleteTempFiles(List<String> paths) async {
  for (final path in paths) {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      dev.log('Failed to delete temp file $path: $e', name: 'Upload');
    }
  }
}

//Upload functions

/// Re-fetches credentials from the backend using the locally-stored participant
/// and experiment records, then returns the newly-saved [CredentialsModel].
///
/// Returns `null` if local data is unavailable or the request fails, so callers
/// can treat a null return as a permanent failure rather than retrying.
Future<CredentialsModel?> _refreshCredentials(SecureSave secureStorage) async {
  try {
    final setup = SetupRepository();
    final participant = setup.getParticipant();
    final experiment = setup.getExperiment();
    if (participant == null) return null;
    await secureStorage.getCredentials(
      study: experiment.login,
      participant: participant.studyCode,
    );
    return await secureStorage.read();
  } catch (e, stackTrace) {
    CrashlyticsService().recordError(e, stackTrace,
        reason: 'Failed to refresh credentials in _refreshCredentials');
    await PendoService.track('Upload Error', {
      'event': 'Refresh Credentials',
      'reason': e.toString(),
    });
    return null;
  }
}

Future<bool> uploadNonAudioData(
  List<PromptEntry> promptEntryList, {
  SecureSave? secureSave,
  http.Client? client,
}) async {
  final secureStorage = secureSave ?? SecureSave();
  final bool ownClient = client == null;
  final httpClient = client ?? http.Client();

  try {
    var cred = await secureStorage.read();

    if (cred == null) {
      dev.log('Credentials null — attempting refresh',
          name: 'Upload - Non-Audio Data');
      cred = await _refreshCredentials(secureStorage);
    }

    if (cred == null) {
      CrashlyticsService()
          .log('Upload failed: credentials null after refresh attempt');
      return false;
    }
    List<Map<String, dynamic>> promptListItems =
        PromptEntry.promptListToMap(promptEntryList);
    String jsonBody = json.encode(promptListItems);

    var url = Uri.parse(cred.dynamoUrl ?? "");

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': "${cred.authorization ?? ""}[0]",
      'x-api-key': cred.xapikey ?? ""
    };

    try {
      final stopwatch = Stopwatch()..start();
      var response =
          await httpClient.post(url, headers: headers, body: jsonBody);
      stopwatch.stop();

      if (stopwatch.elapsed > const Duration(minutes: 2)) {
        CrashlyticsService().log(
            'Slow DynamoDB upload: ${stopwatch.elapsedMilliseconds}ms | prompts=${promptEntryList.length}');
        await PendoService.track('Slow Upload', {
          'event': 'Upload to DynamoDB',
          'duration_ms': stopwatch.elapsedMilliseconds.toString(),
          'prompt_count': promptEntryList.length.toString(),
        });
      }

      if (response.statusCode == 200) {
        return true;
      } else {
        dev.log(
            'DynamoDB upload failed: status=${response.statusCode} body=${response.body}',
            name: 'Upload - Non-Audio Data');
        CrashlyticsService().recordApiError(
            'DynamoDB upload failed: ${response.body}', url.toString(),
            statusCode: response.statusCode,
            method: 'POST',
            requestData: {'prompt_count': promptEntryList.length.toString()});
        await PendoService.track('Upload Error', {
          'event': 'Upload to DynamoDB',
          'response': response.body,
          'status': response.statusCode
        });
        return false;
      }
    } catch (e, stackTrace) {
      dev.log('Error sending request: $e', name: 'Upload - Non-Audio Data');
      CrashlyticsService().recordError(e, stackTrace,
          reason: 'Error sending request in uploadNonAudioData');
      await PendoService.track('Upload Error',
          {'event': 'Upload to DynamoDB', 'reason': e.toString()});
      return false;
    }
  } finally {
    if (ownClient) httpClient.close();
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
Future<String?> getPresignedUrl(
  String apiUrl,
  String filename, {
  SecureSave? secureSave,
  http.Client? client,
}) async {
  final secureStorage = secureSave ?? SecureSave();
  final bool ownClient = client == null;
  final httpClient = client ?? http.Client();

  try {
    var cred = await secureStorage.read();

    if (cred == null) {
      dev.log('Credentials null — attempting refresh',
          name: 'Upload - Get Presigned URL');
      cred = await _refreshCredentials(secureStorage);
    }

    if (cred == null) {
      CrashlyticsService()
          .log('Upload failed: credentials null after refresh attempt');
      return null;
    }

    var requestBody = jsonEncode({'filename': filename});

    var response = await httpClient.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            "${cred.authorization ?? ""}[1]", // password [ AWS ARN FOR THE CALL ]
        'x-api-key': cred.xapikey ?? ""
      },
      body: requestBody,
    );

    if (response.statusCode == 200) {
      var responseBody = response.body;
      var jsonResponse = jsonDecode(responseBody);
      var body = jsonDecode(jsonResponse['body']);
      var uploadUrl = body['uploadURL'];
      return uploadUrl;
    } else {
      CrashlyticsService().recordApiError(
          'Failed to get presigned URL: ${response.body}', apiUrl,
          statusCode: response.statusCode,
          method: 'POST',
          requestData: {'filename': filename});
      await PendoService.track('Upload Error', {
        'event': 'Get Presigned URL',
        'response': response.body,
        'status': response.statusCode
      });
      return null;
    }
  } catch (e, stackTrace) {
    dev.log('Error getting presigned URL: $e',
        name: 'Upload - Get Presigned URL');
    CrashlyticsService().recordError(e, stackTrace,
        reason: 'Error getting presigned URL in getPresignedUrl');
    await PendoService.track(
        'Upload Error', {'event': 'Get Presigned URL', 'reason': e.toString()});
    return null;
  } finally {
    if (ownClient) httpClient.close();
  }
}

/// Hard upper bound on a single S3 upload so a stalled socket fails (and logs)
/// instead of hanging forever. Generous enough for a multi-minute 720p clip on
/// a weak uplink; tune down once payloads are compressed.
const Duration _s3UploadTimeout = Duration(minutes: 2);

Future<bool> uploadFileToS3(String presignedUrl, String filePath) async {
  final s3Client = http.Client();
  try {
    final file = File(filePath);

    if (!await file.exists()) {
      dev.log('S3 upload skipped: file not found: $filePath',
          name: 'Upload - S3 Storage');
      CrashlyticsService().log('S3 upload skipped: file not found: $filePath');
      return false;
    }

    final contentLength = await file.length();
    dev.log('Uploading to S3: $filePath ($contentLength bytes)',
        name: 'Upload - S3 Storage');

    final request = http.StreamedRequest('PUT', Uri.parse(presignedUrl))
      ..headers['Content-Type'] = extensionToContentType(p.extension(filePath))
      ..contentLength = contentLength;

    // Stream the file straight into the request body with backpressure, so peak
    // memory stays at one chunk regardless of file size.
    unawaited(
        request.sink.addStream(file.openRead()).whenComplete(request.sink.close));

    final response = await s3Client.send(request).timeout(_s3UploadTimeout);
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return true;
    }

    dev.log(
        'S3 upload failed: status=${response.statusCode} file=$filePath body=$responseBody',
        name: 'Upload - S3 Storage');
    CrashlyticsService().recordApiError(
        'S3 upload failed with status ${response.statusCode}', presignedUrl,
        statusCode: response.statusCode,
        method: 'PUT',
        requestData: {
          'file_path': filePath,
          'content_length': contentLength.toString()
        });
    await PendoService.track('Upload Error', {
      'event': 'Upload to S3',
      'reason': response.reasonPhrase ?? 'unknown',
      'status': response.statusCode
    });
    return false;
  } on TimeoutException catch (e, stackTrace) {
    dev.log(
        'S3 upload timed out after ${_s3UploadTimeout.inMinutes}m: $filePath',
        name: 'Upload - S3 Storage');
    CrashlyticsService().recordError(e, stackTrace,
        context: {'file_path': filePath},
        reason: 'S3 upload timed out in uploadFileToS3');
    await PendoService.track(
        'Upload Error', {'event': 'Upload to S3', 'reason': 'timeout'});
    return false;
  } catch (e, stackTrace) {
    dev.log('S3 Storage: Error uploading file: $e',
        name: 'Upload - S3 Storage');
    CrashlyticsService().recordError(e, stackTrace,
        context: {'file_path': filePath},
        reason: 'Error uploading file in uploadFileToS3');
    await PendoService.track(
        'Upload Error', {'event': 'Upload to S3', 'reason': e.toString()});
    return false; // Return false if an error occurred
  } finally {
    s3Client.close();
  }
}

String extensionToContentType(String extension) {
  final type = {
    '.aac': 'audio/aac',
    '.jpg': 'image/jpeg',
    '.mp4': 'video/mp4',
  };

  return type[extension] ?? 'audio/mpeg';
}

Future<bool> uploadFiles(List<FileData> files) async {
  final secureStorage = SecureSave();
  var cred = await secureStorage.read();

  if (cred == null) {
    dev.log('Credentials null — attempting refresh',
        name: 'Upload - Upload Files');
    cred = await _refreshCredentials(secureStorage);
  }

  if (cred == null) {
    CrashlyticsService()
        .log('Upload failed: credentials null after refresh attempt');
    return false;
  }

  final apiUrl = cred.presignedUrl ?? "";
  // List to store the results of each file upload
  final results = <bool>[];
  dev.log('Starting Files Upload - ${DateTime.now()}');
  for (var file in files) {
    var presignedUrl = await getPresignedUrl(apiUrl, file.awsS3Directory,
        secureSave: secureStorage);
    if (presignedUrl != null) {
      final stopwatch = Stopwatch()..start();
      final result = await uploadFileToS3(presignedUrl, file.localDirectory);
      stopwatch.stop();

      dev.log(
          'File uploaded: $result | Duration: ${stopwatch.elapsedMilliseconds}ms | File: ${file.awsS3Directory}',
          name: 'Upload - Upload Files');

      if (stopwatch.elapsed > const Duration(minutes: 2)) {
        CrashlyticsService().log(
            'Slow S3 upload: ${file.awsS3Directory} took ${stopwatch.elapsedMilliseconds}ms');
        await PendoService.track('Slow Upload', {
          'event': 'Upload to S3',
          'file': file.awsS3Directory,
          'duration_ms': stopwatch.elapsedMilliseconds.toString(),
        });
      }

      results.add(result);
    } else {
      dev.log('Failed to get presigned URL for: ${file.awsS3Directory}',
          name: 'Upload - Upload Files');
      CrashlyticsService().recordApiError('Presigned URL returned null', apiUrl,
          method: 'POST', requestData: {'filename': file.awsS3Directory});
      results.add(false);
    }
  }
  // Return false explicitly if no files were processed (guards against vacuous truth on empty list)
  if (results.isEmpty) return false;
  return results.every((element) => element);
}

//Upload Models

class FileData {
  String localDirectory;
  String awsS3Directory;

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

Future<bool> awsUploadResponses(
    List<PromptEntry> promptEntryList, List<FileData> files) async {
  try {
    final filesResult = files.isNotEmpty ? await uploadFiles(files) : true;
    final dataSent = await uploadNonAudioData(promptEntryList);

    if (!filesResult || !dataSent) {
      dev.log('awsUploadResponses failed — s3=$filesResult dynamo=$dataSent',
          name: 'Upload - AWS Upload Responses');
      CrashlyticsService().log(
          'Submission failed — S3: $filesResult | DynamoDB: $dataSent | Files: ${files.length} | Prompts: ${promptEntryList.length}');
      await PendoService.track('Submission Failed', {
        'S3 Upload Success': filesResult.toString(),
        'DynamoDB Upload Success': dataSent.toString(),
        'File Count': files.length.toString(),
        'Prompt Count': promptEntryList.length.toString(),
      });
    }

    return filesResult && dataSent;
  } catch (e, stackTrace) {
    dev.log("EXCEPTION: $e", name: "Upload - AWS Upload Responses");
    CrashlyticsService()
        .recordError(e, stackTrace, reason: 'Exception in awsUploadResponses');
    return false;
  }
}
