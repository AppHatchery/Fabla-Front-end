import 'dart:convert';

import 'package:audio_diaries_flutter/core/network/request.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart'
    show CrashlyticsService;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages backend credentials for the app.
///
/// On first login, [getCredentials] exchanges the study code for a [CredentialsModel]
/// via a credentials Lambda endpoint. The returned credentials are persisted to
/// encrypted device storage and read back by the upload layer on every submission.
///
/// **To swap in your own backend:** replace the Lambda URL in [getCredentials] with
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
  static const credentialsKey = 'credentials';
  static const _backgroundAccessMigrationKey =
      'credentials_background_access_v1';

  /// Allows iOS to read upload credentials while the device is locked, after
  /// the user has unlocked it once since the most recent device restart.
  static const backgroundIOSOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage;

  SecureSave({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(iOptions: backgroundIOSOptions);

  /// Rewrites credentials created by older app versions with the background-
  /// accessible iOS Keychain protection level.
  Future<void> migrateCredentialsForBackgroundAccess({
    FlutterSecureStorage? legacyStorage,
    SharedPreferences? preferences,
    bool? isIOS,
  }) async {
    if (!(isIOS ?? defaultTargetPlatform == TargetPlatform.iOS)) return;

    final prefs = preferences ?? await SharedPreferences.getInstance();
    if (prefs.getBool(_backgroundAccessMigrationKey) == true) return;

    final legacy = legacyStorage ?? const FlutterSecureStorage();
    try {
      final stored = await legacy.read(key: credentialsKey);
      if (stored != null && stored.isNotEmpty) {
        // Updating an existing Keychain value does not change its accessibility
        // attribute, so recreate it using the new iOS options.
        await legacy.delete(key: credentialsKey);
        try {
          await _storage.write(key: credentialsKey, value: stored);
        } catch (_) {
          // Avoid losing valid credentials if the migration write fails.
          await legacy.write(key: credentialsKey, value: stored);
          rethrow;
        }
      }
      await prefs.setBool(_backgroundAccessMigrationKey, true);
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(
        e,
        stackTrace,
        reason: 'Failed to migrate credentials for iOS background access',
      );
    }
  }

  /// Fetches credentials from the backend and persists them to secure storage.
  ///
  /// Sends a POST to `/fabla/verifyuser` with the [study] login code and
  /// [participant] ID, then saves the returned [CredentialsModel] via [save].
  ///
  /// Throws a JSON-encoded `{"exists": false}` string on failure so callers
  /// can detect auth errors without relying on exception types.
  Future<void> getCredentials({
    required String study,
    required String participant,
  }) async {
    try {
      final response = await post(path: "/fabla/verifyuser", body: {
        'login_code': study,
        'participant_id': participant,
      });

      if (response != null) {
        final data = json.decode(response)['data'] as Map<String, dynamic>;
        if (data['exists'] != true) {
          throw Exception('Participant not found for study "$study"');
        }
        await save(CredentialsModel.fromBackendMessage(
          data['message'] as Map<String, dynamic>,
        ));
      } else {
        throw Exception('Failed to retrieve credentials: response was null');
      }
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          context: {'StudyCode': study, 'ParticipantID': participant},
          reason: 'Error during HTTP request in getCredentials');
      throw json.encode({'exists': false});
    }
  }

  /// Reads the stored credentials from encrypted device storage.
  ///
  /// Returns `null` if no credentials are saved or decoding fails.
  Future<CredentialsModel?> read() async {
    try {
      final stored = await _storage.read(key: credentialsKey);
      if (stored?.isNotEmpty ?? false) {
        return CredentialsModel.fromJson(json.decode(stored!));
      }
      return null;
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          reason:
              'Failed to read/decode credentials from secure storage — all upload auth will be empty');
      return null;
    }
  }

  /// Persists [credentials] to encrypted device storage.
  ///
  /// Silently logs write errors; the next submission will fail auth rather
  /// than crash the app.
  Future<void> save(CredentialsModel credentials) async {
    try {
      await _storage.write(
          key: credentialsKey, value: json.encode(credentials.toJson()));
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
/// - [dynamoUrl]: Endpoint that receives survey response JSON (see [uploadNonAudioData]).
/// - [presignedUrl]: Endpoint that returns S3 presigned URLs for file uploads (see [getPresignedUrl]).
class CredentialsModel {
  final String? authorization;
  final String? xapikey;
  final String? dynamoUrl;
  final String? presignedUrl;

  CredentialsModel({
    this.authorization,
    this.xapikey,
    this.dynamoUrl,
    this.presignedUrl,
  });

  /// Deserializes from the JSON stored in secure storage.
  ///
  /// Note: the wire key for [xapikey] is `x-api-key` and URL keys use
  /// snake_case to match the backend contract; Dart field names use camelCase.
  CredentialsModel.fromJson(Map<String, dynamic> map)
      : authorization = map['authorization'] as String?,
        xapikey = map['x-api-key'] as String?,
        dynamoUrl = map['dynamo_url'] as String?,
        presignedUrl = map['presigned_url'] as String?;

  /// Deserializes from the `message` object in the backend `/fabla/verifyuser`
  /// response, where `Authorization` is capitalised.
  CredentialsModel.fromBackendMessage(Map<String, dynamic> message)
      : authorization = message['Authorization'] as String?,
        xapikey = message['x-api-key'] as String?,
        dynamoUrl = message['dynamo_url'] as String?,
        presignedUrl = message['presigned_url'] as String?;

  /// Serializes to JSON for secure storage persistence.
  Map<String, dynamic> toJson() => {
        'authorization': authorization,
        'x-api-key': xapikey,
        'dynamo_url': dynamoUrl,
        'presigned_url': presignedUrl,
      };
}
