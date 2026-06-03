import 'dart:convert';

import 'dart:developer' as dev;
import 'package:audio_diaries_flutter/core/database/dao/experiment_dao.dart';
import 'package:audio_diaries_flutter/core/network/request.dart';
import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/experiment.dart';
import 'package:audio_diaries_flutter/screens/onboarding/data/credentials.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart'
    show CrashlyticsService;
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/database/dao/participant_dao.dart';
import '../../../../main.dart';
import '../../../../objectbox.g.dart';
import '../entities/participant.dart';

class LoginRepository {
  final ParticipantDAO _participantDAO =
      ParticipantDAO(box: Box<Participant>(objectbox.store));
  final ExperimentDAO _experimentDAO =
      ExperimentDAO(box: Box<Experiment>(objectbox.store));

  /// Adds a new participant entry to the database.
  ///
  /// This function creates a new participant entry with the provided [code] and
  /// default name (""). The participant entry is then added to the database
  /// using the associated participant DAO (Data Access Object). This function is
  /// typically used when registering a new participant for the study.
  ///
  /// Parameters:
  /// - [code]: The unique study code assigned to the new participant.
  ///
  /// Example usage:
  /// ```dart
  /// addParticipant("ABC123"); // Add a new participant with study code "ABC123".
  /// ```
  void addParticipant(String code) {
    final participant = Participant(name: "", studyCode: code);
    _participantDAO.add(participant);
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

  /// Verifies if a study code exists in the list of valid study codes.
  ///
  /// This function checks whether the provided [code] exists in the list of
  /// valid study codes. It returns a boolean value indicating whether the code
  /// is valid (exists) or not. This is commonly used to validate participant
  /// study codes during login or registration processes.
  ///
  /// Parameters:
  /// - [code]: The study code to be verified.
  ///
  /// Returns:
  /// - `true` if the study code is valid and exists in the list.
  /// - `false` if the study code is not valid or does not exist.
  ///
  /// Example usage:
  /// ```dart
  /// bool isValidCode = await verify("ABC123");
  /// if (isValidCode) {
  ///   // Proceed with login or registration...
  ///   if (isAlreadyLoggedIn) {
  ///     // Show warning about existing login...
  ///   } else {
  ///     // Proceed with normal login...
  ///   }
  /// } else {
  ///   // Display an error message indicating invalid code...
  /// }
  /// ```
  Future<Map<String, Object>> verify(String code) async {
    final entity = _experimentDAO.getExperiment();
    final experiment = ExperimentModel.fromEntity(entity!);

    bool isAlreadyLoggedIn = false;

    // Check if user has already logged in
    final getextrasmap = <String, dynamic>{};
    getextrasmap.addAll({
      'participant_id': code,
      'login_code': experiment.login,
    });

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
      } catch (e) {
        debugPrint("Response JSON decode error: $e");
      }
      return null;
    });

    // Check if user has extras data
    if (getdbextras != null && getdbextras.isNotEmpty) {
      final firstUser = getdbextras[0];
      final extraString = firstUser['extra'];
      if (extraString is String && extraString.isNotEmpty) {
        try {
          final extra = jsonDecode(extraString) as Map<String, dynamic>?;
          if (extra != null && extra.isNotEmpty) {
            // clean extras remove acknowledgment fields to check if there are any other extras
            final cleanedExtras = Map<String, dynamic>.from(extra)
              ..remove('protocol_acknowledged')
              ..remove('protocol_acknowledged_at');

            if (cleanedExtras.isNotEmpty) isAlreadyLoggedIn = true;
          }
        } catch (e) {
          debugPrint("Failed to decode 'extra': $e");
        }
      }
    }

    // Proceed with verification
    final response = await post(path: "/fabla/verifyuser", body: {
      'login_code': experiment.login,
      'participant_id': code,
    });

    if (response != null) {
      final result = json.decode(response);
      final data = result['data'];
      final exists = data['exists'];
      if (exists == true) {
        storeCredentials(data);

        //Add Participant to DB
        addParticipant(code);
        return {
          'success': true,
          'alreadyLoggedIn': isAlreadyLoggedIn,
        };
      }
    }

    return {
      'success': false,
      'alreadyLoggedIn': false,
    };
  }

  void storeCredentials(Map<String, dynamic> data) async {
    final storage = const FlutterSecureStorage();

    String authorization = data['message']['Authorization'];
    String apiKey = data['message']['x-api-key'];
    String dynamoUrl = data['message']['dynamo_url'];
    String presignedUrl = data['message']['presigned_url'];

    final credentials = Credentials(
        authorization: authorization,
        xapikey: apiKey,
        dynamo_url: dynamoUrl,
        presigned_url: presignedUrl);

    await storage.write(
        key: 'credentials', value: json.encode(credentials.toJson()));
  }

  /// Verifies the study code and retrieves the corresponding experiment information.
  ///
  /// This function sends a request to the remote source to retrieve the experiment
  /// information associated with the provided [code]. If the response is successful
  /// and the returned experiment data matches the provided code, the experiment is
  /// saved to the local database via the associated experiment DAO (Data Access Object).
  ///
  /// If the verification fails or an error occurs, the function returns null.
  ///
  /// Parameters:
  /// - [code]: The unique study code to verify.
  ///
  /// Returns:
  /// - [ExperimentModel?]: The experiment model if verification is successful, or null otherwise.
  ///
  /// Example usage:
  /// ```dart
  /// final experiment = await studyVerification("XYZ789");
  /// if (experiment != null) {
  ///   // Proceed with the experiment
  /// }
  /// ```
  Future<ExperimentModel?> studyVerification(String code) async {
    // Get the experiment information from the remote source
    try {
      final response = await post(path: "/fabla/getstudyinfo", body: {
        'login_code': code.toString(),
      });

      if (response != null) {
        final result = json.decode(response);
        final data = result['data'];
        final experiment = ExperimentModel.fromJson(data);

        // Verify the code and save the experiment data to the database
        if (code.toLowerCase() == experiment.login.toLowerCase()) {
          _experimentDAO.replaceExperiment(Experiment.fromModel(experiment));
          final setup = SetupRepository();
          final questions = data['onboarding_questions'] as List;

          final permissions = (data['permissions'] as List?)
                  ?.map((permission) => (permission as String).toLowerCase())
                  .toList() ??
              [];
          // Save the extra permissions to the shared preferences

          // Rearrange the permissions to ensure microphone is the first
          if (permissions.contains('microphone') && permissions.length > 1) {
            permissions.remove('microphone');
            permissions.insert(0, 'microphone');
          }
          await PreferenceService().setStringListPreference(
            key: 'extra_permissions',
            value: permissions,
          );

          setup.saveOnBoardingQuestions(questions);
          return experiment;
        }
      }

      return null;
    } catch (e, stackTrace) {
      // Log the error if something goes wrong
      CrashlyticsService().recordError(e, stackTrace,
          context: {'code': code},
          reason: 'Error during study verification in studyVerification');
      dev.log(e.toString(), name: "Study Verification");
      return null;
    }
  }
}
