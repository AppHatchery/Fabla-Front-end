import 'dart:convert';
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/questions.dart';
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
  try {
    List<DiaryAudioData> fileList = [];
    List<Question> questions = [];

    for (int i = 0; i < diary.prompts.length; i++) {
      var prompt = diary.prompts[i];
      if (prompt.responseType == ResponseType.recording) {
        var rec = prompt.answer?.recordings;


        for (int r = 0; r < rec!.length; r++) {
          fileList.add(DiaryAudioData(
               prompt: i + 1, file: File(rec[r].path), date: diary.start));
        }
      } else {
        questions.add(Question(
            questionType: prompt.questionType,
            answer: prompt.answer!.response!));
      }
    }
    final questionsSubmitted =
        await apiSubmitSurveyQuestions(studyCode, diary, questions);
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
    String studycode, Diary diary, List<Question> questions) async {
  try {
    String graphQLDocument = '''
      query ListFiles {
        listParticipants(filter:{ _deleted:{attributeExists:false}, STUDYCODE: { eq: $studycode } }) {
          items { 
            id
            STUDYCODE
            _version
          }
        }
      }
    ''';
    var operation = Amplify.API.query(
      request: GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {'STUDYCODE': studycode},
      ),
    );
    var response = await operation.response;
    var data = response.data;

    if (data != null) {
      Map<String, dynamic> jsonMap = jsonDecode(data);
      final participantList = jsonMap["listParticipants"]["items"];
      dynamic id = participantList.first['id'];
      int version = participantList.first['_version'];

      final uploaded = uploadQuestions(id, studycode, version, diary, questions);
      return uploaded;
    } else {
      response.errors.forEach((element) {
        safePrint('${element.toJson()}   ${element.message};');
      });
      response.errors.first;
      safePrint("false false");
      return false;
    }
  } catch (e) {
    print('Error checking if $studycode exists: $e');
    return false;
  }
}

Future<bool> uploadQuestions(dynamic id, String studyCode, int entryVersion,
    Diary diary, List<Question> questions) async {
  var physically = filterQuestionByType(questions, QuestionType.physically)!.answer;
  var emotionally = filterQuestionByType(questions, QuestionType.emotionally)!.answer;
  var intensity = filterQuestionByType(questions, QuestionType.intensity)!.answer;
  var lonely = filterQuestionByType(questions, QuestionType.lonely)!.answer;
  var leftout = filterQuestionByType(questions, QuestionType.leftout)!.answer;
  var socialinteraction = filterQuestionByType(questions, QuestionType.socialinteraction)!.answer;
  var understood = filterQuestionByType(questions, QuestionType.understood)!.answer;
  var stressed = filterQuestionByType(questions, QuestionType.stressed)!.answer;
  var whereyouare = filterQuestionByType(questions, QuestionType.whereyouare)!.answer;
  var peoplearoundyou = filterQuestionByType(questions, QuestionType.peoplearoundyou)!.answer;
  var drinks = filterQuestionByType(questions, QuestionType.drinks)!.answer;

  int day = diary.id;

  final input = {
    'id': id,
    'STUDYCODE': '$studyCode',
    'PHYSICALLY_$day': physically,
    'EMOTIONALLY_$day': emotionally,
    'INTENSITY_$day': intensity,
    'LONELY_$day': lonely,
    'LEFT_OUT_$day': leftout,
    'SOCIAL_INTERACTION_$day': socialinteraction,
    'UNDERSTOOD_$day': understood,
    'STRESSED_$day': stressed,
    'WHERE_YOU_ARE_$day': whereyouare,
    'PEOPLE_AROUND_YOU_$day': peoplearoundyou,
    'DRINKS_$day': drinks,
    '_version': entryVersion
  };

  try {
    String graphQLDocument = '''
      mutation UpdateParticipants(\$input: UpdateParticipantsInput!) {
          updateParticipants(input: \$input) {
            id
            STUDYCODE
            PHYSICALLY_$day
            EMOTIONALLY_$day
            INTENSITY_$day
            LONELY_$day
            LEFT_OUT_$day
            SOCIAL_INTERACTION_$day
            UNDERSTOOD_$day
            STRESSED_$day
            WHERE_YOU_ARE_$day
            PEOPLE_AROUND_YOU_$day
            DRINKS_$day
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
      safePrint("Questions submitted");
      return true;
    } else {
      response.errors.forEach((element) {
        safePrint('${element.message};');
      });
      response.errors.first;
      safePrint("false false  ${response.errors.first}");
      return false;
    }
  } catch (e) {
    print('Error checking if ID exists: $e');
    return false;
  }
}
