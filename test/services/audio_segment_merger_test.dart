import 'package:audio_diaries_flutter/services/audio_segment_merger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Covers the Dart half of the iOS segment join. The native half is stubbed at
// the channel, so these pin the contract: what is sent, what a success looks
// like, and that every failure becomes `null` rather than a throw.
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
      '/take_joined.m4a',
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
      '/take_joined.m4a',
    );
  });

  test('tolerates a reply with no skipped list', () async {
    stub((_) async => {'path': '/take_joined.m4a'});

    expect(
      await merger.merge(segments, output: '/take_joined.m4a'),
      '/take_joined.m4a',
    );
  });

  // Every native failure code takes the same path: reported, then null, so
  // the caller keeps the segments and lets the participant try again. Details
  // are optional because only COMPOSE_FAILED and EMPTY carry them.
  for (final failure in {
    'COMPOSE_FAILED': {
      'domain': 'AVFoundationErrorDomain',
      'code': -11800,
      'segments': [
        {'index': 0, 'size': 48, 'reason': 'AVFoundationErrorDomain -11800'},
      ],
    },
    'EMPTY': <Object?>[],
    'EXPORT_FAILED': null,
  }.entries) {
    test('returns null for ${failure.key}', () async {
      stub(
        (_) async => throw PlatformException(
          code: failure.key,
          message: 'failed',
          details: failure.value,
        ),
      );

      expect(await merger.merge(segments, output: '/out.m4a'), isNull);
    });
  }

  test('returns null when the channel is not implemented', () async {
    // What Android sees: only iOS registers the channel.
    stub((_) async => throw MissingPluginException());

    expect(await merger.merge(segments, output: '/out.m4a'), isNull);
  });

  test('returns null when the native side replies null', () async {
    stub((_) async => null);

    expect(await merger.merge(segments, output: '/out.m4a'), isNull);
  });
}
