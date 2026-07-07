import 'dart:async';
import 'dart:convert';

import 'package:audio_diaries_flutter/core/usecases/video_compression.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_compress/video_compress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('video_compress');
  final log = <MethodCall>[];

  /// Per-test platform behaviour, swapped inside individual tests.
  late Future<Object?> Function(MethodCall call) handler;

  String successJson(String path) => jsonEncode({'path': path});

  String sourceOf(MethodCall call) => (call.arguments as Map)['path'] as String;

  /// Default platform: echoes back a compressed path derived from the source.
  Future<Object?> defaultHandler(MethodCall call) async {
    if (call.method == 'compressVideo') {
      return successJson('${sourceOf(call)}.compressed.mp4');
    }
    return null;
  }

  List<MethodCall> compressCalls() =>
      log.where((call) => call.method == 'compressVideo').toList();

  setUp(() {
    log.clear();
    handler = defaultHandler;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
      log.add(call);
      return handler(call);
    });
  });

  tearDown(() async {
    // The queue is a singleton; reset its state so tests stay independent.
    VideoCompressionQueue.instance.cancelAll();
    VideoCompressionQueue.instance.setCameraActive(false);
    await pumpEventQueue();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('compressVideo', () {
    test('returns the compressed file path on success', () async {
      final result = await compressVideo('/videos/raw.mp4');

      expect(result, '/videos/raw.mp4.compressed.mp4');
    });

    test('requests 720p with audio', () async {
      await compressVideo('/videos/raw.mp4');

      final args = compressCalls().single.arguments as Map;
      expect(args['quality'], VideoQuality.Res1280x720Quality.index);
      expect(args['includeAudio'], isTrue);
    });

    test('returns null when the platform returns null', () async {
      handler = (_) async => null;

      expect(await compressVideo('/videos/raw.mp4'), isNull);
    });

    test('returns null when the platform throws', () async {
      handler = (_) async => throw PlatformException(code: 'failed');

      expect(await compressVideo('/videos/raw.mp4'), isNull);
    });

    test('returns null on a malformed platform response', () async {
      handler = (_) async => 'not-json';

      expect(await compressVideo('/videos/raw.mp4'), isNull);
    });
  });

  group('VideoCompressionQueue', () {
    final queue = VideoCompressionQueue.instance;

    test('compresses an enqueued video in the background', () async {
      queue.enqueue('/videos/a.mp4');
      await pumpEventQueue();

      expect(queue.compressedPathFor('/videos/a.mp4'),
          '/videos/a.mp4.compressed.mp4');
    });

    test('processes videos serially', () async {
      final first = Completer<Object?>();
      handler = (call) {
        if (call.method == 'compressVideo' && sourceOf(call) == '/videos/a.mp4') {
          return first.future;
        }
        return defaultHandler(call);
      };

      queue.enqueue('/videos/a.mp4');
      queue.enqueue('/videos/b.mp4');
      await pumpEventQueue();

      // b must wait for a to finish.
      expect(compressCalls(), hasLength(1));

      first.complete(successJson('/videos/a.mp4.compressed.mp4'));
      await pumpEventQueue();

      expect(compressCalls(), hasLength(2));
      expect(queue.compressedPathFor('/videos/a.mp4'), isNotNull);
      expect(queue.compressedPathFor('/videos/b.mp4'), isNotNull);
    });

    test('ignores duplicate enqueues for the same path', () async {
      final first = Completer<Object?>();
      handler = (_) => first.future;

      queue.enqueue('/videos/a.mp4');
      queue.enqueue('/videos/a.mp4'); // duplicate while in flight
      await pumpEventQueue();

      first.complete(successJson('/videos/a.mp4.compressed.mp4'));
      await pumpEventQueue();

      queue.enqueue('/videos/a.mp4'); // duplicate after completion
      await pumpEventQueue();

      expect(compressCalls(), hasLength(1));
    });

    test('does not compress while the camera is active', () async {
      queue.setCameraActive(true);
      queue.enqueue('/videos/a.mp4');
      await pumpEventQueue();

      expect(compressCalls(), isEmpty);

      queue.setCameraActive(false);
      await pumpEventQueue();

      expect(queue.compressedPathFor('/videos/a.mp4'),
          '/videos/a.mp4.compressed.mp4');
    });

    test('cancels and requeues the in-flight video when the camera activates',
        () async {
      final first = Completer<Object?>();
      var compressCount = 0;
      handler = (call) {
        if (call.method == 'compressVideo' && ++compressCount == 1) {
          return first.future;
        }
        return defaultHandler(call);
      };

      queue.enqueue('/videos/a.mp4');
      await pumpEventQueue();
      expect(compressCalls(), hasLength(1));

      queue.setCameraActive(true);
      // The platform reports a cancelled job as null.
      first.complete(null);
      await pumpEventQueue();

      expect(log.map((call) => call.method), contains('cancelCompression'));
      expect(queue.compressedPathFor('/videos/a.mp4'), isNull);
      expect(compressCalls(), hasLength(1)); // held while camera is active

      queue.setCameraActive(false);
      await pumpEventQueue();

      expect(compressCalls(), hasLength(2));
      expect(queue.compressedPathFor('/videos/a.mp4'),
          '/videos/a.mp4.compressed.mp4');
    });

    test('keeps no result when compression fails', () async {
      handler = (_) async => null;

      queue.enqueue('/videos/a.mp4');
      await pumpEventQueue();

      expect(queue.compressedPathFor('/videos/a.mp4'), isNull);
      expect(compressCalls(), hasLength(1)); // no retry loop
    });

    test('cancelAll clears queued work and results', () async {
      queue.enqueue('/videos/a.mp4');
      await pumpEventQueue();
      expect(queue.compressedPathFor('/videos/a.mp4'), isNotNull);

      queue.cancelAll();

      expect(queue.compressedPathFor('/videos/a.mp4'), isNull);
    });
  });
}
