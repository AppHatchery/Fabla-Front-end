import 'dart:convert';
import 'dart:io';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/models/Participants.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/services/diary_init.dart';
import 'package:audio_diaries_flutter/services/notification_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../core/database/dao/participant_dao.dart';
import '../../../../main.dart';
import '../../../../objectbox.g.dart';
import '../../../../theme/resources/strings.dart';
import '../entities/participant.dart';

class SetupRepository {
  final ParticipantDAO _participantDAO =
      ParticipantDAO(box: Box<Participant>(objectbox.store));

  /// Retrieves the participant's information from the database.
  ///
  /// This function fetches and returns the participant's information from the
  /// database using the associated participant DAO (Data Access Object).
  /// It retrieves the participant's data and returns it as a `Participant` object.
  ///
  /// Returns:
  /// - A `Participant` object containing the retrieved participant's information,
  ///   or `null` if no participant information is available.
  ///
  /// Example usage:
  /// ```dart
  /// Participant? participant = getParticipant();
  /// if (participant != null) {
  ///   // Display or manipulate participant data...
  /// }
  /// ```
  Participant? getParticipant() {
    return _participantDAO.get();
  }

  /// Updates the participant's name in the database.
  ///
  /// This function updates the participant's name in the database using the
  /// associated participant DAO (Data Access Object). It takes the new [name]
  /// as input and applies the update operation to the participant's record.
  ///
  /// Parameters:
  /// - [name]: The new name to be assigned to the participant.
  ///
  /// Example usage:
  /// ```dart
  /// updateParticipant("John Doe"); // Update participant's name to "John Doe".
  /// ```
  void updateParticipant(String name) {
    _participantDAO.update(name);
  }

  /// Creates and stores metadata related to the participant's study.
  ///
  /// This function generates metadata regarding the participant's study, including
  /// their study code and the current date. It then stores this metadata in a text
  /// file named "metadata.txt". The file is created in the temporary directory.
  /// The metadata file can later be used for logging and record-keeping.
  ///
  /// After creating the metadata file, the function sends the file to a designated
  /// S3 bucket, which may serve as the participant's root folder for
  /// study-related data.
  ///
  /// Example usage:
  /// ```dart
  /// createMetadata(); // Generate and store participant's study metadata.
  /// ```

  void createMetadata() async {
    final participant = getParticipant();

    final code = participant!.studyCode;
    await diaryInit(code);

    final startDate = DateTime.fromMillisecondsSinceEpoch(
        await PreferenceService().getIntPreference(key: 'startDate') ?? 0);
    final metadata = Strings().participantMetadata(
        code, formatDate(startDate), formatDate(startDate));

    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'metadata.txt');
    final file = File(path);

    if (!file.existsSync()) {
      file.writeAsStringSync(metadata);
      print('File content is ${file.readAsStringSync()}');
      uploadMetaDataS3(code, file);
    }
  }

  /// Responsible for updating the metadata once created. This happens when diary has been submitted by participants or it has been submitted systematically.

  void updateMetaDataFile(DateTime? nextStudyDate) async {
    final participant = getParticipant();
    final code = participant!.studyCode;

    final diaryRepo = DiaryRepository();
    final allDiaries = diaryRepo.getAllDiaries();

    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'metadata.txt');
    final file = File(path);

    String contents = file.readAsStringSync();
    final data = jsonDecode(contents);
    final map = data['diaries'] as Map<String, dynamic>;

    //Check from today and backwards
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayAndBefore = allDiaries
        .where((element) =>
            element.due.isBefore(today.add(const Duration(days: 1))))
        .toList();
    if (todayAndBefore.isNotEmpty) {
      todayAndBefore.sort((a, b) => a.due.compareTo(b.due));

      int day = 1;
      for (var element in todayAndBefore) {
        map['day$day'] = element.status == DiaryStatus.submitted;
        day++;
      }

      //Updating the metadata content
      data['diaries'] = map;

      if (nextStudyDate != null) {
        data['next_study_date'] = formatDate(nextStudyDate);
        data['recent_submit_date'] = formatDate(DateTime.now());
        file.writeAsStringSync(jsonEncode(data));
        uploadMetaDataS3(code, file);
      } else {
        file.writeAsStringSync(jsonEncode(data));
      }
    }
  }
//Data interaction to graphql database online; you have [participantExist]

  ///Code checks if participant is available in the database
  Future<bool> participantExist(String studycode) async {
    try {
      String graphQLDocument = '''
      query ListFiles {
        listParticipants(filter: { _deleted:{attributeExists:false}, STUDYCODE: { eq: $studycode } }) {
          items {
            id
            STUDYCODE
            PHYSICALLY_1
            EMOTIONALLY_1
            _deleted
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
        if (participantList.length > 0) {
          return true;
        }
        safePrint("dataa: $data");
        return false;
      } else {
        response.errors.forEach((element) {
          safePrint('${element.message}.');
        });
        return false;
      }
    } catch (e) {
      print('$e');
      return false;
    }
  }

  Future<void> apiCreateParticipant(String studycode) async {
    if (!await participantExist(studycode)) {
      try {
        final participant = Participants(STUDYCODE: studycode);
        final request = ModelMutations.create(participant);
        final response = await Amplify.API.mutate(request: request).response;

        final participantData = response.data;
        if (participantData == null) {
          safePrint('errors: ${response.errors}');
          return;
        }
        safePrint(
            'Participant Added Mutation result: ${participantData.STUDYCODE}');
      } on ApiException catch (e) {
        safePrint('Mutation failed: $e');
      }
    } else {
      safePrint("Participant Already exists or Submission error");

    }
}

 /// Creates and schedules notifications for daily diaries.
  /// This function retrieves a list of daily diaries from the DiaryRepository,
  /// then retrieves a list of notification times from SharedPreferences using
  /// PreferenceService. For each specified notification time and each diary,
  /// it calculates the notification date and time and schedules a notification
  /// using NotificationService. The notification will remind the user to write
  /// their daily diary.
  /// 
 void createNotifications() async {
    final diaryRepository = DiaryRepository();
    final diaries = diaryRepository.getAllDiaries();

    final timesFromString = await PreferenceService()
        .getStringListPreference(key: 'reminder_times');
    final times = timesFromString
            ?.map((e) => TimeOfDay.fromDateTime(DateTime.parse(e)))
            .toList() ??
        [];

    for (final time in times) {
      for (final diary in diaries) {
        final date = diary.due;

        final notificationDate =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);

        await NotificationService.createNotification(
            id: diary.id,
            title: 'Time for your Daily Diary',
            body: 'Hi! I am ready to hear from you.',
            date: notificationDate);
      }

    }
  }

}