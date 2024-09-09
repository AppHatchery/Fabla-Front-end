import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:audio_diaries_flutter/core/database/dao/protocal_dao.dart';
import 'package:audio_diaries_flutter/core/utils/dummy_data.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/prompt_entity.dart';

//TODO: TO BE REMOVED
// import 'package:audio_diaries_flutter/models/ParticipantsDev.dart';
// import 'package:audio_diaries_flutter/models/UserMetadata.dart';
// import 'package:audio_diaries_flutter/models/UserMetadataDev.dart';

import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/services/notification_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../core/database/dao/participant_dao.dart';
import '../../../../main.dart';
import '../../../../objectbox.g.dart';
import '../../../diary/data/protocol.dart';
import '../../../diary/domain/entities/protocol_entity.dart';
import '../entities/participant.dart';

class SetupRepository {
  final ParticipantDAO _participantDAO =
      ParticipantDAO(box: Box<Participant>(objectbox.store));
  final ProtocolDAO _protocolDAO =
      ProtocolDAO(box: Box<ProtocolEntity>(objectbox.store));

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

  /// This method is responsible for creating a protocol by retrieving data from a remote source.
  ///
  /// This function retrieves the protocol data from a remote source and stores it in the database.
  /// The function then checks if the protocol is already in the database and if the version has changed.
  /// If the protocol is new or the version has changed, the function updates or adds the protocol to the database.
  ///
  /// Example usage:
  /// ```dart
  /// createProtocol(); // Create and store the protocol in the database.
  /// ```
  void createProtocol() async {
    // Get the protocol from the assets/ from Remote source
    final String response = await rootBundle.loadString('assets/protocol.json');
    final data = await json.decode(response);

    // Convert to model
    final protocol = Protocol.fromJson(data);
    //TODO: Remove this print statements
    print(
        "Protocol-FromJSON Blueprints Active Days - ${protocol.diaryBlueprints[0].activeDays}");
    print(
        "Protocol-FromJSON Blueprints Freq - ${protocol.diaryBlueprints[0].frequency}");
    print(
        "Protocol-FromJSON Blueprints Entries = ${protocol.diaryBlueprints[0].entries}");
    print(
        "Protocol-FromJSON Blueprints Start - ${protocol.diaryBlueprints[0].startDate}");
    print(
        "Protocol-FromJSON Blueprints End - ${protocol.diaryBlueprints[0].endDate}");
    print(
        "Protocol-FromJSON Blueprints Start Time - ${protocol.diaryBlueprints[0].startTime}");
    print(
        "Protocol-FromJSON Blueprints End Time - ${protocol.diaryBlueprints[0].endTime}");
    print("Protocol-FromJSON wg - ${protocol.weeklyGoal}");
    print("Protocol-FromJSON dg - ${protocol.dailyGoal}");
    print("Protocol-FromJSON version - ${protocol.version}");

    // check if protocol is already in the database and if version changed
    final ProtocolEntity? existingProtocol = _protocolDAO.getProtocol();

    if (existingProtocol == null ||
        existingProtocol.version != protocol.version) {
      // Update or add the protocol to the database
      print(
          "Protocol is New? - ${existingProtocol == null} | is Updating? - ${existingProtocol?.version != protocol.version}");

      final newProtocol = existingProtocol != null
          ? existingProtocol.copyWith(
              entity: ProtocolEntity.fromModel(model: protocol))
          : ProtocolEntity.fromModel(model: protocol);

      print(
          "Protocol-FromModel Blueprints - ${newProtocol.diaryBlueprints[0]}");
      print("Protocol-FromModel wg - ${newProtocol.weeklyGoal}");
      print("Protocol-FromModel dg - ${newProtocol.dailyGoal}");
      print("Protocol-FromModel version - ${newProtocol.version}");

      _protocolDAO.addProtocol(newProtocol);
    } else {
      print("Protocol already exists and no updates");
    }
  }

