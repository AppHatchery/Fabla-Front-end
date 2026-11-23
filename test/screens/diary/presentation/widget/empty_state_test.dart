import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/empty_state.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/empty_state.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const body =
    'Your past responses will be available here as you progress through the study.';

/// Pumps the empty state where the diary list would be, on a small phone.
Future<void> pumpEmptyState(WidgetTester tester, double textScale,
    {Widget body = const BeforeStartWidget(),
    Size screen = const Size(320, 568)}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(body: body),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('content is vertically centred when it fits', (tester) async {
    await pumpEmptyState(tester, 1.0);
    expect(tester.takeException(), isNull);

    final top = tester.getTopLeft(find.byType(Image)).dy;
    final bottom = tester.getBottomLeft(find.text(body)).dy;
    final screenHeight = tester.getSize(find.byType(Scaffold)).height;
    // Equal space above and below the content.
    expect(top, moreOrLessEquals(screenHeight - bottom, epsilon: 1));
  });

  testWidgets('content scrolls when it is taller than the space',
      (tester) async {
    // A short space (landscape, split view) at the largest font size.
    await pumpEmptyState(tester, 3.1, screen: const Size(320, 300));
    expect(tester.takeException(), isNull);

    final scrollable = find.byType(Scrollable);
    expect(tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
        greaterThan(0));

    // Scroll to the end: the last line of the body text must be reachable.
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    final screenHeight = tester.getSize(find.byType(Scaffold)).height;
    expect(tester.getBottomLeft(find.text(body)).dy,
        lessThanOrEqualTo(screenHeight));
  });

  // The home empty states sit inside pages that already scroll, so they get
  // unbounded height. They must lay out there without a nested scroll view.
  const homeStates = {
    'FreeDayWidget': FreeDayWidget(),
    'EndStateWidget': EndStateWidget(),
    'DayComplete': DayComplete(),
  };
  for (final entry in homeStates.entries) {
    for (final scale in [1.0, 3.1]) {
      testWidgets('${entry.key} inside a scrolling page at ${scale}x',
          (tester) async {
        await pumpEmptyState(
          tester,
          scale,
          body: SingleChildScrollView(
            child: Column(children: [Center(child: entry.value)]),
          ),
        );
        expect(tester.takeException(), isNull);
        // Only the page scrolls; the empty state adds no scroll view.
        expect(find.byType(Scrollable), findsOneWidget);
      });
    }

    testWidgets('${entry.key} given a bounded height scrolls at 3.1x',
        (tester) async {
      await pumpEmptyState(tester, 3.1, body: entry.value);
      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsOneWidget);
    });
  }

  // Same cap as getAdaptiveTextScaler for the platform the test runs on.
  final cap = Platform.isIOS ? 2.0 : 1.5;
  const texts = {
    'BeforeStartWidget': (BeforeStartWidget(), 'No Responses Recorded Yet'),
    'FreeDayWidget': (FreeDayWidget(), 'No Surveys Scheduled Today'),
    'EndStateWidget': (EndStateWidget(), 'Research Journey End'),
    'DayComplete': (DayComplete(), "That's it for today"),
  };
  for (final entry in texts.entries) {
    testWidgets('${entry.key} caps title and message at the adaptive scale',
        (tester) async {
      final (widget, title) = entry.value;
      await pumpEmptyState(tester, 3.1, body: widget);
      final paragraphs = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .toList();
      expect(paragraphs, hasLength(2));
      expect(paragraphs.first.text.toPlainText(), title);
      for (final paragraph in paragraphs) {
        expect(paragraph.textScaler.scale(1), cap);
      }
    });
  }
}
