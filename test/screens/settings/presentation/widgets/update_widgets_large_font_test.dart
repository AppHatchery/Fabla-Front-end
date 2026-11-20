import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/widgets/update_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

// Long single words that would be split mid-word at large font sizes on a
// small phone.
const title = 'Accessibility preferences';
const subtitle = 'Notifications acknowledgement';
final options = [
  Option(title: 'Overwhelmingly', value: 'a'),
  Option(title: 'Sometimes', value: 'b'),
];

/// Pumps an update sheet the way the settings bottom modal shows it (in a
/// scroll view) at the largest system font size on a 320pt-wide phone.
Future<void> pumpSheet(WidgetTester tester, Widget sheet) async {
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
            child: Scaffold(body: SingleChildScrollView(child: sheet)),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Every word of [label] fits on one line at the scale it was painted with.
void expectNoMidWordBreaks(WidgetTester tester, String label) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
  for (final word in label.split(' ')) {
    final painter = TextPainter(
      text: TextSpan(text: word, style: paragraph.text.style),
      textDirection: TextDirection.ltr,
      textScaler: paragraph.textScaler,
      maxLines: 1,
    )..layout();
    expect(painter.width, lessThanOrEqualTo(paragraph.size.width),
        reason: '"$word" in "$label" is wider than its line');
    painter.dispose();
  }
}

void main() {
  group('update sheets at the largest font size', () {
    testWidgets('UpdateRadioOptions', (tester) async {
      await pumpSheet(
        tester,
        UpdateRadioOptions(
          title: title,
          subtitle: subtitle,
          index: 1,
          selected: 'a',
          options: options,
        ),
      );
      for (final label in [title, subtitle, ...options.map((o) => o.title)]) {
        expectNoMidWordBreaks(tester, label);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('UpdateMultipleOptions', (tester) async {
      await pumpSheet(
        tester,
        UpdateMultipleOptions(
          title: title,
          subtitle: subtitle,
          index: 1,
          selected: const ['a'],
          options: options,
        ),
      );
      for (final label in [title, subtitle, ...options.map((o) => o.title)]) {
        expectNoMidWordBreaks(tester, label);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('UpdateTextOption', (tester) async {
      await pumpSheet(
        tester,
        const UpdateTextOption(
          title: title,
          subtitle: subtitle,
          index: 1,
          answer: 'Some answer',
        ),
      );
      for (final label in [title, subtitle]) {
        expectNoMidWordBreaks(tester, label);
      }
      expect(tester.takeException(), isNull);
    });
  });
}
