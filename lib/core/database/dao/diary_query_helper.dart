// FILE: diary_query_helper.dart
// --------------------------------------------------------------------------------
// WHAT: This file defines an abstraction (`DiaryQueryHelper`) for creating
//       ObjectBox query conditions related to Diary entities, and a concrete
//       implementation (`ObjectBoxDiaryQueryHelper`) that uses the actual
//       ObjectBox generated static members (e.g., `Diary_.start`).
//
// WHY: This helper system was introduced primarily for **testability**.
//      Specifically, it addresses challenges in unit testing the `DiaryDAO` class.
//      ObjectBox query conditions often rely on static members (like `Diary_.id`
//      or `Diary_.start`) from the `objectbox.g.dart` file. These static members,
//      when invoked, may attempt to load the ObjectBox native library.
//      In a pure Dart unit test environment (without a full Flutter app context
//      or special setup for native libraries), this can lead to "Failed to load
//      ObjectBox library" errors, making it difficult to test DAO methods that
//      construct queries.
//
// HOW IT WORKS:
//   1. `DiaryQueryHelper` (Interface/Abstract Class):
//      - Defines a contract for any class that can create diary-related query
//        conditions. `DiaryDAO` will depend on this abstraction rather than
//        directly on ObjectBox static members for condition creation.
//   2. `ObjectBoxDiaryQueryHelper` (Concrete Implementation):
//      - Implements `DiaryQueryHelper` using the standard ObjectBox generated static members.
//        This is the implementation used by the application in production.
//   3. Dependency Injection in `DiaryDAO`:
//      - `DiaryDAO` is modified to accept an instance of `DiaryQueryHelper` in
//        its constructor. It defaults to `ObjectBoxDiaryQueryHelper` if no
//        helper is provided.
//      - Example: `DiaryDAO({required this.box, DiaryQueryHelper? queryHelper})`
//                 `: this.queryHelper = queryHelper ?? ObjectBoxDiaryQueryHelper();`
//   4. Mocking in Tests:
//      - In unit tests for `DiaryDAO` (e.g., `diary_dao_test.dart`), a mock
//        implementation of `DiaryQueryHelper` (e.g., `MockDiaryQueryHelper` using
//        `mocktail`) can be created and injected into the `DiaryDAO` instance
//        under test.
//      - This allows tests to specify what `Condition` the helper should return,
//        bypassing the execution of actual ObjectBox static members and the
//        associated native library loading issues.
//
// IMPACT ON ORIGINAL CODE & APP BEHAVIOR:
//   - Functional Behavior: The application's functional behavior remains
//     **unchanged**. The `ObjectBoxDiaryQueryHelper` replicates the exact same
//     query condition logic that was previously hardcoded within `DiaryDAO` methods.
//     So, the queries executed against the database are identical.
//   - Structural Change: `DiaryDAO` is now decoupled from the specifics of
//     ObjectBox condition creation. It relies on the `DiaryQueryHelper` abstraction.
//     This is an application of the Dependency Inversion Principle.
//   - Testability: `DiaryDAO` becomes significantly easier to unit test in isolation,
//     as the problematic ObjectBox-specific static calls can be mocked away.
//
// REASON FOR INTRODUCTION:
//   - To resolve persistent "Failed to load ObjectBox library" errors encountered
//     during unit tests of `DiaryDAO` methods (like `getDailyDiary` and `getDiaryByID`)
//     that construct query conditions.
//   - To enable robust unit testing without needing to manually manage native
//     library paths or use workarounds like `Store.isOpen()` in test setups, which
//     can be unreliable or have side effects.
// --------------------------------------------------------------------------------

import 'package:audio_diaries_flutter/objectbox.g.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart';

/// Abstract class defining a contract for creating query conditions for [Diary] entities.
///
/// This abstraction allows `DiaryDAO` to be decoupled from the specifics of how
/// ObjectBox query conditions are built, enabling easier unit testing by allowing
/// mock implementations of this helper to be injected.
abstract class DiaryQueryHelper {
  /// Creates an ObjectBox [Condition] to find [Diary] entities whose 'start' date
  /// falls within the range defined by [startOfDay] (inclusive) and
  /// [startOfNextDay] (exclusive).
  ///
  /// - [startOfDay]: A [DateTime] representing the beginning of the desired day (e.g., midnight).
  /// - [startOfNextDay]: A [DateTime] representing the beginning of the next day.
  Condition<Diary> createDailyRangeCondition(
      DateTime startOfDay, DateTime startOfNextDay);

  // Future methods for other query conditions (e.g., by ID) can be added here
  // if other DiaryDAO methods are refactored to use this helper system.
  // Example:
  // Condition<Diary> createIdCondition(int id);
}

/// The default, concrete implementation of [DiaryQueryHelper] for use in the
/// live application.
///
/// This class uses the standard ObjectBox generated static members (e.g., `Diary_.start`)
/// to construct query conditions. It encapsulates the direct dependency on ObjectBox
/// query-building specifics.
class ObjectBoxDiaryQueryHelper implements DiaryQueryHelper {
  /// {@macro DiaryQueryHelper.createDailyRangeCondition}
  /// This implementation uses `Diary_.start.greaterOrEqual()` and `Diary_.start.lessThan()`.
  @override
  Condition<Diary> createDailyRangeCondition(
      DateTime startOfDay, DateTime startOfNextDay) {
    return Diary_.start.greaterOrEqual(startOfDay.millisecondsSinceEpoch) &
        Diary_.start.lessThan(startOfNextDay.millisecondsSinceEpoch);
  }

  // Example for ID condition if it were added to the interface:
  // @override
  // Condition<Diary> createIdCondition(int id) {
  //   return Diary_.id.equals(id);
  // }
}
