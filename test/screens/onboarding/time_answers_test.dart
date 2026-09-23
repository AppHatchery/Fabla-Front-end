import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/time_picker.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/widgets/update_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cases = {
    '00:00:00': TimeOfDay(hour: 0, minute: 0),
    '12:00:00': TimeOfDay(hour: 12, minute: 0),
    '09:05:00': TimeOfDay(hour: 9, minute: 5),
    '23:59:00': TimeOfDay(hour: 23, minute: 59),
    '9:05:00': TimeOfDay(hour: 9, minute: 5),
  };

  for (final entry in cases.entries) {
    final expected = entry.key == '9:05:00' ? '09:05:00' : entry.key;
    test('format and reopen ${entry.key}', () {
      expect(timeOfDayFromString(entry.key), entry.value);
      expect(formatTimeAnswer(entry.value), expected);
      expect(timeOfDayFromString(formatTimeAnswer(entry.value)), entry.value);
    });

    testWidgets('onboarding reopens and saves ${entry.key}', (tester) async {
      String? answer;
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: OnboardingTimePicker(
              time: entry.key,
              title: 'Time',
              subtitle: '',
              onChanged: (value) => answer = value,
            ),
          ),
        ),
      ));
      final context = tester.element(find.byType(OnboardingTimePicker));
      final displayed =
          MaterialLocalizations.of(context).formatTimeOfDay(entry.value);
      expect(find.text(displayed), findsOneWidget);
      await tester.tap(find.byKey(const Key('time_picker_icon_button')));
      await tester.pumpAndSettle();
      final wheels = tester
          .widgetList<ListWheelScrollView>(
            find.byType(ListWheelScrollView),
          )
          .toList();
      expect((wheels[0].controller as FixedExtentScrollController).selectedItem,
          (entry.value.hour + 11) % 12);
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();
      expect(answer, expected);
      expect(find.text(displayed), findsOneWidget);
    });

    testWidgets('settings reopens and saves ${entry.key}', (tester) async {
      String? answer;
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: Scaffold(body: Builder(builder: (context) {
            return TextButton(
              onPressed: () async {
                answer = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SingleChildScrollView(
                      child: UpdateTimePicker(
                    title: 'Time',
                    subtitle: '',
                    index: 1,
                    date: timeOfDayFromString(entry.key),
                    minuteInterval: 1,
                  )),
                );
              },
              child: const Text('Edit'),
            );
          })),
        ),
      ));
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      final wheels = tester
          .widgetList<ListWheelScrollView>(
            find.byType(ListWheelScrollView),
          )
          .toList();
      expect((wheels[0].controller as FixedExtentScrollController).selectedItem,
          (entry.value.hour + 11) % 12);
      await tester.ensureVisible(find.text('Update'));
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(answer, expected);
    });
  }
}
