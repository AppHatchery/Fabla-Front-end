import 'package:audio_diaries_flutter/core/network/secrets_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../dummy_data.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureSave secureSave;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    secureSave = SecureSave(
      storage: mockStorage,
    );
  });

  group('SecureSave Tests', () {
    test('read returns null when no credentials stored', () async {
      // ───── Arrange ─────
      when(() => mockStorage.read(key: 'credentials'))
          .thenAnswer((_) async => null);

      // ───── Act ─────
      final result = await secureSave.read();

      // ───── Assert ─────
      expect(result, null);
      verify(() => mockStorage.read(key: 'credentials')).called(1);
    });

    test('read returns CredentialsModel when credentials exist', () async {
      // ───── Arrange ─────
      final storedCredentials = createTestStoredCredentialsJson();
      when(() => mockStorage.read(key: 'credentials'))
          .thenAnswer((_) async => storedCredentials);

      // ───── Act ─────
      final result = await secureSave.read();

      // ───── Assert ─────
      expect(result, isA<CredentialsModel>());
      expect(result?.authorization, TestValues.testAuth);
      expect(result?.xapikey, TestValues.testApiKey);
      expect(result?.dynamoUrl, TestValues.testDynamoUrl);
      expect(result?.presignedUrl, TestValues.testPresignedUrl);
      verify(() => mockStorage.read(key: 'credentials')).called(1);
    });

    test('save stores credentials correctly', () async {
      // ───── Arrange ─────
      final credentials = createTestCredentials();

      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      // ───── Act ─────
      await secureSave.save(credentials);

      // ───── Assert ─────
      verify(() => mockStorage.write(
            key: 'credentials',
            value: any(named: 'value'),
          )).called(1);
    });
  });
}
