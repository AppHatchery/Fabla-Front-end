import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/services/audio_recording_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Covers the contracts `AudioRecordingService` publishes to the UI. The
// service itself drives the microphone, the audio session and an Android
// foreground service, none of which exist in the test VM, so what is asserted
// here is the part a widget actually reads: the state it renders from and the
// save outcome it branches on.
void main() {
  group('AudioRecordingState', () {
    test('starts stopped, at zero, and uninterrupted', () {
      const state = AudioRecordingState();

      expect(state.status, AudioRecordingStatus.stopped);
      expect(state.elapsed, Duration.zero);
      expect(state.isInterrupted, isFalse);
      expect(state.isRecording, isFalse);
      expect(state.isPaused, isFalse);
    });

    // The save and redo controls hang off this, so a take that captured
    // nothing must not look finished.
    test('only reports a completed take once a stop has captured a second',
        () {
      const nothingRecorded = AudioRecordingState();
      const recording = AudioRecordingState(
        status: AudioRecordingStatus.recording,
        elapsed: Duration(seconds: 12),
      );
      const paused = AudioRecordingState(
        status: AudioRecordingStatus.paused,
        elapsed: Duration(seconds: 12),
      );
      const stopped = AudioRecordingState(
        elapsed: Duration(seconds: 12),
      );
      const stoppedSubSecond = AudioRecordingState(
        elapsed: Duration(milliseconds: 900),
      );

      expect(nothingRecorded.hasCompletedTake, isFalse);
      expect(recording.hasCompletedTake, isFalse);
      expect(paused.hasCompletedTake, isFalse);
      expect(stopped.hasCompletedTake, isTrue);
      expect(stoppedSubSecond.hasCompletedTake, isFalse);
    });

    test('copyWith replaces only what it is given', () {
      const state = AudioRecordingState(
        status: AudioRecordingStatus.recording,
        elapsed: Duration(seconds: 3),
        isInterrupted: true,
      );

      final paused = state.copyWith(status: AudioRecordingStatus.paused);

      expect(paused.status, AudioRecordingStatus.paused);
      expect(paused.elapsed, const Duration(seconds: 3));
      expect(paused.isInterrupted, isTrue);
    });

    test('copyWith can clear the interruption flag', () {
      const interrupted = AudioRecordingState(
        status: AudioRecordingStatus.paused,
        isInterrupted: true,
      );

      expect(interrupted.copyWith(isInterrupted: false).isInterrupted, isFalse);
    });

    // Value equality is what lets the ValueNotifier behind
    // AudioRecordingService.state drop a publish that changes nothing, so a
    // handler re-asserting the current state does not rebuild the modal.
    test('equal states compare equal so a no-op publish can be dropped', () {
      const first = AudioRecordingState(
        status: AudioRecordingStatus.recording,
        elapsed: Duration(seconds: 5),
      );
      const second = AudioRecordingState(
        status: AudioRecordingStatus.recording,
        elapsed: Duration(seconds: 5),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('a difference in any field compares unequal', () {
      const base = AudioRecordingState(
        status: AudioRecordingStatus.recording,
        elapsed: Duration(seconds: 5),
      );

      expect(base, isNot(base.copyWith(status: AudioRecordingStatus.paused)));
      expect(base, isNot(base.copyWith(elapsed: const Duration(seconds: 6))));
      expect(base, isNot(base.copyWith(isInterrupted: true)));
    });
  });

  group('RecordingSaveResult', () {
    // The caller does `basePath(result.path!)`, so the path has to be there on
    // a save and absent on everything else.
    test('carries a path only when the take was saved', () {
      const saved = RecordingSaveResult(
        RecordingSaveOutcome.saved,
        '/documents/audios/audio_prompt_1_2026-09-02.aac',
      );

      expect(saved.outcome, RecordingSaveOutcome.saved);
      expect(saved.path, isNotNull);

      for (final outcome in [
        RecordingSaveOutcome.nothingRecorded,
        RecordingSaveOutcome.emptyFile,
        RecordingSaveOutcome.failed,
      ]) {
        expect(RecordingSaveResult(outcome).path, isNull);
      }
    });
  });
}
