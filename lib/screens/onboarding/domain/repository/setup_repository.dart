import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:audio_diaries_flutter/core/database/dao/protocal_dao.dart';
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
import 'package:audio_diaries_flutter/services/diary_init.dart';
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
    developer.log("start date: ${date.toString()}", name: "Start Date");

    for (final phase in phases) {
      final duration = phase['duration'] as int;
      final diariesJson = phase['diaries'] as List<dynamic>;


      List<DateTime> phaseDates = [];
      for (var i = 0; i < duration; i++) {
        phaseDates.add(date);
        date = DateTime(date.year, date.month, date.day + 1);
      }

      for (DateTime date in phaseDates) {
        developer.log("Day: $date", name: "For Loop");
        for (final json in diariesJson) {
          final questions = json["question"] as List<dynamic>;
          final prompts = questions
              .map((question) => PromptModel.fromJson(question))
              .toList();
          final startTime = timeOfDayFromString(json["start_time"]);
          final endTime = timeOfDayFromString(json["end_time"]);
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
          );
          diaries.add(diary);
        }
      }

      date = phaseDates.last.add(Duration(days: 1));


    }

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

    if (times.isNotEmpty) {
      await PendoService.track("ScheduleReminder", {
        "page": page ?? "onboarding",
        "scheduled_by": "user",
        "notification_type": "reminder",
        "number_of_reminders": times.length,
        "reminder_times": times.map((e) => e.toString()).toList(),
      });
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
      await PendoService.track("ScheduleReminder", {
        "page": page ?? "onboarding",
        "scheduled_by": "auto",
        "notification_type": "late_night",
        "number_of_reminders": lateReminders.length,
        "reminder_times": lateReminders.map((e) => e.toString()).toList(),
      });
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
      await PendoService.track("ScheduleReminder", {
        "page": page ?? "onboarding",
        "scheduled_by": "auto",
        "notification_type": "late_night",
        "number_of_reminders": 1,
        "reminder_times": ["21:00"],
      });
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
