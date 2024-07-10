import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/prompt_entity.dart';
import 'package:objectbox/objectbox.dart';

import '../../../../core/utils/statuses.dart';
import '../../data/diary.dart';
import '../../data/prompt.dart';

@Entity()
class Diary {
  @Id()
  int id;
  @Transient()
  DairyType? type;
  @Property(type: PropertyType.date)
  DateTime start;
  @Property(type: PropertyType.date)
  DateTime end;
  int entries;
  int currentEntry;
  @Property(type: PropertyType.date)
  DateTime due;
  String deadline;
  @Transient()
  DiaryStatus? status;

  @Backlink('diary')
  final prompts = ToMany<Prompt>();

  int? get dbDiaryStatus {
    _ensureDiaryStatus();
    return status?.index;
  }

  set dbDiaryStatus(int? index) {
    _ensureDiaryStatus();
    status = DiaryStatus.values[index ?? 0];
  }

  int? get dbDairyType {
    _ensureDiaryType();
    return type?.index;
  }

  set dbDairyType(int? index) {
    _ensureDiaryType();
    type = DairyType.values[index ?? 0];
  }

  Diary(
      {this.id = 0,
      this.type,
      required this.due,
      required this.start,
      required this.entries,
      required this.currentEntry,
      required this.end,
      required this.deadline,
      this.status});

  /// Ensures the consistency of DiaryStatus enumeration indices.
  /// This private method verifies that the indices of the DiaryStatus enum values correspond to their expected numerical values.
  /// It uses assertions to guarantee that the indices are correctly aligned with their respective enum entries.
  ///
  /// Note:
  /// This method is intended for internal validation purposes and is not meant to be called directly in production code.
  /// Its purpose is to catch potential discrepancies between DiaryStatus enum values and their assigned indices during development.
  ///
  void _ensureDiaryStatus() {
    assert(DiaryStatus.idle.index == 0);
    assert(DiaryStatus.ongoing.index == 1);
    assert(DiaryStatus.complete.index == 2);
    assert(DiaryStatus.submitted.index == 3);
    assert(DiaryStatus.missed.index == 4);
  }

  void _ensureDiaryType() {
    assert(DairyType.daily.index == 0);
    assert(DairyType.weekly.index == 1);
    assert(DairyType.monthly.index == 2);
    assert(DairyType.yearly.index == 3);
    assert(DairyType.ema.index == 4);
  }

  /// Factory constructor that creates a DiaryEntity object from a Diary model.
  /// This function generates a DiaryEntity instance using data from a provided Diary model object.
  ///
  /// Parameters:
  /// - [model]: The Diary model object containing data to populate the new DiaryEntity instance.
  ///
  /// Returns:
  /// A DiaryEntity object representing a diary entry, constructed using information from the provided Diary model.
  ///
  factory Diary.fromModel(DiaryModel model) {
    return Diary(
      id: model.id,
      type: model.type,
      due: model.due,
      start: model.start,
      end: model.end,
      entries: model.entries,
      currentEntry: model.currentEntry,
      deadline: model.due.toString(),
      status: model.status,
    );
  }
}

int findKeyForId(int targetId, Map<int, List<PromptModel>> prompts) {
  for (final entry in prompts.entries) {
    final idList = entry.value.map((prompt) => prompt.id).toList();
    if (idList.contains(targetId)) {
      return entry.key;
    }
  }
  // Return -1 or another appropriate value if the ID is not found.
  return -1;
}
