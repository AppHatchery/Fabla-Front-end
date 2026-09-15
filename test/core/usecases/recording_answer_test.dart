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
// and upload while the diary still submitted, so a participant could finish a
// diary whose audio did not exist.
//
// The checker stops that: it deletes rows that cannot be uploaded and reports
// how many good recordings remain, so the Next button stays disabled until one
// replaces them. It is a plain class with an injected `discard` callback, so no
// widget tree or cubit is needed to test it.
// ------------------------------------------------------------------

const MethodChannel _pathProviderChannel =
    MethodChannel('plugins.flutter.io/path_provider');

Recording _recording(String path) =>
    Recording('name', path, 'audio', null, DateTime(2026, 7, 21));

/// The usable count from a sweep.
///
/// Most of these tests are about what the sweep found, not about whether it
/// could read the disk at all, so they take the count and ignore the rest.
/// The "could not read the disk" group covers that half.
Future<int> usableCount(
  RecordingAnswerChecker checker,
  List<Recording> recordings,
) async =>
    (await checker.countUsable(recordings)).usable;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;
  late List<String> discarded;
  late RecordingAnswerChecker checker;

  setUp(() {
    documentsDir = Directory.systemTemp.createTempSync('recording_answer_test');
    discarded = [];
    // Single-answer is the common prompt shape; the multiple-answer group
    // below builds its own checker.
    checker = RecordingAnswerChecker(
      discard: discarded.add,
      singleAnswer: true,
    );

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
  // 0. dismiss() — the participant clearing a notice
  // -------------------------------------------------------------------
  //
  // The other side of report(): same two effects, opposite authority. report()
  // will not delete a canNotPlay row, because a decoder can be wrong.
  // dismiss() will, because a participant asked.
  // -------------------------------------------------------------------
  group('dismiss', () {
    // The case the button exists for. A canNotPlay row keeps its place in the
    // answer list — uncountable, unplayable, and showing a notice where its
    // own delete control would be — so this is the only way it can go.
    test('a row report() refused to delete is deleted', () {
      checker.report('audios/a.aac', AudioStatus.canNotPlay);
      expect(discarded, isEmpty, reason: 'report() leaves this one alone');

      checker.dismiss('audios/a.aac');

      expect(discarded, ['audios/a.aac']);
      expect(checker.unplayable, isEmpty);
    });

    // The notice on a row report() already deleted. There is nothing left to
    // delete, and deleting again would hand the cubit a path that is gone.
    test('a notice for an already deleted row only loses the notice', () {
      checker.report('audios/a.aac', AudioStatus.fileNotFound);
      expect(discarded, ['audios/a.aac']);

      checker.dismiss('audios/a.aac');

      expect(discarded, ['audios/a.aac'], reason: 'not deleted twice');
      expect(checker.unplayable, isEmpty);
    });

    test('dismissing twice deletes once', () {
      checker.report('audios/a.aac', AudioStatus.canNotPlay);

      checker.dismiss('audios/a.aac');
      checker.dismiss('audios/a.aac');

      expect(discarded, ['audios/a.aac']);
    });

    // Notices are per recording. A prompt can carry several, and clearing one
    // must not take the explanation for another down with it.
    test('only the dismissed recording is affected', () {
      checker.report('audios/a.aac', AudioStatus.canNotPlay);
      checker.report('audios/b.aac', AudioStatus.canNotPlay);

      checker.dismiss('audios/a.aac');

      expect(discarded, ['audios/a.aac']);
      expect(checker.unplayable.keys, ['audios/b.aac']);
    });

    // The bug this predicate exists for. dismiss() drops the notice the instant
    // the participant taps, but the row only leaves the prompt once the cubit
    // reloads. Reading `unplayable` alone treats the row as good in that gap,
    // which hid the record button until the diary was closed and reopened.
    test('a dismissed recording is unusable even while its row lingers', () {
      checker.report('audios/a.aac', AudioStatus.canNotPlay);
      expect(checker.isUsable('audios/a.aac'), isFalse,
          reason: 'a notice disqualifies it');

      checker.dismiss('audios/a.aac');

      expect(checker.unplayable, isEmpty, reason: 'the notice is gone');
      expect(checker.isUsable('audios/a.aac'), isFalse,
          reason: 'but the recording still must not count as an answer');
    });

    test('a recording nothing is known against is usable', () {
      expect(checker.isUsable('audios/untouched.aac'), isTrue);
    });

    // countUsable() skips anything already discarded, so a dismissed row must
    // not come back as a fresh notice on the next sweep.
    test('a dismissed row stays gone across a later sweep', () async {
      write('audios/a.aac', bytes: 0);
      checker.report('audios/a.aac', AudioStatus.canNotPlay);
      checker.dismiss('audios/a.aac');

      final usable = await usableCount(checker, [_recording('audios/a.aac')]);

      expect(usable, 0);
      expect(discarded, ['audios/a.aac'], reason: 'still only the one delete');
      expect(checker.unplayable, isEmpty, reason: 'no notice comes back');
    });
  });

  // -------------------------------------------------------------------
  // 0b. Resilience — a failure must not take the sweep or the notices with it
  // -------------------------------------------------------------------
  group('resilience', () {
    // The sweep changes state as it goes: each bad recording gets a notice and
    // a delete before the next is looked at. A throw part-way used to abort the
    // whole thing, so the rest were never examined and the caller got an
    // exception instead of a count.
    //
    // The throw comes from the discard callback, not the disk: `File.exists()`
    // returns false rather than throwing for every bad path this test could
    // build. A cubit call that throws is a realistic failure anyway.
    test('a discard that fails is reported and does not stop the sweep',
        () async {
      write('audios/good.aac', bytes: 4);

      final reasons = <String>[];

      checker = RecordingAnswerChecker(
        discard: (path) => throw StateError('the row is gone'),
        singleAnswer: true,
        onError: (error, stackTrace, reason) => reasons.add(reason),
      );

      final usable = await usableCount(checker, [
        _recording('audios/gone.aac'),
        _recording('audios/good.aac'),
      ]);

      expect(usable, 1, reason: 'the healthy recording was still counted');
      expect(reasons, hasLength(1), reason: 'and the failure was not silent');
    });

    // The row is still there when the delete fails, so the checker must not
    // remember it as gone. Marking it discarded up front left a row that never
    // counted, was never retried, and lost its notice — so the participant
    // could neither use it nor remove it, with nothing explaining why.
    test('a row whose delete failed is tried again on the next sweep',
        () async {
      write('audios/good.aac', bytes: 4);

      var deleteWorks = false;

      checker = RecordingAnswerChecker(
        discard: (path) {
          if (!deleteWorks) throw StateError('the row is gone');
          discarded.add(path);
        },
        singleAnswer: true,
      );

      List<Recording> prompt() => [
            _recording('audios/missing.aac'),
            _recording('audios/good.aac'),
          ];

      await usableCount(checker, prompt());
      expect(discarded, isEmpty, reason: 'nothing was actually deleted');

      deleteWorks = true;
      await usableCount(checker, prompt());

      expect(discarded, ['audios/missing.aac'],
          reason: 'the second sweep reached it because the first did not '
              'claim it was already gone');
    });

    // The same retry with nothing else on the prompt to trigger it. It used to
    // depend on _retireDiscardedNotices() clearing the notice first, which only
    // runs on a single-answer prompt that already has a good recording — so
    // everywhere else the row was never tried again at all.
    test('a row whose delete failed is retried with nothing else to go on',
        () async {
      var deleteWorks = false;

      checker = RecordingAnswerChecker(
        discard: (path) {
          if (!deleteWorks) throw StateError('the row is gone');
          discarded.add(path);
        },
        singleAnswer: false,
        onError: (error, stackTrace, reason) {},
      );

      List<Recording> prompt() => [_recording('audios/missing.aac')];

      expect(await usableCount(checker, prompt()), 0);
      expect(discarded, isEmpty, reason: 'the first delete threw');

      deleteWorks = true;
      expect(await usableCount(checker, prompt()), 0);

      expect(discarded, ['audios/missing.aac'],
          reason: 'the second sweep reached it even with no healthy sibling '
              'to retire the notice');
    });

    // The sweep now checks every row still on the prompt, not just the ones
    // without a notice — so a recording that exists and has bytes but will not
    // play must stay uncounted on the card's word alone.
    test('a recording a card rejected is not counted by a healthy stat',
        () async {
      write('audios/broken.aac', bytes: 4);

      checker.report('audios/broken.aac', AudioStatus.canNotPlay);

      expect(await usableCount(checker, [_recording('audios/broken.aac')]), 0);
      expect(discarded, isEmpty,
          reason: 'and a decoder’s verdict still does not destroy it');
    });

    // The other half of the same failure. _retireDiscardedNotices() used to
    // decide from the status alone, but a deletable status only means report()
    // *tried*. When the delete threw, the row is still there, so dropping its
    // notice handed a missing file back as a perfectly good answer.
    test('a notice is not retired for a row that was never deleted', () async {
      write('audios/good.aac', bytes: 4);

      checker = RecordingAnswerChecker(
        discard: (path) => throw StateError('the cubit refused'),
        singleAnswer: true,
        onError: (error, stackTrace, reason) {},
      );

      final usable = await usableCount(checker, [
        _recording('audios/missing.aac'),
        _recording('audios/good.aac'),
      ]);

      expect(usable, 1, reason: 'the good recording retires the notices');
      expect(checker.unplayable.keys, ['audios/missing.aac'],
          reason: 'but not this one — its row is still there');
      expect(checker.isUsable('audios/missing.aac'), isFalse,
          reason: 'and it must not come back as an answer');
    });

    // Every onError call sits inside a catch whose whole job is to absorb a
    // failure. A reporter that throws would escape that block and undo the
    // recovery it was being told about — turning something already handled
    // back into the unhandled error this class works to avoid.
    test('a reporter that throws cannot undo the recovery', () async {
      write('audios/good.aac', bytes: 4);

      checker = RecordingAnswerChecker(
        discard: (path) => throw StateError('the row is gone'),
        singleAnswer: true,
        onError: (error, stackTrace, reason) =>
            throw StateError('and the reporter is down too'),
      );

      final count = await checker.countUsable([
        _recording('audios/gone.aac'),
        _recording('audios/good.aac'),
      ]);

      expect(count.checked, isTrue);
      expect(count.usable, 1,
          reason: 'the sweep finished despite both failures');
    });

    // The notices are handed to the card that renders them. Letting it write
    // to the map would let a widget clear an explanation the participant is
    // owed, or mark a broken recording available, with the page none the
    // wiser — the page owns that decision, through report() and dismiss().
    test('the notices cannot be rewritten by whoever is rendering them', () {
      checker.report('audios/a.aac', AudioStatus.canNotPlay);

      expect(() => checker.unplayable.clear(), throwsUnsupportedError);
      expect(
        () => checker.unplayable['audios/a.aac'] = AudioStatus.available,
        throwsUnsupportedError,
      );
      expect(() => checker.unplayable.remove('audios/a.aac'),
          throwsUnsupportedError);

      expect(checker.unplayable['audios/a.aac'], AudioStatus.canNotPlay,
          reason: 'and the notice is still there to read');
    });
  });

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
      expect(discarded, isEmpty,
          reason: 'a working recording is never dropped');
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
  // 1b. A sweep that could not look at the disk at all
  // -------------------------------------------------------------------
  //
  // Zero used to mean two different things. "Checked them all, none count" is
  // something a participant can fix by recording again; "could not find the
  // documents folder" is a device fault that every retry repeats. Both arrived
  // as a bare `0`, so the page shut the gate and said nothing.
  // -------------------------------------------------------------------
  group('a sweep that could not read the disk', () {
    void failTheDocumentsDirectory() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        _pathProviderChannel,
        (call) async => throw PlatformException(code: 'no-documents-directory'),
      );
    }

    test('says so, rather than reporting that nothing counts', () async {
      failTheDocumentsDirectory();

      final count = await checker.countUsable([_recording('audios/a.aac')]);

      expect(count.checked, isFalse);
      expect(count.usable, 0, reason: 'nothing was established either way');
    });

    test('a sweep that ran and found nothing still reports itself checked',
        () async {
      final count = await checker.countUsable([_recording('audios/a.aac')]);

      expect(count.checked, isTrue);
      expect(count.usable, 0);
    });

    // The gate stays shut either way, but nothing may be destroyed or written
    // off on the strength of a lookup that never ran: not one of these files
    // was actually examined.
    test('writes nothing off and deletes nothing', () async {
      failTheDocumentsDirectory();

      await checker.countUsable([_recording('audios/a.aac')]);

      expect(discarded, isEmpty);
      expect(checker.unplayable, isEmpty);
      expect(checker.isUsable('audios/a.aac'), isTrue,
          reason: 'the next sweep has to be free to check it properly');
    });

    test('reports the failure rather than swallowing it', () async {
      final reasons = <String>[];

      checker = RecordingAnswerChecker(
        discard: discarded.add,
        singleAnswer: true,
        onError: (error, stackTrace, reason) => reasons.add(reason),
      );

      failTheDocumentsDirectory();

      await checker.countUsable([_recording('audios/a.aac')]);

      expect(reasons, hasLength(1));
    });

    // A prompt with nothing on it never reaches the disk, so its zero is a
    // real verdict and the page has nothing to explain.
    test('a prompt with no recordings counts as checked', () async {
      failTheDocumentsDirectory();

      final count = await checker.countUsable([]);

      expect(count.checked, isTrue);
      expect(count.usable, 0);
    });
  });

  // -------------------------------------------------------------------
  // 2. countUsable() — the sweep
  // -------------------------------------------------------------------
  group('countUsable', () {
    test('an empty list needs no disk access', () async {
      expect(await usableCount(checker, []), 0);
      expect(discarded, isEmpty);
    });

    test('counts recordings that exist and have content', () async {
      write('audios/a.aac', bytes: 16);
      write('audios/b.aac', bytes: 16);

      final usable = await usableCount(
        checker,
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
          await usableCount(checker, [_recording('audios/never_written.aac')]);

      expect(usable, 0);
      expect(discarded, ['audios/never_written.aac']);
      expect(
        checker.unplayable['audios/never_written.aac'],
        AudioStatus.fileNotFound,
      );
    });

    test('a zero byte file is discarded as noAudioLength', () async {
      write('audios/empty.aac', bytes: 0);

      final usable =
          await usableCount(checker, [_recording('audios/empty.aac')]);

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

      final usable = await usableCount(checker, [
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
          await usableCount(checker, [_recording('audios/missing.aac')]);

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
          await usableCount(checker, [_recording('audios/garbage.aac')]);

      expect(usable, 0);
      expect(discarded, isEmpty);
    });

    test('is idempotent across repeated sweeps', () async {
      write('audios/good.aac', bytes: 16);

      final first = await usableCount(checker, [
        _recording('audios/good.aac'),
        _recording('audios/missing.aac'),
      ]);
      final second = await usableCount(checker, [
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

      expect(await usableCount(checker, [_recording('audios/nested.aac')]), 1);
      expect(await usableCount(checker, [_recording('nested.aac')]), 0);
    });

    test('a replacement retires the notice on a single-answer prompt',
        () async {
      // The replacement is saved as a fresh row with its own timestamped name,
      // so its notice can never be matched by path. A single-answer prompt has
      // one slot, so any usable recording is the replacement the notice was
      // asking for — otherwise the discarded take's explanation sits on screen
      // beside the new answer forever.
      const old = 'audios/audio_prompt_1_20-55-36.aac';
      const replacement = 'audios/audio_prompt_1_21-02-14.aac';

      // First sweep: the take was never written, so the row goes.
      expect(await usableCount(checker, [_recording(old)]), 0);
      expect(discarded, [old]);
      expect(checker.unplayable[old], AudioStatus.fileNotFound);

      // Second sweep, after the participant records again.
      write(replacement, bytes: 16);

      expect(await usableCount(checker, [_recording(replacement)]), 1);
      expect(checker.unplayable, isEmpty);
    });

    test('retiring keeps an undecodable recording flagged', () async {
      // The row is still in answer.recordings — only missing and empty files
      // get deleted. Dropping its key alongside the discarded ones would hand
      // it back as a playable answer: it would count towards the record button
      // and, on the next sweep, towards the gate.
      write('audios/garbage.aac', bytes: 16);
      write('audios/good.aac', bytes: 16);

      checker.report('audios/garbage.aac', AudioStatus.canNotPlay);

      expect(await usableCount(checker, [_recording('audios/missing.aac')]), 0);
      expect(
          checker.unplayable['audios/missing.aac'], AudioStatus.fileNotFound);

      final usable = await usableCount(checker, [
        _recording('audios/good.aac'),
        _recording('audios/garbage.aac'),
      ]);

      expect(usable, 1, reason: 'the undecodable file is still not an answer');
      expect(checker.unplayable['audios/missing.aac'], isNull,
          reason: 'the discarded row\'s notice has served its purpose');
      expect(checker.unplayable['audios/garbage.aac'], AudioStatus.canNotPlay,
          reason: 'the row is still present, so it stays flagged');
      expect(discarded, isNot(contains('audios/garbage.aac')));
    });

    test('a healthy sibling retires nothing on a multiple-answer prompt',
        () async {
      // Nothing links a new recording to any particular lost take, so on a
      // prompt that accepts several answers there is no honest way to say
      // which notice it replaces. Guessing is what let one healthy recording
      // erase the explanation for a different discarded one.
      final multi = RecordingAnswerChecker(
        discard: discarded.add,
        singleAnswer: false,
      );

      write('audios/good.aac', bytes: 16);

      final usable = await usableCount(multi, [
        _recording('audios/good.aac'),
        _recording('audios/missing.aac'),
      ]);

      expect(usable, 1);
      expect(discarded, ['audios/missing.aac']);
      expect(multi.unplayable['audios/missing.aac'], AudioStatus.fileNotFound,
          reason: 'the lost answer still needs explaining');
    });

    test('each lost take on a multiple-answer prompt keeps its own notice',
        () async {
      final multi = RecordingAnswerChecker(
        discard: discarded.add,
        singleAnswer: false,
      );

      write('audios/good.aac', bytes: 16);
      write('audios/empty.aac', bytes: 0);

      final usable = await usableCount(multi, [
        _recording('audios/good.aac'),
        _recording('audios/empty.aac'),
        _recording('audios/missing.aac'),
      ]);

      expect(usable, 1);
      expect(multi.unplayable, hasLength(2));
      expect(multi.unplayable['audios/empty.aac'], AudioStatus.noAudioLength);
      expect(multi.unplayable['audios/missing.aac'], AudioStatus.fileNotFound);
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
        singleAnswer: true,
      );

      expect(await usableCount(mutating, recordings), 0);
      expect(recordings, isEmpty, reason: 'both rows should be discarded');
      expect(mutating.unplayable, hasLength(2));
    });
  });
}
