import '../../../objectbox.g.dart';
import '../../../screens/diary/domain/entities/diary_entity.dart';

class DiaryDAO {
  final Box<Diary> box;

  DiaryDAO({required this.box});

  /// Retrieves and returns a list of all DiaryEntity objects stored in the database.
  /// This function provides access to the complete collection of diary entries.
  /// It retrieves the entries from the underlying storage box and returns them as a list.
  ///
  /// Returns:
  /// A list of DiaryEntity objects representing all stored diary entries.
  ///
  List<Diary> getAllDiaries() {
    return box.getAll();
  }

  /// Retrieves a single DiaryEntity object from the database based on the specified due date.
  /// This function searches for a diary entry with a due date matching the provided DateTime.
  /// It constructs a query to find the relevant entry within the storage box and returns it.
  ///
  /// Parameters:
  /// - [due]: The DateTime representing the due date of the desired diary entry.
  ///
  /// Returns:
  /// A DiaryEntity object representing the diary entry with the specified due date,
  /// or null if no matching entry is found.
  ///
  Diary? getDiary(DateTime start, DateTime due) {
    final query =
        box.query(Diary_.start.equals(start.millisecondsSinceEpoch)).build();
    return query.findFirst();
  }

  List<Diary> getDiaries(DateTime day) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final startOfNextDay = startOfDay.add(const Duration(days: 1));
    final query = box
        .query(Diary_.start.lessThan(startOfNextDay.millisecondsSinceEpoch))
        .build();
    return query.find();
  }

  /// Retrieves a diary from the database by its ID.
  ///
  /// This function constructs a query to retrieve a diary from the database based on the provided ID.
  /// It then executes the query and returns the first diary found that matches the ID.
  ///
  /// Parameters:
  /// - [id]: The ID of the diary to retrieve.
  ///
  /// Returns:
  /// The Diary object with the specified ID if found, otherwise null.
  Diary? getDiaryByID(int id) {
    // Construct a query to find a diary with the specified ID
    final query = box.query(Diary_.id.equals(id)).build();
    // Execute the query and return the first diary found
    return query.findFirst();
  }

  /// Retrieves a list of DiaryEntity objects from the database based on the specified due date.
  /// This function searches diary entries with a due date matching the provided DateTime.
  /// It constructs a query to find the relevant entry within the storage box and returns it.
  ///
  /// Parameters:
  /// - [due]: The DateTime representing the due date of the desired diary entry.
  ///
  /// Returns:
  /// A list of DiaryEntity objects representing the diary entry with the specified due date,
  /// or an empty list if no matching entry is found.
  ///
  List<Diary> getDailyDiary(DateTime due) {
    // Get the start of the provided date (midnight)
    DateTime startOfDay = DateTime(due.year, due.month, due.day);
    // Get the start of the next day (to use for comparison)
    DateTime startOfNextDay = startOfDay.add(const Duration(days: 1));
    final query = box
        .query(Diary_.start.greaterOrEqual(startOfDay.millisecondsSinceEpoch) &
            Diary_.start.lessThan(startOfNextDay.millisecondsSinceEpoch))
        .build();

    final diaries = query.find();
    query.close();
    return diaries;
  }

  /// Adds a collection of DiaryEntity objects to the database.
  /// This function stores multiple diary entries within the storage box in a single operation.
  ///
  /// Parameters:
  /// - [diaries]: A list of DiaryEntity objects representing the diary entries to be added.
  ///
  /// Note:
  /// This function efficiently inserts multiple diary entries into the storage box
  /// in a single bulk operation, which can be more efficient than inserting them individually.
  ///
  void addDiaries(List<Diary> diaries) {
    box.putMany(diaries);
  }

  /// Updates an existing DiaryEntity object in the database.
  /// This function modifies the properties of a specific diary entry within the storage box.
  ///
  /// Parameters:
  /// - [diary]: The DiaryEntity object representing the entry to be updated.
  ///
  /// Note:
  /// This function efficiently applies changes to a single diary entry within the storage box.
  /// It ensures that the modified data replaces the existing entry while preserving its unique identifier.
  ///
  void updateDiary(Diary diary) {
    box.put(diary);
  }

  /// Updates multiple existing DiaryEntity objects in the database.
  /// This function modifies the properties of a specific diary entry within the storage box.
  ///
  /// Parameters:
  /// - [diaries]: The List of DiaryEntity objects representing the entries to be updated.
  ///
  /// Note:
  /// This function efficiently applies changes to a multiple diary entries within the storage box.
  /// It ensures that the modified data replaces the existing entries while preserving its unique identifier.
  ///
  void updateDiaries(List<Diary> diaries) {
    box.putMany(diaries);
  }

  /// Delete all diary entries from the database.
  /// This function removes all diary entries from the storage box, effectively clearing the database.
  ///
  /// Returns:
  /// A boolean value indicating whether the operation was successful.
  ///
  bool deleteAllDiaries() {
    try {
      box.removeAll();
      return true;
    } catch (e) {
      return false;
    }
  }
}