  /// This method is responsible for creating a protocol by retrieving data from a remote source.
  Protocol? getProtocol() {
    final ProtocolEntity? protocolEntity = _protocolDAO.getProtocol();
    return protocolEntity == null ? null : Protocol.fromEntity(protocolEntity);
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
    final String response = await rootBundle.loadString('assets/protocol.json');
    final data = await json.decode(response);
    final phases = data['phase'] as List<dynamic>;
    final dayOfDownload = DateTime.now(); //Starting date
    DateTime endDay =
        DateTime(dayOfDownload.year, dayOfDownload.month, dayOfDownload.day);
    final List<DiaryModel> diaries = [];
    DateTime date = endDay;

    await PreferenceService()
        .setStringPreference(key: 'firstDay', value: dayOfDownload.toString());

    for (final phase in phases) {
      final duration = phase['duration'] as int;
      final diariesJson = phase['diaries'] as List<dynamic>;

      List<DateTime> phaseDates = [];
      for (var i = 0; i < duration; i++) {
        phaseDates.add(date);
        date = DateTime(date.year, date.month, date.day + 1);
      }

      for (DateTime date in phaseDates) {
        for (final json in diariesJson) {
          final questions = json["question"] as List<dynamic>;
          final prompts = questions
              .map((question) => PromptModel.fromJson(question))
              .toList();
          final startTime = timeOfDayFromString(json["start_time"]);
          final endTime = timeOfDayFromString(json["end_time"]);

          String rawType = json["type"];
          DiaryTypes diaryType = diaryTypeString(rawType);
          //developer.log("prompts: $prompts");
          final diary = DiaryModel(
            id: 0,
            prompts: prompts,
            tags: null,
            status: DiaryStatus.idle,
            due: DateTime(
                date.year, date.month, date.day, endTime.hour, endTime.minute),
            start: DateTime(date.year, date.month, date.day, startTime.hour,
                startTime.minute),
            entries: json["entries"],
            currentEntry: 0,
            end: DateTime(
                date.year, date.month, date.day, endTime.hour, endTime.minute),
            type: diaryType,
          );
          diaries.add(diary);
        }
      }

      date = phaseDates.last.add(const Duration(days: 1));
    }

    DateTime lastDay = date.subtract(const Duration(days: 1));
    await PreferenceService()
        .setStringPreference(key: 'lastDay', value: lastDay.toString());

    final entities = diaries.map((model) {
      final prompts =
          model.prompts.map((model) => Prompt.fromModel(model)).toList();
      final entity = Diary.fromModel(model);
      entity.prompts.addAll(prompts);
      return entity;
    }).toList();

    final repository = DiaryRepository();
    repository.addDiaries(entities);

    final protocol = Protocol(
        version: 1,
        weeklyGoal: data['weekly_goal'],
        dailyGoal: data['daily_goal'],
        diaryBlueprints: []);

    final protocolEntity = ProtocolEntity.fromModel(model: protocol);
    _protocolDAO.addProtocol(protocolEntity);
    // final participant = getParticipant();

    // final code = participant!.studyCode;
    // await diaryInit(code);

    // final startDate = DateTime.fromMillisecondsSinceEpoch(
    //     await PreferenceService().getIntPreference(key: 'startDate') ?? 0);
    // final metadata = Strings().participantMetadata(
    //     code, formatDate(startDate), formatDate(startDate));

    // final directory = await getApplicationDocumentsDirectory();
    // final path = p.join(directory.path, 'metadata.txt');
    // final file = File(path);

    // if (!file.existsSync()) {
    //   file.writeAsStringSync(metadata);
    //   print('File content is ${file.readAsStringSync()}');
    //   //TODO: TO BE REMOVED
    //   //uploadMetaDataS3(code, file);
    // }
  }

  /// Responsible for updating the metadata once created. This happens when diary has been submitted by participants or it has been submitted systematically.

  void updateMetaDataFile(DateTime? nextStudyDate) async {
    // final participant = getParticipant();
    // final code = participant!.studyCode;

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
        //TODO: TO BE REMOVED
        //uploadMetaDataS3(code, file);
      } else {
        file.writeAsStringSync(jsonEncode(data));
      }
    }
  }

