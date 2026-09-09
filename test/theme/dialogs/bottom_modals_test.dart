import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/services/audio_recording_service.dart';
import 'package:audio_diaries_flutter/theme/dialogs/bottom_modals.dart';
import 'package:flutter_test/flutter_test.dart';

//
// ------------------------------------------------------------------
// Why the dispatch is mirrored rather than driven
// ------------------------------------------------------------------
// `save()` is a private method on a private State. Reaching it means mounting
// `BottomRecordingModal`, and its `initState` calls `_loadRive()`, which loads
// Rive's native binary over FFI and trips a SIGABRT in flutter_tester. So the
// switch is reproduced below by `_SaveDispatchHarness`, one branch per outcome.
//
// If you change the switch in `save()`, mirror the change here AND update these
// tests — otherwise the spec drifts away from the impl.
// ------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------
  // 1. basePath — the relative path stored on the Recording row
  // -------------------------------------------------------------------
  //
  // `save()` persists `basePath(result.path!)`, not the absolute path. Keeping
  // only the last two segments makes the reference survive reinstalls, because
  // the iOS container UUID in the absolute path changes.
  // -------------------------------------------------------------------
  group('basePath contract', () {
    test('keeps the final directory and filename', () {
      expect(
        basePath('/var/mobile/Containers/Data/Application/B2AD9040/Documents/'
            'audios/audio_prompt_120_2026-07-21-20-55-36.m4a'),
        'audios/audio_prompt_120_2026-07-21-20-55-36.m4a',
      );
    });

    test('drops the container UUID that changes between installs', () {
      const first = '/var/mobile/Containers/Data/Application/AAAA-1111/'
          'Documents/audios/clip.m4a';
      const second = '/var/mobile/Containers/Data/Application/BBBB-2222/'
          'Documents/audios/clip.m4a';

      expect(basePath(first), basePath(second));
    });

    test('handles a two segment path', () {
      expect(basePath('audios/clip.m4a'), 'audios/clip.m4a');
    });
  });

  // -------------------------------------------------------------------
  // 2. save() outcome dispatch
  // -------------------------------------------------------------------
  //
  // The service reports what happened to the take; the modal decides what the
  // participant gets. Only `saved` may reach `onSave` and close the sheet —
  // everything else leaves the modal open so the answer can be recorded again.
  // -------------------------------------------------------------------
  group('save() outcome dispatch', () {
    late _SaveDispatchHarness harness;

    setUp(() {
      harness = _SaveDispatchHarness();
    });

    test('a saved take is persisted by its relative path and closes the sheet',
        () async {
      await harness.save(const RecordingSaveResult(
        RecordingSaveOutcome.saved,
        '/var/mobile/Containers/Data/Application/AAAA/Documents/'
        'audios/clip.m4a',
      ));

      expect(harness.savedName, 'audios/clip.m4a',
          reason: 'the row stores the reinstall-safe path, not the absolute');
      expect(harness.popped, isTrue);
      expect(harness.failuresTracked, 0);
    });

    // The production data-loss case: flutter_sound creates the file lazily on
    // the first audio write, so an inactive session leaves a valid-looking path
    // pointing at nothing. A row for that path reaches DynamoDB and then fails
    // forever on playback and on S3 upload.
    test('an empty take is not persisted and clears the waveform', () async {
      await harness
          .save(const RecordingSaveResult(RecordingSaveOutcome.emptyFile));

      expect(harness.savedName, isNull,
          reason: 'no database row may be created for audio that is not there');
      expect(harness.popped, isFalse,
          reason: 'the modal stays open so the participant can retry');
      expect(harness.eraseToggles, 1,
          reason: 'the bars of the take that captured nothing must come down');
    });

    test('nothing recorded is a silent no-op', () async {
      await harness.save(
          const RecordingSaveResult(RecordingSaveOutcome.nothingRecorded));

      expect(harness.savedName, isNull);
      expect(harness.popped, isFalse);
      expect(harness.eraseToggles, 0,
          reason: 'there is no waveform to clear — nothing was captured');
      expect(harness.failuresTracked, 0,
          reason: 'reaching save with no take is the timer-limit path, '
              'not a failure worth reporting');
    });

    test('a failed save is reported and leaves the modal open', () async {
      await harness
          .save(const RecordingSaveResult(RecordingSaveOutcome.failed));

      expect(harness.failuresTracked, 1);
      expect(harness.savedName, isNull);
      expect(harness.popped, isFalse);
    });

    // onSave writes the answer away, so a throw from it lands in save()'s
    // catch. The sheet must not close on top of an answer that was never
    // written.
    test(
        'a throw from onSave is caught, reported, and does not close the sheet',
        () async {
      harness.onSaveThrows = true;

      await harness.save(const RecordingSaveResult(
        RecordingSaveOutcome.saved,
        '/Documents/audios/clip.m4a',
      ));

      expect(harness.failuresTracked, 1);
      expect(harness.popped, isFalse);
    });

    test('every outcome is handled — the switch has no silent default', () {
      for (final outcome in RecordingSaveOutcome.values) {
        expect(
          () => _SaveDispatchHarness().save(RecordingSaveResult(
            outcome,
            outcome == RecordingSaveOutcome.saved ? '/a/audios/c.m4a' : null,
          )),
          returnsNormally,
          reason: 'adding an outcome must not fall through unhandled',
        );
      }
    });
  });
}

/// Mirror of the switch in `_BottomRecordingModalState.save()`:
///
///   final result = await _recordingService.save();
///   if (!mounted) return;
///   switch (result.outcome) {
///     case RecordingSaveOutcome.saved:
///       widget.onSave?.call(basePath(result.path!));
///       if (mounted) Navigator.pop(context);
///     case RecordingSaveOutcome.emptyFile:
///       _erase.value = !_erase.value;
///     case RecordingSaveOutcome.nothingRecorded:
///       break;
///     case RecordingSaveOutcome.failed:
///       _trackFailedSave();
///   }
///   ... catch: report to Crashlytics, then _trackFailedSave()
///
/// `onSave`, `Navigator.pop`, the `_erase` notifier and the Pendo call are
/// stood in for by counters. The real `basePath` is used, not a copy.
class _SaveDispatchHarness {
  String? savedName;
  bool popped = false;
  int eraseToggles = 0;
  int failuresTracked = 0;

  /// Makes the stand-in for `widget.onSave` throw, as a write of the answer
  /// can.
  bool onSaveThrows = false;

  Future<void> save(RecordingSaveResult result) async {
    try {
      switch (result.outcome) {
        case RecordingSaveOutcome.saved:
          if (onSaveThrows) throw StateError('onSave failed');
          savedName = basePath(result.path!);
          popped = true;
          break;
        case RecordingSaveOutcome.emptyFile:
          eraseToggles++;
          break;
        case RecordingSaveOutcome.nothingRecorded:
          break;
        case RecordingSaveOutcome.failed:
          failuresTracked++;
          break;
      }
    } catch (_) {
      // Deliberately unnarrowed, as in save(): a StateError or TypeError out of
      // onSave would otherwise reach PlatformDispatcher.onError as a fatal.
      failuresTracked++;
    }
  }
}
