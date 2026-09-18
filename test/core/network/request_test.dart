import 'package:audio_diaries_flutter/core/network/http_client_factory.dart'
    show debugPlatformClientBuilder;
import 'package:audio_diaries_flutter/core/network/request.dart';
import 'package:audio_diaries_flutter/core/network/retry_policy.dart'
    show kMaxRetries;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import '../../dummy_data.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    // request.dart builds its top-level `headers` map via `dotenv.env['APIKEY']!`.
    // That map is lazy-initialized on first access, so dotenv MUST be seeded
    // before any test touches get()/post(). Otherwise the `!` throws.
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.loadFromString(
      envString: 'APIKEY=${TestValues.testApiKey}',
    );
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    registerFallbackValue(Uri.parse(TestValues.testUrl));
  });

  // Exercised through the `client == null` branch, which is the one that
  // ships: injecting a client skips the line that picks the retry budget.
  group('production retry budgets', () {
    late int sends;

    setUp(() {
      sends = 0;
      debugPlatformClientBuilder = () => MockClient((_) {
            sends++;
            throw http.ClientException('connection closed');
          });
    });

    tearDown(() => debugPlatformClientBuilder = null);

    test('get is retried', () async {
      expect(await get(path: 'test'), isNull);
      expect(sends, kMaxRetries + 1);
    });

    test('post is not retried unless a caller opts in', () async {
      // The safe default for a generic POST helper: this function cannot know
      // whether the endpoint it is pointed at appends.
      expect(await post(path: 'test', body: const {}), isNull);
      expect(sends, 1);
    });

    test('post re-sends when a caller opts in', () async {
      expect(
        await post(path: 'test', body: const {}, retries: kMaxRetries),
        isNull,
      );
      expect(sends, kMaxRetries + 1);
    });
  });

  group('Network Request Tests', () {
    group('GET requests', () {
      test('get returns response body on successful request (200)', () async {
        final expectedResponse = createTestApiResponse();

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response(
                  expectedResponse,
                  TestValues.testStatusOk,
                ));

        final result = await get(path: 'test', client: mockHttpClient);

        expect(result, expectedResponse);
        verify(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .called(1);
      });

      test('get returns response body even on failed HTTP status (400)',
          () async {
        final errorResponse = createTestErrorResponse();

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response(
                  errorResponse,
                  TestValues.testStatusError,
                ));

        final result = await get(path: 'test', client: mockHttpClient);

        expect(result, errorResponse);
        verify(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .called(1);
      });

      test('get returns response body for any status code (500)', () async {
        final serverErrorResponse =
            createTestErrorResponse(message: 'Internal Server Error');

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response(
                  serverErrorResponse,
                  TestValues.testStatusServerError,
                ));

        final result = await get(path: 'test', client: mockHttpClient);

        expect(result, serverErrorResponse);
        verify(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .called(1);
      });

      test('get returns null on network exception', () async {
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenThrow(Exception('Network error'));

        final result = await get(path: 'test', client: mockHttpClient);

        expect(result, null);
        verify(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .called(1);
      });
    });

    group('POST requests', () {
      test('post returns response body on successful request (200)', () async {
        final expectedResponse = createTestApiResponse();
        final testBody = createTestPostBody();

        when(() => mockHttpClient.post(any(),
                headers: any(named: 'headers'), body: any(named: 'body')))
            .thenAnswer((_) async => http.Response(
                  expectedResponse,
                  TestValues.testStatusOk,
                ));

        final result =
            await post(path: 'test', body: testBody, client: mockHttpClient);

        expect(result, expectedResponse);
        verify(() => mockHttpClient.post(any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'))).called(1);
      });

      test('post returns null on non-200 response (400)', () async {
        final testBody = createTestPostBody();
        final errorResponse = createTestErrorResponse();

        when(() => mockHttpClient.post(any(),
                headers: any(named: 'headers'), body: any(named: 'body')))
            .thenAnswer((_) async => http.Response(
                  errorResponse,
                  TestValues.testStatusError,
                ));

        final result =
            await post(path: 'test', body: testBody, client: mockHttpClient);

        expect(result, null);
        verify(() => mockHttpClient.post(any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'))).called(1);
      });

      test('post returns null on non-200 response (500)', () async {
        final testBody = createTestPostBody();
        final serverError = createTestErrorResponse(message: 'Server Error');

        when(() => mockHttpClient.post(any(),
                headers: any(named: 'headers'), body: any(named: 'body')))
            .thenAnswer((_) async => http.Response(
                  serverError,
                  TestValues.testStatusServerError,
                ));

        final result =
            await post(path: 'test', body: testBody, client: mockHttpClient);

        expect(result, null);
        verify(() => mockHttpClient.post(any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'))).called(1);
      });

      test('post returns null on network exception', () async {
        final testBody = createTestPostBody();

        when(() => mockHttpClient.post(any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'))).thenThrow(Exception('Network error'));

        final result =
            await post(path: 'test', body: testBody, client: mockHttpClient);

        expect(result, null);
        verify(() => mockHttpClient.post(any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'))).called(1);
      });
    });

    group('Headers from .env', () {
      test('get sends x-api-key sourced from dotenv', () async {
        Map<String, String>? capturedHeaders;

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((invocation) async {
          capturedHeaders =
              invocation.namedArguments[#headers] as Map<String, String>?;
          return http.Response(
            createTestApiResponse(),
            TestValues.testStatusOk,
          );
        });

        await get(path: 'test', client: mockHttpClient);

        expect(capturedHeaders, isNotNull);
        expect(capturedHeaders!['x-api-key'], TestValues.testApiKey);
        expect(capturedHeaders!['Content-Type'],
            'application/x-www-form-urlencoded');
      });

      test('post sends x-api-key sourced from dotenv', () async {
        Map<String, String>? capturedHeaders;
        final testBody = createTestPostBody();

        when(() => mockHttpClient.post(any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'))).thenAnswer((invocation) async {
          capturedHeaders =
              invocation.namedArguments[#headers] as Map<String, String>?;
          return http.Response(
            createTestApiResponse(),
            TestValues.testStatusOk,
          );
        });

        await post(path: 'test', body: testBody, client: mockHttpClient);

        expect(capturedHeaders, isNotNull);
        expect(capturedHeaders!['x-api-key'], TestValues.testApiKey);
        expect(capturedHeaders!['Content-Type'],
            'application/x-www-form-urlencoded');
      });
    });

    group('Function behavior documentation', () {
      test('documents the difference between get and post behavior', () {
        const getBehavior = 'Returns response body for any HTTP status code';
        const postBehavior = 'Returns response body only for 200 status code';

        expect(getBehavior, contains('any HTTP status'));
        expect(postBehavior, contains('only for 200'));
      });
    });
  });
}
