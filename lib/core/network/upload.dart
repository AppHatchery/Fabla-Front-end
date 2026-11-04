import 'dart:convert';
import 'dart:io';
import 'package:audio_diaries_flutter/core/network/build_submission_payload.dart';
import 'package:audio_diaries_flutter/core/usecases/diary.dart';
import 'package:audio_diaries_flutter/core/usecases/location.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as dev;
import 'package:audio_diaries_flutter/core/network/dynamo_upload.dart';
import 'package:audio_diaries_flutter/core/network/s3_upload.dart';
import 'package:audio_diaries_flutter/core/network/submission_models.dart';

export 'dynamo_upload.dart';
export 's3_upload.dart';
export 'submission_models.dart';

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
  try {
    final dir = await getApplicationDocumentsDirectory();
    final repository = SetupRepository();
    final diaryRepository = DiaryRepository();
    final experiment = repository.getExperiment();
    final promptEntryList = <PromptEntry>[];
    final files = <FileData>[];
    final references =
        <PromptEntry>[]; // for referencing the audio files in Dynamo

    final study = await diaryRepository.getStudy(diary.studyID);

    for (final prompt in diary.prompts) {
      if (prompt.answer == null) continue;

      if ((prompt.responseType == ResponseType.textAudio &&
              (prompt.answer?.recordings.isNotEmpty ?? false)) ||
          prompt.responseType == ResponseType.audio ||
          prompt.responseType == ResponseType.image ||
          prompt.responseType == ResponseType.video ||
          prompt.responseType == ResponseType.imageVideo) {
        await addFileData(experiment.login, prompt, participantID, diary, study,
            dir, files, references);

        // If the prompt is textAudio and has a text response, add the text response
        if (prompt.responseType == ResponseType.textAudio &&
            (prompt.answer?.response?.isNotEmpty ?? false)) {
          _addPromptEntry(prompt, participantID, experiment.login, diary, study,
              promptEntryList);
        }
      } else {
        _addPromptEntry(prompt, participantID, experiment.login, diary, study,
            promptEntryList);
      }
    }

    //Add Location if Experiment has location
    final location =
        await captureLocation(diary: diary, participantID: participantID);
    if (location != null) {
      promptEntryList.add(locationEntry(location,
          experimentCode: experiment.login,
          participantID: participantID,
          diary: diary,
          study: study));
    }

    // Submitting the completion time for this diary
    final completionTime = await submitDiaryCompletionTime(
        experimentCode: experiment.login,
        participantID: participantID,
        promptLength: diary.prompts.length,
        diary: diary,
        study: study);
    promptEntryList.addAll(completionTime);

    // Not sent yet: logged so the nested shape can be checked on a device
    // until the Lambda accepts it.
    if (kDebugMode) {
      await _logSubmissionPayload(
          diary: diary,
          study: study,
          participantID: participantID,
          experimentCode: experiment.login,
          completionTime: completionTime,
          location: location,
          files: files,
          dir: dir);
    }

    promptEntryList.addAll(
        references); // Adding the references to the list going to Dynamo

    final missingFileCount = references
        .where((r) => r.reference == PromptEntry.missingFileReference)
        .length;

    CrashlyticsService().setCustomKeys({
      'submitting_diary': diary.name.toString(),
      'submitting_diary_id': diary.id.toString(),
      'submitting_participant_id': participantID,
      'submitting_entry': diary.currentEntry.toString(),
      'submitting_file_count': files.length.toString(),
      'submitting_missing_file_count': missingFileCount.toString(),
    });

    // Recorded after the keys above so the non-fatal carries them. A log alone
    // would never be sent, because this submission is expected to succeed.
    if (missingFileCount > 0) {
      CrashlyticsService().recordError(
          StateError('Recording files missing at upload'), StackTrace.current,
          reason: 'Skipped recordings with no file on disk in upload');
    }

    await PendoService.track('Submission Started', {
      'Diary': diary.name.toString(),
      'DiaryID': diary.id.toString(),
      'Entry': diary.currentEntry.toString(),
      'FileCount': files.length.toString(),
      'MissingFileCount': missingFileCount.toString(),
      'HasFiles': files.isNotEmpty.toString(),
    });

    final uploaded = await awsUploadResponses(promptEntryList, files);

    // Only now: a failed upload must keep the times for its retry.
    if (uploaded) {
      await clearDiaryCompletionTime(diaryID: diary.id.toString());
    }

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
  }
}

