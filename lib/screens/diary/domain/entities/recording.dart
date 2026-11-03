import 'package:objectbox/objectbox.dart';

import 'answer.dart';

@Entity()
class Recording {
  @Id()
  int id;
  String name;
  String path;
  String type;
  String? transcript;
  @Property(type: PropertyType.date)
  DateTime date;

  /// How long an audio take captured for, pauses left out. Null for images,
  /// videos and audio recorded before this was kept.
  int? durationMs;

  /// The loudest level an audio take reached, on flutter_sound's relative
  /// 0–120 scale. Null for images, videos and older audio.
  double? peakLevel;

  final answer = ToOne<Answer>();

  Recording(this.name, this.path, this.type, this.transcript, this.date,
      {this.id = 0, this.durationMs, this.peakLevel});
}
