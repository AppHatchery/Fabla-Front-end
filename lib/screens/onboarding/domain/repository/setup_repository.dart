import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/models/Participants.dart';
import 'package:audio_diaries_flutter/models/UserMetadata.dart';
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






Future<void> apiCreateMetadata(String studycode) async {
    if (!await recordExists(GqlModelType.userMetatdata, studycode)) {
      try {
        final startDate = DateTime.fromMillisecondsSinceEpoch(
            await PreferenceService().getIntPreference(key: 'startDate') ?? 0);
        final participant = UserMetadata(
          participant: studycode,
          start_study_date: formatDate(startDate),
          next_study_date: formatDate(startDate),
          day1: "null",
          day2: "null",
          day3: "null",
          day4: "null",
          day5: "null",
          day6: "null",
        );
        final request = ModelMutations.create(participant);
        final response = await Amplify.API.mutate(request: request).response;

        final participantData = response.data;
        if (participantData != null) {
          safePrint('Metadata Created mutation result: ${participantData.participant}');
          
        }else{
          safePrint('errors: ${response.errors}');
        }
      } on ApiException catch (e) {
        safePrint('Mutation failed: $e');
      }
    } else {
      safePrint("Metadata record already exists or Submission error");
    }
  }




//CURRENT TASK TEST OUT THIS FUCTION 
  Future<bool> recordExists(GqlModelType modelType, String studycode) async {
    try {
      switch (modelType) {
        case GqlModelType.participant:
          String graphQLDocument = '''
              query ListFiles {
                listParticipants(filter: { _deleted:{attributeExists:false}, studycode: { eq: "$studycode" } }) {
                  items {
                    id
                    studycode
                    _deleted
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

        case GqlModelType.userMetatdata:
          String graphQLDocument = '''
            query ListFiles {
              listUserMetadata(filter: {participant: {eq: "$studycode"}, _deleted: {attributeExists: false}}) {
                items {
                  id
                  _deleted
                }
              }
            }


            ''';
          var operation = Amplify.API.query(
            request: GraphQLRequest<String>(
              document: graphQLDocument,
              variables: {'participant': studycode},
            ),
          );
          var response = await operation.response;
          var data = response.data;
          if (data != null) {
            Map<String, dynamic> jsonMap = jsonDecode(data);
            final participantList = jsonMap["listUserMetadata"]["items"];
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
      }
    } catch (e) {
       print('$e');
      return false;
    }
  }





//Data interaction to graphql database online; you have [participantExist]

  ///Code checks if participant is available in the database
  Future<bool> participantExist(String studycode) async {
    try {
      String graphQLDocument = '''
      query ListFiles {
        listParticipants(filter: { _deleted:{attributeExists:false}, studycode: { eq: "$studycode" } }) {
          items {
            id
            studycode
            _deleted
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
        if (participantList.length > 0) {
          return true;
        }
        print("dataa: $data");
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
        final participant = Participants(studycode: studycode);
        final request = ModelMutations.create(participant);
        final response = await Amplify.API.mutate(request: request).response;

        final participantData = response.data;
        if (participantData == null) {
          print('errors: ${response.errors}');
          return;
        }
        print(
            'Participant Added Mutation result: ${participantData.studycode}');
      } on ApiException catch (e) {
        print('Mutation failed: $e');
      }
    } else {
      print("Participant Already exists or Submission error");
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
    // Cancel all existing notifications
    await NotificationService.cancelAllNotifications();

    final diaryRepository = DiaryRepository();
    final diaries = diaryRepository.getAllDiaries();

    final timesFromString = await PreferenceService()
        .getStringListPreference(key: 'reminder_times');
    final times = timesFromString
            ?.map((e) => TimeOfDay.fromDateTime(DateTime.parse(e)))
            .toList() ??
        [];
    times.sort((a, b) =>
        (a.hour + a.minute / 60.0).compareTo(b.hour + b.minute / 60.0));

    List<TimeOfDay> lateReminders =
        times.where((element) => element.hour >= 19).toList();

    final diaryNotifications = <int, List<int>>{};

    // Schedule notifications for each diary and each time.
    for (final time in times) {
      for (final diary in diaries) {
        final diaryId = diary.id;

        // Initialize the list if it doesn't exist for the diary
        diaryNotifications.putIfAbsent(diaryId, () => []);

        final date = diary.start;
        final notificationDate =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);

        final id = Random().nextInt(100000);
        final isDiary1 = diaryId == 1;
        final isSecondReminder = times.indexOf(time) > 0;

        // Define notification title and body based on diary and reminder
        final title = isDiary1
            ? 'Get Started on Your Diary Journey!'
            : 'Keep Going on Your Diary Journey!';
        final body = isDiary1
            ? isSecondReminder
                ? "Hey there! Just another check-in. Don’t forget to do your diary today."
                : "Hey there! It's time to start your diary. Your insights matter! Tap here to begin now."
            : isSecondReminder
                ? "Hey there! Just another check-in. Don’t forget to do your diary today."
                : "Hey there! You're doing great, but it's time to continue with your next diary. Your insights matter! Tap here to begin now.";

        await NotificationService.createNotification(
            id: id, title: title, body: body, date: notificationDate);

        // Add the notification ID to the diary's list
        diaryNotifications[diaryId]!.add(id);
      }
    }

    // Schedule late reminders
    final last = lateReminders.lastOrNull;
    //If there is a late reminder and it is not past 12am
    if (last != null && last.hour + 3 < 24) {
      for (final diary in diaries) {
        final diaryId = diary.id;

        final date = diary.start;
        final notificationDate = DateTime(
            date.year, date.month, date.day, last.hour + 3, last.minute);

        final id = Random().nextInt(100000);

        const title = "Let's Get Started on Your Diary!";
        const body =
            "Hey, it looks like you haven't started your diary yet. Don't worry; it's not too late to begin! Your insights are valuable, so let's start today. Click here to begin now.";

        await NotificationService.createNotification(
            id: id, title: title, body: body, date: notificationDate);

        // Add the notification ID to the diary's list
        diaryNotifications[diaryId]!.add(id);
      }
    } else if (lateReminders.isEmpty) {
      for (final diary in diaries) {
        final diaryId = diary.id;

        final date = diary.start;
        final notificationDate =
            DateTime(date.year, date.month, date.day, 21, 0);

        final id = Random().nextInt(100000);

        const title = "Let's Get Started on Your Diary!";
        const body =
            "Hey, it looks like you haven't started your diary yet. Don't worry; it's not too late to begin! Your insights are valuable, so let's start today. Click here to begin now.";

        await NotificationService.createNotification(
            id: id, title: title, body: body, date: notificationDate);

        // Add the notification ID to the diary's list
        diaryNotifications[diaryId]!.add(id);
      }
    }

    //Save to Shared Preferences
    final jsonMap = diaryNotifications.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final encoded = json.encode(jsonMap);

    PreferenceService()
        .setStringPreference(key: 'diary_notifications', value: encoded);

    // Schedule notifications for day before start
    final time =
        times.isNotEmpty ? times[0] : const TimeOfDay(hour: 17, minute: 0);
    final date = diaries[0].start.subtract(const Duration(days: 1));
    final notificationDate =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    await NotificationService.createNotification(
        title: 'Get Ready - Your Study Starts Tomorrow!',
        body:
            "Hey there! We're excited to remind you that your Daily Diary study is just around the corner. Tomorrow, we embark on this exciting journey together. Your insights will make a difference!",
        date: notificationDate);
  }
}
