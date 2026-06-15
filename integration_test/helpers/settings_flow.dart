import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:audio_diaries_flutter/theme/components/textfields.dart';

Future<void> settingsFlow(WidgetTester tester) async {
  await tester.pump();

  // Go to settings page
  await tester.tap(find.text("Settings"));
  await tester.pump(const Duration(seconds: 2));

  // Check for study details
  expect(find.text("View Details"), findsOneWidget);

  // Leave study popup
  await tester.tap(find.text("Leave Study"));
  await tester.pump(const Duration(seconds: 2));

  await tester.tap(find.text("Dismiss"));
  await tester.pump(const Duration(seconds: 2));

  // View participant details
  await tester.tap(find.text("Onboarding Survey"));
  await tester.pump(const Duration(seconds: 2));

  // Question 1 - TextField
  await tester.tap(find.byKey(const Key("edit_icon_button")).at(0));
  await tester.pump(const Duration(seconds: 2));
  await tester.enterText(find.byType(CustomTextField), "Cheese");
  await tester.pump(const Duration(seconds: 2));
  await tester.tap(find.text("Update"));
  await tester.pump(const Duration(seconds: 2));

  // Question 2 - Slider
  await tester.tap(find.byKey(const Key("edit_icon_button")).at(1));
  await tester.pump(const Duration(seconds: 2));
  await tester.drag(find.byType(Slider), const Offset(100, 0));
  await tester.pump(const Duration(seconds: 2));
  await tester.tap(find.text("Update"));
  await tester.pump(const Duration(seconds: 2));

  // Question 3 - Multiple choice
  await tester.tap(find.byKey(const Key("edit_icon_button")).at(2));
  await tester.pump(const Duration(seconds: 2));
  await tester.tap(find.text("One").first);
  await tester.pump(const Duration(seconds: 2));
  await tester.tap(find.text("Update"));
  await tester.pump(const Duration(seconds: 2));

  // Scroll for more questions
  await tester.drag(
    find.byType(SingleChildScrollView),
    const Offset(0, -500),
  );
  await tester.pump(const Duration(seconds: 2));

  // Question 4 - Radio
  await tester.tap(find.byKey(const Key("edit_icon_button")).at(3));
  await tester.pump(const Duration(seconds: 2));
  await tester.tap(find.text("One").first);
  await tester.pump(const Duration(seconds: 2));
  await tester.tap(find.text("Update"));
  await tester.pump(const Duration(seconds: 2));

  // Question 5 - Time Picker
  await tester.tap(find.byKey(const Key("edit_icon_button")).at(4));
  await tester.pump(const Duration(seconds: 2));
  await tester.tap(find.text("Update"));
  await tester.pump(const Duration(seconds: 2));

  // Question 6 - Date Picker
  await tester.tap(find.byKey(const Key("edit_icon_button")).at(5));
  await tester.pump(const Duration(seconds: 2));
  final date = DateTime.now().day.toString();
  await tester.tap(find.text(date));
  await tester.pump(const Duration(seconds: 2));
  await tester.tap(find.text("Update"));
  await tester.pump(const Duration(seconds: 2));

  // Return to settings page
  final backButton = find.byKey(const Key("back_button"));
  await tester.tap(backButton);
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(seconds: 2));
  }

  // Microphone test
  await tester.tap(find.text("Test Microphone"));
  await tester.pump(const Duration(seconds: 2));
  await tester.tap(find.text("Stop Test"));
  await tester.pump(const Duration(seconds: 2));

  // Add reminder time
  await tester.tap(find.text("+ Add Reminder"));
  await tester.pump();
  await Future.delayed(const Duration(seconds: 10));
  await tester.tap(find.text("SAVE"));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}
