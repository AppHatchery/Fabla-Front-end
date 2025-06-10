import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/core/network/secrets_handler.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'dart:io';

class MockHttpClient extends Mock implements http.Client {}

class MockSetupRepository extends Mock implements SetupRepository {}

class MockSecureSave extends Mock implements SecureSave {}

class MockDirectory extends Mock implements Directory {}

// Initialize Flutter binding at the start
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHttpClient mockHttpClient;
  late MockSetupRepository mockSetupRepository;
  late MockSecureSave mockSecureSave;
  late MockDirectory mockDirectory;

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockSetupRepository = MockSetupRepository();
    mockSecureSave = MockSecureSave();
    mockDirectory = MockDirectory();

    // Register fallback values for any() matcher
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  group('Upload Tests', () {
    test('uploadNonAudioData successfully uploads data', () async {
      // ───── Arrange ─────
      final credentials = CredentialsModel(
        authorization: 'test-auth',
        xapikey: 'test-api-key',
        dynamo_url: 'test-dynamo-url',
        presigned_url: 'test-presigned-url',
      );

      final promptEntries = [
        PromptEntry(
          participantID: 'test-participant',
          experimentCode: 'test-experiment',
          questionTitle: 'Test Question',
          diaryID: '1',
          promptID: '1',
          response: 'Test Response',
          questionsType: 'text',
          required: true,
        ),
      ];

      when(() => mockSecureSave.read()).thenAnswer((_) async => credentials);
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Success', 200));

      // ───── Act ─────
      final result = await uploadNonAudioData(
        promptEntries,
        secureSave: mockSecureSave,
        client: mockHttpClient,
      );

      // ───── Assert ─────
      expect(result, true);
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('uploadNonAudioData returns false on failed upload', () async {
      // ───── Arrange ─────
      final credentials = CredentialsModel(
        authorization: 'test-auth',
        xapikey: 'test-api-key',
        dynamo_url: 'test-dynamo-url',
        presigned_url: 'test-presigned-url',
      );

      final promptEntries = [
        PromptEntry(
          participantID: 'test-participant',
          experimentCode: 'test-experiment',
          questionTitle: 'Test Question',
          diaryID: '1',
          promptID: '1',
          response: 'Test Response',
          questionsType: 'text',
          required: true,
        ),
      ];

      when(() => mockSecureSave.read()).thenAnswer((_) async => credentials);
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Error', 400));

      // ───── Act ─────
      final result = await uploadNonAudioData(
        promptEntries,
        secureSave: mockSecureSave,
        client: mockHttpClient,
      );

      // ───── Assert ─────
      expect(result, false);
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('uploadNonAudioData returns false on network error', () async {
      // ───── Arrange ─────
      final credentials = CredentialsModel(
        authorization: 'test-auth',
        xapikey: 'test-api-key',
        dynamo_url: 'test-dynamo-url',
        presigned_url: 'test-presigned-url',
      );

      final promptEntries = [
        PromptEntry(
          participantID: 'test-participant',
          experimentCode: 'test-experiment',
          questionTitle: 'Test Question',
          diaryID: '1',
          promptID: '1',
          response: 'Test Response',
          questionsType: 'text',
          required: true,
        ),
      ];

      when(() => mockSecureSave.read()).thenAnswer((_) async => credentials);
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Network error'));

      // ───── Act ─────
      final result = await uploadNonAudioData(
        promptEntries,
        secureSave: mockSecureSave,
        client: mockHttpClient,
      );

      // ───── Assert ─────
      expect(result, false);
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('getPresignedUrl returns URL on successful request', () async {
      // ───── Arrange ─────
      const apiUrl = 'https://example.com';
      const filename = 'test.txt';
      const expectedUrl = 'https://presigned-url.com/test.txt';

      when(() => mockHttpClient.post(
                any(),
                headers: any(named: 'headers'),
                body: any(named: 'body'),
              ))
          .thenAnswer(
              (_) async => http.Response('{"url": "$expectedUrl"}', 200));

      // ───── Act ─────
      final result = await getPresignedUrl(
        apiUrl,
        filename,
        client: mockHttpClient,
      );

      // ───── Assert ─────
      expect(result, expectedUrl);
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('getPresignedUrl returns null on failed request', () async {
      // ───── Arrange ─────
      const apiUrl = 'https://example.com';
      const filename = 'test.txt';

      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Error', 400));

      // ───── Act ─────
      final result = await getPresignedUrl(
        apiUrl,
        filename,
        client: mockHttpClient,
      );

      // ───── Assert ─────
      expect(result, null);
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('getPresignedUrl returns null on network error', () async {
      // ───── Arrange ─────
      const apiUrl = 'https://example.com';
      const filename = 'test.txt';

      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Network error'));

      // ───── Act ─────
      final result = await getPresignedUrl(
        apiUrl,
        filename,
        client: mockHttpClient,
      );

      // ───── Assert ─────
      expect(result, null);
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });
  });
}