//TOD :TO BE REMOVED

  // Future<void> apiCreateMetadata(String studycode) async {
  //   if (!await recordExists(GqlModelType.userMetatdata, studycode)) {
  //     try {
  //       final startDate = DateTime.fromMillisecondsSinceEpoch(
  //           await PreferenceService().getIntPreference(key: 'startDate') ?? 0);
  //       final participant = UserMetadata(
  //         participant: studycode,
  //         start_study_date: formatDate(startDate),
  //         next_study_date: formatDate(startDate),
  //         day1: "null",
  //         day2: "null",
  //         day3: "null",
  //         day4: "null",
  //         day5: "null",
  //         day6: "null",
  //       );
  //       final request = ModelMutations.create(participant);
  //       final response = await Amplify.API.mutate(request: request).response;

  //       final participantData = response.data;
  //       if (participantData != null) {
  //         safePrint(
  //             'Metadata Created mutation result: ${participantData.participant}');
  //       } else {
  //         safePrint('errors: ${response.errors}');
  //       }
  //     } on ApiException catch (e) {
  //       safePrint('Mutation failed: $e');
  //     }
  //   } else {
  //     safePrint("Metadata record already exists or Submission error");
  //   }
  // }

//TODO: TO BE REMOVED

  // Future<void> apiCreateMetadataDev(String studycode) async {
  //   final startDate = DateTime.fromMillisecondsSinceEpoch(
  //       await PreferenceService().getIntPreference(key: 'startDate') ?? 0);

  //   try {
  //     final metadata = UserMetadataDev(
  //       id: studycode,
  //       start_study_date: formatDate(startDate),
  //       next_study_date: formatDate(startDate),
  //       day1: "null",
  //       day2: "null",
  //       day3: "null",
  //       day4: "null",
  //       day5: "null",
  //       day6: "null",
  //     );
  //     final request = ModelMutations.create(metadata);
  //     final response = await Amplify.API.mutate(request: request).response;

  //     final metadataData = response.data;
  //     if (metadataData == null) {
  //       print('Metadata already exist');
  //       print('errors: ${response.errors}');
  //       return;
  //     }
  //     print('Metadata Added Mutation result: ${metadataData.id}');
  //   } on ApiException catch (e) {
  //     print('Mutation failed: $e');
  //   }
  // }

