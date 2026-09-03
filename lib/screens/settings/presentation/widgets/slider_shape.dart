// RoundedRectSliderTrackShape draws the active segment 2px taller than the
// inactive one by default; zeroing that out keeps both at `trackHeight`.
// Also paints a lighter inset highlight capsule over the active segment for
// a subtle glossy/3d look.
import 'package:flutter/material.dart';

class EqualHeightSliderTrackShape extends RoundedRectSliderTrackShape {
  const EqualHeightSliderTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      secondaryOffset: secondaryOffset,
      isDiscrete: isDiscrete,
      isEnabled: isEnabled,
      additionalActiveTrackHeight: 0,
    );

    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final activeRect = switch (textDirection) {
      TextDirection.ltr => Rect.fromLTRB(
          trackRect.left, trackRect.top, thumbCenter.dx, trackRect.bottom),
      TextDirection.rtl => Rect.fromLTRB(
          thumbCenter.dx, trackRect.top, trackRect.right, trackRect.bottom),
    };

    const inset = 6.0;
    final highlightHeight = trackRect.height * 0.4;
    final highlightTop = trackRect.top + trackRect.height * 0.18;
    final highlightRect = Rect.fromLTRB(
      activeRect.left + inset,
      highlightTop,
      activeRect.right - inset,
      highlightTop + highlightHeight,
    );
    if (highlightRect.width > 0) {
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(
            highlightRect, Radius.circular(highlightHeight / 2)),
        Paint()..color = Color(0xFFFFBF64),
      );
    }
  }
}
