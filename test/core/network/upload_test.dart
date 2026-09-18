import 'package:audio_diaries_flutter/core/network/http_client_factory.dart';
import 'package:audio_diaries_flutter/core/network/retry_policy.dart';
import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/core/network/secrets_handler.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'dart:async';
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

  // These exercise the `client == null` branch — the one that ships — by
  // swapping the platform client out from under it. Injecting a client at the
  // call site skips the very line that chooses the retry budget, so without
  // this seam dropping a `retries:` argument would leave every test green.
  group('production retry budgets', () {
    late int sends;

    setUp(() {
      sends = 0;
      registerFallbackValue(Uri.parse(TestValues.testUrl));
      when(() => mockSecureSave.read())
          .thenAnswer((_) async => createTestCredentials());
    });

    tearDown(() => debugPlatformClientBuilder = null);

    /// A client that always fails the way a dropped connection does.
    void failEveryAttemptWith(Object error) {
      debugPlatformClientBuilder = () => MockClient((_) {
            sends++;
            throw error;
          });
    }

    test('the diary write is sent once and never re-sent', () async {
      // The append-shaped write: a re-send could add a second row, and the
      // Lambda has no dedupe. A mid-request drop is exactly the error that
      // would be retried if this call site inherited the default budget.
      failEveryAttemptWith(http.ClientException('connection closed'));

      final result = await uploadNonAudioData(
        createTestPromptEntries(1),
        secureSave: mockSecureSave,
      );

      expect(result, isFalse);
      expect(sends, 1);
    });

    test('minting a presigned URL is retried', () async {
      // The contrast that makes the test above meaningful: same error, same
      // seam, different budget — because this call reserves nothing.
      failEveryAttemptWith(http.ClientException('connection closed'));

      final result = await getPresignedUrl(
        TestValues.testUrl,
        'diary/audio.m4a',
        secureSave: mockSecureSave,
      );

      expect(result, isNull);
      expect(sends, kMaxRetries + 1);
    });
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

  group('uploadFileToS3', () {
    late Directory tempDir;
    late String filePath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('upload_test');
      filePath = p.join(tempDir.path, 'recording.m4a');
      File(filePath).writeAsBytesSync(List<int>.generate(1024, (i) => i % 256));
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('returns true when S3 accepts the PUT', () async {
      // ───── Arrange ─────
      final sent = <http.Request>[];
      final client = MockClient((request) async {
        sent.add(request);
        return http.Response('', 200);
      });

      // ───── Act ─────
      final result =
          await uploadFileToS3(TestValues.testUrl, filePath, client: client);

      // ───── Assert ─────
      expect(result, true);
      expect(sent.length, 1);
      expect(sent.single.method, 'PUT');
      expect(sent.single.headers['Content-Type'], 'audio/mp4');
      expect(sent.single.bodyBytes.length, 1024);
    });

    test('returns false on a non-200 without re-sending', () async {
      // ───── Arrange ─────
      var sends = 0;
      final client = MockClient((_) async {
        sends++;
        return http.Response('AccessDenied', 403);
      });

      // ───── Act ─────
      final result =
          await uploadFileToS3(TestValues.testUrl, filePath, client: client);

      // ───── Assert ─────
      expect(result, false);
      expect(sends, 1);
    });

    test('a retried upload reuses the same presigned URL, so S3 holds one object',
        () async {
      // ───── Arrange ─────
      // This is the no-duplicate-upload guard: the retry must overwrite the
      // same key rather than create a second object.
      final sent = <http.Request>[];
      final inner = MockClient((request) async {
        sent.add(request);
        if (sent.length == 1) throw TimeoutException('timed out');
        return http.Response('', 200);
      });

      // ───── Act ─────
      final result = await uploadFileToS3(
        TestValues.testUrl,
        filePath,
        client: wrapClient(
          inner,
          retries: kUploadMaxRetries,
          delay: (_) => Duration.zero,
        ),
      );

      // ───── Assert ─────
      expect(result, true);
      expect(sent.length, 2);
      expect(sent[1].url, sent[0].url);
      expect(sent[1].bodyBytes, sent[0].bodyBytes);
    });

    test('returns false once the retry budget is exhausted', () async {
      // ───── Arrange ─────
      var sends = 0;
      final inner = MockClient((_) async {
        sends++;
        throw const SocketException('connection reset');
      });

      // ───── Act ─────
      final result = await uploadFileToS3(
        TestValues.testUrl,
        filePath,
        client: wrapClient(
          inner,
          retries: kUploadMaxRetries,
          delay: (_) => Duration.zero,
        ),
      );

      // ───── Assert ─────
      expect(result, false);
      expect(sends, kUploadMaxRetries + 1);
    });
  });

  group('uploadNonAudioData retry safety', () {
    test('a 500 posts the diary response exactly once', () async {
      // ───── Arrange ─────
      // A 5xx may be returned after the write landed, so re-sending it could
      // duplicate the participant's responses in DynamoDB.
      var sends = 0;
      final inner = MockClient((_) async {
        sends++;
        return http.Response('internal error', 500);
      });

      when(() => mockSecureSave.read())
          .thenAnswer((_) async => createTestCredentials());

      // ───── Act ─────
      final result = await uploadNonAudioData(
        createTestPromptEntries(2),
        secureSave: mockSecureSave,
        client: wrapClient(
          inner,
          retries: kMaxRetries,
          delay: (_) => Duration.zero,
        ),
      );

      // ───── Assert ─────
      expect(result, false);
      expect(sends, 1);
    });

    test('a dropped connection is retried and can still succeed', () async {
      // ───── Arrange ─────
      var sends = 0;
      final inner = MockClient((_) async {
        sends++;
        if (sends == 1) throw const SocketException('connection reset');
        return http.Response('Success', 200);
      });

      when(() => mockSecureSave.read())
          .thenAnswer((_) async => createTestCredentials());

      // ───── Act ─────
      final result = await uploadNonAudioData(
        createTestPromptEntries(1),
        secureSave: mockSecureSave,
        client: wrapClient(
          inner,
          retries: kMaxRetries,
          delay: (_) => Duration.zero,
        ),
      );

      // ───── Assert ─────
      expect(result, true);
      expect(sends, 2);
    });
  });
}
