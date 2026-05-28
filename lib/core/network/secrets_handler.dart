import 'dart:convert';

import 'package:audio_diaries_flutter/services/crashlytics_service.dart'
    show CrashlyticsService;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Manages backend credentials for the app.
///
/// On first login, [postData] exchanges the study code for a [CredentialsModel]
/// via a credentials Lambda endpoint. The returned credentials are persisted to
/// encrypted device storage and read back by the upload layer on every submission.
///
/// **To swap in your own backend:** replace the Lambda URL in [postData] with
/// your own credentials endpoint. The endpoint must accept a `StudyCode` form
/// field and return JSON matching:
/// ```json
/// {
///   "message": {
///     "Authorization": "…",
///     "x-api-key": "…",
///     "dynamo_url": "https://…",
///     "presigned_url": "https://…"
///   }
/// }
/// ```
class SecureSave {
  final FlutterSecureStorage _storage;
  final http.Client _client;

  SecureSave({
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  /// Fetches credentials from the backend using [st] as the study code,
  /// then persists them via [save]. Call this once during onboarding login.
  Future<String> postData(String st) async {
    try {
      // Updated to use injected http client instead of static http.post
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
    } catch (e, stackTrace) {
      //print('Error during HTTP request: $e');
      Map<String, dynamic> error = {
        'exists': false,
      };
      CrashlyticsService().recordError(e, stackTrace,
          context: {'StudyCode': st},
          reason: 'Error during HTTP request in postData');
      throw jsonEncode(error);
    }
  }

  Future<CredentialsModel?> read() async {
    try {
      final credentialsModel = await _storage.read(key: 'credentials');
      if (credentialsModel?.isNotEmpty ?? false) {
        return CredentialsModel.fromJson(json.decode(credentialsModel!));
      }
      return null;
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          reason:
              'Failed to read/decode credentials from secure storage — all upload auth will be empty');
      return null;
    }
  }

  Future<void> save(CredentialsModel credentialsModel) async {
    try {
      await _storage.write(
          key: 'credentials', value: json.encode(credentialsModel.toJson()));
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          reason:
              'Failed to write credentials to secure storage — next submission will have no auth');
    }
  }
}

/// Holds the backend credentials used by the upload layer.
///
/// - [authorization]: Bearer / AWS auth header value passed to DynamoDB and S3 endpoints.
/// - [xapikey]: API Gateway key attached to every upload request as `x-api-key`.
/// - [dynamo_url]: Endpoint that receives survey response JSON (see [uploadNonAudioData]).
/// - [presigned_url]: Endpoint that returns S3 presigned URLs for file uploads (see [getPresignedUrl]).
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
