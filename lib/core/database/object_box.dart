import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../objectbox.g.dart';

class ObjectBox {
  late final Store store;

  ObjectBox._create(this.store);

  /// Creates and initializes an ObjectBox database store.
  ///
  /// This static function is used to set up and initialize an ObjectBox database store.
  /// It first retrieves the application documents directory, then opens a store in the
  /// specified directory path with the name "database". The resulting store is used to
  /// create an ObjectBox instance, which is encapsulated in an `ObjectBox` object and returned.
  ///
  /// Returns:
  /// - An `ObjectBox` instance representing the initialized ObjectBox store.
  ///
  /// Usage example:
  /// ```dart
  /// final objectBox = await ObjectBox.create();
  /// ```
  static Future<ObjectBox> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, "database");
    // Use attach() if a store is already open at this path (e.g. when a
    // Firebase background message isolate calls main() while the foreground
    // isolate already holds the store open).
    final store = Store.isOpen(path)
        ? Store.attach(getObjectBoxModel(), path)
        : await openStore(directory: path);
    return ObjectBox._create(store);
  }
}
