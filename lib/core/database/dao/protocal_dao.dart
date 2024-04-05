import 'package:objectbox/objectbox.dart';

import '../../../screens/diary/domain/entities/protocol_entity.dart';

class ProtocolDAO {
  final Box<ProtocolEntity> box;

  ProtocolDAO({required this.box});

  /// Retrieves and returns a ProtocolEntity object stored in the database.
  /// This function provides access to the stored protocol data.
  /// It retrieves the protocol from the underlying storage box and returns it.
  ///
  /// Returns:
  /// A ProtocolEntity object representing the stored protocol data.
  ///
  ProtocolEntity? getProtocol() {
    return box.isEmpty() ? null : box.getAll().first;
  }

  /// Adds a ProtocolEntity object to the database.
  /// This function stores the protocol data within the storage box.
  ///
  /// Parameters:
  /// - [entity]: A ProtocolEntity object representing the protocol data to be added.
  ///
  /// Note:
  /// This function inserts the protocol data into the storage box. If there is an existing protocol,
  /// it will be replaced by the new data.
  void addProtocol(ProtocolEntity entity) {
    box.put(entity);
  }

  /// Deletes the stored ProtocolEntity object from the database.
  /// This function removes the protocol data from the storage box.
  ///
  /// Note:
  /// This function deletes the protocol data from the storage box. If there is no protocol data stored,
  void deleteProtocol() {
    box.removeAll();
  }
}
