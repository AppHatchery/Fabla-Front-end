// Tests around the timer question.
//
// IMPORTANT — read before adding tests here.
//
// This file does NOT mount the production `TimerWidget`. Mounting it pulls in
// permission_handler, the `alarm` plugin (Pigeon channels), audioplayers and a
// Rive asset load, none of which are stubbed in a plain widget test. Instead a
// stand-in (`TimerQuestionStandIn`) mirrors the idle-state layout so the shared
// picker and formatting can be exercised deterministically.
//
// What is real production code under test:
//   - `CustomMinuteSecondPicker`  (theme/components/time_picker.dart)
//   - `formatDurationMMOnly` / `formatDurationSSOnly`  (core/utils/formatter.dart)
//
// What is NOT under test:
//   - `TimerWidget` itself — start/pause/resume/restart/stop, alarm scheduling,
//     lifecycle drift reconciliation, and the `_syncLiveUpdate` calls that drive
//     the Android Live Update notification.
//
// Asserting live-update behaviour against the stand-in would only prove the
// stand-in does what the stand-in was written to do. Closing that gap needs
// either the show/hide decision extracted from `_syncLiveUpdate` into a pure
// function, or the plugin channels above stubbed so the real widget can mount.
// The channel contract itself is covered in
// test/services/timer_live_update_service_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/theme/components/time_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Helper function available to all test groups
Widget createTimerWidget({
  Duration? time,
  bool playbackControls = true,
  bool userInteraction = true,
  void Function(String)? respond,
  Function(Function)? addToPreFunction,
}) {
  return ScreenUtilInit(
    minTextAdapt: true,
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      home: Scaffold(
        body: TimerQuestionStandIn(
          time: time ?? const Duration(seconds: 10),
          playbackControls: playbackControls,
          userInteraction: userInteraction,
          respond: respond ?? (String _) {},
          addToPreFunction: addToPreFunction ?? ((_) {}),
        ),
      ),
    ),
  );
}

/// Test-only stand-in for the production `TimerWidget`.
///
/// Mirrors the idle-state layout and the picker wiring, but has no alarm,
/// audio, permission or notification behaviour. See the file header.
class TimerQuestionStandIn extends StatefulWidget {
  final Duration time;
  final bool playbackControls;
  final bool userInteraction;
  final void Function(String) respond;
  final Function(Function) addToPreFunction;

  const TimerQuestionStandIn({
    super.key,
    required this.time,
    required this.playbackControls,
    required this.userInteraction,
    required this.respond,
    required this.addToPreFunction,
  });

  @override
  State<TimerQuestionStandIn> createState() => _TimerQuestionStandInState();
}

class _TimerQuestionStandInState extends State<TimerQuestionStandIn> {
  late Duration duration;
  bool complete = false;

  @override
  void initState() {
    super.initState();
    duration = widget.time;
  }

  Future<void> _showPicker() async {
    final result = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => CustomMinuteSecondPicker(duration: duration),
    );

