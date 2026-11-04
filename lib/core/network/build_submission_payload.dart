import 'dart:developer' as dev;
import 'dart:io';

import 'package:audio_diaries_flutter/core/network/s3_upload.dart';
import 'package:audio_diaries_flutter/core/network/submission_models.dart';
import 'package:audio_diaries_flutter/core/usecases/submission_metadata.dart';
import 'package:audio_diaries_flutter/core/utils/device_appInfo.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/data/submission_payload.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/recording.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/services/recorder_settings.dart';
import 'package:path/path.dart' as p;

/// Builds the nested submission for [diary].
///
/// [sessionStartedAt] and [sessionCompletedAt] are passed in rather than read
/// here, so they always match the flat rows [submitDiaryCompletionTime] built.
Future<SubmissionPayload> buildSubmissionPayload(
    {required DiaryModel diary,
    required StudyModel? study,
    required String participantID,
    required String experimentCode,
    required String? sessionStartedAt,
    required String? sessionCompletedAt,
    required List<Map<String, dynamic>> responses}) async {
  final submittedAt = DateTime.now();
  final metadata = await getSubmissionMetadata();
  final device = await collectDeviceSnapshot();

  // Set by _uploadAndRecord before every upload, so a null here is a bug.
  // Generating a fresh ID would break its reuse across retries.
  final submissionID = diary.submissionID;
  if (submissionID == null) {
    throw StateError(
        'Diary ${diary.id} has no submission ID, something went wrong when setting the ID');
  }

  return SubmissionPayload(
      submissionID: submissionID,
      submittedAt: submittedAt,
      environment: metadata['Environment'] as String? ?? '',
      protocolVersion: metadata['ProtocolVersion'] as String? ?? '',
      uploadAttempts: diary.uploadAttempts,
      participant: {
        'ParticipantID': participantID,
        'ExperimentCode': experimentCode
      },
      device: device,
      diary: {
        'DiaryID': diary.id.toString(),
        'DiaryName': diary.name,
        'StudyPhaseName': study?.name ?? '',
        'EntryNumber': diary.currentEntry,
        'SessionStartedAt': sessionStartedAt,
        'SessionCompletedAt': sessionCompletedAt,
      },
      responses: responses);
}

/// One entry per answered prompt in [prompts], each recording listed under
/// `Files`.
///
/// [files] is what [addFileData] queued for S3, so a recording with no match
/// there had no file on disk. It is kept and flagged `Missing` rather than
/// dropped, so the backend can tell a lost file from an unanswered prompt.
Future<List<Map<String, dynamic>>> buildResponses(
    {required List<PromptModel> prompts,
    required List<FileData> files,
    required Directory dir,
    Future<int> Function(String path) fileSize = _fileSize}) async {
  final queued = {for (final file in files) file.localDirectory: file};
  final responses = <Map<String, dynamic>>[];

  for (final prompt in prompts) {
    final answer = prompt.answer;
    if (answer == null) continue;

    final response = <String, dynamic>{
      'PromptID': prompt.id.toString(),
      'QuestionTitle': prompt.question,
      'QuestionType': responseTypeValue(prompt.responseType),
      'Required': prompt.required,
      'Response': answer.response ?? <String>[],
      'RespondedAt': answer.date.toUtc().toIso8601String(),
    };

    final recordings = List.of(answer.recordings);
    if (recordings.isNotEmpty) {
      response['Files'] = [
        for (final record in recordings)
          await _fileEntry(
              record, queued[p.join(dir.path, record.path)], fileSize)
      ];
    }

    responses.add(response);
  }

  return responses;
}

Future<Map<String, dynamic>> _fileEntry(Recording record, FileData? file,
    Future<int> Function(String path) fileSize) async {
  final entry = <String, dynamic>{
    'RecordingID': record.id.toString(),
    'Type': record.type,
    'RecordedAt': record.date.toUtc().toIso8601String(),
    'Missing': file == null,
    'Reference': null,
    'S3Key': null,
    'MimeType': null,
    'FileSizeBytes': null,
    if (record.type == 'audio') ...{
      'DurationMs': record.durationMs,
      // flutter_sound's relative 0–120 scale, not dBFS.
      'PeakLevel': record.peakLevel,
      // Only a take with a duration is known to have been recorded with
      // these. Audio saved by an older build used flutter_sound's defaults.
      ...RecorderSettings.toJson().map((key, value) =>
          MapEntry(key, record.durationMs == null ? null : value)),
    },
  };
  if (file == null) return entry;

  entry['Reference'] = p.basenameWithoutExtension(file.awsS3Directory);
  entry['S3Key'] = file.awsS3Directory;
  entry['MimeType'] = extensionToContentType(p.extension(file.localDirectory));
  try {
    entry['FileSizeBytes'] = await fileSize(file.localDirectory);
  } catch (e) {
    // The file was there when it was queued; a size is not worth failing for.
    dev.log('Failed to read size of ${file.localDirectory}: $e',
        name: 'Upload - Submission Payload');
  }
  return entry;
}

Future<int> _fileSize(String path) => File(path).length();
