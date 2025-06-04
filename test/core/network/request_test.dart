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
    test('get returns response body on successful request', () async {
      // ───── Arrange ─────
      const expectedResponse = '{"data": "test"}';
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(expectedResponse, 200));

      // ───── Act ─────
      final result = await get(path: 'test', client: mockHttpClient);

      // ───── Assert ─────
      expect(result, expectedResponse);
      verify(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .called(1);
    });

    test('get returns null on failed request', () async {
      // ───── Arrange ─────
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Error', 400));

      // ───── Act ─────
      final result = await get(path: 'test', client: mockHttpClient);

      // ───── Assert ─────
      expect(result, null);
      verify(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .called(1);
    });

    test('get returns null on network error', () async {
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

    test('post returns response body on successful request', () async {
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
          headers: any(named: 'headers'), body: any(named: 'body'))).called(1);
    });

    test('post returns null on non-200 response', () async {
      // ───── Arrange ─────
      const testBody = {'key': 'value'};
      when(() => mockHttpClient.post(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('Error', 400));

      // ───── Act ─────
      final result =
          await post(path: 'test', body: testBody, client: mockHttpClient);

      // ───── Assert ─────
      expect(result, null);
      verify(() => mockHttpClient.post(any(),
          headers: any(named: 'headers'), body: any(named: 'body'))).called(1);
    });

    test('post returns null on network error', () async {
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
          headers: any(named: 'headers'), body: any(named: 'body'))).called(1);
    });
  });
}
