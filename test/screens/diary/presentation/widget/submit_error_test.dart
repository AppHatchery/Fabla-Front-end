import 'package:audio_diaries_flutter/core/diagnostics/debug_trace.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/submit_error.dart';
import 'package:audio_diaries_flutter/services/developer_mode_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final panel = find.byKey(const Key('submission_debug_panel'));

  DebugTrace failedTrace() =>
      DebugTrace('diary_submission', context: {'DiaryID': '7'})
        ..step('upload_responses')
        ..fail('Response upload rejected by server',
            statusCode: 500, responseBody: 'Internal error');

  Widget buildPage(DebugTrace? trace) => ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(home: SubmitErrorPage(trace: trace)),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DeveloperModeService().load();
  });

  // Phone-sized surface, so the expanded panel lays out as it does on device.
  void usePhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('hides the debug panel when developer mode is off',
      (tester) async {
    await tester.pumpWidget(buildPage(failedTrace()));

    expect(find.text('Oops! Something went wrong.'), findsOneWidget);
    expect(panel, findsNothing);
  });

  testWidgets('hides the debug panel when there is no trace', (tester) async {
    await DeveloperModeService().enable();
    await tester.pumpWidget(buildPage(null));

    expect(panel, findsNothing);
  });

  testWidgets('shows what failed, where, and why in developer mode',
      (tester) async {
    usePhoneSize(tester);
    await DeveloperModeService().enable();
    await tester.pumpWidget(buildPage(failedTrace()));

    expect(panel, findsOneWidget);
    expect(find.text('Failed at: upload_responses'), findsOneWidget);

    await tester.tap(find.text('Debug details'));
    await tester.pumpAndSettle();

    expect(
        find.textContaining('Response upload rejected by server',
            findRichText: true),
        findsWidgets);
    expect(find.textContaining('Internal error', findRichText: true),
        findsWidgets);
  });

  testWidgets('copies the full report to the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    usePhoneSize(tester);
    await DeveloperModeService().enable();
    final trace = failedTrace();
    await tester.pumpWidget(buildPage(trace));
    await tester.tap(find.text('Debug details'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('copy_debug_details')));
    await tester.tap(find.byKey(const Key('copy_debug_details')));
    await tester.pump();

    expect(copied, trace.toReport());
    expect(find.text('Debug details copied to clipboard'), findsOneWidget);
  });
}
