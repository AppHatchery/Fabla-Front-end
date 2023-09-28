import 'dart:convert';
import 'dart:io';
import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/services/diary_init.dart';
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

  void createMetadata(DateTime nextStudyDate) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final participant = getParticipant();
    final today = DateTime.now();
    final date = formatDate(today);
    final code = participant!.studyCode;

    final metadata =
        Strings().participantMetadata(code, date, formatDate(nextStudyDate));
    await diaryInit(code);

    final filePath = p.join(documentsDirectory.path, 'metadata.txt');
    var file = File(filePath);
    if (!file.existsSync()) {
      file.writeAsStringSync(metadata);

      print('file here ${file.path}');
      uploadMetaDataS3(code, file);
    }
  }

  /// Responsible for updating the metadata once created. This happens when diary has been submitted by participants or it has been submitted systematically.

  void updateMetaDataFile(DateTime nextStudyDate) async {
    final participant = getParticipant();
    final code = participant!.studyCode;
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final filePath = p.join(documentsDirectory.path, 'metadata.txt');
    final file = File(filePath);

    String contents = file.readAsStringSync();
    final data = jsonDecode(contents);

    final map = data['diaries'] as Map<String, dynamic>;
    final diaryRepo = DiaryRepository();

    final allDiaries = diaryRepo.getAllDiaries();

    //Check from today and backwards
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
            .add(Duration(days: 4));
    final todayAndBefore = allDiaries
        .where((element) =>
            element.due.isBefore(today.add(const Duration(days: 1))))
        .toList();
    todayAndBefore.sort((a, b) => a.due.compareTo(b.due));

    print('todays ${formatDate(today)} ${todayAndBefore.length}}');
    int day = 1;
    todayAndBefore.forEach((element) {
      map['day$day'] = element.status == DiaryStatus.submitted;
      day++;

      print('dues: ${element.due}');
    });

    print('$map map');

    //Updating the metadata content
    data['diaries'] = map;
    data['next_study_date'] = formatDate(nextStudyDate);
    data['recent_submit_date'] = formatDate(DateTime.now());

    file.writeAsStringSync(jsonEncode(data));
    //uploadMetaDataS3(code, file);

    print("File Contents :${map.length}  ${file.readAsStringSync()}");
  }
}