//CURRENT TASK TEST OUT THIS FUCTION
  Future<bool> recordExists(GqlModelType modelType, String studycode) async {
    try {
      switch (modelType) {
        case GqlModelType.participant:
          String graphQLDocumentDev = '''
        query ListFiles {
          getParticipantsDev(id: $studycode){
            id
            _deleted
          } 
      }
    ''';

          var operation = Amplify.API.query(
            request: GraphQLRequest<String>(document: graphQLDocumentDev),
          );
          var response = await operation.response;
          var data = response.data;
          if (data != null) {
            Map<String, dynamic> jsonMap = jsonDecode(data);
            final participantList = jsonMap["getParticipantsDev"];
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
          String graphQLDocumentDev = '''
        query ListFiles {
          getUserMetadataDev(id: "$studycode"){
            id
          }
        }
    ''';

          var operation = Amplify.API.query(
            request: GraphQLRequest<String>(document: graphQLDocumentDev),
          );
          var response = await operation.response;
          var data = response.data;
          if (data != null) {
            Map<String, dynamic> jsonMap = jsonDecode(data);
            final participantList = jsonMap["getUserMetadataDev"];
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
      String graphQLDocumentDev = '''
        query ListFiles {
          getParticipantsDev(id: "$studycode"){
            id
          }
        }
    ''';

      var operation = Amplify.API.query(
        request: GraphQLRequest<String>(document: graphQLDocumentDev),
      );
      var response = await operation.response;
      var data = response.data;
      print("check data $data ");
      if (data != null) {
        Map<String, dynamic> jsonMap = jsonDecode(data);
        print("jm: $jsonMap");
        final participantList = jsonMap["getParticipantsDev"];

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

//TODO: TO BE REMOVED

  // Future<void> apiCreateParticipant(String studycode) async {
  //   try {
  //     final participant = ParticipantsDev(id: studycode);
  //     final request = ModelMutations.create(participant);
  //     final response = await Amplify.API.mutate(request: request).response;

  //     final participantData = response.data;
  //     if (participantData == null) {
  //       print('Probably user already exists');
  //       print('errors: ${response.errors}');
  //       return;
  //     } else {
  //       apiCreateMetadataDev(studycode);
  //       print('Participant Added Mutation result: ${participantData.id}');
  //     }
  //   } on ApiException catch (e) {
  //     print('Mutation failed: $e');
  //   }
  // }

  List<DateTime> dateArray = [];
  List<Map<String, dynamic>> notifArray = [];

  Future<void> initializeAndCreateNotifications() async {
    await _initializeDateArray();
    await _loadNotifArray();
    await _createInitialNotifications();
    // print("After initialization, notifArray: $notifArray");
  }

  Future<void> checkAndCreateNotifications() async {
    await _loadNotifArray(); // Load the latest notifArray from storage
    // print("At start of check, notifArray: $notifArray");

    final now = DateTime.now();
    notifArray
        .removeWhere((item) => DateTime.parse(item['date']).isBefore(now));
    // print("After removal of old notifications, notifArray: $notifArray");

    await _initializeDateArray();

    final daysWithNotifications = notifArray.length;
    print("daysWithNotifications: $daysWithNotifications");

    if (daysWithNotifications < 4) {
      final daysToCreate = 5 - daysWithNotifications;
      print("Creating notifications for $daysToCreate days");
      await _createNotificationsForDays(daysToCreate);
      //  print("After creating new notifications, notifArray: $notifArray");
    }

    await _saveNotifArray();
    // final now = DateTime.now();
    // notifArray
    //     .removeWhere((item) => DateTime.parse(item['date']).isBefore(now));
    // print("notifArray: $notifArray");

    // final daysWithNotifications = notifArray.length;
    // print("daysWithNotifications: $daysWithNotifications");
    // if (daysWithNotifications < 5) {
    //   final daysToCreate = 5 - daysWithNotifications;
    //   await _createNotificationsForDays(daysToCreate);
    // }
  }

  Future<void> _initializeDateArray() async {
    final String? lastInitDate =
        await PreferenceService().getStringPreference(key: 'last_init_date');
    DateTime startDate;
    // final DateTime startDate =
    //     lastInitDate != null ? DateTime.parse(lastInitDate) : DateTime.now();

    if (lastInitDate != null && !notifArray.isEmpty) {
      // If we have existing notifications, calculate the next date
      final lastDate = DateTime.parse(notifArray.last['date']);
      startDate = lastDate.add(Duration(days: 1));
    } else {
      // Initial setup or no existing notifications
      startDate =
          lastInitDate != null ? DateTime.parse(lastInitDate) : DateTime.now();
    }
    dateArray =
        List.generate(14, (index) => startDate.add(Duration(days: index)));

    await PreferenceService().setStringPreference(
      key: 'last_init_date',
      value: startDate.toIso8601String(),
    );
    //print("dateArray initialized: $dateArray");
  }

  Future<void> _loadNotifArray() async {
    final String? savedNotifArray =
        await PreferenceService().getStringPreference(key: 'notif_array');
    if (savedNotifArray != null) {
      notifArray =
          List<Map<String, dynamic>>.from(json.decode(savedNotifArray));
      // print("loadednotif?>>>>>>: $notifArray");
    } else {
      // print("No saved notifArray found");
      notifArray = [];
    }
  }

  Future<void> _createInitialNotifications() async {
    if (notifArray.isEmpty) {
      // print("Creating initial notifications");
      await _createNotificationsForDays(5);
    } else {
      // print("Initial notifications already exist");
    }
  }

  Future<void> _createNotificationsForDays(int days) async {
    final diaryRepository = DiaryRepository();
    final emaDiaries = diaryRepository.getEMADiaries();
    final dailyDiary = diaryRepository.getDiariesDaily();
    final surveyDiary = diaryRepository.getSurveyDiaries();

    print("Creating notifications for notification for days $days days");
    final firstString =
        await PreferenceService().getStringPreference(key: 'firstDay');
    final first = DateTime.parse(firstString!);
    final firstDay = DateTime(first.year, first.month, first.day);

    final limitDate = first.add(Duration(days: 14));

    for (int i = 0; i < days; i++) {
      print(
          ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${dateArray.length}");
      if (i >= dateArray.length) break;

      final date = dateArray[i];
      if (date.isAfter(limitDate)) {
        print("Reached 14 days limit. Stopping notification creation.");
        break;
      }
      final dayNotifications = await _createNotificationsForDate(
          date, emaDiaries, dailyDiary, surveyDiary);

      if (dayNotifications.isNotEmpty) {
        notifArray.add({
          'date': date.toIso8601String(),
          'notifications': dayNotifications,
        });
        // print("Created notifications for date: $date");
      } else {
        print("No notifications created for date: $date");
      }
    }

    // for (int i = 0; i < days; i++) {
    //   if (i >= dateArray.length) break;

    //   final date = dateArray[i];
    //   final dayNotifications = await _createNotificationsForDate(
    //       date, emaDiaries, dailyDiary, surveyDiary);
    //   notifArray.add({
    //     'date': date.toIso8601String(),
    //     'notifications': dayNotifications,
    //   });
    //   print("Created notifications for date: $date");
    // }

    await _saveNotifArray();
  }

  Future<List<Map<String, dynamic>>> _createNotificationsForDate(
    DateTime date,
    List<DiaryModel> emaDiaries,
    List<DiaryModel> dailyDiary,
    List<DiaryModel> surveyDiaries,
  ) async {
    List<Map<String, dynamic>> dayNotifications = [];

    if (emaDiaries.isNotEmpty) {
      final emaDiary = emaDiaries.first;
      final emaNotifications = await _createEMANotifications(emaDiary, date);
      dayNotifications.addAll(emaNotifications);
    } else {
      print("No EMA diary available for date: $date");
    }

    // final emaDiary = emaDiaries.isNotEmpty ? emaDiaries.first : null;

    // if (emaDiary != null) {
    //   return await _createEMANotifications(emaDiary, date);
    // }

    // Create EMA notifications
    // for (final diary in emaDiaries) {
    //   final notifications = await _createEMANotifications(diary, date);
    //   dayNotifications.addAll(notifications);
    // }

    // print("No EMA diary available for date: $date");

    return dayNotifications;
    //return [];
  }

  Future<List<Map<String, dynamic>>> _createEMANotifications(
      DiaryModel diary, DateTime date) async {
    final startTime = DateTime(
        date.year, date.month, date.day, diary.start.hour, diary.start.minute);
    final endTime = DateTime(
        date.year, date.month, date.day, diary.end.hour, diary.end.minute);

    final startNotificationTime = startTime;
    final midNotificationTime = startTime.add(const Duration(hours: 1));
    final endNotificationTime = endTime.subtract(const Duration(minutes: 15));

    List<Map<String, dynamic>> notifications = [];
    int notifCount = 0;

    for (final time in [
      startNotificationTime,
      midNotificationTime,
      endNotificationTime
    ]) {
      String title;
      String body;

      if (time == startNotificationTime) {
        title = "It's Time to Do Your EMA";
        body =
            "Hey there, your EMA period has begun, you have two hours to complete this EMA before it won't be available";
      } else if (time == midNotificationTime) {
        title = "Your EMA is Pending";
        body =
            "Only 1 hour left to complete the EMA, it will take you 5 minutes, you don't want to miss this";
      } else {
        title = "Your EMA is Due Soon";
        body =
            "Hey there, you have only 15 mins to complete this EMA, try to grab a second from what you are doing and try to complete, shouldn't take you more than 5 minutes";
      }

      final notificationID = Random().nextInt(100000);
      await NotificationService.createNotification(
        id: notificationID,
        title: title,
        body: body,
        date: time,
      );

      notifications.add({
        'id': notificationID,
        'title': title,
        'body': body,
        'time': time.toIso8601String(),
      });

      notifCount++;

      print('Notification created for $notifCount ${diary.id} at $time');
    }

    return notifications;
  }

  Future<void> _saveNotifArray() async {
    final encoded = json.encode(notifArray);
    await PreferenceService()
        .setStringPreference(key: 'notif_array', value: encoded);
    // print("Saved notifArray: $notifArray");
  }

  // void diaryNotifications() async {
  //   DiaryRepository diaryRepository = DiaryRepository();
  //   final emaDiaries = diaryRepository.getEMADiaries();
  //   Map<int, List<int>> emaReminders = {};

  //   /// EMA NOTIFICATIONS
  //   for (final diary in emaDiaries) {
  //     final diaryId = diary.id;
  //     final startTime = diary.start;
  //     final endTime = diary.end;

  //     final startNotificationTime = startTime;
  //     final midNotificationTime = startTime.add(const Duration(hours: 1));
  //     final endNotificationTime = endTime.subtract(const Duration(minutes: 15));

  //     List<int> notificationIds = [];
  //     for (final time in [
  //       startNotificationTime,
  //       midNotificationTime,
  //       endNotificationTime
  //     ]) {
  //       String title;
  //       String body;
  //       if (time == startNotificationTime) {
  //         title = "It's Time to Do Your EMA";
  //         body =
  //             "Hey there, your EMA period has begun, you have two hours to complete this EMA before it won't be available";
  //       } else if (time == midNotificationTime) {
  //         title = "Your EMA is Pending";
  //         body =
  //             "Only 1 hour left to complete the EMA, it will take you 5 minutes, you don't want to miss this";
  //       } else {
  //         title = "Your EMA is Due Soon";
  //         body =
  //             "Hey there, you have only 15 mins to complete this EMA, try to grab a second from what you are doing and try to complete, shouldn't take you more than 5 minutes";
  //       }
  //       final notificationID = Random().nextInt(100000);
  //       await NotificationService.createNotification(
  //           id: notificationID, title: title, body: body, date: time);
  //       notificationIds.add(notificationID);
  //     }
  //     emaReminders[diaryId] = notificationIds;
  //     final encoded = json.encode(
  //         emaReminders.map((key, value) => MapEntry(key.toString(), value)));
  //     await PreferenceService()
  //         .setStringPreference(key: 'ema_reminders', value: encoded);
  //   }
  // }

  /// Creates and schedules notifications for daily diaries.
  /// This function retrieves a list of daily diaries from the DiaryRepository,
  /// then retrieves a list of notification times from SharedPreferences using
  /// PreferenceService. For each specified notification time and each diary,
  /// it calculates the notification date and time and schedules a notification
  /// using NotificationService. The notification will remind the user to write
  /// their daily diary.
  ///
  void createNotifications({String? page}) async {
    // Cancel all existing notifications
    await NotificationService.cancelAllNotifications();

    //final diaryRepository = DiaryRepository();
    //final diaries = diaryRepository.getAllDiaries();

    final timesFromString = await PreferenceService()
        .getStringListPreference(key: 'reminder_times');
    final times = timesFromString
            ?.map((e) => TimeOfDay.fromDateTime(DateTime.parse(e)))
            .toList() ??
        [];
    times.sort((a, b) =>
        (a.hour + a.minute / 60.0).compareTo(b.hour + b.minute / 60.0));

    Map<int, List<int>> userReminders = {};

    final firstString =
        await PreferenceService().getStringPreference(key: 'firstDay');
    final first = DateTime.parse(firstString!);
    final firstDay = DateTime(first.year, first.month, first.day);

    final durationDays = 14;

    //schedule notification for each time:
    for (int day = 0; day < durationDays; day++) {
      List<int> notificationIds = [];
      for (final time in times) {
        final date = DateTime.now().add(Duration(days: day));
        final notificationDate =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
        final id = Random().nextInt(100000);
        final isFirstDay = DateTime(date.year, date.month, date.day)
            .isAtSameMomentAs(firstDay);

        final title = isFirstDay
            ? 'Get Started on Your Diary Journey!'
            : 'Keep Going on Your Diary Journey!';
        const body =
            "Hey there! It's time to start your diary. Your insights matter! Tap here to begin now.";

        await NotificationService.createNotification(
            id: id, title: title, body: body, date: notificationDate);

        notificationIds.add(id);
      }
      userReminders[day] = notificationIds;
    }

    if (times.isNotEmpty) {
      await PendoService.track("ScheduleReminder", {
        "page": page ?? "onboarding",
        "scheduled_by": "user",
        "notification_type": "reminder",
        "number_of_reminders": times.length,
        "reminder_times": times.map((e) => e.toString()).toList(),
      });
    }

    //Save to Shared Preferences
    final jsonMap = userReminders.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final encoded = json.encode(jsonMap);

    PreferenceService()
        .setStringPreference(key: 'diary_notifications', value: encoded);
  }
}
