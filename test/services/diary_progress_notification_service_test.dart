import 'package:audio_diaries_flutter/services/diary_progress_notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel =
      MethodChannel('edu.emory.audio_diaries_flutter/diary_progress');

  late List<MethodCall> calls;

  void setHandler(Future<Object?>? Function(MethodCall)? handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  setUp(() {
    calls = [];
    setHandler((call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() => setHandler(null));

  test('show sends the question position', () async {
    await DiaryProgressNotificationService(isAndroid: true)
        .show(questionNumber: 3, questionCount: 8);

    expect(calls.single.method, 'show');
    expect(calls.single.arguments,
        <String, dynamic>{'questionNumber': 3, 'questionCount': 8});
  });

  test('hide sends hide with no arguments', () async {
    await DiaryProgressNotificationService(isAndroid: true).hide();

    expect(calls.single.method, 'hide');
    expect(calls.single.arguments, isNull);
  });

  test('swallows a platform failure', () async {
    setHandler((call) async => throw PlatformException(code: 'DISABLED'));

    await expectLater(
      DiaryProgressNotificationService(isAndroid: true)
          .show(questionNumber: 1, questionCount: 2),
      completes,
    );
  });

  test('never touches the channel off Android', () async {
    final service = DiaryProgressNotificationService(isAndroid: false);
    await service.show(questionNumber: 1, questionCount: 2);
    await service.hide();

    expect(calls, isEmpty);
  });
}
