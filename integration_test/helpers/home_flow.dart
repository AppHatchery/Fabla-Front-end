

import 'package:audio_diaries_flutter/screens/home/presentation/widgets/today_goal.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/todays_diary_list.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/weekly_goal.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> homeFlow(WidgetTester tester) async {
  await tester.pump();

  expect(find.byType(TodayGoalWidget), findsOneWidget);
  expect(find.text("Today's Goal"), findsOneWidget);
  expect(find.byKey(Key('displayText')), findsNWidgets(3));

  expect(find.byType(WeeklyGoalWidget), findsOneWidget);
  expect(find.text('Weekly Goal'), findsOneWidget);
  expect(find.byKey(Key('weekly_goal_icon')), findsOneWidget);

  await tester.tap(find.byKey(Key('weekly_goal_widget')));
  await tester.pump(Duration(seconds: 2));

  await tester.tap(find.byKey(Key('weekly_goal_widget')));
  await tester.pump(Duration(seconds: 2));

  await tester.tap(find.byType(IconButton));
  await tester.pump(Duration(seconds: 4));
  await tester.tap(find.byType(IconButton).at(1));
  await tester.pump(Duration(seconds: 4));

  await tester.tap(find.byKey(Key('Incentive')));
  await tester.pump(Duration(seconds: 2));
  await tester.tap(find.byType(IconButton).at(1));
  await tester.pump(Duration(seconds: 4));

  expect(find.byType(TodaysDiaryList), findsOneWidget);
  expect(find.text("Today's Entries"), findsOneWidget);

  await tester.tap(find.text("Camera Diary"));
  await tester.pump(Duration(seconds: 2));
  await Future.delayed(Duration(seconds: 5));

  await tester.tap(find.text("Explore the outdoors"));
  await tester.pump();
  await tester.tap(find.byType(CustomFlatButton));
  await tester.pump(Duration(seconds: 2));
  await Future.delayed(Duration(seconds: 5));

  await tester.tap(find.text("Take a Picture"));
  await tester.pump(Duration(seconds: 2));
  await tester.tap(find.byKey(Key("capture")));
  await tester.pump(Duration(seconds: 2));
  await tester.tap(find.byKey(Key("save")));
  await tester.pump(Duration(seconds: 2));
  await tester.tap(find.byType(CustomFlatButton));
  await tester.pump(Duration(seconds: 2));
  await Future.delayed(Duration(seconds: 2));

  await tester.tap(find.text("Submit My Response"));
  for (int i = 0; i < 20; i++) {
    await tester.pump(Duration(seconds: 2));
  }

  await tester.tap(find.text("Return Home"));
  await tester.pump(Duration(seconds: 4));
}