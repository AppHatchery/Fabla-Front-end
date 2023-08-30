import 'dart:io';
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

  Participant? getParticipant() {
    return _participantDAO.get();
  }

  void updateParticipant(String name) {
    _participantDAO.update(name);
  }

  void createMetadata() async {
    final participant = getParticipant();
    final today = DateTime.now();
    final date = "${today.month}/${today.day}/${today.year}";
    final code = participant!.studyCode;

    final metadata = Strings().participantMetadata(code, date);

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, "metadata.txt");
    final file = File(path);

    await file.writeAsString(metadata);

    final text = await file.readAsString();
    print("Metadata: $text");
    // TODO: Send file to S3 bucket, should be the root folder of the participant's folder
  }
}
