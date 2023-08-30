import '../../../objectbox.g.dart';
import '../../../screens/onboarding/domain/entities/participant.dart';

class ParticipantDAO {
  final Box<Participant> box;

  ParticipantDAO({required this.box});

  Participant? get() {
    final query = box.query().build();
    return query.findFirst();
  }

  void add(Participant participant) {
    box.put(participant);
  }

  void update(String name) {
    final participant = get();
    if (participant != null) {
      participant.name = name;
      box.put(participant);
    }
  }
}
