import 'package:audio_diaries_flutter/screens/diary/presentation/pages/diarycompletion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps the completion page at [textScale] and returns any framework
/// errors. A layout error here is what shows as a blank white screen in the
/// app.
Future<List<FlutterErrorDetails>> pumpCompletion(
  WidgetTester tester, {
  required double textScale,
  bool submissionFailed = false,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final errors = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = errors.add;
  try {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: DiaryCompletionPage(
                submissionFailed: submissionFailed,
                // Loading the ghost .riv aborts flutter_tester.
                showRiveAnimation: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    // Run past the confetti's 2s start delay so no timer is left pending.
    await tester.pump(const Duration(seconds: 3));
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

void main() {
  for (final scale in [1.0, 3.1]) {
    testWidgets('completion page lays out at ${scale}x text', (tester) async {
      final errors = await pumpCompletion(tester, textScale: scale);
      expect(errors.map((e) => e.exceptionAsString()), isEmpty);
      expect(find.text('Thanks for your response!'), findsOneWidget);
      expect(find.text('Return Home'), findsOneWidget);
    });
  }

  testWidgets('completion page with failed submission card at 3.1x text',
      (tester) async {
    final errors =
        await pumpCompletion(tester, textScale: 3.1, submissionFailed: true);
    expect(errors.map((e) => e.exceptionAsString()), isEmpty);
    expect(find.text('Return Home'), findsOneWidget);
  });
}
