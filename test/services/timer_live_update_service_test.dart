import 'package:audio_diaries_flutter/services/timer_live_update_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel =
      MethodChannel('edu.emory.audio_diaries_flutter/timer_live_update');

  late List<MethodCall> calls;
  late TimerLiveUpdateService service;

  void setHandler(Future<Object?>? Function(MethodCall)? handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  setUp(() {
    calls = <MethodCall>[];
    service = TimerLiveUpdateService(isAndroid: true);

    setHandler((call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() => setHandler(null));

  group('TimerLiveUpdateService.show', () {
    test('sends the whole timer state as one payload', () async {
      await service.show(
        total: const Duration(minutes: 1),
        remaining: const Duration(seconds: 45),
        isPaused: false,
      );

      expect(calls, hasLength(1));
      expect(calls.single.method, 'show');
      expect(calls.single.arguments, <String, dynamic>{
        'title': 'Diary Timer',
        'totalSeconds': 60,
        'remainingSeconds': 45,
        'isPaused': false,
      });
    });

    test('forwards a paused state', () async {
      await service.show(
        total: const Duration(minutes: 1),
        remaining: const Duration(seconds: 29),
        isPaused: true,
      );

      expect(calls.single.arguments['isPaused'], isTrue);
      expect(calls.single.arguments['remainingSeconds'], 29);
    });

    test('forwards a custom title', () async {
      await service.show(
        total: const Duration(seconds: 30),
        remaining: const Duration(seconds: 30),
        isPaused: false,
        title: 'Meditation',
      );

      expect(calls.single.arguments['title'], 'Meditation');
    });

    // The native side takes whole seconds, so anything finer must be truncated
    // rather than rounded up past the real deadline.
    test('truncates sub-second precision', () async {
      await service.show(
        total: const Duration(milliseconds: 60500),
        remaining: const Duration(milliseconds: 1999),
        isPaused: false,
      );

      expect(calls.single.arguments['totalSeconds'], 60);
      expect(calls.single.arguments['remainingSeconds'], 1);
    });

    test('repeated calls each reach the platform', () async {
      const total = Duration(seconds: 10);

      await service.show(
          total: total, remaining: const Duration(seconds: 9), isPaused: false);
      await service.show(
          total: total, remaining: const Duration(seconds: 8), isPaused: false);

      expect(calls.map((call) => call.method), <String>['show', 'show']);
      expect(calls.last.arguments['remainingSeconds'], 8);
    });
  });

  group('TimerLiveUpdateService.show clears instead of showing', () {
    test('when the total is zero', () async {
      await service.show(
        total: Duration.zero,
        remaining: const Duration(seconds: 10),
        isPaused: false,
      );

      expect(calls.map((call) => call.method), <String>['hide']);
    });

    test('when nothing remains', () async {
      await service.show(
        total: const Duration(minutes: 1),
        remaining: Duration.zero,
        isPaused: false,
      );

      expect(calls.map((call) => call.method), <String>['hide']);
    });

    // Reconciling against a wall-clock end time can overshoot past zero.
    test('when the remaining time has gone negative', () async {
      await service.show(
        total: const Duration(minutes: 1),
        remaining: const Duration(seconds: -5),
        isPaused: false,
      );

      expect(calls.map((call) => call.method), <String>['hide']);
    });
  });

  group('TimerLiveUpdateService.hide', () {
    test('sends hide with no arguments', () async {
      await service.hide();

      expect(calls, hasLength(1));
      expect(calls.single.method, 'hide');
      expect(calls.single.arguments, isNull);
    });

    test('is safe to call when nothing is showing', () async {
      await service.hide();
      await service.hide();

      expect(calls.map((call) => call.method), <String>['hide', 'hide']);
    });
  });

  // A notification that fails to post must never take the countdown with it.
  group('TimerLiveUpdateService failure handling', () {
    test('swallows a platform rejection on show', () async {
      setHandler((call) async {
        throw PlatformException(code: 'NOTIFICATIONS_DISABLED');
      });

      await expectLater(
        service.show(
          total: const Duration(seconds: 30),
          remaining: const Duration(seconds: 30),
          isPaused: false,
        ),
        completes,
      );
    });

    test('swallows a platform rejection on hide', () async {
      setHandler((call) async {
        throw PlatformException(code: 'NOTIFICATIONS_DISABLED');
      });

      await expectLater(service.hide(), completes);
    });

    test('swallows a missing handler when the engine has detached', () async {
      setHandler(null);

      await expectLater(
        service.show(
          total: const Duration(seconds: 30),
          remaining: const Duration(seconds: 30),
          isPaused: false,
        ),
        completes,
      );
      await expectLater(service.hide(), completes);
    });
  });

  group('TimerLiveUpdateService on non-Android platforms', () {
    setUp(() => service = TimerLiveUpdateService(isAndroid: false));

    test('never touches the channel', () async {
      await service.show(
        total: const Duration(seconds: 30),
        remaining: const Duration(seconds: 30),
        isPaused: false,
      );
      await service.hide();

      expect(calls, isEmpty);
    });
  });
}
