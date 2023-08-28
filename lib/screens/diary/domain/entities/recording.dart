import 'package:objectbox/objectbox.dart';

import 'answer.dart';

@Entity()
class Recording {
  @Id()
  int id;
  String name;
  String path;
  String? transcript;
  @Property(type: PropertyType.date)
  DateTime date;

  final answer = ToOne<Answer>();

  Recording(this.name, this.path, this.transcript, this.date, {this.id = 0});
}
