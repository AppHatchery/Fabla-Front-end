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

  group('RecorderState Tests', () {
    test('RecorderState enum should have all expected values', () {
      expect(RecorderState.values.length, equals(3));
      expect(RecorderState.values, contains(RecorderState.isStopped));
      expect(RecorderState.values, contains(RecorderState.isPaused));
      expect(RecorderState.values, contains(RecorderState.isRecording));
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
}
