import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/verification_code.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/components/textfields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> onboardingFlow(WidgetTester tester) async {
  await tester.pumpAndSettle();

  // Study code page
  await tester.enterText(find.byType(VerificationCodeTextField), 'ls11');
  await Future.delayed(const Duration(seconds: 2));

  await tester.tap(find.byType(CustomFlatButton).at(0));
  await tester.pumpAndSettle();

  // Study Information page
  await tester.tap(find.byType(CustomFlatButton).at(0));
  await tester.pumpAndSettle();
  await Future.delayed(const Duration(seconds: 2));

  // Participant login page
  await tester.enterText(find.byType(VerificationCodeTextField), '54');
  await Future.delayed(const Duration(seconds: 2));
  await tester.tap(find.byType(CustomFlatButton).at(0));
  await tester.pump(const Duration(seconds: 2));

  // Welcome page
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(seconds: 2));
  }

  await tester.tap(find.byType(CustomFlatButton));
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 2));

  // Participant name page
  await tester.enterText(find.byType(CustomTextField), "John A");
  await Future.delayed(const Duration(seconds: 2));
  await tester.tap(find.byType(CustomFlatButton));
  await tester.pump(const Duration(seconds: 2));
  await Future.delayed(const Duration(seconds: 2));

  // Notifications permission
  await tester.tap(find.byType(CustomFlatButton));
  await tester.pump(const Duration(seconds: 2));
  await Future.delayed(const Duration(seconds: 4));
  await tester.tap(find.byType(CustomFlatButton));
  await tester.pump(const Duration(seconds: 2));

  // Microphone permission
  await tester.tap(find.byType(CustomFlatButton));
  await tester.pump(const Duration(seconds: 2));
  await Future.delayed(const Duration(seconds: 4));
  await tester.tap(find.byType(CustomFlatButton));
  await tester.pump(const Duration(seconds: 2));

  // Camera permission
  await tester.tap(find.text("Continue"));
  await tester.pump(const Duration(seconds: 2));
  await Future.delayed(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 2));
  await tester.tap(find.text("Continue"));
  await tester.pump(const Duration(seconds: 2));

  // Location permission
  await tester.tap(find.text('Continue'));
  await tester.pump(const Duration(seconds: 2));

  // Dynamic onboarding
  await tester.tap(find.byType(CustomFlatButton));
  await tester.pump(const Duration(seconds: 2));
  await Future.delayed(const Duration(seconds: 2));

  //onboarding question 1
  await tester.enterText(find.byType(CustomTextField), "Cheese");
  await Future.delayed(const Duration(seconds: 2));
  await tester.tap(find.byType(CustomFlatButton));
  await tester.pump(const Duration(seconds: 2));

  // onboarding question 2
  await tester.drag(find.byType(Slider), const Offset(100, 0));
  await tester.pump(const Duration(seconds: 2));
  await tester.tap(find.byType(CustomFlatButton));
  await tester.pump(const Duration(seconds: 2));

  // onboarding question 3
  await tester.tap(find.text("Zero"));
  await tester.pump(const Duration(seconds: 2));
  await tester.tap(find.byType(CustomFlatButton));
  await tester.pump(const Duration(seconds: 2));

  // onboarding question 4
  await tester.tap(find.text("Zero"));
  await tester.pump(const Duration(seconds: 2));
  await tester.tap(find.byType(CustomFlatButton));
  await tester.pump(const Duration(seconds: 2));

  // onboarding question 5
  await tester.tap(find.byKey(const Key("time_picker_icon_button")));
  await tester.pump(const Duration(seconds: 2));
  await tester.tap(find.text("SAVE"));
  await tester.pump(const Duration(seconds: 2));
  await tester.tap(find.byType(CustomFlatButton));
  await tester.pump(const Duration(seconds: 2));

  // onboarding question 6
  final date = DateTime.now().day.toString();
  await tester.tap(find.text(date));
  await tester.pump(const Duration(seconds: 2));
  await tester.tap(find.text("Continue"));
  await tester.pump(const Duration(seconds: 2));

  //loading screen
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(seconds: 2));
  }

  //date selection
  await tester.tap(find.byType(CustomFlatButton));
  await tester.pump(const Duration(seconds: 2));

  //proceed to home screen
  await tester.tap(find.byType(CustomFlatButton));
  await tester.pump(const Duration(seconds: 2));
}