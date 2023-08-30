
import 'package:objectbox/objectbox.dart';

@Entity()
class Participant {
  @Id()
  int id;
  String name;
  String studyCode;

  Participant({this.id = 0, required this.name, required this.studyCode});
}
