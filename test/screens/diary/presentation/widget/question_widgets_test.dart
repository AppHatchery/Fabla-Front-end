import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/question_widgets.dart';
import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart'
    as onboarding;
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/dynamic_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  group('choice options at the largest font size', () {
    // One long word that would be split mid-word at the iOS 2x cap on a
    // small phone.
    const options = ['Overwhelmingly', 'Sometimes'];

    Future<void> pumpLarge(WidgetTester tester, Widget question) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (_, __) => MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(3.1)),
                child: Scaffold(body: question),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    /// Every word of every option label fits on one line at the scale it
    /// was actually painted with, so none is broken mid-word.
    void expectNoMidWordBreaks(WidgetTester tester) {
      for (final label in options) {
        final paragraph =
            tester.renderObject<RenderParagraph>(find.text(label));
        for (final word in label.split(' ')) {
          final painter = TextPainter(
            text: TextSpan(text: word, style: paragraph.text.style),
            textDirection: TextDirection.ltr,
            textScaler: paragraph.textScaler,
            maxLines: 1,
          )..layout();
          expect(painter.width, lessThanOrEqualTo(paragraph.size.width),
              reason: '"$word" is wider than its line');
          painter.dispose();
        }
      }
      expect(tester.takeException(), isNull);
    }

    testWidgets('MultipleQuestion', (tester) async {
      await pumpLarge(
          tester,
          MultipleQuestion(
              options: options, selected: const [], onChanged: (_) {}));
      expectNoMidWordBreaks(tester);
    });

    testWidgets('RadioQuestion', (tester) async {
      await pumpLarge(tester,
          RadioQuestion(value: null, options: options, onChanged: (_) {}));
      expectNoMidWordBreaks(tester);
    });

    testWidgets('MultipleQuestionSummary', (tester) async {
      await pumpLarge(tester, const MultipleQuestionSummary(answers: options));
      expectNoMidWordBreaks(tester);
    });

    testWidgets('RadioQuestionSummary', (tester) async {
      await pumpLarge(
          tester, const RadioQuestionSummary(selectedOption: 'Overwhelmingly'));
      final paragraph =
          tester.renderObject<RenderParagraph>(find.text('Overwhelmingly'));
      final painter = TextPainter(
        text: TextSpan(text: 'Overwhelmingly', style: paragraph.text.style),
        textDirection: TextDirection.ltr,
        textScaler: paragraph.textScaler,
        maxLines: 1,
      )..layout();
      expect(painter.width, lessThanOrEqualTo(paragraph.size.width));
      painter.dispose();
    });
  });
}
