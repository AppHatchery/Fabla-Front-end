import '../../../objectbox.g.dart';
import '../../../screens/diary/domain/entities/answer.dart';

class AnswerDAO {
  final Box<Answer> box;

  AnswerDAO({required this.box});

  /// Retrieves a list of Answer objects associated with a specific prompt ID from the database.
  /// This function searches for and returns all answers related to the provided prompt ID.
  ///
  /// Parameters:
  /// - [id]: An integer representing the unique ID of the prompt for which answers are sought.
  ///
  /// Returns:
  /// A list of Answer objects representing responses linked to the specified prompt ID.
  ///
  List<Answer> getAnswers(int id) {
    // changed from : 
    ///    return box.query(Answer_.promptId.equals(id)).build().find();
    /// to this for cleaning
    return box.query().build().find();
  }

  /// Adds or updates an answer in the database based on the provided answer's prompt ID.
  ///
  /// This function adds a new answer to the data store if no existing answer is associated with
  /// the provided [answer]'s prompt ID. If an answer with the same prompt ID already exists, the
  /// provided answer is updated with the same ID. The answer is then stored in the database.
  ///
  /// Parameters:
  /// - [answer]: The answer instance to be added or updated in the database.
  ///
  /// Usage example:
  /// ```dart
  /// final newAnswer = Answer(promptId: 123, date: DateTime.now());
  /// addResponse(newAnswer);
  /// ```
  void addResponse(Answer answer) {
    // Query for existing answers with the same prompt ID
    //commented out for cleaning purposes
    // final query = box.query(Answer_.promptId.equals(answer.promptId)).build();
    // final results = query.find();

    // if (results.isNotEmpty) {
    //   final id = results.first.id; // Update the ID with the existing ID
    //   answer.id = id;
    // }

    box.put(answer); // Store the answer in the database
  }

  /// Updates or adds an Answer object in the database.
  /// This function either updates an existing stored response or adds a new response to the storage box.
  ///
  /// Parameters:
  /// - [answer]: The Answer object representing the response to be updated or added.
  ///
  /// Note:
  /// This function efficiently applies changes to a single response within the storage box.
  /// If the provided Answer object has an existing identifier, it updates the corresponding response;
  /// if the identifier is new, it adds the response as a new entry.
  ///
  void updateResponse(Answer answer) {
    box.put(answer);
  }

  /// Removes a response from the database based on a specified identifier.
  /// This function deletes a stored response associated with the provided identifier.
  ///
  /// Parameters:
  /// - [id]: An identifier indicating the response to be removed.
  ///
  /// Note:
  /// This function efficiently removes a response from the storage box based on its identifier.
  /// It ensures that the response is permanently deleted from the data storage.
  ///
  void removeResponse(int id) {
    box.remove(id);
  }
}
