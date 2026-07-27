import 'dart:convert';
import 'dart:io';
import '../models/schema.dart';

class SchemaLoader {
  Future<ObjectBoxModel> load(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('ObjectBox model file not found at: $path');
    }
    final content = await file.readAsString();
    final json = jsonDecode(content);
    return ObjectBoxModel.fromJson(json);
  }
}
