import 'dart:async';

import 'package:audio_diaries_flutter/services/audio_segment_merger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Covers the Dart half of the iOS segment join. The native half is stubbed at
// the channel, so these pin the contract: what is sent, what a success looks
// like, and how each failure is reported rather than thrown.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('diary/audio_segments');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;

  void stub(Future<Object?> Function(MethodCall call) handler) {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return handler(call);
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  final merger = AudioSegmentMerger();
  const segments = ['/take.m4a', '/take_part2.m4a'];

  test('sends the segments in order with the output path', () async {
    stub((_) async => {'path': '/take_joined.m4a', 'skipped': []});

    await merger.merge(segments, output: '/take_joined.m4a');

    expect(calls.single.method, 'merge');
    expect(calls.single.arguments, {
      'segments': segments,
      'output': '/take_joined.m4a',
    });
  });

  test('returns the joined path when nothing was skipped', () async {
    stub((_) async => {'path': '/take_joined.m4a', 'skipped': []});

    expect(
      await merger.merge(segments, output: '/take_joined.m4a'),
      isA<SegmentsJoined>()
          .having((r) => r.path, 'path', '/take_joined.m4a'),
    );
  });

  test('still returns the path when some segments were skipped', () async {
    stub(
      (_) async => {
        'path': '/take_joined.m4a',
        'skipped': [
          {'index': 1, 'size': 48, 'reason': 'AVFoundationErrorDomain -11800'},
        ],
      },
    );

    expect(
      await merger.merge(segments, output: '/take_joined.m4a'),
      isA<SegmentsJoined>()
          .having((r) => r.path, 'path', '/take_joined.m4a'),
    );
  });

  test('tolerates a reply with no skipped list', () async {
    stub((_) async => {'path': '/take_joined.m4a'});

    expect(
      await merger.merge(segments, output: '/take_joined.m4a'),
      isA<SegmentsJoined>()
          .having((r) => r.path, 'path', '/take_joined.m4a'),
    );
  });

  // Only NO_USABLE_SEGMENTS means retrying cannot help, and the caller
  // deletes the segments on it, so it also has to account for every one.
  Map<String, Object?> skippedAll(List<int> indexes) => {
        'domain': 'AVFoundationErrorDomain',
        'code': -11800,
        'segments': [
          for (final i in indexes)
            {'index': i, 'size': 48, 'reason': 'AVFoundationErrorDomain -11800'},
        ],
      };

  for (final failure in {
    'every segment skipped': (
      code: 'NO_USABLE_SEGMENTS',
      details: skippedAll([0, 1]),
      result: isA<SegmentsUnusable>(),
    ),
    'only some segments listed': (
      code: 'NO_USABLE_SEGMENTS',
      details: skippedAll([0]),
      result: isA<SegmentJoinFailed>(),
    ),
    'a duplicated index': (
      code: 'NO_USABLE_SEGMENTS',
      details: skippedAll([0, 0]),
      result: isA<SegmentJoinFailed>(),
    ),
    'no details': (
      code: 'NO_USABLE_SEGMENTS',
      details: null,
      result: isA<SegmentJoinFailed>(),
    ),
    'another code with every segment skipped': (
      code: 'COMPOSE_FAILED',
      details: skippedAll([0, 1]),
      result: isA<SegmentJoinFailed>(),
    ),
    'an export failure': (
      code: 'EXPORT_FAILED',
      details: null,
      result: isA<SegmentJoinFailed>(),
    ),
  }.entries) {
    test('${failure.key} is reported as ${failure.value.result}', () async {
      stub(
        (_) async => throw PlatformException(
          code: failure.value.code,
          message: 'failed',
          details: failure.value.details,
        ),
      );

      expect(
        await merger.merge(segments, output: '/out.m4a'),
        failure.value.result,
      );
    });
  }

  test('a native call that never answers times out as retryable', () async {
    final never = Completer<Object?>();
    stub((_) => never.future);

    final quick = AudioSegmentMerger(timeout: const Duration(milliseconds: 10));

    expect(
      await quick.merge(segments, output: '/out.m4a'),
      isA<SegmentJoinFailed>(),
    );
  });

  test('a missing channel is a retryable failure', () async {
    // What Android sees: only iOS registers the channel.
    stub((_) async => throw MissingPluginException());

    expect(
      await merger.merge(segments, output: '/out.m4a'),
      isA<SegmentJoinFailed>(),
    );
  });

  test('a null reply is a retryable failure', () async {
    stub((_) async => null);

    expect(
      await merger.merge(segments, output: '/out.m4a'),
      isA<SegmentJoinFailed>(),
    );
  });
}
