import 'package:objectbox/objectbox.dart';

import '../../../../core/utils/statuses.dart';
import '../../data/diary.dart';

@Entity()
class DiaryEntity {
  int id;
  @Property(type: PropertyType.byteVector)
  List<int> prompts;
  @Property(type: PropertyType.date)
  DateTime due;
  @Transient()
  DiaryStatus? status;

  int? get dbDiaryStatus {
    _ensureDiaryStatus();
    return status?.index;
  }

  set dbDiaryStatus(int? index) {
    _ensureDiaryStatus();
    status = DiaryStatus.values[index ?? 0];
  }

  DiaryEntity(
      {this.id = 0, required this.prompts, required this.due, this.status});

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
  factory DiaryEntity.fromModel(Diary model) {
    return DiaryEntity(
      id: model.id,
      prompts: model.prompts.map((e) => e.id).toList(),
      due: model.due,
      status: model.status,
    );
  }
}
