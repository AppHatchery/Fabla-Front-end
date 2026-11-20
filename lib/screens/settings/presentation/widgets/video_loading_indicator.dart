import 'dart:math' as math;

import 'package:audio_diaries_flutter/core/usecases/font_scaler_detector_and_adjuster.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class VideoLoadingIndicator extends StatefulWidget {
  const VideoLoadingIndicator({super.key});

  @override
  State<VideoLoadingIndicator> createState() => _VideoLoadingIndicatorState();
}

class _VideoLoadingIndicatorState extends State<VideoLoadingIndicator> {
  File? _riveFile;
  RiveWidgetController? _riveController;

  Future<void> _initAnimation() async {
    final riveFile = await File.asset(
        "assets/animations/fabla_video_loader.riv",
        riveFactory: Factory.rive);
    if (riveFile == null || !mounted) return;

    setState(() {
      _riveFile = riveFile;
      _riveController = RiveWidgetController(
        riveFile,
        // stateMachineSelector: StateMachineSelector.byName('State Machine 1'));
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  @override
  void dispose() {
    _riveFile?.dispose();
    _riveController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _riveController;
    return VideoLoadingLayout(
      animationBuilder: controller == null
          ? null
          : (height) => RiveWidget(
                controller: controller,
                // Fill the width at full height, as before; when squeezed,
                // show the whole animation smaller instead of cropping it.
                fit: height < VideoLoadingLayout.animationHeight
                    ? Fit.contain
                    : Fit.fitWidth,
              ),
    );
  }
}

/// The loading indicator's layout, kept apart from the Rive animation so it
/// can be tested without the Rive native library.
///
/// It often sits in whatever space a screen has left (the quick-start
/// modal's video slot). The text always shows; the animation gets the height
/// left over, up to its usual 210pt, and is dropped when too little is left
/// to be worth showing. It scrolls only if even the text is too tall.
class VideoLoadingLayout extends StatelessWidget {
  /// Builds the animation at the given height; null while it loads.
  final Widget Function(double height)? animationBuilder;

  const VideoLoadingLayout({super.key, this.animationBuilder});

  static const title = 'Getting your video ready';
  static const subtitle = 'Fabio’s lining up the shot.';
  static const animationHeight = 210.0;
  static const minAnimationHeight = 60.0;
  static const _gap = 24.0;
  static const _textGap = 12.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.widthOf(context);
    final titleStyle = CustomTypography().headlineMedium();
    final subtitleStyle = CustomTypography().bodyLarge();

    return AdaptiveTextScaleScope(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: LayoutBuilder(builder: (context, constraints) {
          final textHeight =
              _textHeight(context, title, titleStyle, constraints.maxWidth) +
                  _textGap +
                  _textHeight(
                      context, subtitle, subtitleStyle, constraints.maxWidth);
          final height = constraints.hasBoundedHeight
              ? math.min(
                  animationHeight, constraints.maxHeight - textHeight - _gap)
              : animationHeight;
          final builder = animationBuilder;
          final showAnimation = builder != null && height >= minAnimationHeight;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    constraints.hasBoundedHeight ? constraints.maxHeight : 0,
              ),
              child: Column(
                spacing: _gap,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showAnimation)
                    SizedBox(
                      height: height,
                      width: width,
                      child: builder(height),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: _textGap,
                    children: [
                      Text(title,
                          style: titleStyle, textAlign: TextAlign.center),
                      Text(subtitle,
                          style: subtitleStyle, textAlign: TextAlign.center),
                    ],
                  )
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Height [text] takes when wrapped to [maxWidth], as the Text widget
  /// above lays it out.
  static double _textHeight(BuildContext context, String text,
      TextStyle style, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(
          text: text, style: DefaultTextStyle.of(context).style.merge(style)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);
    final height = painter.height;
    painter.dispose();
    return height;
  }
}
