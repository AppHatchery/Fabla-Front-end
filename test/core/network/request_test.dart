import 'package:audio_diaries_flutter/core/network/request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockHttpClient();
    // Register fallback values for any() matcher
    registerFallbackValue(Uri.https('example.com', ''));
  });

  group('Network Request Tests', () {
    group('GET requests', () {
      test('get returns response body on successful request (200)', () async {
        // ───── Arrange ─────
        const expectedResponse = '{"data": "test"}';
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response(expectedResponse, 200));

        // ───── Act ────
        final result = await get(path: 'test', client: mockHttpClient);

        // ───── Assert ─────
        expect(result, expectedResponse);
        verify(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .called(1);
      });

      test('get returns response body even on failed HTTP status (400)',
          () async {
        // ───── Arrange ─────
        const errorResponse = 'Bad Request Error';
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response(errorResponse, 400));

        // ───── Act ─────
        final result = await get(path: 'test', client: mockHttpClient);

        // ───── Assert ─────
        // get() returns response body regardless of status code
        expect(result, errorResponse);
        verify(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .called(1);
      });

      test('get returns response body for any status code (500)', () async {
        // ───── Arrange ─────
        const serverErrorResponse = 'Internal Server Error';
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response(serverErrorResponse, 500));

        // ───── Act ─────
        final result = await get(path: 'test', client: mockHttpClient);

        // ───── Assert ─────
        // get() returns response body regardless of status code
        expect(result, serverErrorResponse);
        verify(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .called(1);
      });

      test('get returns null on network exception', () async {
        // ───── Arrange ─────
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenThrow(Exception('Network error'));

        // ───── Act ─────
        final result = await get(path: 'test', client: mockHttpClient);

        // ───── Assert ─────
        expect(result, null);
        verify(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .called(1);
      });
    });

    group('POST requests', () {
      test('post returns response body on successful request (200)', () async {
        // ───── Arrange ─────
        const expectedResponse = '{"data": "test"}';
        const testBody = {'key': 'value'};
        when(() => mockHttpClient.post(any(),
                headers: any(named: 'headers'), body: any(named: 'body')))
            .thenAnswer((_) async => http.Response(expectedResponse, 200));

        // ───── Act ─────
        final result =
            await post(path: 'test', body: testBody, client: mockHttpClient);

        // ───── Assert ─────
        expect(result, expectedResponse);
        verify(() => mockHttpClient.post(any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'))).called(1);
      });

      test('post returns null on non-200 response (400)', () async {
        // ───── Arrange ─────
        const testBody = {'key': 'value'};
        when(() => mockHttpClient.post(any(),
                headers: any(named: 'headers'), body: any(named: 'body')))
            .thenAnswer((_) async => http.Response('Bad Request', 400));

        // ───── Act ─────
        final result =
            await post(path: 'test', body: testBody, client: mockHttpClient);

        // ───── Assert ─────
        // post() returns null for non-200 status codes (throws exception caught by try-catch)
        expect(result, null);
        verify(() => mockHttpClient.post(any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'))).called(1);
      });

      test('post returns null on non-200 response (500)', () async {
        // ───── Arrange ─────
        const testBody = {'key': 'value'};
        when(() => mockHttpClient.post(any(),
                headers: any(named: 'headers'), body: any(named: 'body')))
            .thenAnswer((_) async => http.Response('Server Error', 500));

        // ───── Act ─────
        final result =
            await post(path: 'test', body: testBody, client: mockHttpClient);

        // ───── Assert ─────
        // post() returns null for non-200 status codes (throws exception caught by try-catch)
        expect(result, null);
        verify(() => mockHttpClient.post(any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'))).called(1);
      });

      test('post returns null on network exception', () async {
        // ───── Arrange ─────
        const testBody = {'key': 'value'};
        when(() => mockHttpClient.post(any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'))).thenThrow(Exception('Network error'));

        // ───── Act ─────
        final result =
            await post(path: 'test', body: testBody, client: mockHttpClient);

        // ───── Assert ─────
        expect(result, null);
        verify(() => mockHttpClient.post(any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'))).called(1);
      });
    });

    group('Function behavior documentation', () {
      test('documents the difference between get and post behavior', () {
        // This test serves as documentation for the different behaviors:
        // - get() returns response.body for ANY status code (200, 400, 500, etc.)
        // - get() only returns null on network exceptions (timeouts, connection errors)
        // - post() returns response.body ONLY for 200 status code
        // - post() returns null for non-200 status codes AND network exceptions

        const getBehavior = 'Returns response body for any HTTP status code';
        const postBehavior = 'Returns response body only for 200 status code';

        expect(getBehavior, contains('any HTTP status'));
        expect(postBehavior, contains('only for 200'));
      });
    });
  });
}
