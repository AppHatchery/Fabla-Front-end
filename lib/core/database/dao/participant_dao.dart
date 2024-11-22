import '../../../objectbox.g.dart';
import '../../../screens/onboarding/domain/entities/participant.dart';

class ParticipantDAO {
  final Box<Participant> box;

  ParticipantDAO({required this.box});

  /// Retrieves the first participant record from the database.
  ///
  /// This function constructs and executes a query to retrieve the first participant
  /// record from the database using the associated box. It returns a `Participant`
  /// object representing the first participant found, or `null` if no participants
  /// are available in the database. This function is commonly used to retrieve
  /// the current participant's information for various purposes.
  ///
  /// Returns:
  /// - A `Participant` object representing the first participant in the database,
  ///   or `null` if no participants are available.
  ///
  /// Example usage:
  /// ```dart
  /// Participant? participant = get();
  /// if (participant != null) {
  ///   // Display or manipulate participant data...
  /// }
  /// ```
  Participant? get() {
    final query = box.query().build();
    return query.findFirst();
  }

  /// Adds a participant record to the database.
  ///
  /// This function stores the provided [participant] record in the database
  /// using the associated box. The participant's data is persisted in the
  /// database, allowing it to be retrieved and used for various purposes.
  ///
  /// Parameters:
  /// - [participant]: The participant record to be added to the database.
  ///
  /// Example usage:
  /// ```dart
  /// Participant newParticipant = Participant(name: "John Doe", studyCode: "ABC123");
  /// add(newParticipant); // Store the new participant record in the database.
  /// ```
  void add(Participant participant) {
    remove();
    box.put(participant);
  }

  /// Updates the name of the current participant in the database.
  ///
  /// This function retrieves the current participant from the database using
  /// the associated box. If a participant exists, it updates the participant's
  /// [name] with the provided value and then stores the updated participant data
  /// back into the database. This function is commonly used to modify and
  /// update participant information, such as their name.
  ///
  /// Parameters:
  /// - [name]: The new name to be assigned to the participant.
  ///
  /// Example usage:
  /// ```dart
  /// update("Jane Smith"); // Update the participant's name to "Jane Smith".
  /// ```
  void update(String name) {
    final participant = get();
    if (participant != null) {
      participant.name = name;
      box.put(participant);
    }
  }

  void remove(){
    box.removeAll();
  }
}
