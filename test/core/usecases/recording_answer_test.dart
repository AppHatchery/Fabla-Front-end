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

    test('an undecodable file is remembered but never deleted', () {
      // The file exists and holds bytes — only the decoder objected, and a
      // decoder can object to a good recording (a first getDuration() on AAC
      // comes back null on some devices). Discarding deletes the audio and
      // its row, so this verdict alone must not trigger it. The recording
      // still does not count as an answer, so the gate stays shut.
      checker.report('audios/a.aac', AudioStatus.canNotPlay);

      expect(checker.unplayable['audios/a.aac'], AudioStatus.canNotPlay);
      expect(discarded, isEmpty);
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

    test('a healthy sibling does not clear another recording\'s notice', () {
      // A multiple-answer prompt with one bad recording and one good one.
      // Clearing every notice on any success made the outcome depend on which
      // card resolved last: if the good one won, the discarded recording just
      // vanished from the list with nothing on screen to explain it. Only a
      // replacement retires a notice, and countUsable() is what spots one.
      checker.report('audios/bad.aac', AudioStatus.fileNotFound);
      discarded.clear();

      final changed = checker.report('audios/good.aac', AudioStatus.available);

      expect(changed, isFalse, reason: 'nothing about bad.aac changed');
      expect(checker.unplayable['audios/bad.aac'], AudioStatus.fileNotFound);
      expect(discarded, isEmpty);
    });

    test('failures are tracked per recording', () {
      checker.report('audios/a.aac', AudioStatus.fileNotFound);
      checker.report('audios/b.aac', AudioStatus.canNotPlay);

      expect(checker.unplayable, hasLength(2));
      expect(discarded, ['audios/a.aac'],
          reason: 'only the filesystem verdict deletes a row');
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

    test('a replacement recorded under a new filename retires the notice',
        () async {
      // The replacement is saved as a fresh row with its own timestamped
      // name, so its notice can never be matched by path — it has to be
      // recognised as new instead, or the discarded recording's explanation
      // sits on screen beside the new answer forever.
      const old = 'audios/audio_prompt_1_20-55-36.aac';
      const replacement = 'audios/audio_prompt_1_21-02-14.aac';

      // First sweep: the take was never written, so the row goes.
      expect(await checker.countUsable([_recording(old)]), 0);
      expect(discarded, [old]);
      expect(checker.unplayable[old], AudioStatus.fileNotFound);

      // Second sweep, after the participant records again.
      write(replacement, bytes: 16);

      expect(await checker.countUsable([_recording(replacement)]), 1);
      expect(checker.unplayable, isEmpty);
    });

    test('a sibling that was there all along retires nothing', () async {
      // The other half of the same rule: only a *new* recording counts as a
      // replacement. A healthy sibling present on the previous sweep must not
      // erase the explanation for one that was discarded.
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
      expect(checker.unplayable['audios/missing.aac'],
          AudioStatus.fileNotFound);
    });

    test('survives a discard that removes from the list being swept', () async {
      // The tests above inject a `discard` that only records the path, which
      // is not what production does: it reaches
      // PromptRepository.removeResponse, whose `recordings.removeWhere` runs
      // synchronously on the very `Answer.recordings` relation handed to this
      // sweep. Walking that list directly threw ConcurrentModificationError on
      // the next moveNext — on any single unusable recording, the one case the
      // sweep exists for.
      final recordings = [
        _recording('audios/missing_one.aac'),
        _recording('audios/missing_two.aac'),
      ];

      final mutating = RecordingAnswerChecker(
        discard: (path) => recordings.removeWhere((r) => r.path == path),
      );

      expect(await mutating.countUsable(recordings), 0);
      expect(recordings, isEmpty, reason: 'both rows should be discarded');
      expect(mutating.unplayable, hasLength(2));
    });
  });
}