/// Queues each of [prompt]'s recordings for S3 and adds its Dynamo reference
/// row. A recording whose file is gone gets no [FileData] and a
/// [PromptEntry.missingFileReference] reference, so it cannot fail the upload.
@visibleForTesting
Future<void> addFileData(
  String experimentCode,
  PromptModel prompt,
  String participantID,
  DiaryModel diary,
  StudyModel? study,
  Directory dir,
  List<FileData> files,
  List<PromptEntry> references, {
  Future<bool> Function(String path) fileExists = _fileExists,
}) async {
  final recordings = prompt.answer?.recordings;
  if (recordings == null) return;

  // A copy, because the loop now awaits and the relation must not change
  // under it.
  for (final record in List.of(recordings)) {
    final localPath = p.join(dir.path, record.path);
    var reference = PromptEntry.missingFileReference;

    if (await _isOnDisk(localPath, fileExists)) {
      final formattedTime = DateFormat('HH-mm-ss').format(record.date);
      // Shared by the S3 filename and the Dynamo reference so they match.
      reference =
          "${experimentCode}_${participantID}_${formatSubmissionDate(diary.start)}_${formattedTime}_${record.id}";
      final folder = '${capitalizeFirstLetter(record.type)}s';

      files.add(FileData(
          localDirectory: localPath,
          awsS3Directory:
              "$experimentCode/$folder/$reference${p.extension(localPath)}"));
    } else {
      dev.log('Skipping missing ${record.type} file: ${record.path}',
          name: 'Upload - Add File Data');
      CrashlyticsService().log(
          'Upload skipped missing ${record.type} recording ${record.id} (prompt ${prompt.id}): ${record.path}');
    }

    // Adding references for audio question for transcription
    references.add(
      PromptEntry(
          participantID: participantID,
          experimentCode: experimentCode,
          questionTitle: prompt.question,
          diaryID: diary.id.toString(),
          promptID: prompt.id.toString(),
          diaryName: diary.name,
          study: study?.name ?? "",
          response: "",
          respondedAt: record.date.toIso8601String(),
          questionsType: responseTypeValue(prompt.responseType),
          required: prompt.required,
          reference: reference),
    );
  }
}

Future<bool> _fileExists(String path) => File(path).exists();

/// A check that throws counts as present. Calling a real file missing would
/// drop it for good once the upload succeeds, while calling a missing file
/// present only fails this upload in [uploadFileToS3], which can be retried.
Future<bool> _isOnDisk(
    String path, Future<bool> Function(String path) fileExists) async {
  try {
    return await fileExists(path);
  } catch (e, s) {
    CrashlyticsService().recordError(e, s,
        context: {'file_path': path},
        reason: 'Checking a recording on disk failed in addFileData');
    return true;
  }
}

void _addPromptEntry(
    PromptModel prompt,
    String participantID,
    String experimentCode,
    DiaryModel diary,
    StudyModel? study,
    List<PromptEntry> promptEntryList) {
  promptEntryList.add(
    PromptEntry(
      participantID: participantID,
      experimentCode: experimentCode,
      questionTitle: prompt.question,
      diaryID: diary.id.toString(),
      promptID: prompt.id.toString(),
      diaryName: diary.name,
      study: study?.name ?? "",
      response: prompt.answer?.response?.join(' | ') ?? "",
      respondedAt: prompt.answer?.date.toIso8601String() ?? "",
      questionsType: responseTypeValue(prompt.responseType),
      required: prompt.required,
    ),
  );
}

/// Builds the nested submission and logs it. A failure here is only logged,
/// so it can never fail the flat upload.
Future<void> _logSubmissionPayload(
    {required DiaryModel diary,
    required StudyModel? study,
    required String participantID,
    required String experimentCode,
    required List<PromptEntry> completionTime,
    required LocationSnapshot? location,
    required List<FileData> files,
    required Directory dir}) async {
  try {
    String? sessionTime(String type) => completionTime
        .where((e) => e.questionsType == type)
        .firstOrNull
        ?.response;

    final payload = await buildSubmissionPayload(
        diary: diary,
        study: study,
        participantID: participantID,
        experimentCode: experimentCode,
        sessionStartedAt: sessionTime('start_time'),
        sessionCompletedAt: sessionTime('end_time'),
        responses: [
          ...await buildResponses(
              prompts: diary.prompts, files: files, dir: dir),
          // The same reading as the flat location row.
          if (location != null) locationResponse(location),
        ]);

    dev.log(jsonEncode(payload.toJson()), name: 'Upload - Submission Payload');
  } catch (e) {
    dev.log('Failed to build submission payload: $e',
        name: 'Upload - Submission Payload');
  }
}

String formatSubmissionDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
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
