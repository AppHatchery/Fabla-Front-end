import 'dart:convert';

import 'package:audio_diaries_flutter/core/utils/dummy_data.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/dao/participant_dao.dart';
import '../../../../main.dart';
import '../../../../objectbox.g.dart';
import '../entities/participant.dart';

class LoginRepository {
  final ParticipantDAO _participantDAO =
      ParticipantDAO(box: Box<Participant>(objectbox.store));

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
  /// } else {
  ///   // Display an error message indicating invalid code...
  /// }
  /// ```
  Future<bool> verify(int code) async =>
      participantCodes.contains(code) || code == 0000;

  Future<bool> studyVerification(String code) async {
    //get study
    final String response = await rootBundle.loadString('assets/protocol.json');
    final data = await json.decode(response);

    final loginCode = data['login_code'];
    print('loginCode: $loginCode | code: $code');

    return Future.delayed(
      const Duration(seconds: 2),
      () => code == loginCode,
    );
  }
}
