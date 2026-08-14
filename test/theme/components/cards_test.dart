import 'dart:io';

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

// Tests for the recording playback guards in lib/theme/components/cards.dart.
//
// ------------------------------------------------------------------
// Background
// ------------------------------------------------------------------
// Recordings were being written to the database for files that were never
// created on disk (Crashlytics issue ea6670918b178545b203745b920fee57). Both
// the audio player and the S3 uploader then failed on the same absent path:
//
//   AVPlayerItem.Status.failed on setSourceUrl
//   PathNotFoundException: Cannot open file, .../audios/audio_prompt_120_*.aac
//
// `AudioPlaybackMixin` verifies the recording on disk before exposing a
// player, so a missing, empty or undecodable file settles on an `AudioStatus`
// the card renders as an explanation, instead of throwing an uncaught
// PlatformException out of the platform audio stack.
//
// ------------------------------------------------------------------
// Testability
// ------------------------------------------------------------------
// The mixin is public and has no dependency on the card widgets, so it can be
// hosted by a minimal harness rather than mounting AudioDiaryCard (which pulls
// in Pendo, layout and MediaQuery).
//
// The file checks run BEFORE `AudioPlayer` is constructed, so those paths need
// no audioplayers platform mocking — only path_provider. Paths that require a
// live player are covered by setting `audioStatus` directly, which is a public
// field on the mixin.
//
// `initAudio` performs real dart:io work, which does not complete inside the
// FakeAsync zone that `testWidgets` installs. Every pump therefore goes
// through `tester.runAsync`.
// ------------------------------------------------------------------

const MethodChannel _pathProviderChannel =
    MethodChannel('plugins.flutter.io/path_provider');

const String _recordingPath = 'audios/audio_prompt_1_2026-07-21-20-55-36.aac';

/// Minimal host for [AudioPlaybackMixin].
class _PlaybackHarness extends StatefulWidget {
  const _PlaybackHarness({required this.recordingPath});

  final String recordingPath;

  @override
  State<_PlaybackHarness> createState() => _PlaybackHarnessState();
}

