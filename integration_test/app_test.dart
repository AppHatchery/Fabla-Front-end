import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/diary_list.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/todays_diary_list.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/weekly_goal.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/today_goal.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/verification_code.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:audio_diaries_flutter/theme/components/textfields.dart';
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

  setUpAll(() async {
    // Initialize the global objectbox instance
    app.objectbox = await ObjectBox.create();

    // Initialize other required services from main.dart
    app.cameras = await availableCameras();
    await Alarm.init();
    await NotificationService.init();
    await PendoService.init();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  // uncomment this block to clean up (delete all data) after each test
  // tearDown(() async {
  //   // Clear all boxes/tables
  //   app.objectbox.store.box<DiaryModel>().removeAll();
  //   app.objectbox.store.box<StudyModel>().removeAll();
  //   app.objectbox.store.box<ExperimentModel>().removeAll();
  // });

  // clean up(delete all data) once after all tests
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
    //Note: each tests is ran one after the other and in order, so if one test fails the next one will fail as well and so on..
    testWidgets('Onboarding flow Test', (tester) async {
      // Use the helper to build the app
      await pumpAppWithRoute(tester);
      await tester.pumpAndSettle();

      // study code page
      expect(find.byType(VerificationCodeTextField), findsOneWidget);
      await tester.enterText(find.byType(VerificationCodeTextField), 'ls11');
      await Future.delayed(const Duration(seconds: 2));

      expect(find.byType(CustomFlatButton), findsOneWidget);
      await tester.tap(find.byType(CustomFlatButton).at(0));
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

      await tester.tap(find.byType(CustomFlatButton).at(0));
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
      await tester.tap(find.text("Continue"));
      await tester.pump(const Duration(seconds: 2));

      await Future.delayed(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text("Continue"));
      await tester.pump(const Duration(seconds: 2));

// location access page
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(Text), findsNWidgets(2));
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(seconds: 2));

// Dynamic onboarding page
      expect(find.byType(Text), findsNWidgets(2));
      await tester.tap(find.byType(CustomFlatButton));

      await tester.pump(const Duration(seconds: 2));
      await Future.delayed(const Duration(seconds: 2));

      //text question
      await tester.enterText(find.byType(CustomTextField), "Cheese");
      await Future.delayed(const Duration(seconds: 2));

      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));

      //slider question
      await tester.drag(find.byType(Slider), Offset(100, 0));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));

      //multiple choice question
      await tester.tap(find.text("Zero"));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));

      //radio question
      await tester.tap(find.text("Zero"));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));

      // time picker question
      await tester.tap(find.byKey(const Key("time_picker_icon_button")));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text("SAVE"));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));

      // data picker question
      final date = DateTime.now().day.toString();
      await tester.tap(find.text(date));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text("Continue"));
      await tester.pump(const Duration(seconds: 2));

      //loading next page (simulates the loading of the next page by waiting for 80 seconds)
      for (int i = 0; i < 20; i++) {
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
      await tester.tap(find.text("Camera Diary"));
      await tester.pump(const Duration(seconds: 2));
      await Future.delayed(const Duration(seconds: 5));

      //answer the first question
      await tester.tap(find.text("Explore the outdoors"));
      await tester.pump();
      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));
      await Future.delayed(const Duration(seconds: 5));

      //answers the second question
      await tester.tap(find.text("Take a Picture"));
      await tester.pump(const Duration(seconds: 2));

      //tap the camera button
      await tester.tap(find.byKey(const Key("capture")));
      await tester.pump(const Duration(seconds: 2));

      //tap the ticked button
      await tester.tap(find.byKey(const Key("save")));
      await tester.pump(const Duration(seconds: 2));

      //submit the response
      await tester.tap(find.byType(CustomFlatButton));
      await tester.pump(const Duration(seconds: 2));
      await Future.delayed(const Duration(seconds: 2));

      //answer the prompt
      await tester.tap(find.text("Submit My Response"));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(seconds: 2));
      }

      //return to home page
      await tester.tap(find.text("Return Home"));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('History flow Test', (tester) async {
      await pumpAppWithRoute(tester);
      await tester.pump();

      //Going to history page by clicking history in the bottom nav
      await tester.tap(find.text("History"));
      await tester.pump(const Duration(seconds: 2));


      //checking to see the dairy list cards and history title is present
      expect(find.byType(DiaryList), findsOneWidget);
      expect(find.text("History"), findsNWidgets(2));

      //taps on the entry called weekly diary
      await tester.tap(find.text("Weekly Diary").first);
      await tester.pump(const Duration(seconds: 2));

      // first question - selects the explore the outdoors option
      await tester.tap(find.text("Explore the outdoors"));
      await tester.pump(const Duration(seconds: 2));

      //continue button
      await tester.tap(find.text("Continue"));
      await tester.pump(const Duration(seconds: 2));

      await Future.delayed(const Duration(seconds: 5));

      //second question - drags the slider
      await tester.drag(find.byType(Slider), Offset(100, 0));
      await tester.pump(const Duration(seconds: 2));

      //continue button
      await tester.tap(find.text("Continue"));
      await tester.pump(const Duration(seconds: 2));

      //submit button
      await tester.tap(find.text("Submit My Response"));

      // loading
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(seconds: 2));
      }

      // response is submitted and clicks return home button
      await tester.tap(find.text("Return Home"));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('Settings flow Test', (tester) async {
      await pumpAppWithRoute(tester);
      await tester.pump();

      //go to settings page
      await tester.tap(find.text("Settings"));
      await tester.pump(const Duration(seconds: 2));

      //check for study details
      expect(find.text("View Details"), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));

      //leave study pop up - testing the leave study pop up
      await tester.tap(find.text("Leave This Study"));
      await tester.pump(const Duration(seconds: 2));

      //clicks the dismiss button
      await tester.tap(find.text("Dismiss"));
      await tester.pump(const Duration(seconds: 2));

      //view participant details
      await tester.tap(find.text("Onboarding Survey"));
      await tester.pump(const Duration(seconds: 2));

      //update the participant details questions
      //question 1
      await tester.tap(find.byKey(const Key("edit_icon_button")).at(0));
      await tester.pump(const Duration(seconds: 2));

      await tester.enterText(find.byType(CustomTextField), "Cheese");
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text("Update"));
      await tester.pump(const Duration(seconds: 2));

      //question 2
      await tester.tap(find.byKey(const Key("edit_icon_button")).at(1));
      await tester.pump(const Duration(seconds: 2));

      await tester.drag(find.byType(Slider), Offset(100, 0));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text("Update"));
      await tester.pump(const Duration(seconds: 2));

      // question 3 multiple choice
      await tester.tap(find.byKey(const Key("edit_icon_button")).at(2));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text("One").at(0));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text("Update"));
      await tester.pump(const Duration(seconds: 2));

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500), // Scroll down (negative value)
      );
      await tester.pump(const Duration(seconds: 2));

      //question 4
      await tester.tap(find.byKey(const Key("edit_icon_button")).at(3));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text("One").at(0));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text("Update"));
      await tester.pump(const Duration(seconds: 2));

      // question 5
      await tester.tap(find.byKey(const Key("edit_icon_button")).at(4));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text("Update"));
      await tester.pump(const Duration(seconds: 2));

      // question 6
      await tester.tap(find.byKey(const Key("edit_icon_button")).at(5));
      await tester.pump(const Duration(seconds: 2));

      final date = DateTime.now().day.toString();
      await tester.tap(find.text(date));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text("Update"));
      await tester.pump(const Duration(seconds: 2));

      //return to settings page
      final backButton = find.byKey(const Key("back_button"));
      await tester.tap(backButton);

      //simulate a loading animation to ensure the update loading screen is processed
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(seconds: 2));
      }


      // test microphone
      await tester.tap(find.text("Test Microphone"));
      await tester.pump(const Duration(seconds: 2));

      await Future.delayed(const Duration(seconds: 2));

      await tester.tap(find.text("Stop Test"));
      await tester.pump(const Duration(seconds: 2));

      //add a reminder time
      await tester.tap(find.text("Add a Reminder Time"));
      await tester.pump(const Duration(seconds: 2));


    // multipe async operations running at the same throwing  ConcurrentModificationError
      // await tester.tap(find.text("SAVE"));
      // for (int i = 0; i < 15; i++) {
      //   await tester.pump(const Duration(seconds: 2));
      // }
    });
  });
}
