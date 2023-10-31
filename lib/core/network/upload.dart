import 'dart:convert';
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/questions.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:path/path.dart' as p;
import 'package:aws_common/vm.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';

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
  final dir = await getApplicationDocumentsDirectory();
  try {
    List<DiaryAudioData> fileList = [];
    List<Question> questions = [];

    for (int i = 0; i < diary.prompts.length; i++) {
      var prompt = diary.prompts[i];
      if (prompt.responseType == ResponseType.recording) {
        var rec = prompt.answer?.recordings;
        

        for (int r = 0; r < rec!.length; r++) {
          final path = p.join(dir.path, 'recordings',rec[r].path);
          fileList.add(DiaryAudioData(
              prompt: i + 1, file: File(path), date: diary.start));
        }
      } else {
        if (prompt.answer != null) {
          questions.add(Question(
              questionType: prompt.questionType,
              answer: prompt.answer!.response!));
        }
      }
    }
    final resMap = getResponses(diary.id, questions);

    final questionsSubmitted =
        await apiSubmitSurveyQuestions(studyCode, diary, resMap);
    final audioSubmitted = await uploadFilesToS3(studyCode, fileList);
    return questionsSubmitted && audioSubmitted;
  } catch (e) {
    print("$e");
    return false;
  }
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
      PendoService.track("UploadError", {"errorcode":"s3 diary"});
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
    PendoService.track("UploadError", {"errorcode":"S3 metadata"});
    print('Error uploading file: ${e.message}');
    return false;
  }
  return true;
}

Question? filterQuestionByType(List<Question> objectList, QuestionType type) {
  try {
    return objectList.firstWhere((obj) => obj.questionType == type);
  } catch (e) {
    return null;
  }
}

///Submits all diary questions to dynamo db by updating empty questions slots on tha particular participant
///Example initial, 10001 - PHYSICALLY_1 ="", then updated to, -> 10001 - PHYSICALLY_1="3"
///
Future<bool> apiSubmitSurveyQuestions(
    String studycode, Diary diary, Map<String,dynamic> map) async {
  try {
    String graphQLDocument = '''
      query ListFiles {
        listParticipants(filter:{ _deleted:{attributeExists:false}, studycode: { eq: "$studycode" } }) {
          items { 
            id
            studycode
            _version
          }
        }
      }
    ''';
    var operation = Amplify.API.query(
      request: GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {'studycode': studycode},
      ),
    );
    var response = await operation.response;
    var data = response.data;

    if (data != null) {
      Map<String, dynamic> jsonMap = jsonDecode(data);
      final participantList = jsonMap["listParticipants"]["items"];
      dynamic id = participantList.first['id'];
      int version = participantList.first['_version'];
      final uploaded =
          uploadQuestions(id, studycode, version, diary, map);
      return uploaded;
    } else {
      response.errors.forEach((element) {
        safePrint('${element.toJson()}   ${element.message};');
      });
      return false;
    }
  } catch (e) {
    PendoService.track("UploadError", {"errorcode":"GraphQL diary"});
    print('Error checking if $studycode exists: $e');
    return false;
  }
}

Future<GqlApiRequestStateUpdate> participantsDiaryStartDate(
    Diary? diary) async {
  int day = diary!.id;
  DateTime diaryStartTime = DateTime.now();
  SetupRepository repo = SetupRepository();
  GqlApiRequestStateUpdate updateState = GqlApiRequestStateUpdate.idle;
  final studycode = repo.getParticipant()!.studyCode;

  if (await repo.participantExist(studycode)) {
    final map = await apiGetParticipant(studycode);
    safePrint("map: $map");
    final id = map.first['id'];
    int version = map.first['_version'];
    final input = {
      'id': id,
      'studycode': studycode,
      'starttime_$day': formatDate(diaryStartTime),
      '_version': version
    };
    try {
      String graphQLDocument = '''
      mutation UpdateParticipants(\$input: UpdateParticipantsInput!) {
          updateParticipants(input: \$input) {
            id
            studycode
            starttime_$day
            _version
          }
        }
    ''';

      var operation = Amplify.API.query(
        request: GraphQLRequest<String>(
          document: graphQLDocument,
          variables: {'input': input},
        ),
      );
      var response = await operation.response;
      var data = response.data;

      if (data != null) {
        safePrint(
            "Diary started updated startdate ${formatDate(diaryStartTime)}");
        updateState = GqlApiRequestStateUpdate.updated;
        return updateState;
      } else {
        response.errors.forEach((element) {
          safePrint('${element.message};');
        });
        updateState = GqlApiRequestStateUpdate.error;
        return updateState;
      }
    } catch (e) {
      print('Exception: $e');
      return GqlApiRequestStateUpdate.error;
    }
  } else {
    updateState = GqlApiRequestStateUpdate.notfound;
    return updateState;
  }
}