    if (result != null && mounted) {
      setState(() => duration = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (complete) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          "🎉 Good job! You have completed the task!",
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.only(bottom: 102.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const Row(
              children: [
                Flexible(child: Text('Time Length')),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('$minutes min $seconds sec')),
                  IconButton(
                    onPressed: widget.userInteraction ? _showPicker : null,
                    icon: widget.userInteraction
                        ? const Icon(Icons.edit_outlined)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Start Timer Now'),
            ),
            const SizedBox(height: 40),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  complete = true;
                });
                widget.respond('Complete');
              },
              child: const Text('I Have Completed The Task'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('Timer question stand-in UI', () {
    group('Widget Creation and Display', () {
      testWidgets('should display initial timer state correctly',
          (tester) async {
        await tester.pumpWidget(createTimerWidget());

        // Check if the time length label is displayed
        expect(find.text('Time Length'), findsOneWidget);

        // Check if the duration is displayed correctly (0 min 10 sec)
        expect(find.text('0 min 10 sec'), findsOneWidget);

        // Check if Start Timer button is displayed
        expect(find.text('Start Timer Now'), findsOneWidget);

        // Check if Complete button is displayed
        expect(find.text('I Have Completed The Task'), findsOneWidget);
      });

      testWidgets('should display edit icon when userInteraction is true',
          (tester) async {
        await tester.pumpWidget(createTimerWidget(userInteraction: true));

        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      });

      testWidgets('should not display edit icon when userInteraction is false',
          (tester) async {
        await tester.pumpWidget(createTimerWidget(userInteraction: false));

        expect(find.byIcon(Icons.edit_outlined), findsNothing);
      });

      testWidgets('reports completion to the host question', (tester) async {
        final responses = <String>[];

        await tester
            .pumpWidget(createTimerWidget(respond: responses.add));

        await tester.tap(find.text('I Have Completed The Task'));
        await tester.pumpAndSettle();

        expect(responses, <String>['Complete']);
        expect(find.text('Start Timer Now'), findsNothing);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle very large durations', (tester) async {
        // Test with large duration
        await tester.pumpWidget(
            createTimerWidget(time: const Duration(hours: 2, minutes: 30)));

        expect(find.text('150 min 00 sec'), findsOneWidget);
      });
    });
  });

  group('Time picker integration (production CustomMinuteSecondPicker)', () {
    testWidgets('should open time picker when edit button is tapped',
        (tester) async {
      await tester.pumpWidget(createTimerWidget(userInteraction: true));

      // Find and tap edit button
      final editButton = find.byIcon(Icons.edit_outlined);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Should show the time picker modal
      expect(find.text('Time Length'), findsAtLeast(1));
      expect(find.text('SAVE'), findsOneWidget);
      expect(find.text('min'), findsOneWidget);
      expect(find.text('sec'), findsOneWidget);

      await tester.tap(find.text('SAVE'));

      await tester.pumpAndSettle();

      // Should close the time picker modal
      expect(find.text('Time Length'), findsOneWidget);
      expect(find.text('SAVE'), findsNothing);
      expect(find.text('min'), findsNothing);
      expect(find.text('sec'), findsNothing);

      expect(editButton, findsOneWidget);

      await tester.tap(editButton);
      await tester.pumpAndSettle();

      //closing the time picker
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Should navigate back
      expect(find.text('SAVE'), findsNothing);
    });

    testWidgets('dismissing the picker leaves the duration unchanged',
        (tester) async {
      await tester.pumpWidget(
          createTimerWidget(time: const Duration(minutes: 2, seconds: 30)));

      expect(find.text('2 min 30 sec'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('2 min 30 sec'), findsOneWidget);
    });

    testWidgets('should not open time picker when userInteraction is false',
        (tester) async {
      await tester.pumpWidget(createTimerWidget(userInteraction: false));

      // Edit button should not exist
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });
  });

  // These back the "MM" / "SS" fields the picker writes and the countdown the
  // timer modal renders, so the timer question depends on them directly.
  group('Duration formatting (production formatter.dart)', () {
    test('should format minutes correctly', () {
      const duration1 = Duration(minutes: 5, seconds: 30);
      expect(formatDurationMMOnly(duration1), equals('05'));

      const duration2 = Duration(minutes: 25, seconds: 10);
      expect(formatDurationMMOnly(duration2), equals('25'));

      const duration3 = Duration(seconds: 45);
      expect(formatDurationMMOnly(duration3), equals('00'));
    });

    test('should format seconds correctly', () {
      const duration1 = Duration(minutes: 5, seconds: 5);
      expect(formatDurationMMOnly(duration1), equals('05'));

      const duration2 = Duration(minutes: 25, seconds: 30);
      expect(formatDurationSSOnly(duration2), equals('30'));

      const duration3 = Duration(seconds: 9);
      expect(formatDurationSSOnly(duration3), equals('09'));
    });

    test('pads both fields to two digits at the boundaries', () {
      expect(formatDurationMMOnly(Duration.zero), equals('00'));
      expect(formatDurationSSOnly(Duration.zero), equals('00'));

      const oneMinute = Duration(seconds: 60);
      expect(formatDurationMMOnly(oneMinute), equals('01'));
      expect(formatDurationSSOnly(oneMinute), equals('00'));

      const justUnderAMinute = Duration(seconds: 59);
      expect(formatDurationMMOnly(justUnderAMinute), equals('00'));
      expect(formatDurationSSOnly(justUnderAMinute), equals('59'));
    });

    // Characterisation, not endorsement: both helpers take `.remainder(60)`, so
    // anything at or past an hour wraps. The picker caps at 59 minutes, but a
    // study-configured `TimerWidget.time` is not capped and would display wrong.
    test('wraps at an hour because minutes are taken modulo 60', () {
      const ninetyMinutes = Duration(minutes: 90);
      expect(formatDurationMMOnly(ninetyMinutes), equals('30'));

      const exactlyOneHour = Duration(hours: 1);
      expect(formatDurationMMOnly(exactlyOneHour), equals('00'));
      expect(formatDurationSSOnly(exactlyOneHour), equals('00'));
    });
  });
}
