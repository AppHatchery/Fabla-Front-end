import 'package:audio_diaries_flutter/services/recording_live_update_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel =
      MethodChannel('edu.emory.audio_diaries_flutter/recording_live_update');

  late List<MethodCall> calls;

  void setHandler(Future<Object?>? Function(MethodCall)? handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  Future<void> sendFromPlatform(String method) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
            channel.name,
            const StandardMethodCodec().encodeMethodCall(MethodCall(method)),
            (_) {});
  }

  setUp(() {
    calls = <MethodCall>[];
    setHandler((call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() => setHandler(null));

  test('show sends the whole recording state', () async {
    await RecordingLiveUpdateService(isAndroid: true).show(
      elapsed: const Duration(seconds: 48, milliseconds: 900),
      phase: RecordingLiveUpdatePhase.recording,
      limit: const Duration(minutes: 5),
      questionNumber: 3,
      questionCount: 8,
    );

    expect(calls.single.method, 'show');
    expect(calls.single.arguments, <String, dynamic>{
      'title': 'Recording',
      'elapsedSeconds': 48,
      'limitSeconds': 300,
      'phase': 'recording',
      'questionNumber': 3,
      'questionCount': 8,
    });
  });

  test('no limit is sent as zero', () async {
    await RecordingLiveUpdateService(isAndroid: true)
        .show(elapsed: Duration.zero, phase: RecordingLiveUpdatePhase.paused);

    expect(calls.single.arguments['limitSeconds'], 0);
    expect(calls.single.arguments['phase'], 'paused');
  });

  test('every phase is sent by name', () async {
    final service = RecordingLiveUpdateService(isAndroid: true);
    for (final phase in RecordingLiveUpdatePhase.values) {
      await service.show(elapsed: Duration.zero, phase: phase);
    }

    expect(calls.map((c) => c.arguments['phase']), [
      'recording',
      'paused',
      'pausedByCall',
      'readyToSave',
      'couldNotResume',
      'saved',
      'recordingStopped',
    ]);
  });

  test('hide sends hide with no arguments', () async {
    await RecordingLiveUpdateService(isAndroid: true).hide();

    expect(calls.single.method, 'hide');
    expect(calls.single.arguments, isNull);
  });

  test('notification actions reach their callbacks while showing', () async {
    final actions = <String>[];
    final service = RecordingLiveUpdateService(
      isAndroid: true,
      onPause: () => actions.add('pause'),
      onResume: () => actions.add('resume'),
      onSave: () => actions.add('save'),
      onRecordAgain: () => actions.add('recordAgain'),
    );

    await service.show(
        elapsed: Duration.zero, phase: RecordingLiveUpdatePhase.recording);
    await sendFromPlatform('pause');
    await sendFromPlatform('resume');
    await sendFromPlatform('save');
    await sendFromPlatform('recordAgain');
    await service.hide();
    await sendFromPlatform('pause');

    expect(actions, ['pause', 'resume', 'save', 'recordAgain']);
  });

  test('swallows a platform failure', () async {
    setHandler((call) async => throw PlatformException(code: 'DISABLED'));

    await expectLater(
      RecordingLiveUpdateService(isAndroid: true).show(
          elapsed: Duration.zero, phase: RecordingLiveUpdatePhase.recording),
      completes,
    );
  });

  test('never touches the channel off Android', () async {
    final service = RecordingLiveUpdateService(isAndroid: false);
    await service.show(
        elapsed: Duration.zero, phase: RecordingLiveUpdatePhase.recording);
    await service.hide();

    expect(calls, isEmpty);
  });
}