enum GqlApiRequestStateUpdate { idle, updated, error, notfound }

Future<dynamic> apiGetParticipant(String studycode) async {
  String graphQLDocument = '''
      query ListFiles {
        listParticipants(filter:{ _deleted:{attributeExists:false}, studycode: { eq: "$studycode" } }) {
          items { 
            id
            studycode
            _version
          }
        }
      }
    ''';

  try {
    var operation = Amplify.API.query(
      request: GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {'studycode': studycode},
      ),
    );
    var response = await operation.response;
    var data = response.data;

    if (data != null) {
      Map<String, dynamic> jsonMap = jsonDecode(data);
      final participantList = jsonMap["listParticipants"]["items"];
      return participantList;
    } else {
      response.errors.forEach((element) {
        safePrint('${element.toJson()}   ${element.message};');
      });
      return null;
    }
  } catch (e) {
    PendoService.track("UploadError", {"errorcode":"GraphQL get participant"});
    print('Error checking if $studycode exists: $e');
    return null;
  }
}

Map<String, dynamic> getResponses(int day, List<Question> r) {
  Map<String, dynamic> map = {};
  r.forEach((element) {
    var type = element.questionType;

    switch (type) {
      case QuestionType.physically:
        map['physically_$day'] = element.answer!;
        break;
      case QuestionType.emotionally:
        map['emotionally_$day'] = element.answer!;
        break;
      case QuestionType.intensity:
        map['intensity_$day'] = element.answer!;
        break;
      case QuestionType.lonely:
        map['lonely_$day'] = element.answer!;
        break;
      case QuestionType.leftout:
        map['left_out_$day'] = element.answer!;
        break;
      case QuestionType.socialinteraction:
        map['social_interaction_$day'] = element.answer!;
        break;
      case QuestionType.understood:
        map['understood_$day'] = element.answer!;
        break;
      case QuestionType.stressed:
        map['stressed_$day'] = element.answer!;
        break;
      case QuestionType.whereyouare:
        map['where_you_are_$day'] = element.answer!;
        break;
      case QuestionType.peoplearoundyou:
        map['people_around_you_$day'] = element.answer!;
        break;
      case null:
      // TODO: Handle this case.
    }
  });
  return map;
}

Future<bool> uploadQuestions(dynamic id, String studyCode, int entryVersion,
  Diary diary, Map<String, dynamic> responseMap) async {
  
  int day = diary.id;
  final endtime = DateTime.now();

  final input = {
    'id': id,
    'studycode': studyCode,
    '_version': entryVersion
  };
  input.addAll(responseMap);
  input['endtime_$day'] = formatDate(endtime);

  final parameters = responseMap.keys.toList().join("\t\t\n");
  try {
    String graphQLDocument = '''
      mutation UpdateParticipants(\$input: UpdateParticipantsInput!) {
          updateParticipants(input: \$input) {
            id
            studycode
            _version
            $parameters
          }
        }
    ''';

    var operation = Amplify.API.query(
      request: GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {'input': input},
      ),
    );
    var response = await operation.response;
    var data = response.data;

    if (data != null) {
      safePrint("Questions submitted");
      return true;
    } else {
      response.errors.forEach((element) {
        safePrint('${element.message};');
      });
      return false;
    }
  } catch (e) {
    print('Exception: $e');
    return false;
  }
}
