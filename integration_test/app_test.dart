import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/todays_diary_list.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/weekly_goal.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/today_goal.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/verification_code.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/components/textfields.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:audio_diaries_flutter/main.dart' as app;
import 'package:alarm/alarm.dart';
import 'package:audio_diaries_flutter/services/notification_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:camera/camera.dart';
import 'package:audio_diaries_flutter/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  setUpAll(() async {
    // Initialize the global objectbox instance
    app.objectbox = await ObjectBox.create();

    // Initialize other required services from main.dart
    app.cameras = await availableCameras();
    await Alarm.init();
    await NotificationService.init();
    await PendoService.init();
  });

  // Add this to clean up after each test
  // tearDown(() async {
  //   // Clear all boxes/tables
  //   app.objectbox.store.box<DiaryModel>().removeAll();
  //   app.objectbox.store.box<StudyModel>().removeAll();
  //   app.objectbox.store.box<ExperimentModel>().removeAll();
  //   // Add any other boxes you need to clear
  // });

  // clean up once after all tests
  tearDownAll(() async {
    // Clear all data
    app.objectbox.store.close();
  });

  // Helper function to build the app with the given route
  Future<void> pumpAppWithRoute(WidgetTester tester) async {
    final route = await RouteService().getRoute();
    await tester.pumpWidget(app.MyApp(route: route));
  }

  group('End to End Test', () {
    testWidgets('Onboarding flow Test', (tester) async {
      // Use the helper to build the app
      await pumpAppWithRoute(tester);
      await tester.pumpAndSettle();

      // study code page
      expect(find.byType(VerificationCodeTextField), findsOneWidget);
      await tester.enterText(find.byType(VerificationCodeTextField), 'ls11');
      await Future.delayed(const Duration(seconds: 2));

      expect(find.byType(CustomFlatButton), findsOneWidget);
      await tester.tap(find.byType(CustomFlatButton));
      await tester.pumpAndSettle();

// study Information page

      expect(find.byType(CustomFlatButton), findsNWidgets(2));
      await tester.tap(find.byType(CustomFlatButton).at(0));
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

// participant login page

      expect(find.byType(VerificationCodeTextField), findsOneWidget);
      expect(find.byType(CustomFlatButton), findsOneWidget);

      await tester.enterText(find.byType(VerificationCodeTextField), '54');
      await Future.delayed(const Duration(seconds: 2));

      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));

// Welcome page
      // wait for all animations and async operations to complete
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 2));
      }

      expect(find.byType(Text), findsNWidgets(3));
      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

// participant name page
      await tester.enterText(find.byType(CustomTextField), "John A");
      await Future.delayed(const Duration(seconds: 2));

      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));
      await Future.delayed(const Duration(seconds: 2));

// Turn on Notifications page
      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));

      await Future.delayed(const Duration(seconds: 4));

      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));

// mic permission page
      expect(find.byType(Text), findsNWidgets(2));
      expect(find.byType(CustomFlatButton), findsOneWidget);

      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));

      await Future.delayed(const Duration(seconds: 4));

      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));

// Camera permission page
      //assertions
      expect(find.byType(Text), findsNWidgets(2));
      expect(find.byType(CustomFlatButton), findsOneWidget);

      //actions
      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));

      await Future.delayed(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));

// location access page
      expect(find.byType(Text), findsNWidgets(2));
      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));

// Dynamic onboarding page
      expect(find.byType(Text), findsNWidgets(2));
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(seconds: 2));
      }

// Active dates page
      expect(find.byType(Text), findsAtLeast(3));

      //actions
      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));

// Finish page
      expect(find.byType(Text), findsNWidgets(3));

      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('Home flow Test', (tester) async {
      await pumpAppWithRoute(tester);
      await tester.pump();

//today's goal widget
      expect(find.byType(TodayGoalWidget), findsOneWidget);
      expect(find.text('Today\'s Goal'), findsOneWidget);
      expect(find.byKey(const Key('displayText')), findsNWidgets(3));

//Weekly Goal
      expect(find.byType(WeeklyGoalWidget), findsOneWidget);
      expect(find.text('Weekly Goal'), findsOneWidget);
      expect(find.byKey(const Key('weekly_goal_icon')), findsOneWidget);

      await tester.tap(find.byKey(const Key('weekly_goal_widget')));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Weekly Goal'), findsOneWidget);
      expect(find.byKey(const Key('weekly_goal_icon')), findsOneWidget);
      expect(find.byKey(const Key('weekly_goal_text')), findsOneWidget);

      await tester.tap(find.byKey(const Key('weekly_goal_widget')));
      await tester.pump(const Duration(seconds: 2));

//study calendar
      //finds the icon button
      expect(find.byType(IconButton), findsOneWidget);
      //tap the icon button
      await tester.tap(find.byType(IconButton));
      //wait for the calendar to appear
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      //tap the back button
      await tester.tap(find.byType(IconButton).at(1));
      //wait for the calendar to disappear
      await tester.pump(const Duration(seconds: 2));
      await Future.delayed(const Duration(seconds: 2));

//Incentive pop up
      //looks for the incentive icon
      expect(find.byKey(const Key('Incentive')), findsOneWidget);
      //tap the incentive icon
      await tester.tap(find.byKey(const Key('Incentive')));
      //wait for the pop up to appear
      await tester.pump(const Duration(seconds: 2));
      //tap the back button
      await tester.tap(find.byType(IconButton).at(1));
      await tester.pump(const Duration(seconds: 2));
      await Future.delayed(const Duration(seconds: 2));

//Diary list
      //check for today's entries list
      expect(find.byType(TodaysDiaryList), findsOneWidget);
      expect(find.text("Today's Entries"), findsOne);

      //clicks the first entry
      await tester.tap(find.byType(TodaysDiaryList).at(1));
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
