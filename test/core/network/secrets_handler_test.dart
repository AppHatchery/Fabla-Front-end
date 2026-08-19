import 'package:audio_diaries_flutter/core/network/secrets_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dummy_data.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureSave secureSave;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockStorage = MockFlutterSecureStorage();
    secureSave = SecureSave(storage: mockStorage);
  });

  group('CredentialsModel', () {
    test('fromJson deserializes stored credentials correctly', () {
      final map = {
        'authorization': TestValues.testAuth,
        'x-api-key': TestValues.testApiKey,
        'dynamo_url': TestValues.testDynamoUrl,
        'presigned_url': TestValues.testPresignedUrl,
      };

      final model = CredentialsModel.fromJson(map);

      expect(model.authorization, TestValues.testAuth);
      expect(model.xapikey, TestValues.testApiKey);
      expect(model.dynamoUrl, TestValues.testDynamoUrl);
      expect(model.presignedUrl, TestValues.testPresignedUrl);
    });

    test('fromBackendMessage deserializes backend response correctly', () {
      final message = {
        'Authorization': TestValues.testAuth,
        'x-api-key': TestValues.testApiKey,
        'dynamo_url': TestValues.testDynamoUrl,
        'presigned_url': TestValues.testPresignedUrl,
      };

      final model = CredentialsModel.fromBackendMessage(message);

      expect(model.authorization, TestValues.testAuth);
      expect(model.xapikey, TestValues.testApiKey);
      expect(model.dynamoUrl, TestValues.testDynamoUrl);
      expect(model.presignedUrl, TestValues.testPresignedUrl);
    });

    test('toJson serializes with correct wire keys', () {
      final model = createTestCredentials();

      final json = model.toJson();

      expect(json['authorization'], TestValues.testAuth);
      expect(json['x-api-key'], TestValues.testApiKey);
      expect(json['dynamo_url'], TestValues.testDynamoUrl);
      expect(json['presigned_url'], TestValues.testPresignedUrl);
    });

    test('fromJson round-trips through toJson', () {
      final original = createTestCredentials();
      final restored = CredentialsModel.fromJson(original.toJson());

      expect(restored.authorization, original.authorization);
      expect(restored.xapikey, original.xapikey);
      expect(restored.dynamoUrl, original.dynamoUrl);
      expect(restored.presignedUrl, original.presignedUrl);
    });

    test('fromJson handles null values gracefully', () {
      final model = CredentialsModel.fromJson({});

      expect(model.authorization, isNull);
      expect(model.xapikey, isNull);
      expect(model.dynamoUrl, isNull);
      expect(model.presignedUrl, isNull);
    });
  });

  group('SecureSave', () {
    test('read returns null when no credentials stored', () async {
      when(() => mockStorage.read(key: 'credentials'))
          .thenAnswer((_) async => null);

      final result = await secureSave.read();

      expect(result, null);
      verify(() => mockStorage.read(key: 'credentials')).called(1);
    });

    test('read returns CredentialsModel when credentials exist', () async {
      final storedCredentials = createTestStoredCredentialsJson();
      when(() => mockStorage.read(key: 'credentials'))
          .thenAnswer((_) async => storedCredentials);

      final result = await secureSave.read();

      expect(result, isA<CredentialsModel>());
      expect(result?.authorization, TestValues.testAuth);
      expect(result?.xapikey, TestValues.testApiKey);
      expect(result?.dynamoUrl, TestValues.testDynamoUrl);
      expect(result?.presignedUrl, TestValues.testPresignedUrl);
      verify(() => mockStorage.read(key: 'credentials')).called(1);
    });

    test('read returns null on malformed JSON', () async {
      when(() => mockStorage.read(key: 'credentials'))
          .thenAnswer((_) async => 'not-valid-json');

      final result = await secureSave.read();

      expect(result, isNull);
    });

    test('save stores credentials correctly', () async {
      final credentials = createTestCredentials();
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await secureSave.save(credentials);

      verify(() => mockStorage.write(
            key: 'credentials',
            value: any(named: 'value'),
          )).called(1);
    });

    test('migrates existing iOS credentials to background access', () async {
      final legacyStorage = MockFlutterSecureStorage();
      final preferences = await SharedPreferences.getInstance();
      final storedCredentials = createTestStoredCredentialsJson();

      when(() => legacyStorage.read(key: SecureSave.credentialsKey))
          .thenAnswer((_) async => storedCredentials);
      when(() => legacyStorage.delete(key: SecureSave.credentialsKey))
          .thenAnswer((_) async {});
      when(() => mockStorage.write(
            key: SecureSave.credentialsKey,
            value: storedCredentials,
          )).thenAnswer((_) async {});

      await secureSave.migrateCredentialsForBackgroundAccess(
        legacyStorage: legacyStorage,
        preferences: preferences,
        isIOS: true,
      );

      verifyInOrder([
        () => legacyStorage.read(key: SecureSave.credentialsKey),
        () => legacyStorage.delete(key: SecureSave.credentialsKey),
        () => mockStorage.write(
              key: SecureSave.credentialsKey,
              value: storedCredentials,
            ),
      ]);
      expect(
        preferences.getBool('credentials_background_access_v1'),
        isTrue,
      );
    });

    test('does not run iOS credential migration on Android', () async {
      final legacyStorage = MockFlutterSecureStorage();

      await secureSave.migrateCredentialsForBackgroundAccess(
        legacyStorage: legacyStorage,
        isIOS: false,
      );

      verifyNever(() => legacyStorage.read(key: any(named: 'key')));
    });
  });
}
