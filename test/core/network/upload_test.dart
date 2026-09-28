import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/core/network/secrets_handler.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'dart:convert';
import 'dart:io';

import '../../dummy_data.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockSetupRepository extends Mock implements SetupRepository {}

class MockSecureSave extends Mock implements SecureSave {}

class MockDirectory extends Mock implements Directory {}

// Initialize Flutter binding at the start
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHttpClient mockHttpClient;
  late MockSecureSave mockSecureSave;

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockSecureSave = MockSecureSave();
    registerFallbackValue(Uri.parse(TestValues.testUrl));
  });

  group('Upload Tests', () {
    test('uploadNonAudioData successfully uploads data', () async {
      // ───── Arrange ─────
      final credentials = createTestCredentials();
      final promptEntries = createTestPromptEntries(1);

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
      final credentials = createTestCredentials();
      final promptEntries = createTestPromptEntries(2);

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
      final credentials = createTestCredentials();
      final promptEntries = createTestPromptEntries(3);

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
      const apiUrl = TestValues.testUrl;
      const filename = 'test.txt';
      const expectedUrl = 'https://presigned-url.com/test.txt';

      final credentials = createTestCredentials();

      when(() => mockSecureSave.read()).thenAnswer((_) async => credentials);
      when(() => mockHttpClient.post(
                any(),
                headers: any(named: 'headers'),
                body: any(named: 'body'),
              ))
          .thenAnswer((_) async => http.Response(
              '{"body": "{\\"uploadURL\\": \\"$expectedUrl\\"}"}', 200));

      // ───── Act ─────
      final result = await getPresignedUrl(
        apiUrl,
        filename,
        secureSave: mockSecureSave,
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
      const apiUrl = TestValues.testUrl;
      const filename = 'test.txt';

      final credentials = createTestCredentials();

      when(() => mockSecureSave.read()).thenAnswer((_) async => credentials);
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Error', 400));

      // ───── Act ─────
      final result = await getPresignedUrl(
        apiUrl,
        filename,
        secureSave: mockSecureSave,
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
      const apiUrl = TestValues.testUrl;
      const filename = 'test.txt';

      final credentials = createTestCredentials();

      when(() => mockSecureSave.read()).thenAnswer((_) async => credentials);
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Network error'));

      // ───── Act ─────
      final result = await getPresignedUrl(
        apiUrl,
        filename,
        secureSave: mockSecureSave,
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

  // The diary and device-info uploads share one POST path, so each must still
  // reach its own endpoint with its own auth token.
  group('Endpoint routing', () {
    final record = {'ParticipantID': TestValues.testStudyCode};

    void stubPost(int status) {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('', status));
    }

    List<dynamic> capturedPost() => verify(() => mockHttpClient.post(
          captureAny(),
          headers: captureAny(named: 'headers'),
          body: captureAny(named: 'body'),
        )).captured;

    test('uploadNonAudioData posts to dynamo_url with the [0] token', () async {
      when(() => mockSecureSave.read())
          .thenAnswer((_) async => createTestCredentials());
      stubPost(200);

      await uploadNonAudioData(createTestPromptEntries(1),
          secureSave: mockSecureSave, client: mockHttpClient);

      final captured = capturedPost();
      expect(captured[0], Uri.parse(TestValues.testDynamoUrl));
      expect((captured[1] as Map)['Authorization'], '${TestValues.testAuth}[0]');
    });

    test('uploadDeviceInfo posts the record as a one-item list', () async {
      when(() => mockSecureSave.read())
          .thenAnswer((_) async => createTestCredentials());
      stubPost(200);

      final result = await uploadDeviceInfo(record,
          secureSave: mockSecureSave, client: mockHttpClient);

      expect(result, isTrue);
      final captured = capturedPost();
      expect(captured[0], Uri.parse(TestValues.testDeviceInfoUrl));
      expect((captured[1] as Map)['Authorization'], '${TestValues.testAuth}[2]');
      expect((captured[1] as Map)['x-api-key'], TestValues.testApiKey);
      expect(json.decode(captured[2] as String), [record]);
    });

    test('uploadDeviceInfo returns false on a non-200 response', () async {
      when(() => mockSecureSave.read())
          .thenAnswer((_) async => createTestCredentials());
      stubPost(500);

      final result = await uploadDeviceInfo(record,
          secureSave: mockSecureSave, client: mockHttpClient);

      expect(result, isFalse);
    });

    // Credentials stored before the endpoint existed have no URL for it.
    // Refreshing needs the local database, which tests don't have, so the
    // refresh fails and nothing should be posted to an empty URL.
    test('uploadDeviceInfo posts nothing when the endpoint is missing',
        () async {
      when(() => mockSecureSave.read())
          .thenAnswer((_) async => createTestCredentials(deviceInfoUrl: null));

      final result = await uploadDeviceInfo(record,
          secureSave: mockSecureSave, client: mockHttpClient);

      expect(result, isFalse);
      verifyNever(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ));
    });
  });
}
