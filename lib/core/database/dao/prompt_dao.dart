import '../../../objectbox.g.dart';
import '../../../screens/diary/domain/entities/prompt_entity.dart';

class PromptDAO {
  final Box<Prompt> box;

  PromptDAO({required this.box});

  /// Retrieves a prompt with the specified ID from the database.
  ///
  /// This function queries the database to retrieve a prompt with the given ID,
  /// and returns the first prompt found that matches the ID.
  ///
  /// Parameters:
  /// - [id]: The ID of the prompt to retrieve.
  ///
  /// Returns:
  /// A Prompt object representing the prompt with the specified ID.
  Prompt getPrompt(int id) {
    // Query the database to find the prompt with the specified ID
    return box.query().build().find().firstWhere((element) => element.id == id);
  }

  /// Retrieves prompts associated with a specific diary ID from the database.
  ///
  /// This function queries the database to retrieve prompts that are associated with
  /// the diary having the provided ID. It filters prompts based on the target diary's ID.
  ///
  /// Parameters:
  /// - [id]: The ID of the diary whose prompts are to be retrieved.
  ///
  /// Returns:
  /// A list of Prompt objects associated with the diary ID.
  List<Prompt> getPrompts({required int id}) {
    // Query the database to find prompts associated with the specified diary ID
    return box
        .query()
        .build()
        .find()
        .where((element) => element.diary.target?.id == id)
        .toList();
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
}
