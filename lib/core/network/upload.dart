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
import 'package:http/http.dart' as http;
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
Future<bool> upload(String studyCode, DiaryModel diary) async {
  final dir = await getApplicationDocumentsDirectory();
  try {
    List<PromptEntry> promptEntryList = [];
    List<AudioData> audioData = [];

    int promptNumber = 0;

    for (int i = 0; i < diary.prompts.length; i++) {
      var prompt = diary.prompts[i];

      if (prompt.answer != null) {
        promptNumber++;

        if (prompt.responseType == ResponseType.recording) {
          if (prompt.answer!.recordings.isNotEmpty) {
            final path = p.join(
                dir.path, 'recordings', prompt.answer?.recordings.first.path);
            var filename = p.basename(path);
            var date = getPostDate(diary.start);
            var awsPath = "$studyCode/$date/prompt_$promptNumber/$filename";
            audioData
                .add(AudioData(localDirectory: path, awsS3Directory: awsPath));
          } else {
            promptEntryList.add(PromptEntry(
                studyCode: studyCode,
                questionTitle: prompt.question,
                diaryID: diary.id.toString(),
                promptID: prompt.id.toString(),
                response: prompt.answer!.response!,
                questionsType: AwsUtils.getResponseType(
                    ResponseType.text.toString()), // Corrected parameter name
                required: prompt.required));
          }
        } else {
          promptEntryList.add(PromptEntry(
              studyCode: studyCode,
              questionTitle: prompt.question,
              diaryID: diary.id.toString(),
              promptID: prompt.id.toString(),
              response: prompt.answer!.response!,
              questionsType:
                  AwsUtils.getResponseType(prompt.responseType.toString()),
              // Corrected parameter name
              required: prompt.required));
        }
      }
    }

    var uploaded = await awsUploadResponses(promptEntryList, audioData);
    if (uploaded) {
      print("All data sent to AWS");
    } else {
      print("Data not sent to AWS");
    }

    return uploaded;
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
      PendoService.track("UploadError", {"errorcode": "s3 diary"});
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
    PendoService.track("UploadError", {"errorcode": "S3 metadata"});
    print('Error uploading file: ${e.message}');
    return false;
  }
  return true;
}

Future<bool> uploadFileS3(var studyCode, File file) async {
  final awsFile = AWSFilePlatform.fromFile(file);
  try {
    final name = p.basename(file.path);
    final uploadResult = await Amplify.Storage.uploadFile(
      localFile: awsFile,
      key: "$studyCode/$name",
    ).result;
    print('Uploaded file to s3: ${uploadResult.uploadedItem.key}');
    return true;
  } on StorageException catch (e) {
    print('Error uploading file: ${e.message}');
    return false;
  }
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
    String studycode, DiaryModel diary, Map<String, dynamic> map) async {
  try {
    String graphQLDocument = '''
      query ListFiles {
  getParticipantsDev(id: $studycode){
    id
    _version
  }
}

    ''';
    var operation = Amplify.API.query(
      request: GraphQLRequest<String>(document: graphQLDocument),
    );
    var response = await operation.response;
    var data = response.data;

    if (data != null) {
      Map<String, dynamic> jsonMap = jsonDecode(data);
      print("map size: $jsonMap");
      final participantList = jsonMap["getParticipantsDev"];
      dynamic id = participantList['id'];
      int version = participantList['_version'];
      final uploaded = uploadQuestions(id, studycode, version, diary, map);
      return uploaded;
    } else {
      response.errors.forEach((element) {
        safePrint('${element.toJson()}   ${element.message};');
      });
      return false;
    }
  } catch (e) {
    PendoService.track("UploadError", {"errorcode": "GraphQL diary"});
    print('Error checking if $studycode exists: $e');
    return false;
  }
}
// META DATA FUNCTIONS

