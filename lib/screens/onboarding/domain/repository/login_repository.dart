import '../../../../core/database/dao/participant_dao.dart';
import '../../../../main.dart';
import '../../../../objectbox.g.dart';
import '../entities/participant.dart';

class LoginRepository {
  final ParticipantDAO _participantDAO =
      ParticipantDAO(box: Box<Participant>(objectbox.store));

  void addParticipant(String code) {
    final participant = Participant(name: "", studyCode: code);
    _participantDAO.add(participant);
  }

  void updateParticipant(String name) {
    _participantDAO.update(name);
  }

  Future<bool> verify(String code) async {
    print("Repo Code: $code");
    if (code == "123456") {
      return true;
    }

    return false;
  }
}
