import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/home_calendar.dart';
import 'package:audio_diaries_flutter/theme/components/calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../firebase_mock.dart';

class _EmptyDiaryRepository extends Mock implements DiaryRepository {}

/// Pumps the Study Calendar page with no diaries at [textScale] on a
/// [screen]-wide phone and returns any layout errors.
Future<List<FlutterErrorDetails>> pumpStudyCalendar(
  WidgetTester tester, {
  required Size screen,
  required double textScale,
}) async {
  tester.view.physicalSize = Size(screen.width, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final repository = _EmptyDiaryRepository();
  when(() => repository.getAllDiariesWithMultipleEntries()).thenReturn([]);

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
                body: StudyCalendar(
                  studies: const [],
                  refresh: (_) {},
                  getPageName: () => 'calendar',
                  repository: repository,
                  showRiveAnimation: false,
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

/// True if every line [text] wraps onto starts at a word boundary.
bool _breaksOnlyBetweenWords(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text).first);
  double? previousTop;
  for (var offset = 0; offset < text.length; offset++) {
    final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: offset, extentOffset: offset + 1));
    if (boxes.isEmpty) continue; // trailing space at a line end
    final top = boxes.first.top;
    // A character on a lower line than the one before starts a new line;
    // that is only fine right after a space.
    if (previousTop != null &&
        top > previousTop + 1 &&
        text[offset - 1] != ' ') {
      return false;
    }
    previousTop = top;
  }
  return true;
}

void main() {
  setupFirebaseMocks();

  const screens = {
    'iPhone SE (320x568)': Size(320, 568),
    'iPhone 13 mini (375x812)': Size(375, 812),
  };
  const scales = [1.0, 2.0, 3.1];

  for (final screen in screens.entries) {
    for (final scale in scales) {
      testWidgets('StudyCalendar lays out on ${screen.key} at ${scale}x text',
          (tester) async {
        final errors = await pumpStudyCalendar(
          tester,
          screen: screen.value,
          textScale: scale,
        );
        expect(errors.map((e) => e.exceptionAsString()), isEmpty);

        // Headings shrink rather than break mid-word ("Calend / ar").
        final month = find.textContaining(RegExp(r'^[A-Z][a-z]+ \d{4}$'));
        for (final heading in [
          'Study Calendar',
          (tester.widget<Text>(month).data)!,
        ]) {
          expect(_breaksOnlyBetweenWords(tester, heading), isTrue,
              reason: '"$heading" breaks mid-word');
        }

        // Every day number is drawn by CalendarDayCircle, which fits it in
        // its cell.
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
