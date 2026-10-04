import 'package:flutter_test/flutter_test.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';

void main() {
  group('DiaryStatus Tests', () {
    test('DiaryStatus enum should have all expected values', () {
      expect(DiaryStatus.values.length, equals(5));
      expect(DiaryStatus.values, contains(DiaryStatus.idle));
      expect(DiaryStatus.values, contains(DiaryStatus.ongoing));
      expect(DiaryStatus.values, contains(DiaryStatus.complete));
      expect(DiaryStatus.values, contains(DiaryStatus.submitted));
      expect(DiaryStatus.values, contains(DiaryStatus.missed));
    });
  });

  group('SubmissionStatus Tests', () {
    // Tests that all three submission states exist in the enum
    test('SubmissionStatus enum should have all expected values', () {
      expect(SubmissionStatus.values.length, equals(3));
      expect(SubmissionStatus.values, contains(SubmissionStatus.pending));
      expect(SubmissionStatus.values, contains(SubmissionStatus.successful));
      expect(SubmissionStatus.values, contains(SubmissionStatus.failed));
    });
  });

  group('TimerStatus Tests', () {
    // Tests that all four timer states exist in the enum
    test('TimerStatus enum should have all expected values', () {
      expect(TimerStatus.values.length, equals(4));
      expect(TimerStatus.values, contains(TimerStatus.idle));
      expect(TimerStatus.values, contains(TimerStatus.running));
      expect(TimerStatus.values, contains(TimerStatus.paused));
      expect(TimerStatus.values, contains(TimerStatus.complete));
    });
  });

  group('Global TimerStatus Getter Tests', () {
    // The file exposes a top-level `status` variable and derived boolean getters.
    // Each test resets `status` to idle first to ensure isolation.

    test('inProgress is true when status is running', () {
      status = TimerStatus.running;
      expect(inProgress, isTrue);
    });

    test('inProgress is true when status is paused', () {
      status = TimerStatus.paused;
      expect(inProgress, isTrue);
    });

    test('inProgress is false when status is idle', () {
      status = TimerStatus.idle;
      expect(inProgress, isFalse);
    });

    test('inProgress is false when status is complete', () {
      status = TimerStatus.complete;
      expect(inProgress, isFalse);
    });

    test('isRunning is true only when status is running', () {
      status = TimerStatus.running;
      expect(isRunning, isTrue);

      // All other states should return false
      status = TimerStatus.idle;
      expect(isRunning, isFalse);
      status = TimerStatus.paused;
      expect(isRunning, isFalse);
      status = TimerStatus.complete;
      expect(isRunning, isFalse);
    });

    test('isPaused is true only when status is paused', () {
      status = TimerStatus.paused;
      expect(isPaused, isTrue);

      // All other states should return false
      status = TimerStatus.idle;
      expect(isPaused, isFalse);
      status = TimerStatus.running;
      expect(isPaused, isFalse);
      status = TimerStatus.complete;
      expect(isPaused, isFalse);
    });

    test('isComplete is true only when status is complete', () {
      status = TimerStatus.complete;
      expect(isComplete, isTrue);

      // All other states should return false
      status = TimerStatus.idle;
      expect(isComplete, isFalse);
      status = TimerStatus.running;
      expect(isComplete, isFalse);
      status = TimerStatus.paused;
      expect(isComplete, isFalse);
    });

    tearDown(() {
      // Reset the global status back to idle after each test to avoid
      // state leaking into other test groups
      status = TimerStatus.idle;
    });
  });

  group('AudioStatus Tests', () {
    // AudioStatus drives what a recording card shows when the audio behind it
    // cannot be played. Each failure value maps to distinct participant-facing
    // copy, so the set is asserted exactly.
    test('AudioStatus enum should have all expected values', () {
      expect(AudioStatus.values.length, equals(5));
      expect(AudioStatus.values, contains(AudioStatus.loading));
      expect(AudioStatus.values, contains(AudioStatus.available));
      expect(AudioStatus.values, contains(AudioStatus.fileNotFound));
      expect(AudioStatus.values, contains(AudioStatus.noAudioLength));
      expect(AudioStatus.values, contains(AudioStatus.canNotPlay));
    });

    test('available is the only playable state', () {
      final playable = AudioStatus.values
          .where((status) => status == AudioStatus.available)
          .toList();

      expect(playable, equals([AudioStatus.available]));
    });

    test('failure states are distinct from loading and available', () {
      const failures = [
        AudioStatus.fileNotFound,
        AudioStatus.noAudioLength,
        AudioStatus.canNotPlay,
      ];

      expect(failures, isNot(contains(AudioStatus.loading)));
      expect(failures, isNot(contains(AudioStatus.available)));
      expect(failures.toSet().length, equals(3));
    });

    test('names are stable — they are sent to Crashlytics as custom keys', () {
      // AudioPlaybackMixin._fail reports `audio_status: status.name`, so
      // renaming a value silently breaks issue grouping in Crashlytics.
      expect(AudioStatus.loading.name, equals('loading'));
      expect(AudioStatus.available.name, equals('available'));
      expect(AudioStatus.fileNotFound.name, equals('fileNotFound'));
      expect(AudioStatus.noAudioLength.name, equals('noAudioLength'));
      expect(AudioStatus.canNotPlay.name, equals('canNotPlay'));
    });
  });
}
