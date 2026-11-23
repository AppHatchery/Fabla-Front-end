import 'package:audio_diaries_flutter/theme/components/time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [picker] the way the app shows it (a scroll-controlled bottom sheet
/// body) at [textScale] on a [screen]-sized phone, and returns any layout
/// errors (RenderFlex overflows and the like).
Future<List<FlutterErrorDetails>> pumpPicker(
  WidgetTester tester, {
  required Widget picker,
  required Size screen,
  required double textScale,
  bool wrapInScrollView = true,
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
                body: wrapInScrollView
                    ? SingleChildScrollView(child: picker)
                    : picker,
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

  final pickers = <String, (Widget, bool)>{
    'CustomTimePicker': (
      const CustomTimePicker(
        subtitle: 'Pick when you want to be reminded',
        date: TimeOfDay(hour: 12, minute: 30),
      ),
      true,
    ),
    'CustomTimeElapsedPicker': (
      const CustomTimeElapsedPicker(
        title: 'How long were you active?',
        duration: Duration(hours: 1, minutes: 30),
      ),
      true,
    ),
    'CustomMinuteSecondPicker': (
      const CustomMinuteSecondPicker(duration: Duration(minutes: 2)),
      false,
    ),
  };

  for (final picker in pickers.entries) {
    for (final screen in screens.entries) {
      for (final scale in scales) {
        testWidgets(
            '${picker.key} lays out without overflow on ${screen.key} '
            'at ${scale}x text', (tester) async {
          final errors = await pumpPicker(
            tester,
            picker: picker.value.$1,
            screen: screen.value,
            textScale: scale,
            wrapInScrollView: picker.value.$2,
          );
          expect(errors.map((e) => e.exceptionAsString()), isEmpty);
        });
      }
    }
  }

  testWidgets('CustomTimePicker opens on the saved 12:30', (tester) async {
    await pumpPicker(
      tester,
      picker: const CustomTimePicker(date: TimeOfDay(hour: 12, minute: 30)),
      screen: const Size(375, 812),
      textScale: 1.0,
    );
    final wheels = tester
        .widgetList<ListWheelScrollView>(find.byType(ListWheelScrollView))
        .toList();
    final hours = wheels[0].controller! as FixedExtentScrollController;
    final minutes = wheels[1].controller! as FixedExtentScrollController;
    final period = wheels[2].controller! as FixedExtentScrollController;
    expect(hours.selectedItem, 11); // "12"
    expect(minutes.selectedItem, 6); // "30" with 5-minute steps
    expect(period.selectedItem, 1); // "PM"
  });
}
