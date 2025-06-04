import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as dev;

class SecureSave {
  // Dependencies are stored as final fields to ensure immutability
  final FlutterSecureStorage _storage;
  final http.Client _client;

  /// Creates a new instance of SecureSave.
  ///
  /// This constructor uses dependency injection to allow for better testability:
  /// - [storage]: Optional FlutterSecureStorage instance. If not provided, creates a new instance.
  /// - [client]: Optional HTTP client. If not provided, creates a new instance.
  ///
  /// This pattern allows us to:
  /// 1. Mock dependencies in tests without modifying the actual storage or making real HTTP calls
  /// 2. Maintain backward compatibility for production code (no changes needed in existing usage)
  /// 3. Control the behavior of dependencies in tests (e.g., simulate network errors)
  SecureSave({
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  Future<String> postData(String st) async {
    try {
      // Using the injected _client instead of http.post directly
      // This allows us to mock the HTTP client in tests
      var response = await _client.post(
        Uri.parse(
            'https://3z44ix42wc77473ramwyoqr6ji0fswhn.lambda-url.us-east-1.on.aws/api/getdata'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'StudyCode': st,
        },
      );

      if (response.statusCode == 200) {
        dev.log('Response body: ${response.body}',
            name: 'Secrets Handler - Post Data');
        String jsonString = response.body;
        Map<String, dynamic> data = jsonDecode(jsonString);
        String authorization = data['message']['Authorization'];
        String apiKey = data['message']['x-api-key'];
        String dynamoUrl = data['message']['dynamo_url'];
        String presignedUrl = data['message']['presigned_url'];
        save(CredentialsModel(
            authorization: authorization,
            xapikey: apiKey,
            dynamo_url: dynamoUrl,
            presigned_url: presignedUrl));

        return response.body;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      //print('Error during HTTP request: $e');
      Map<String, dynamic> error = {
        'exists': false,
      };
      throw jsonEncode(error);
    }
  }

  Future<CredentialsModel?> read() async {
    final credentialsModel = await _storage.read(key: 'credentials');
    if (credentialsModel?.isNotEmpty ?? false) {
      return CredentialsModel.fromJson(json.decode(credentialsModel!));
    }
    return null;
  }

  Future<void> save(CredentialsModel credentialsModel) async {
    await _storage.write(
        key: 'credentials', value: json.encode(credentialsModel.toJson()));
  }
}

class CredentialsModel {
  String? authorization;
  String? xapikey;
  // ignore: non_constant_identifier_names
  String? dynamo_url;
  // ignore: non_constant_identifier_names
  String? presigned_url;

  CredentialsModel(
      // ignore: non_constant_identifier_names
      {this.authorization,
      this.xapikey,
      this.dynamo_url,
      this.presigned_url});
  CredentialsModel.fromJson(Map<String, dynamic> json) {
    authorization = json['authorization'];
    xapikey = json['x-api-key'];
    dynamo_url = json['dynamo_url'];
    presigned_url = json['presigned_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['authorization'] = authorization;
    data['x-api-key'] = xapikey;
    data['dynamo_url'] = dynamo_url;
    data['presigned_url'] = presigned_url;
    return data;
  }
}
