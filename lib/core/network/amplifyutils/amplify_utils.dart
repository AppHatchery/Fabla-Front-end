import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:audio_diaries_flutter/amplifyconfiguration.dart';

import 'package:audio_diaries_flutter/core/network/utils.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:aws_common/vm.dart';
import 'package:path/path.dart' as fpath;


/// It initializes the the amplify library with its dependencies e.g. Amplify Storage, Amplify Cognito

Future<void> configureAmplify() async {
  try {
    final auth = AmplifyAuthCognito();
    final storage = AmplifyStorageS3();
    await Amplify.addPlugins([auth, storage]);
    await Amplify.configure(amplifyconfig);
  } on Exception catch (e) {
    print('An error occurred configuring Amplify: $e');
  }
}

/// Responsible for uploading audio files to S3 Buckets

Future<void> uploadFilesToS3(List<DiaryAudioData> audioData) async {
  var studycode = "000001";

  for (DiaryAudioData fileData in audioData) {
    var filePath = fileData.file.path;

    var date = getPostDate(fileData.date);
    final awsFile = AWSFilePlatform.fromFile(fileData.file);
    var filename = fpath.basename(filePath);
    try {

      final uploadResult = await Amplify.Storage.uploadFile(
        localFile: awsFile,
        key: "$studycode/$date/prompt_${fileData.prompt}/$filename",
      ).result;
      print('Uploaded file: ${uploadResult.uploadedItem.key}');

    } on StorageException catch (e) {
      print('Error uploading file: ${e.message}');
      rethrow;
    }
  }
}
