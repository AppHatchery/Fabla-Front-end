import 'package:flutter_test/flutter_test.dart';
import 'package:audio_diaries_flutter/core/usecases/page_timer.dart';

void main() {
  late PageTimer pageTimer;

  setUp(() {
    pageTimer = PageTimer();
  });

  tearDown(() {
    pageTimer.dispose();
  });

  group('PageTimer', () {
    test('start should increment time every second', () async {
      pageTimer.start();
      await Future.delayed(const Duration(seconds: 2));
      final time = pageTimer.stop();
      expect(time, 2);
    });

    test('stop should return current time and cancel timer', () {
      pageTimer.start();
      final time = pageTimer.stop();
      expect(time, 0);
      // Timer should be cancelled
      expect(pageTimer.timer, null);
    });

    test('reset should return current time and restart timer', () {
      pageTimer.start();
      final time = pageTimer.reset();
      expect(time, 0);
      // Timer should be restarted
      expect(pageTimer.timer, isNotNull);
    });

    test('dispose should clean up resources', () {
      pageTimer.start();
      pageTimer.dispose();
      expect(pageTimer.timer, null);
      expect(pageTimer.time, 0);
    });

    test('multiple start calls should not create multiple timers', () {
      pageTimer.start();
      pageTimer.start();
      pageTimer.start();
      expect(pageTimer.timer, isNotNull);
      final time = pageTimer.stop();
      expect(time, 0);
    });
  });
}