Future<GqlApiRequestStateUpdate> participantsDiaryStartDate(
    DiaryModel? diary) async {
  int day = diary!.id;
  DateTime diaryStartTime = DateTime.now();
  SetupRepository repo = SetupRepository();
  GqlApiRequestStateUpdate updateState = GqlApiRequestStateUpdate.idle;
  final studycode = repo.getParticipant()!.studyCode;

  if (await repo.participantExist(studycode)) {
    final map = await apiGetParticipant(studycode);
    safePrint("map: $map");
    final id = map['id'];
    final version = map['_version'];

    final input = {
      'id': id,
      'starttime_$day': formatDate(diaryStartTime),
      '_version': version
    };
    //safePrint("StartTime: $input");
    try {
      String graphQLDocument = '''
      mutation UpdateParticipantsDev(\$input: UpdateParticipantsDevInput!) {
          updateParticipantsDev(input: \$input) {
            id
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
            "${data} Diary started updated startdate ${formatDate(diaryStartTime)}");
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
  String graphQLDocumentDev = '''
        query ListFiles {
          getParticipantsDev(id: $studycode){
          id
          _version
        }
      }
    ''';

  try {
    var operation = Amplify.API.query(
      request: GraphQLRequest<String>(
        document: graphQLDocumentDev,
      ),
    );
    var response = await operation.response;
    var data = response.data;

    if (data != null) {
      Map<String, dynamic> jsonMap = jsonDecode(data);
      print("jsson map: $jsonMap ");
      final participantList = jsonMap["getParticipantsDev"];
      return participantList;
    } else {
      response.errors.forEach((element) {
        safePrint('${element.toJson()}   ${element.message};');
      });
      return null;
    }
  } catch (e) {
    PendoService.track("UploadError", {"errorcode": "GraphQL get participant"});
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
    DiaryModel diary, Map<String, dynamic> responseMap) async {
  int day = diary.id;
  final endtime = DateTime.now();
  if (responseMap.length == 10) {
    responseMap['endtime_$day'] = formatDate(endtime);
  }

  final input = {'id': id, '_version': entryVersion};
  input.addAll(responseMap);

  final directory = await getTemporaryDirectory();
  final path = p.join(directory.path, 'responses_diary_${diary.id}.json');
  final file = File(path);
  file.writeAsString(jsonEncode(responseMap));

  final parameters = responseMap.keys.toList().join("\t\t\n");
  try {
    String graphQLDocument = '''
      mutation UpdateParticipantsDev(\$input: UpdateParticipantsDevInput!) {
          updateParticipantsDev(input: \$input) {
            id
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

    final uploaded = await uploadFileS3(studyCode, file);

    if (data != null && uploaded) {
      print("Questions submitted");
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

Future<dynamic> apiGetUseMetaData(String studycode) async {
  String graphQLDocumentDev = '''
        query ListFiles {
          getUserMetadataDev(id: $studycode){
          id
          _version
        }
      }
    ''';

  try {
    var operation = Amplify.API.query(
      request: GraphQLRequest<String>(
        document: graphQLDocumentDev,
      ),
    );
    var response = await operation.response;
    var data = response.data;

    if (data != null) {
      Map<String, dynamic> jsonMap = jsonDecode(data);
      //print("jsson map: $jsonMap ");
      final participantList = jsonMap["getUserMetadataDev"];
      return participantList;
    } else {
      response.errors.forEach((element) {
        safePrint('${element.toJson()}   ${element.message};');
      });
      return null;
    }
  } catch (e) {
    print('Error checking if $studycode exists: $e');
    return null;
  }
}

Future<GqlApiRequestStateUpdate> updateMetataData(DiaryModel? diary) async {
  final day = diary!.id;
  DateTime diaryStartTime = DateTime.now();
  SetupRepository repo = SetupRepository();
  GqlApiRequestStateUpdate updateState = GqlApiRequestStateUpdate.idle;
  final studycode = repo.getParticipant()!.studyCode;

  if (await repo.recordExists(GqlModelType.userMetatdata, studycode)) {
    final map = await apiGetUseMetaData(studycode);
    final id = map['id'];
    int version = map['_version'];

    final dateNow = DateTime.now();
    final recentSubmittedDate = formatDate(DateTime.now());

    final nextStudyDate = formatDate(
        DateTime(dateNow.year, dateNow.month, dateNow.day)
            .add(const Duration(days: 1)));

    final nsd = parametersNextStudydate(nextStudyDate, day);

    final input = {
      'id': id,
      '_version': version,
      'day$day': 'true',
      'next_study_date': nsd,
      'recent_submit_date': recentSubmittedDate
    };
    try {
      String graphQLDocument = '''
      mutation UpdateUserMetadataDev(\$input: UpdateUserMetadataDevInput!) {
          updateUserMetadataDev(input: \$input) {
            id
            _version
            day$day
            next_study_date
            recent_submit_date
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
        updateState = GqlApiRequestStateUpdate.updated;
        print("metadata updated to true for this day");
        return updateState;
      } else {
        for (var element in response.errors) {
          safePrint('${element.message};');
        }
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

String parametersNextStudydate(String date, int day) {
  if (day != 6) {
    return date;
  } else {
    return "";
  }
}

//Upload functions
Future<bool> uploadNonAudioData(List<PromptEntry> promptEntryList) async {
  // List of items to be sent in the request body
  List<Map<String, dynamic>> promptListItems =
      PromptEntry.promptListToMap(promptEntryList);
  // Encode the list of items to JSON
  String jsonBody = json.encode(promptListItems);

  // Set up the HTTP POST request
  var url = Uri.parse(
      'https://r79428yn1l.execute-api.us-east-1.amazonaws.com/live/dynsendresponse'); // Replace with your API endpoint
  var headers = {
    'Content-Type': 'application/json',
    'Authorization': 'MySecretToken',
    'x-api-key': 'GUdxp5Wjej8uNDz2WoXm34QOpCJigEMl8570RFNy'
  };

  try {
    var response = await http.post(url, headers: headers, body: jsonBody);

    if (response.statusCode == 200) {
      // Request successful
      print('Dynamo DB: All items processed successfully');
      return true; // Submission successful
    } else {
      // Request failed
      print('Dynamo DB: Request failed with status: ${response}');
      return false; // Submission failed
    }
  } catch (e) {
    // An error occurred
    print('Error sending request: $e');
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
Future<String?> getPresignedUrl(String apiUrl, String filename) async {
  try {
    var requestBody = jsonEncode({'filename': filename});

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
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

      print("presigned URL is generated");
      return uploadUrl;
    } else {
      print(
          'Failed to get presigned URL: ${response.statusCode}, ${response.body}');
      return null;
    }
  } catch (e) {
    print('Error getting presigned URL: $e');
    return null;
  }
}

Future<bool> uploadFileToS3(String presignedUrl, String filePath) async {
  try {
    var file = File(filePath);
    var fileStream = file.openRead();

    var request = http.Request('PUT', Uri.parse(presignedUrl))
      ..headers['Content-Type'] = 'audio/mpeg';

    // Collect bytes from the file stream into a single list
    List<int> bytes = [];
    await for (var chunk in fileStream) {
      bytes.addAll(chunk);
    }

    // Set the body bytes of the request
    request.bodyBytes = bytes;

    var response = await http.Client().send(request);

    if (response.statusCode == 200) {
      print('S3 Storage: File uploaded successfully');
      return true; // Return true if upload successful
    } else {
      print(
          'S3 Storage: Failed to upload file. Status code: ${response.statusCode}');
      return false; // Return false if upload failed
    }
  } catch (e) {
    print('S3 Storage: Error uploading file: $e');
    return false; // Return false if an error occurred
  }
}

Future<bool> uploadAudios(List<AudioData> audioFileData) async {
  var apiUrl =
      'https://r79428yn1l.execute-api.us-east-1.amazonaws.com/live/s3upload';
  var sent = false;
  for (var data in audioFileData) {
    var presignedUrl = await getPresignedUrl(apiUrl, data.awsS3Directory);
    //print("PRESIGNED URL: " + presignedUrl!);
    if (presignedUrl != null) {
      sent = await uploadFileToS3(presignedUrl, data.localDirectory);
    }
  }
  print("uploaded in array $sent");
  return sent;
}

//Upload Models

class AudioData {
  String localDirectory;
  String awsS3Directory;
  // Constructor
  AudioData({required this.localDirectory, required this.awsS3Directory});
}

class AwsUtils {
  static getResponseType(String inputString) {
    List<String> parts = inputString.split('.');
    return parts.length > 1 ? parts[1] : inputString;
  }
}

///Class representing audio entry in the dynamo db once an object is created
///
class PromptEntry {
  String studyCode;
  String questionTitle;
  String diaryID;
  String promptID;
  String response;
  String questionsType; // Corrected parameter name
  bool required;

  // Constructor
  PromptEntry(
      {required this.studyCode,
      required this.questionTitle,
      required this.diaryID,
      required this.promptID,
      required this.response,
      required this.questionsType, // Corrected parameter name
      required this.required});

  static List<Map<String, dynamic>> promptListToMap(
      List<PromptEntry> promptEntryList) {
    List<Map<String, dynamic>> items = [];

    for (var entry in promptEntryList) {
      Map<String, dynamic> map = {
        "StudyCode": entry.studyCode,
        "QuestionTitle": entry.questionTitle,
        "DiaryID": entry.diaryID,
        "PromptID": entry.promptID,
        "Response": entry.response,
        "QuestionsType": entry.questionsType,
        "Required": entry.required.toString() // Convert bool to string
      };
      items.add(map);
    }

    return items;
  }
}

Future<bool> awsUploadResponses(
    List<PromptEntry> promptEntryList, List<AudioData> audioData) async {
  try {
    if (audioData.isNotEmpty) {
      var audioDataSent = await uploadAudios(audioData);
      if (!audioDataSent) {
        return false; // Return false if audio data failed to upload
      }
    }
    // Send non-audio data regardless of whether audio data was sent or not
    var nonAudioDataSent = await uploadNonAudioData(promptEntryList);
    return nonAudioDataSent;
  } catch (e) {
    print("EXCEPTION: $e");
    return false;
  }
}
