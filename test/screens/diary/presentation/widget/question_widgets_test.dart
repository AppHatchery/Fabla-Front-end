import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/question_widgets.dart';
import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart'
    as onboarding;
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/dynamic_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<FlutterErrorDetails>> pumpQuestion(
  WidgetTester tester,
  Widget question,
) async {
  final frameworkErrors = <FlutterErrorDetails>[];
  final previousErrorHandler = FlutterError.onError;
  FlutterError.onError = frameworkErrors.add;

  try {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: Scaffold(body: question),
        ),
      ),
    );

    await tester.pump();
  } finally {
    FlutterError.onError = previousErrorHandler;
  }

  return frameworkErrors;
}

void main() {
  group('question option Material hierarchy', () {
    testWidgets('diary multiple-choice options render without framework errors',
        (tester) async {
      final frameworkErrors = await pumpQuestion(
        tester,
        MultipleQuestion(
          options: const ['First', 'Second'],
          selected: const [],
          onChanged: (_) {},
        ),
      );

      expect(frameworkErrors, isEmpty);
    });

    testWidgets('diary single-choice options render without framework errors',
        (tester) async {
      final frameworkErrors = await pumpQuestion(
        tester,
        RadioQuestion(
          value: null,
          options: const ['First', 'Second'],
          onChanged: (_) {},
        ),
      );

      expect(frameworkErrors, isEmpty);
    });

    testWidgets(
        'onboarding multiple-choice options render without framework errors',
        (tester) async {
      final frameworkErrors = await pumpQuestion(
        tester,
        CustomMultipleQuestion(
          options: [
            onboarding.Option(title: 'First', value: 'first'),
            onboarding.Option(title: 'Second', value: 'second'),
          ],
          selected: const [],
          onChanged: (_) {},
        ),
      );

      expect(frameworkErrors, isEmpty);
    });

    testWidgets(
        'onboarding single-choice options render without framework errors',
        (tester) async {
      final frameworkErrors = await pumpQuestion(
        tester,
        CustomRadioQuestion(
          options: [
            onboarding.Option(title: 'First', value: 'first'),
            onboarding.Option(title: 'Second', value: 'second'),
          ],
          selected: null,
          onChanged: (_) {},
        ),
      );

      expect(frameworkErrors, isEmpty);
    });
  });
}
