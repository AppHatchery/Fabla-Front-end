import 'package:audio_diaries_flutter/core/network/secrets_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

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
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  group('SecureSave Tests', () {
    test('postData successfully retrieves and saves credentials', () async {
      // ───── Arrange ─────
      const studyCode = 'TEST123';
      const responseBody = '''
      {
        "message": {
          "Authorization": "test-auth",
          "x-api-key": "test-api-key",
          "dynamo_url": "test-dynamo-url",
          "presigned_url": "test-presigned-url"
        }
      }
      ''';

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
      const studyCode = 'TEST123';
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Error', 400));

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
      const studyCode = 'TEST123';
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
      const storedCredentials = '''
      {
        "authorization": "test-auth",
        "x-api-key": "test-api-key",
        "dynamo_url": "test-dynamo-url",
        "presigned_url": "test-presigned-url"
      }
      ''';
      when(() => mockStorage.read(key: 'credentials'))
          .thenAnswer((_) async => storedCredentials);

      // ───── Act ─────
      final result = await secureSave.read();

      // ───── Assert ─────
      expect(result, isA<CredentialsModel>());
      expect(result?.authorization, 'test-auth');
      expect(result?.xapikey, 'test-api-key');
      expect(result?.dynamo_url, 'test-dynamo-url');
      expect(result?.presigned_url, 'test-presigned-url');
      verify(() => mockStorage.read(key: 'credentials')).called(1);
    });

    test('save stores credentials correctly', () async {
      // ───── Arrange ─────
      final credentials = CredentialsModel(
        authorization: 'test-auth',
        xapikey: 'test-api-key',
        dynamo_url: 'test-dynamo-url',
        presigned_url: 'test-presigned-url',
      );

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
