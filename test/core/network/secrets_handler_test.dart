import 'package:audio_diaries_flutter/core/network/secrets_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import '../../dummy_data.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockHttpClient mockHttpClient;
  late MockFlutterSecureStorage mockStorage;
  late SecureSave secureSave;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockStorage = MockFlutterSecureStorage();
    secureSave = SecureSave(
      storage: mockStorage,
      client: mockHttpClient,
    );

    // Register fallback values for any() matcher
    registerFallbackValue(Uri.parse(TestValues.testUrl));
  });

  group('SecureSave Tests', () {
    test('postData successfully retrieves and saves credentials', () async {
      // ───── Arrange ─────
      const studyCode = TestValues.testStudyCode;
      final responseBody = createTestCredentialsApiResponse();

      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(responseBody, 200));

      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      // ───── Act ─────
      final result = await secureSave.postData(studyCode);

      // ───── Assert ─────
      expect(result, responseBody);
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
      verify(() => mockStorage.write(
            key: 'credentials',
            value: any(named: 'value'),
          )).called(1);
    });

    test('postData throws encoded error on non-200 response', () async {
      // ───── Arrange ─────
      const studyCode = TestValues.testStudyCode;
      final errorResponse = createTestCredentialsApiResponse();
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            errorResponse, // ✅ Use centralized
            TestValues.testStatusError, // ✅ Use centralized
          ));

      // ───── Act & Assert ─────
      expect(() => secureSave.postData(studyCode), throwsA(isA<String>()));
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('postData throws encoded error on network error', () async {
      // ───── Arrange ─────
      const studyCode = TestValues.testStudyCode;
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Network error'));

      // ───── Act & Assert ─────
      expect(() => secureSave.postData(studyCode), throwsA(isA<String>()));
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

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
      expect(result?.dynamo_url, TestValues.testDynamoUrl);
      expect(result?.presigned_url, TestValues.testPresignedUrl);
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
