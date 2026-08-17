import 'dart:io';

import 'package:audio_diaries_flutter/core/usecases/recording_answer.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/recording.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

// Unit tests for RecordingAnswerChecker — the single owner of "can this
// recording serve as an answer".
//
// ------------------------------------------------------------------
// Background
// ------------------------------------------------------------------
// Recordings were reaching the database for files the recorder never wrote
// (Crashlytics issue ea6670918b178545b203745b920fee57). They failed playback
// and S3 upload while the submission still committed to DynamoDB, so a
// participant could finish a diary whose audio did not exist.
//
// The checker is what stops that: it discards rows that cannot be uploaded and
// reports how many usable recordings remain, so the Next / Back To Summary
// buttons stay disabled until a good recording replaces them.
//
// It is deliberately a plain class with an injected `discard` callback — the
// diary flow and the edit screen share one instance each, and neither the
// widget tree nor PromptCubit is needed to exercise it.
// ------------------------------------------------------------------

const MethodChannel _pathProviderChannel =
    MethodChannel('plugins.flutter.io/path_provider');

Recording _recording(String path) =>
    Recording('name', path, 'audio', null, DateTime(2026, 7, 21));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;
  late List<String> discarded;
  late RecordingAnswerChecker checker;

  setUp(() {
    documentsDir = Directory.systemTemp.createTempSync('recording_answer_test');
    discarded = [];
    checker = RecordingAnswerChecker(discard: discarded.add);

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

  /// Creates `<documents>/[relativePath]` holding [bytes] zero bytes.
  void write(String relativePath, {required int bytes}) {
    final file = File(p.join(documentsDir.path, relativePath))
      ..createSync(recursive: true);

    if (bytes > 0) {
      file.writeAsBytesSync(List<int>.filled(bytes, 0));
    }
  }

  // -------------------------------------------------------------------
  // 1. report() — a card's verdict
  // -------------------------------------------------------------------
  group('report', () {
    test('a failure is remembered and the row is discarded', () {
      final changed = checker.report('audios/a.aac', AudioStatus.fileNotFound);

      expect(changed, isTrue);
      expect(checker.unplayable['audios/a.aac'], AudioStatus.fileNotFound);
      expect(discarded, ['audios/a.aac']);
    });

    test('an undecodable file is discarded like a missing one', () {
      // The file exists and has content, but nothing can play it. Leaving it
      // would let the participant proceed and then fail at submission.
      checker.report('audios/a.aac', AudioStatus.canNotPlay);

      expect(checker.unplayable['audios/a.aac'], AudioStatus.canNotPlay);
      expect(discarded, ['audios/a.aac']);
    });

    test('repeating the same verdict does not discard twice', () {
      checker.report('audios/a.aac', AudioStatus.fileNotFound);
      final changed = checker.report('audios/a.aac', AudioStatus.fileNotFound);

      expect(changed, isFalse, reason: 'no state change, so no rebuild');
      expect(discarded, hasLength(1));
    });

    test('available for an unknown recording changes nothing', () {
      final changed = checker.report('audios/a.aac', AudioStatus.available);

      expect(changed, isFalse);
      expect(checker.unplayable, isEmpty);
      expect(discarded, isEmpty);
    });

    test('available clears an earlier failure without discarding', () {
      checker.report('audios/a.aac', AudioStatus.fileNotFound);
      discarded.clear();

      final changed = checker.report('audios/a.aac', AudioStatus.available);

      expect(changed, isTrue);
      expect(checker.unplayable, isEmpty);
      expect(discarded, isEmpty, reason: 'a working recording is never dropped');
    });

    test('a replacement under a new filename clears the old notice', () {
      // The replacement is saved as a fresh row with its own timestamped name,
      // so clearing by path alone would leave the discarded recording's
      // explanation on screen beside the new answer.
      checker.report('audios/audio_prompt_1_20-55-36.aac',
          AudioStatus.fileNotFound);
      discarded.clear();

      final changed = checker.report(
          'audios/audio_prompt_1_21-02-14.aac', AudioStatus.available);

      expect(changed, isTrue);
      expect(checker.unplayable, isEmpty);
      expect(discarded, isEmpty);
    });

    test('failures are tracked per recording', () {
      checker.report('audios/a.aac', AudioStatus.fileNotFound);
      checker.report('audios/b.aac', AudioStatus.canNotPlay);

      expect(checker.unplayable, hasLength(2));
      expect(discarded, ['audios/a.aac', 'audios/b.aac']);
    });
  });

  // -------------------------------------------------------------------
  // 2. countUsable() — the sweep
  // -------------------------------------------------------------------
  group('countUsable', () {
    test('an empty list needs no disk access', () async {
      expect(await checker.countUsable([]), 0);
      expect(discarded, isEmpty);
    });

    test('counts recordings that exist and have content', () async {
      write('audios/a.aac', bytes: 16);
      write('audios/b.aac', bytes: 16);

      final usable = await checker.countUsable(
        [_recording('audios/a.aac'), _recording('audios/b.aac')],
      );

      expect(usable, 2);
      expect(discarded, isEmpty);
      expect(checker.unplayable, isEmpty);
    });

    test('a missing file is discarded as fileNotFound', () async {
      // The production case: startRecorder captured nothing, so the file was
      // never created, but stopRecorder returned its intended path anyway.
      final usable =
          await checker.countUsable([_recording('audios/never_written.aac')]);

      expect(usable, 0);
      expect(discarded, ['audios/never_written.aac']);
      expect(
        checker.unplayable['audios/never_written.aac'],
        AudioStatus.fileNotFound,
      );
    });

    test('a zero byte file is discarded as noAudioLength', () async {
      write('audios/empty.aac', bytes: 0);

      final usable = await checker.countUsable([_recording('audios/empty.aac')]);

      expect(usable, 0);
      expect(discarded, ['audios/empty.aac']);
      expect(
        checker.unplayable['audios/empty.aac'],
        AudioStatus.noAudioLength,
        reason: 'an empty file is distinguished from a missing one',
      );
    });

    test('counts only the usable ones in a mixed set', () async {
      write('audios/good.aac', bytes: 16);
      write('audios/empty.aac', bytes: 0);

      final usable = await checker.countUsable([
        _recording('audios/good.aac'),
        _recording('audios/empty.aac'),
        _recording('audios/missing.aac'),
      ]);

      expect(usable, 1);
      expect(discarded, ['audios/empty.aac', 'audios/missing.aac']);
    });

    test('a recording already reported bad is not discarded again', () async {
      checker.report('audios/missing.aac', AudioStatus.fileNotFound);
      discarded.clear();

      final usable =
          await checker.countUsable([_recording('audios/missing.aac')]);

      expect(usable, 0);
      expect(discarded, isEmpty, reason: 'already dropped once');
    });

    test('an undecodable file is not counted even though it is on disk',
        () async {
      // canNotPlay files pass every filesystem check, so the card's verdict is
      // the only thing that can exclude them.
      write('audios/garbage.aac', bytes: 16);
      checker.report('audios/garbage.aac', AudioStatus.canNotPlay);
      discarded.clear();

      final usable =
          await checker.countUsable([_recording('audios/garbage.aac')]);

      expect(usable, 0);
      expect(discarded, isEmpty);
    });

    test('is idempotent across repeated sweeps', () async {
      write('audios/good.aac', bytes: 16);

      final first = await checker.countUsable([
        _recording('audios/good.aac'),
        _recording('audios/missing.aac'),
      ]);
      final second = await checker.countUsable([
        _recording('audios/good.aac'),
        _recording('audios/missing.aac'),
      ]);

      expect(first, 1);
      expect(second, 1);
      expect(discarded, ['audios/missing.aac'],
          reason: 'a second sweep must not re-discard');
    });

    test('resolves paths relative to the documents directory', () async {
      // Recording.path is stored relative so it survives a reinstall — the iOS
      // container UUID in an absolute path changes.
      write('audios/nested.aac', bytes: 16);

      expect(await checker.countUsable([_recording('audios/nested.aac')]), 1);
      expect(await checker.countUsable([_recording('nested.aac')]), 0);
    });
  });
}
