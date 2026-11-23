import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/custom_calender.dart';
import 'package:audio_diaries_flutter/theme/components/calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _EmptyDiaryRepository extends Mock implements DiaryRepository {}

/// Pumps the calendar as the active-dates screen shows it (16pt side
/// padding, inside a scroll view) at [textScale] on a [screen]-sized phone,
/// with no diaries, and returns any layout errors.
Future<List<FlutterErrorDetails>> pumpCalendar(
  WidgetTester tester, {
  required Size screen,
  required double textScale,
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final repository = _EmptyDiaryRepository();
  when(() => repository.getAllDiaries()).thenReturn([]);
  when(() => repository.getAllStudies()).thenReturn([]);
  when(() => repository.getDailyDiaries(any())).thenReturn([]);

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
                  child: CustomCalender(repository: repository),
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
  setUpAll(() => registerFallbackValue(DateTime(2026)));

  const screens = {
    'iPhone SE (320x568)': Size(320, 568),
    'iPhone 13 mini (375x812)': Size(375, 812),
  };
  const scales = [1.0, 2.0, 3.1];

  for (final screen in screens.entries) {
    for (final scale in scales) {
      testWidgets(
          'CustomCalender lays out without overflow on ${screen.key} '
          'at ${scale}x text', (tester) async {
        final errors = await pumpCalendar(
          tester,
          screen: screen.value,
          textScale: scale,
        );
        expect(errors.map((e) => e.exceptionAsString()), isEmpty);

        // The calendar fits the screen: no part of it (Sunday, the
        // next-month arrow) sits past the 16pt right padding.
        expect(
          tester.getRect(find.byType(CustomCalender)).right,
          lessThanOrEqualTo(screen.value.width - 16 + 0.5),
        );

        // Every day number is drawn by CalendarDayCircle, which fits the
        // number inside its cell instead of letting large text clip.
        for (final label in ['1', '15', '28']) {
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
