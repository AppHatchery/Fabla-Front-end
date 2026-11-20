import 'package:audio_diaries_flutter/theme/components/calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps the date picker as the settings and onboarding screens show it
/// (inside a scroll view with 16pt side padding) at [textScale] on a
/// [screen]-sized phone, and returns any layout errors.
Future<List<FlutterErrorDetails>> pumpDatePicker(
  WidgetTester tester, {
  required Size screen,
  required double textScale,
}) async {
  tester.view.physicalSize = screen;
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
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomDatePicker(
                    // A month that needs six rows, with a long name.
                    date: DateTime(2026, 11, 18),
                    onSelect: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

void main() {
  const screens = {
    'iPhone SE (320x568)': Size(320, 568),
    'iPhone 13 mini (375x812)': Size(375, 812),
  };
  const scales = [1.0, 2.0, 3.1];

  for (final screen in screens.entries) {
    for (final scale in scales) {
      testWidgets(
          'CustomDatePicker lays out without overflow on ${screen.key} '
          'at ${scale}x text', (tester) async {
        final errors = await pumpDatePicker(
          tester,
          screen: screen.value,
          textScale: scale,
        );
        expect(errors.map((e) => e.exceptionAsString()), isEmpty);

        // Large text never throws in the calendar; it gets clipped instead.
        // Every day number, including October's 26th to 31st shown before
        // November 1st, must be drawn by CalendarDayCircle, which fits the
        // number inside its cell.
        for (final label in ['26', '31', '18', '30']) {
          for (final element in find.text(label).evaluate()) {
            expect(
              find.ancestor(
                of: find.byWidget(element.widget),
                matching: find.byType(CalendarDayCircle),
              ),
              findsOneWidget,
              reason: 'day "$label" is drawn outside CalendarDayCircle',
            );
          }
        }
      });
    }
  }
}
