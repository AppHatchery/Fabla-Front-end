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
    test('start should increment time approximately every second', () async {
      pageTimer.start();
      // Wait a bit longer to account for CI timing variations
      await Future.delayed(const Duration(milliseconds: 2100));
      final time = pageTimer.stop();
      // Allow for timing variations in CI environments
      // Timer should be at least 1 second but might be 2 or slightly more
      expect(time, greaterThanOrEqualTo(1));
      expect(time, lessThanOrEqualTo(3)); // Allow some tolerance for slow CI
    });

    test('start should increment time over longer period', () async {
      pageTimer.start();
      // Test with a longer period for more predictable results
      await Future.delayed(const Duration(milliseconds: 3200));
      final time = pageTimer.stop();
      // Should be at least 2 seconds, might be 3 or 4 in slow CI
      expect(time, greaterThanOrEqualTo(2));
      expect(time, lessThanOrEqualTo(5));
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

    test('timer increments after short delay', () async {
      pageTimer.start();
      // Wait just over 1 second
      await Future.delayed(const Duration(milliseconds: 1100));
      final time = pageTimer.stop();
      // Should be at least 1, but allow for variations
      expect(time, greaterThanOrEqualTo(1));
      expect(time, lessThanOrEqualTo(2));
    });
  });
}
