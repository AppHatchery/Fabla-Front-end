import '../../../objectbox.g.dart';
import '../../../screens/diary/domain/entities/prompt_entity.dart';

class PromptDAO {
  final Box<Prompt> box;

  PromptDAO({required this.box});

  Prompt getPrompt(int id) {
    final prompt = box.get(id);
    if (prompt == null) throw StateError('Prompt $id not found');
    return prompt;
  }

  List<Prompt> getPrompts({required int id}) {
    return box
        .query(Prompt_.diary.equals(id))
        .order(Prompt_.questionNumber)
        .build()
        .find();
  }

  /// Retrieves all prompts from the database.
  ///
  /// This function retrieves all prompts stored in the database.
  ///
  /// Returns:
  /// A list of all Prompt objects stored in the database.
  List<Prompt> getAllPrompts() {
    // Retrieve all prompts from the database
    return box.getAll();
  }

  /// Updates a prompt in the database.
  ///
  /// This function updates the provided prompt in the database.
  ///
  /// Parameters:
  /// - [prompt]: The Prompt object to be updated in the database.
  void updatePrompt(Prompt prompt) {
    // Update the prompt in the database
    box.put(prompt);
  }

  /// Removes an item from the database by its ID.
  ///
  /// This function removes an item from the database based on the provided ID.
  ///
  /// Parameters:
  /// - [id]: The ID of the item to be removed from the database.
  void remove(int id) {
    // Remove the item from the database using its ID
    box.remove(id);
  }

  /// Removes all prompts from the database.
  /// This function removes all prompts from the database.
  void removeAllPrompts() {
    // Remove all prompts from the database
    box.removeAll();
  }
}
