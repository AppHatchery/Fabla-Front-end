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
}
