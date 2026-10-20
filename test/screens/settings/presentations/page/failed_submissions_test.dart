import 'dart:convert';

import 'package:audio_diaries_flutter/core/diagnostics/debug_trace.dart';
import 'package:audio_diaries_flutter/core/diagnostics/trace_log.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/pages/failed_submissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget buildPage() => ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => const MaterialApp(home: FailedSubmissionsPage()),
      );

  DebugTrace failed(String reason, String diary) =>
      DebugTrace('diary_submission', context: {'Diary': diary})
        ..step('connectivity')
        ..fail(reason);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Seeds the stored log directly, as [TraceLog.add] would, newest first.
  void store(List<DebugTrace> newestFirst) {
    SharedPreferences.setMockInitialValues({
      TraceLog.preferenceKey: [
        for (final trace in newestFirst)
          jsonEncode(TraceRecord.fromTrace(trace).toJson()),
      ],
    });
  }

  // Phone-sized surface, so expanded cards lay out as they do on device.
  void usePhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('shows an empty state with no failures', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.text('No failed submissions recorded on this device.'),
        findsOneWidget);
  });

  testWidgets('lists failures newest first with their step and reason',
      (tester) async {
    usePhoneSize(tester);
    store([
      failed('Second failure', 'Evening'),
      failed('First failure', 'Morning'),
    ]);

    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    final subtitles = tester
        .widgetList<Text>(find.textContaining('Failed at: connectivity'))
        .map((t) => t.data!)
        .toList();
    expect(subtitles, hasLength(2));
    expect(subtitles.first, contains('Evening'));
    expect(subtitles.first, contains('Second failure'));
    expect(subtitles.last, contains('Morning'));
  });

  testWidgets('expands to the full report and copies it', (tester) async {
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
    final trace = failed('No internet connection', 'Morning');
    store([trace]);

    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Failed at: connectivity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy'));
    await tester.pump();

    expect(copied, trace.toReport());
    expect(find.text('Debug details copied to clipboard'), findsOneWidget);
  });

  testWidgets('clear removes the failures after confirming', (tester) async {
    usePhoneSize(tester);
    store([failed('Rejected', 'Morning')]);

    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clear_failed_submissions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_clear_failed_submissions')));
    await tester.pumpAndSettle();

    expect(find.text('No failed submissions recorded on this device.'),
        findsOneWidget);
  });
}
