/// All functions for uploading files to the server should be here.
///
import 'dart:io';
import 'package:audio_diaries_flutter/core/network/amplifyutils/amplify_utils.dart';
import 'package:audio_diaries_flutter/core/network/utils.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';

/// Creates a list of files with DiaryAudioData ready to be submitted to S3 bucket

Future<void> prepareAudioUpload(Diary diary) async {
  List<DiaryAudioData> fileList = [];

  for (int i = 0; i < diary.prompts.length; i++) {
    var prompt = diary.prompts[i];
    var rec = prompt.answer?.recordings;

    for (int r = 0; r < rec!.length; r++) {
      fileList.add(DiaryAudioData(i + 1, File(rec[r].path), rec[r].date));
    }
  }
  uploadFilesToS3(fileList);
}
