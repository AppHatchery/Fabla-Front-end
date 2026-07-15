import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:developer' as dev;
import 'package:audio_diaries_flutter/core/database/dao/experiment_dao.dart';
import 'package:audio_diaries_flutter/core/database/dao/protocal_dao.dart';
import 'package:audio_diaries_flutter/core/database/dao/questions_dao.dart';
import 'package:audio_diaries_flutter/core/database/dao/study_dao.dart';
import 'package:audio_diaries_flutter/core/network/request.dart';
import 'package:audio_diaries_flutter/core/usecases/connectivity.dart'
    show checkForInternet;
import 'package:audio_diaries_flutter/core/usecases/home_progress_tracking.dart' show clearAllHomeProgressTracking;
import 'package:audio_diaries_flutter/core/usecases/notification_manager.dart';
import 'package:audio_diaries_flutter/core/utils/dummy_data.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/prompt_entity.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/answer_repository.dart';

import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/prompt_repository.dart';
import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/experiment.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/study.dart';
import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/questions_entity.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/notification_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/database/dao/participant_dao.dart';
import '../../../../main.dart';
import '../../../../objectbox.g.dart';
import '../../../diary/data/protocol.dart';
import '../../../diary/domain/entities/protocol_entity.dart';
import '../entities/participant.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SetupRepository {
  final ParticipantDAO _participantDAO =
      ParticipantDAO(box: Box<Participant>(objectbox.store));
  final ProtocolDAO _protocolDAO =
      ProtocolDAO(box: Box<ProtocolEntity>(objectbox.store));
  final StudyDAO _studyDAO = StudyDAO(box: Box<Study>(objectbox.store));
  final QuestionsDAO _questionsDAO =
      QuestionsDAO(box: Box<QuestionsEntity>(objectbox.store));
  final ExperimentDAO _experimentDAO =
      ExperimentDAO(box: Box<Experiment>(objectbox.store));
  final DiaryRepository diaryRepository = DiaryRepository();
  final PromptRepository promptRepository = PromptRepository();
  final AnswerRepository answerRepository = AnswerRepository();

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

    // check if protocol is already in the database and if version changed
    final ProtocolEntity? existingProtocol = _protocolDAO.getProtocol();

    if (existingProtocol == null ||
        existingProtocol.version != protocol.version) {
      // Update or add the protocol to the database
      final newProtocol = existingProtocol != null
          ? existingProtocol.copyWith(
              entity: ProtocolEntity.fromModel(model: protocol))
          : ProtocolEntity.fromModel(model: protocol);

      _protocolDAO.addProtocol(newProtocol);
    } else {
      debugPrint("Protocol already exists and no updates");
    }
  }

  /// This method is responsible for creating a protocol by retrieving data from a remote source.
  Protocol? getProtocol() {
    final ProtocolEntity? protocolEntity = _protocolDAO.getProtocol();
    return protocolEntity == null ? null : Protocol.fromEntity(protocolEntity);
  }

  /// Retrieves studies and diaries from the remote source and updates the local database.
  ///
  /// This function fetches the current experiment data from the local database and uses it
  /// to request the associated studies and diaries from a remote source. The studies and diaries
  /// are then parsed, converted into their respective models, and saved to the local database.
  ///
  /// If the request is successful, the studies and diaries are updated in the local database
  /// via the associated DAOs (Data Access Objects).
  ///
  /// This function does not return any data but updates the local database directly.
  ///
  /// Parameters:
  /// - [partialCleanDB]: If true, the database will be partially cleared by removing diaries
  ///  from the current date until the last diary, while keeping all old data. If false,
  /// the database will be completely cleared before adding new studies and diaries.
  ///
  /// Example usage:
  /// ```dart
  /// await getStudies(); // Fetch and update studies and diaries in the local database.
  /// ```
  Future<bool> getStudies({bool partialCleanDB = false}) async {
    // Retrieve the current experiment from the local database
    final entity = _experimentDAO.getExperiment();
    final experiment = ExperimentModel.fromEntity(entity!);

    final participant = _participantDAO.get();

    // Request the user's studies and diaries from the remote source
    final response = await post(path: "/fabla/getuserprotocol", body: {
      'login_code': experiment.login,
      'participant_id': participant!.studyCode,
    });

    if (response != null) {
      try {
        final data = json.decode(response)['data'];
        final studiesFromJson = data['studies'] as List;
        final studies = <StudyModel>[];

        final fetchedDiaries = <DiaryModel>[];

        for (final study in studiesFromJson) {
          final studyModel = StudyModel.fromJson(study, experiment.login);
          studies.add(studyModel);

          final diariesJson = study['diaries'] as List;
          for (final json in diariesJson) {
            final diary = DiaryModel.fromJson(json, studyModel.studyId);
            fetchedDiaries.add(diary);
          }
        }

        // If no diaries are found, return true
        if (fetchedDiaries.isEmpty) {
          dev.log("No diaries fetched from server", name: "Get Studies");
          return true;
        }

        // Determine which diaries to add based on whether this is a fresh install or not
        List<DiaryModel> diariesToAdd;

        if (partialCleanDB) {
          // NOT a fresh install - only add today and future diaries
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          diariesToAdd = fetchedDiaries
              .where((diary) => !diary.start.isBefore(today))
              .toList();

          dev.log(
              "Partial update: Total fetched: ${fetchedDiaries.length}, Future only: ${diariesToAdd.length}",
              name: "Get Studies");
        } else {
          // Fresh install - add ALL diaries
          diariesToAdd = fetchedDiaries;
          dev.log("Fresh install: Adding all ${diariesToAdd.length} diaries",
              name: "Get Studies");
        }

        // If no diaries to add, return true
        if (diariesToAdd.isEmpty) {
          dev.log("No diaries to add", name: "Get Studies");
          return true;
        }

        // Convert diaries to entities and map prompts to their models
        final entities = diariesToAdd.map((model) {
          final prompts =
              model.prompts.map((prompt) => Prompt.fromModel(prompt)).toList();
          final entity = Diary.fromModel(model);
          entity.prompts.addAll(prompts);
          return entity;
        }).toList();

        // Convert studies to entities
        final studyEntities =
            studies.map((model) => Study.fromModel(model)).toList();
        setColorForStudy(studies);

        // if partialCleanDB is true, clear the database partially
        if (partialCleanDB) {
          // Partially clear the database not to lose the old data
          // Get rid of all the data from now till last while keeping all the old data
          final now = DateTime.now();
          //get today's date
          final today = DateTime(now.year, now.month, now.day);

          dev.log("Partial clean: Deleting diaries from today onwards",
              name: "Get Studies");

          await Future.microtask(() async {
            final DiaryRepository repository = DiaryRepository();
            repository.removeDiariesFrom(today);
            _studyDAO.deleteAllStudies();
          });

          //store the date the person last updated.
          final SharedPreferences lastUpdated =
              await SharedPreferences.getInstance();

          final lastUpdatedDate = DateFormat('dd/MM/yyyy').format(today);

          await lastUpdated.setString(
              'last_Updated', lastUpdatedDate); // store today's date
          dev.log('Value added successfully!');
        } else {
          clearStudies();
        }

        // Update the local database with the fetched studies and diaries
        dev.log(
            "Studies: ${studyEntities.length} | Entities: ${entities.length}",
            name: "Get Studies");
        _studyDAO.addStudies(studyEntities);
        diaryRepository.addDiaries(entities);

        //give enough time for the database to update
        await Future.delayed(const Duration(milliseconds: 500));
        // Schedule notifications for the diaries
        NotificationManager().scheduleLimit();
        return true;
      } catch (e, stackTrace) {
        dev.log("Error parsing studies or diaries: $e", name: "Get Studies");
        CrashlyticsService().recordError(e, stackTrace,
            reason: 'Error parsing studies or diaries in getStudies');
        return false;
      }
    }
    return false;
  }

  ExperimentModel getExperiment() {
    final entity = _experimentDAO.getExperiment();
    return ExperimentModel.fromEntity(entity!);
  }

  /// Null-safe variant for flows (e.g. login screens) that run before an
  /// experiment has been stored.
  ExperimentModel? getExperimentOrNull() {
    final entity = _experimentDAO.getExperiment();
    return entity == null ? null : ExperimentModel.fromEntity(entity);
  }

  setColorForStudy(List<StudyModel> studies) async {
    final pref = PreferenceService();
    final source = await pref.getStringPreference(key: 'study_color_source');
    final Map<String, String> data = source != null
        ? (json.decode(source) as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, value.toString()))
        : {};

    for (int i = 0; i < studies.length; i++) {
      final name = studies[i].name;
      if (!data.containsKey(name)) {
        final color = studyColors[i % studyColors.length];
        data[name] = color.value.toRadixString(16);
      }
    }
    return await pref.setStringPreference(
        key: 'study_color_source', value: json.encode(data));
  }

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

  /// Retrieves the onboarding questions from the local database.
  /// This function fetches the onboarding questions from the local database
  /// using the associated questions DAO (Data Access Object). It retrieves
  /// the questions and returns them as a list of `Questions` objects.
  ///
  /// Returns:
  /// - A list of `Questions` objects containing the onboarding questions.
  Future<List<Questions>> getOnBoardingQuestions() async {
    final List<Questions> onboardingQuestions = _questionsDAO
        .getAllQuestions()
        .map((e) => Questions.fromEntity(e))
        .toList();

    return onboardingQuestions;
  }

  /// Saves the participant's onboarding answers to the local database.
  /// This function takes a `JSON` object as input.
  /// It then adds the questions in the local database using the
  /// associated questions DAO (Data Access Object).
  ///
  /// Parameters:
  /// - [json]: The `JSON` object to be added in the database.
  ///
  /// Example usage:
  /// ```dart
  /// saveOnBoardingAnswer([{...}]); // Save the answer "Yes" for the question.
  /// ```
  Future saveOnBoardingQuestions(List<dynamic> json) async {
    removeAllQuestions();

    final List<Questions> questionsModel = json
        .map((dynamic item) => Questions.fromJson(item as Map<String, dynamic>))
        .toList();

    final result = _questionsDAO.addManyQuestions(
        questionsModel.map((e) => QuestionsEntity.fromModel(e)).toList());

    debugPrint("Added questions: $result");
  }

  void saveOnBoardingAnswer(QuestionsEntity question) async {
    int result = _questionsDAO.updateQuestion(question);
    debugPrint("Save OnBoarding Answer: $result");
  }

  void removeAllQuestions() async {
    _questionsDAO.removeAllQuestions();
  }

  /// Uploads the participant's onboarding answers to the remote source.
  /// This function retrieves the onboarding questions from the local database
  /// using the associated questions DAO (Data Access Object). It then converts
  /// the questions to a `JSON` object and sends the data to the remote source.
  ///
  /// Parameters:
  /// - [partialCleanDB]: If true, the database will be partially cleared by removing diaries
  ///  from the current date until the last diary, while keeping all old data. If false,
  /// the database will be completely cleared before adding new studies and diaries.
  ///
  /// Returns:
  /// - A `Future` that resolves to a `bool` value indicating the success of the operation.
  Future<bool?> uploadOnBoardingQuestions({bool partialCleanDB = false}) async {
    final hasInternet = await checkForInternet();
    if (!hasInternet) return null;

    final List<Questions> onboardingQuestions = _questionsDAO
        .getAllQuestions()
        .map((e) => Questions.fromEntity(e))
        .toList();
    final experiment = _experimentDAO.getExperiment();
    final participant = _participantDAO.get();

    final map = <String, dynamic>{};
    final getextrasmap = <String, dynamic>{};

    final extras = <String, dynamic>{};

    for (var question in onboardingQuestions) {
      extras[question.variable] = question.answer;
    }

    String? firebaseToken;
    try {
      firebaseToken = await FirebaseMessaging.instance.getToken();
      if (firebaseToken != null) {
      } else {
        debugPrint("Failed to fetch Firebase token: Token is null.");
      }
    } catch (e, stackTrace) {
      CrashlyticsService()
          .recordError(e, stackTrace, reason: "Fetching Firebase token failed");
      debugPrint("Error fetching Firebase token: $e");
    }

    String platformName;
    if (Platform.isAndroid) {
      platformName = 'GCM';
      debugPrint("Running on Android platform.");
    } else if (Platform.isIOS) {
      platformName = 'APNS';
      debugPrint("Running on iOS platform.");
    } else {
      platformName = 'Unsupported';
      debugPrint("Running on an unsupported platform.");
    }

    // Log the platform-specific name (optional)
    debugPrint("Firebase Platform Name: $platformName");

    var repo = _experimentDAO.getExperiment();
    if (repo != null) {
      dev.log("Experiment not found.....", name: repo.login);
    }

    /////////////-------------------------------------------------/////////////
    getextrasmap.addAll(
      {
        'participant_id': participant!.studyCode.toString(),
        'login_code': experiment!.login,
      },
    );

    final getdbextras =
        await post(path: "/fabla/getuserextras", body: getextrasmap)
            .then((value) {
      if (value == null) return null;
      try {
        final response = jsonDecode(value);
        if (response is Map<String, dynamic> &&
            response['status'] == 'success') {
          return response['data'] as List<dynamic>?;
        }
      } catch (e, stackTrace) {
        CrashlyticsService()
            .recordError(e, stackTrace, reason: "Fetching user extras failed");
        dev.log("Response JSON decode error: $e");
      }
      return null;
    });

    final date = DateTime.now();
    final formatted = DateFormat('yyyy-MM-dd').format(date);
    final SharedPreferences dateJoined = await SharedPreferences.getInstance();

    if (getdbextras == null || getdbextras.isEmpty) {
      dev.log(">>>>>>>>>>>No users found in response.");
      extras['date_adjuster'] = formatted;
    } else {
      final firstUser = getdbextras[0];
      final extraString = firstUser['extra'];
      if (extraString is String) {
        try {
          final extra = jsonDecode(extraString) as Map<String, dynamic>?;
          extras['date_adjuster'] =
              (extra?['date_adjuster']?.toString().trim().isNotEmpty ?? false)
                  ? extra!['date_adjuster']
                  : formatted;
          dev.log(">>>>>>>>>>>date_adjuster: ${extras['date_adjuster']}");
        } catch (e, stackTrace) {
          CrashlyticsService().recordError(e, stackTrace,
              reason: "Decoding 'extra' field failed");
          dev.log(">>>>>>>>>>>Failed to decode 'extra': $e");
          extras['date_adjuster'] = formatted;
        }
      } else {
        dev.log(">>>>>>>>>>>Missing or invalid 'extra' field for first user.");
        extras['date_adjuster'] = formatted;
      }
    }

    final finalDate = DateFormat('dd/MM/yyyy').format(date);
    //store the date the person has finished onboarding, we will use this as date joined
    if (!dateJoined.containsKey('date_joined')) {
      await dateJoined.setString(
          'date_joined', finalDate); // store formatted, not extras map
      dev.log('Value added successfully!');
    } else {
      dev.log('Key already exists. No value was added.');
    }

    // append acknowledgment of protocol to extras
    extras['protocol_acknowledged'] = true;
    extras['protocol_acknowledged_at'] =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    //dev.log(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>: $jsonString");

    // Check if date_adjuster is already in extras from onboarding questions
    // If it exists and is not empty, use that date otherwise use current date

    map.addAll(
      {
        'participant_id': participant.studyCode.toString(),
        'login_code': experiment.login,
        'extras': jsonEncode(extras),
        'token': firebaseToken,
        'service': platformName,
      },
    );

    final result =
        await post(path: "/fabla/updateuserextras", body: map).then((value) {
      if (value != null) {
        final response = jsonDecode(value);
        return response['status'] == 'success';
      }
      return false;
    });

    if (result) {
      final res = await getStudies(partialCleanDB: partialCleanDB);
      if (res != true) {
        // getStudies failed — the server already has protocol_acknowledged=true
        // but local content was never refreshed. Roll back the acknowledgment
        // so checkForUpdates still surfaces the update on the next attempt.
        extras['protocol_acknowledged'] = false;
        extras.remove('protocol_acknowledged_at');
        map['extras'] = jsonEncode(extras);
        await post(path: "/fabla/updateuserextras", body: map);
      }
      return res;
    }

    return false;
  }

  /// Clear All Studies and Diaries
  /// This function clears all studies and diaries from the local database.
  ///
  /// Example usage:
  /// ```dart
  /// clearStudies(); // Clear all studies and diaries from the local database.
  /// ```
  void clearStudies() {
    _studyDAO.deleteAllStudies();
    diaryRepository.removeAllDiaries();
  }

  /// Leave the current study
  /// Purge all data related to the current study and participant
  /// This function clears all studies and diaries from the local database.
  /// It also removes the participant's information from the local database.
  /// The function then navigates the user to the onboarding screen.
  /// Example usage:
  /// ```dart
  /// leaveStudy(); // Leave the current study and navigate to the onboarding screen.
  /// ```
  /// Returns:
  /// - A `Future` that resolves to a `bool` value indicating the success of the operation.
  Future<bool> leaveStudy() async {
    final userclearextrasmap = <String, dynamic>{};

    final participant = _participantDAO.get();
    final experiment = _experimentDAO.getExperiment();

    try {
      userclearextrasmap.addAll(
        {
          'participant_id': participant!.studyCode.toString(),
          'login_code': experiment!.login,
        },
      );

      final leavestudymap =
          await post(path: "/fabla/leavestudy", body: userclearextrasmap)
              .then((value) {
        if (value == null) return null;
        try {
          final response = jsonDecode(value);
          if (response is Map<String, dynamic> &&
              response['status'] == 'success') {
            return response['status'];
          }
        } catch (e, stackTrace) {
          CrashlyticsService()
              .recordError(e, stackTrace, reason: "Leaving study failed");
          dev.log("Response JSON decode error: $e");
        }
        //return null;
      });

      if (leavestudymap != 'success') {
        return false;
      }

      _participantDAO.remove();
      _experimentDAO.deleteExperiment();
      _protocolDAO.deleteProtocol();
      _studyDAO.deleteAllStudies();
      _questionsDAO.removeAllQuestions();
      diaryRepository.removeAllDiaries();
      promptRepository.removeAll();
      answerRepository.removeAllResponses();
      removeAllQuestions();

      // Clear all notifications
      await NotificationService.cancelAllNotifications();

      // Clear all preferences
      await PreferenceService().clearPreferences();
      // Clear home progress tracking
      await clearAllHomeProgressTracking();

      // Clear all saved recordings
      final dir = await getApplicationDocumentsDirectory();
      final paths = ['recordings', 'images', 'videos']
          .map((folder) => p.join(dir.path, folder))
          .toList();

      await Future.wait(paths.map((path) async {
        final pathDir = Directory(path);
        if (await pathDir.exists()) {
          pathDir.deleteSync(recursive: true);
        }
      }));

      // Clear Credentials
      final storage = const FlutterSecureStorage();
      await storage.deleteAll();

      return true;
    } catch (e, stackTrace) {
      CrashlyticsService()
          .recordError(e, stackTrace, reason: "Leaving study failed");
      return false;
    }
  }
}
