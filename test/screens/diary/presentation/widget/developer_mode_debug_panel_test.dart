import 'package:audio_diaries_flutter/core/diagnostics/debug_trace.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/submission_debug_panel.dart';
import 'package:audio_diaries_flutter/services/developer_mode_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final panel = find.byKey(const Key('submission_debug_panel'));

  DebugTrace noInternetTrace() => DebugTrace('diary_submission')
    ..step('connectivity')
    ..fail('No internet connection');

  Widget build(DebugTrace? trace) => ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(body: DeveloperModeDebugPanel(trace: trace)),
        ),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DeveloperModeService().load();
  });

  testWidgets('shows the trace in developer mode', (tester) async {
    await DeveloperModeService().enable();
    await tester.pumpWidget(build(noInternetTrace()));

    expect(panel, findsOneWidget);
    expect(find.text('Failed at: connectivity'), findsOneWidget);
  });

  testWidgets('shows nothing when developer mode is off', (tester) async {
    await tester.pumpWidget(build(noInternetTrace()));

    expect(panel, findsNothing);
  });

  testWidgets('shows nothing without a trace', (tester) async {
    await DeveloperModeService().enable();
    await tester.pumpWidget(build(null));

    expect(panel, findsNothing);
  });

  testWidgets('appears when developer mode is turned on', (tester) async {
    await tester.pumpWidget(build(noInternetTrace()));
    expect(panel, findsNothing);

    await DeveloperModeService().enable();
    await tester.pump();

    expect(panel, findsOneWidget);
  });
}
