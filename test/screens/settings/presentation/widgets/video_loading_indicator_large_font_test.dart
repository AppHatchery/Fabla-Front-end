import 'package:audio_diaries_flutter/screens/settings/presentation/widgets/video_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _animationKey = Key('animation');

/// Pumps the loading layout, with a plain box standing in for the Rive
/// animation, into a slot [slotHeight] tall (like the quick-start modal's
/// video area) at [textScale]. Returns any layout errors.
Future<List<FlutterErrorDetails>> pumpLayout(
  WidgetTester tester, {
  required double slotHeight,
  required double textScale,
}) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final errors = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = errors.add;
  try {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: Scaffold(
                body: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: slotHeight,
                    child: VideoLoadingLayout(
                      animationBuilder: (_) =>
                          const ColoredBox(key: _animationKey, color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

void main() {
  // 40pt is about what the quick-start modal's "Need Help Later?" view
  // leaves for the video on a small phone at 2x text; 600pt is a full screen.
  const slotHeights = [40.0, 150.0, 300.0, 600.0];
  const scales = [1.0, 2.0, 3.1];

  for (final slot in slotHeights) {
    for (final scale in scales) {
      testWidgets(
          'VideoLoadingLayout fits a ${slot.toInt()}pt slot at ${scale}x text',
          (tester) async {
        final errors =
            await pumpLayout(tester, slotHeight: slot, textScale: scale);
        expect(errors.map((e) => e.exceptionAsString()), isEmpty);
        expect(find.text(VideoLoadingLayout.title), findsOneWidget);

        final animation = find.byKey(_animationKey);
        if (animation.evaluate().isNotEmpty) {
          final height = tester.getSize(animation).height;
          expect(height, lessThanOrEqualTo(VideoLoadingLayout.animationHeight));
          expect(height,
              greaterThanOrEqualTo(VideoLoadingLayout.minAnimationHeight));
        }
      });
    }
  }

  testWidgets('full-screen at normal text keeps the 210pt animation',
      (tester) async {
    await pumpLayout(tester, slotHeight: 600, textScale: 1.0);
    expect(tester.getSize(find.byKey(_animationKey)).height,
        VideoLoadingLayout.animationHeight);
  });

  testWidgets('a tiny slot drops the animation and keeps the text',
      (tester) async {
    await pumpLayout(tester, slotHeight: 40, textScale: 2.0);
    expect(find.byKey(_animationKey), findsNothing);
    expect(find.text(VideoLoadingLayout.title), findsOneWidget);
  });
}
