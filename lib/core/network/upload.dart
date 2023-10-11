import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:path/path.dart' as p;
import 'package:aws_common/vm.dart';

import '../../screens/diary/data/diary_audio_data.dart';
import '../utils/formatter.dart';

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
Future<bool> upload(String studyCode, Diary diary) async {
  List<DiaryAudioData> fileList = [];

  for (int i = 0; i < diary.prompts.length; i++) {
    var prompt = diary.prompts[i];
    if (prompt.responseType == ResponseType.recording) {
      var rec = prompt.answer?.recordings;

      for (int r = 0; r < rec!.length; r++) {
        fileList.add(DiaryAudioData(
            prompt: i + 1, file: File(rec[r].path), date: diary.start));
      }
    }
  }
  final uploaded = await uploadFilesToS3(studyCode, fileList);
  return uploaded;
}

/// Uploads a list of audio files to an S3 storage location.
///
/// This function takes a list of [audioData], where each element represents audio
/// file information, including the file itself, date, prompt number, and more. It
/// uploads these audio files to an S3 storage destination. The function returns
/// a boolean value indicating the success or failure of the upload process.
///
/// Parameters:
/// - [audioData]: A list of audio file data to be uploaded, typically associated
///   with diary entries.
/// - [studycode]: The study code identifying the study associated with the uploads.
///
/// Returns:
/// - `true` if all audio files were successfully uploaded.
/// - `false` if any part of the upload process failed.
///
/// Example usage:
/// ```dart
/// List<DiaryAudioData> audioData = ... // Prepare audio data list.
/// String studyCode = ... // Provide the study code.
/// bool uploadResult = await uploadFilesToS3(audioData, studyCode);
/// if (uploadResult) {
///   // Handle successful upload.
/// } else {
///   // Handle upload failure.
/// }
/// ```
Future<bool> uploadFilesToS3(
    String studyCode, List<DiaryAudioData> audioData) async {
  for (DiaryAudioData fileData in audioData) {
    var filePath = fileData.file.path;

    var date = getPostDate(fileData.date);
    final awsFile = AWSFilePlatform.fromFile(fileData.file);
    var filename = p.basename(filePath);
    try {
      final uploadResult = await Amplify.Storage.uploadFile(
        localFile: awsFile,
        key: "$studyCode/$date/prompt_${fileData.prompt}/$filename",
      ).result;
      print('Uploaded file: ${uploadResult.uploadedItem.key}');
    } on StorageException catch (e) {
      print('Error uploading file: ${e.message}');
      return false;
    }
  }
  return true;
}

/// Uploads a file having metadata about the study pertaining the participant to the s3 Bucket of the current participant

Future<bool> uploadMetaDataS3(var studyCode, File file) async {
  final awsFile = AWSFilePlatform.fromFile(file);
  try {
    final uploadResult = await Amplify.Storage.uploadFile(
      localFile: awsFile,
      key: "$studyCode/metadata.txt",
    ).result;
    print('Uploaded Meta data file: ${uploadResult.uploadedItem.key}');
  } on StorageException catch (e) {
    print('Error uploading file: ${e.message}');
    return false;
  }

  return true;
}
