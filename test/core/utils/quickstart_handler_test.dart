import 'dart:convert';

import 'package:audio_diaries_flutter/core/utils/quickstart_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends Mock implements http.Client {}

http.Response _presignedResponse(String url) =>
    http.Response(jsonEncode({'url': url}), 200);

void main() {
  late QuickstartHandler handler;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    handler = QuickstartHandler();
    mockHttpClient = MockHttpClient();
  });

  group('getVideoUrl', () {
    test('appends the video filename to the existing key query parameter', () {
      final uri = handler.getVideoUrl('walkThrough');

      expect(uri.scheme, 'https');
      expect(uri.host,
          'rni3xlmdeyk4mk4tqab6mudmwa0bpais.lambda-url.us-east-1.on.aws');
      expect(uri.queryParameters['key'],
          'amazon-fabla-videos/0_full_walkthrough.mp4');
    });

    test('throws for an unknown video name', () {
      expect(() => handler.getVideoUrl('not-a-real-video'), throwsException);
    });
  });

  group('getVideo', () {
    test('returns the presigned url on a 200 response', () async {
      when(() => mockHttpClient.post(any())).thenAnswer(
          (_) async => _presignedResponse('https://cdn.example.com/a.mp4'));

      final url = await handler.getVideo('study', client: mockHttpClient);

      expect(url, 'https://cdn.example.com/a.mp4');
    });

    test('does not close an injected client', () async {
      when(() => mockHttpClient.post(any())).thenAnswer(
          (_) async => _presignedResponse('https://cdn.example.com/a.mp4'));
      when(() => mockHttpClient.close()).thenReturn(null);

      await handler.getVideo('study', client: mockHttpClient);

      verifyNever(() => mockHttpClient.close());
    });

    test('throws when the response status is not 200', () async {
      when(() => mockHttpClient.post(any()))
          .thenAnswer((_) async => http.Response('error', 500));

      await expectLater(
          handler.getVideo('study', client: mockHttpClient), throwsException);
    });

    test('throws when the response body has no url field', () async {
      when(() => mockHttpClient.post(any())).thenAnswer(
          (_) async => http.Response(jsonEncode({'oops': true}), 200));

      await expectLater(
          handler.getVideo('study', client: mockHttpClient), throwsException);
    });

    test('propagates network errors', () async {
      when(() => mockHttpClient.post(any())).thenThrow(Exception('offline'));

      await expectLater(
          handler.getVideo('study', client: mockHttpClient), throwsException);
    });
  });

  group('getVideos', () {
    test('caches a url for every video on success', () async {
      when(() => mockHttpClient.post(any())).thenAnswer((invocation) async {
        final uri = invocation.positionalArguments.first as Uri;
        return _presignedResponse(
            'https://cdn.example.com/${uri.queryParameters['key']}');
      });

      await handler.getVideos(client: mockHttpClient);

      final cached = await handler.getCachedVideoUrls();
      expect(cached.keys.toSet(), QuickstartHandler.videos.keys.toSet());
    });

    test('keeps a partial cache when some videos fail to fetch', () async {
      when(() => mockHttpClient.post(any())).thenAnswer((invocation) async {
        final uri = invocation.positionalArguments.first as Uri;
        if (uri.queryParameters['key']!.contains('history')) {
          return http.Response('error', 500);
        }
        return _presignedResponse('https://cdn.example.com/ok.mp4');
      });

      await handler.getVideos(client: mockHttpClient);

      final cached = await handler.getCachedVideoUrls();
      expect(cached.containsKey('history'), isFalse);
      expect(cached.containsKey('study'), isTrue);
    });

    test('does not close an injected client', () async {
      when(() => mockHttpClient.post(any())).thenAnswer(
          (_) async => _presignedResponse('https://cdn.example.com/a.mp4'));
      when(() => mockHttpClient.close()).thenReturn(null);

      await handler.getVideos(client: mockHttpClient);

      verifyNever(() => mockHttpClient.close());
    });
  });

  group('getCachedVideoUrls', () {
    test('returns an empty map when nothing has been cached', () async {
      expect(await handler.getCachedVideoUrls(), <String, String>{});
    });

    test('returns cached urls within the 10 hour TTL', () async {
      final fetchedAt = DateTime.now().millisecondsSinceEpoch -
          const Duration(hours: 9).inMilliseconds;
      SharedPreferences.setMockInitialValues({
        'videoUrls': jsonEncode({
          'fetchedAt': fetchedAt,
          'urls': {'walkThrough': 'https://cdn.example.com/a.mp4'},
        }),
      });

      final cached = await handler.getCachedVideoUrls();
      expect(cached['walkThrough'], 'https://cdn.example.com/a.mp4');
    });

    test('treats a cache older than 10 hours as missing', () async {
      final fetchedAt = DateTime.now().millisecondsSinceEpoch -
          const Duration(hours: 11).inMilliseconds;
      SharedPreferences.setMockInitialValues({
        'videoUrls': jsonEncode({
          'fetchedAt': fetchedAt,
          'urls': {'walkThrough': 'https://cdn.example.com/a.mp4'},
        }),
      });

      expect(await handler.getCachedVideoUrls(), <String, String>{});
    });

    test('treats a legacy flat-map cache (pre-TTL format) as missing',
        () async {
      SharedPreferences.setMockInitialValues({
        'videoUrls':
            jsonEncode({'walkThrough': 'https://cdn.example.com/a.mp4'}),
      });

      expect(await handler.getCachedVideoUrls(), <String, String>{});
    });
  });

  group('ensureVideosCached', () {
    test('does not hit the network when every video is already cached',
        () async {
      final fetchedAt = DateTime.now().millisecondsSinceEpoch;
      final urls = {
        for (final name in QuickstartHandler.videos.keys)
          name: 'https://cdn.example.com/$name.mp4'
      };
      SharedPreferences.setMockInitialValues({
        'videoUrls': jsonEncode({'fetchedAt': fetchedAt, 'urls': urls}),
      });

      await handler.ensureVideosCached(client: mockHttpClient);

      verifyNever(() => mockHttpClient.post(any()));
    });

    test('fetches when the cache is missing entries', () async {
      when(() => mockHttpClient.post(any())).thenAnswer(
          (_) async => _presignedResponse('https://cdn.example.com/a.mp4'));

      await handler.ensureVideosCached(client: mockHttpClient);

      verify(() => mockHttpClient.post(any()))
          .called(QuickstartHandler.videos.length);
    });

    test('refetches once the cache has passed the 10 hour TTL', () async {
      final staleFetchedAt = DateTime.now().millisecondsSinceEpoch -
          const Duration(hours: 11).inMilliseconds;
      final urls = {
        for (final name in QuickstartHandler.videos.keys)
          name: 'https://cdn.example.com/$name.mp4'
      };
      SharedPreferences.setMockInitialValues({
        'videoUrls': jsonEncode({'fetchedAt': staleFetchedAt, 'urls': urls}),
      });
      when(() => mockHttpClient.post(any())).thenAnswer(
          (_) async => _presignedResponse('https://cdn.example.com/fresh.mp4'));

      await handler.ensureVideosCached(client: mockHttpClient);

      verify(() => mockHttpClient.post(any()))
          .called(QuickstartHandler.videos.length);
    });
  });
}
