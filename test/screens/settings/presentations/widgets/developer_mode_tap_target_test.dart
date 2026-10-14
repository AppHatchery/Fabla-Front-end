import 'package:audio_diaries_flutter/screens/settings/presentation/widgets/developer_mode_tap_target.dart';
import 'package:audio_diaries_flutter/services/developer_mode_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final target = find.byKey(const Key('developer_mode_tap_target'));

  Widget buildTarget() => const MaterialApp(
        home: Scaffold(
          body: Center(
            child:
                DeveloperModeTapTarget(child: Text('Powered by AppHatchery')),
          ),
        ),
      );

  Future<void> tapTimes(WidgetTester tester, int times) async {
    for (var i = 0; i < times; i++) {
      await tester.tap(target);
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DeveloperModeService().load();
  });

  testWidgets('does not enable before the required number of taps',
      (tester) async {
    await tester.pumpWidget(buildTarget());

    await tapTimes(tester, DeveloperModeService.requiredTaps - 1);

    expect(DeveloperModeService().isEnabled, isFalse);
  });

  testWidgets('shows a countdown for the last few taps', (tester) async {
    await tester.pumpWidget(buildTarget());

    await tapTimes(tester, 5);
    expect(find.textContaining('away from developer mode'), findsNothing);

    await tapTimes(tester, 1);
    expect(
        find.text('You are 4 taps away from developer mode'), findsOneWidget);

    await tapTimes(tester, 3);
    expect(find.text('You are 1 tap away from developer mode'), findsOneWidget);
  });

  testWidgets('enables developer mode after the required taps', (tester) async {
    await tester.pumpWidget(buildTarget());

    await tapTimes(tester, DeveloperModeService.requiredTaps);

    expect(DeveloperModeService().isEnabled, isTrue);
    expect(find.text('Developer mode is now on'), findsOneWidget);
  });

  testWidgets('resets the count when taps are too far apart', (tester) async {
    await tester.pumpWidget(buildTarget());

    await tapTimes(tester, DeveloperModeService.requiredTaps - 1);
    await tester.pump(const Duration(seconds: 3));
    await tapTimes(tester, 1);

    expect(DeveloperModeService().isEnabled, isFalse);
  });

  testWidgets('tells the user when developer mode is already on',
      (tester) async {
    await DeveloperModeService().enable();
    await tester.pumpWidget(buildTarget());

    await tapTimes(tester, 1);

    expect(find.text('Developer mode is already on'), findsOneWidget);
  });
}
