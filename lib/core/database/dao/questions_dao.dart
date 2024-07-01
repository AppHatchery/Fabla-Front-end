import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/questions_entity.dart';

import '../../../objectbox.g.dart';

class QuestionsDAO {
  final Box<QuestionsEntity> box;

  QuestionsDAO({required this.box});

  /// Retrieves a question with the specified ID from the database.
  /// This function queries the database to retrieve a question with the given ID,
  /// and returns the first question found that matches the ID.
  /// Parameters:
  /// - [id]: The ID of the question to retrieve.
  /// Returns:
  /// A QuestionsEntity object representing the question with the specified ID.
  QuestionsEntity getQuestion(int id) {
    // Query the database to find the question with the specified ID
    return box.query().build().find().firstWhere((element) => element.id == id);
  }

  /// Retrieves all questions from the database.
  /// This function retrieves all questions stored in the database.
  /// Returns:
  /// A list of all QuestionsEntity objects stored in the database.
  List<QuestionsEntity> getAllQuestions() {
    // Retrieve all questions from the database
    return box.getAll();
  }

  /// Updates a question in the database.
  /// This function updates the provided question in the database.
  /// Parameters:
  /// - [question]: The QuestionsEntity object to be updated in the database.
  ///
  /// Returns:
  /// The ID of the updated question.
  int updateQuestion(QuestionsEntity question) {
    // Update the question in the database
    return box.put(question);
  }

  /// Add many questions in the database
  List<int> addManyQuestions(List<QuestionsEntity> entities) {
    return box.putMany(entities);
  }

  /// Remove all the questions from the database
  /// This function removes all the questions from the database.
  /// Returns:
  /// The number of questions removed.
  int removeAllQuestions() {
    // Remove all the questions from the database
    return box.removeAll();
  }
}