class _PlaybackHarnessState extends State<_PlaybackHarness>
    with AudioPlaybackMixin<_PlaybackHarness> {
  @override
  void initState() {
    super.initState();
    initAudio(widget.recordingPath);
  }

  @override
  void dispose() {
    disposeAudio();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Widget _wrap(Widget child) => ScreenUtilInit(
      minTextAdapt: true,
      designSize: const Size(1080, 1920),
      builder: (context, _) => MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;

  setUp(() {
    documentsDir = Directory.systemTemp.createTempSync('audio_cards_test');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return documentsDir.path;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);

    if (documentsDir.existsSync()) {
      documentsDir.deleteSync(recursive: true);
    }
  });

  /// Creates `<documents>/[relativePath]` containing [bytes] zero bytes.
  void writeRecording(String relativePath, {required int bytes}) {
    final file = File(p.join(documentsDir.path, relativePath))
      ..createSync(recursive: true);

    if (bytes > 0) {
      file.writeAsBytesSync(List<int>.filled(bytes, 0));
    }
  }

  /// Mounts the harness and drains the real async work `initAudio` performs.
  Future<_PlaybackHarnessState> pumpHarness(
    WidgetTester tester, {
    String recordingPath = _recordingPath,
  }) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        _wrap(_PlaybackHarness(recordingPath: recordingPath)),
      );
      // Lets getApplicationDocumentsDirectory() and the File checks settle.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    // ScreenUtilInit builds its child after the first frame.
    await tester.pump();
    await tester.pump();

    return tester.state<_PlaybackHarnessState>(find.byType(_PlaybackHarness));
  }

  // -------------------------------------------------------------------
  // 1. File existence check
  // -------------------------------------------------------------------
  group('AudioPlaybackMixin — missing recording', () {
    testWidgets('resolves to fileNotFound when the file is absent',
        (tester) async {
      // No file written — this is the production case where the recorder
      // reported a path it never wrote to.
      final state = await pumpHarness(tester);

      expect(state.audioStatus, AudioStatus.fileNotFound);
    });

    testWidgets('does not expose a player when the file is absent',
        (tester) async {
      final state = await pumpHarness(tester);

      expect(state.audioPlayer, isNull);
      expect(state.canPlay, isFalse);
    });

    testWidgets('leaves playback state at rest when the file is absent',
        (tester) async {
      final state = await pumpHarness(tester);

      expect(state.isPlaying, isFalse);
      expect(state.currentSliderPosition, 0);
      expect(state.maxSliderPosition, 0);
      expect(state.maxDuration, Duration.zero);
    });

    testWidgets('resolves to fileNotFound when only the directory exists',
        (tester) async {
      Directory(p.join(documentsDir.path, 'audios')).createSync(recursive: true);

      final state = await pumpHarness(tester);

      expect(state.audioStatus, AudioStatus.fileNotFound);
    });
  });

  // -------------------------------------------------------------------
  // 2. Empty file check
  // -------------------------------------------------------------------
  group('AudioPlaybackMixin — empty recording', () {
    testWidgets('resolves to noAudioLength for a zero byte file',
        (tester) async {
      // flutter_sound creates the file lazily on first audio write, so an
      // inactive audio session can leave a zero byte file behind.
      writeRecording(_recordingPath, bytes: 0);

      final state = await pumpHarness(tester);

      expect(state.audioStatus, AudioStatus.noAudioLength);
    });

    testWidgets('does not expose a player for a zero byte file',
        (tester) async {
      writeRecording(_recordingPath, bytes: 0);

      final state = await pumpHarness(tester);

      expect(state.audioPlayer, isNull);
      expect(state.canPlay, isFalse);
    });

    testWidgets('distinguishes an empty file from a missing one',
        (tester) async {
      writeRecording(_recordingPath, bytes: 0);

      final state = await pumpHarness(tester);

      // Both are unplayable, but they get different participant-facing copy.
      expect(state.audioStatus, isNot(AudioStatus.fileNotFound));
      expect(state.audioStatus, AudioStatus.noAudioLength);
    });
  });

  // -------------------------------------------------------------------
  // 3. Playback controls are inert while unplayable
  // -------------------------------------------------------------------
  group('AudioPlaybackMixin — controls while unplayable', () {
    for (final status in [
      AudioStatus.loading,
      AudioStatus.fileNotFound,
      AudioStatus.noAudioLength,
      AudioStatus.canNotPlay,
    ]) {
      testWidgets('canPlay is false for $status', (tester) async {
        final state = await pumpHarness(tester);
        state.audioStatus = status;

        expect(state.canPlay, isFalse);
      });
    }

    testWidgets('canPlay is true only for available', (tester) async {
      final state = await pumpHarness(tester);
      state.audioStatus = AudioStatus.available;

      expect(state.canPlay, isTrue);
    });

    testWidgets('play/seek/skip are no-ops without a player', (tester) async {
      final state = await pumpHarness(tester);

      // Guarded by `_run`: no player and not playable, so these must return
      // rather than throw on a null player.
      await expectLater(state.play(), completes);
      await expectLater(state.seek(1000), completes);
      await expectLater(state.skip(15000), completes);

      expect(state.audioStatus, AudioStatus.fileNotFound);
      expect(state.isPlaying, isFalse);
      expect(state.currentSliderPosition, 0);
    });

    testWidgets('controls stay inert even if the status is forced available',
        (tester) async {
      final state = await pumpHarness(tester);

      // Player is still null — `_run` must check both.
      state.audioStatus = AudioStatus.available;

      await expectLater(state.play(), completes);
      await expectLater(state.skip(-15000), completes);
    });

    testWidgets('disposeAudio is safe when no player was created',
        (tester) async {
      await pumpHarness(tester);

      // Tearing down the harness calls disposeAudio() on a null player.
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));

      expect(tester.takeException(), isNull);
    });
  });

  // -------------------------------------------------------------------
  // 4. Participant-facing error copy
  // -------------------------------------------------------------------
  group('RecordingIssueCard', () {
    Future<void> pumpCard(WidgetTester tester, AudioStatus status) async {
      await tester.pumpWidget(_wrap(RecordingIssueCard(status: status)));
      await tester.pumpAndSettle();
    }

    testWidgets('fileNotFound explains the recording is not on the device',
        (tester) async {
      await pumpCard(tester, AudioStatus.fileNotFound);

      expect(
        find.textContaining('find this recording on your device'),
        findsOneWidget,
      );
    });

    testWidgets('noAudioLength explains no audio was captured', (tester) async {
      await pumpCard(tester, AudioStatus.noAudioLength);

      expect(
        find.textContaining('no audio was captured'),
        findsOneWidget,
      );
    });

    testWidgets('canNotPlay explains something went wrong', (tester) async {
      await pumpCard(tester, AudioStatus.canNotPlay);

      expect(
        find.textContaining('something went wrong'),
        findsOneWidget,
      );
    });

    testWidgets('every failure status tells the participant to record again',
        (tester) async {
      for (final status in [
        AudioStatus.fileNotFound,
        AudioStatus.noAudioLength,
        AudioStatus.canNotPlay,
      ]) {
        await pumpCard(tester, status);

        expect(
          find.textContaining('record your answer again'),
          findsOneWidget,
          reason: '$status must offer a way forward',
        );
      }
    });

    testWidgets('each failure status renders distinct copy', (tester) async {
      final messages = <String>{};

      for (final status in [
        AudioStatus.fileNotFound,
        AudioStatus.noAudioLength,
        AudioStatus.canNotPlay,
      ]) {
        await pumpCard(tester, status);
        messages.add(tester.widget<Text>(find.byType(Text)).data ?? '');
      }

      expect(messages.length, 3);
    });

    testWidgets('renders a warning icon', (tester) async {
      await pumpCard(tester, AudioStatus.fileNotFound);

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('renders empty copy for non-failure statuses', (tester) async {
      // Defensive: the cards never build this for available/loading, but it
      // must not throw if they ever do.
      await pumpCard(tester, AudioStatus.available);

      expect(tester.takeException(), isNull);
      expect(tester.widget<Text>(find.byType(Text)).data, isEmpty);
    });
  });
}
