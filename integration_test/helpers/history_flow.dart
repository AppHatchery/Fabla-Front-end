import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/diary_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> historyFlow(WidgetTester tester) async {
  await tester.pump();

  await tester.tap(find.text("History"));
  await tester.pump(Duration(seconds: 2));

  expect(find.byType(DiaryList), findsOneWidget);
  expect(find.text("History"), findsNWidgets(2));

  await tester.tap(find.text("Weekly Diary").first);
  await tester.pump(Duration(seconds: 2));
  await tester.tap(find.text("Explore the outdoors"));
  await tester.pump(Duration(seconds: 2));
  await tester.tap(find.text("Continue"));
  await tester.pump(Duration(seconds: 2));
  await Future.delayed(Duration(seconds: 5));

  await tester.drag(find.byType(Slider), Offset(100, 0));
  await tester.pump(Duration(seconds: 2));
  await tester.tap(find.text("Continue"));
  await tester.pump(Duration(seconds: 2));

  await tester.tap(find.text("Submit My Response"));
  for (int i = 0; i < 20; i++) {
    await tester.pump(Duration(seconds: 2));
  }

  await tester.tap(find.text("Return Home"));
  await tester.pump(Duration(seconds: 4));
}
