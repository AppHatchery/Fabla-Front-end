import 'package:flutter/material.dart';

import '../../core/usecases/font_scaler_detector_and_adjuster.dart';
import '../custom_colors.dart';
import '../custom_typography.dart';

/// Image, title and message shown when a list has nothing in it.
///
/// Works in both places empty states appear:
/// - Given a bounded height (it replaces a list, e.g. diary history), it
///   fills that height, stays vertically centred, and scrolls by itself when
///   large text makes it taller than the space.
/// - Given unbounded height (inside a page that already scrolls, e.g. home
///   or the calendar), it is a plain column and the page does the scrolling.
///   A scroll view there would throw "unbounded height" and blank the page.
///
/// The title and message grow with the system font size up to the
/// [getAdaptiveTextScaler] cap.
class EmptyStateLayout extends StatelessWidget {
  final String imageAsset;
  final double imageHeight;
  final String title;
  final TextStyle titleStyle;
  final String message;

  const EmptyStateLayout({
    super.key,
    required this.imageAsset,
    this.imageHeight = 108,
    required this.title,
    required this.titleStyle,
    required this.message,
  });

  static const _padding = EdgeInsets.symmetric(horizontal: 47);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (!constraints.hasBoundedHeight) {
        return Padding(
            padding: _padding, child: _content(context, MainAxisSize.min));
      }
      return SingleChildScrollView(
        padding: _padding,
        child: ConstrainedBox(
          // At least the full height, so the content stays centred when it
          // fits; it grows past this and scrolls at large font sizes.
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: _content(context, MainAxisSize.max),
        ),
      );
    });
  }

  Widget _content(BuildContext context, MainAxisSize size) {
    final scaler = getAdaptiveTextScaler(context);
    return Column(
      mainAxisSize: size,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(imageAsset, height: imageHeight),
        const SizedBox(height: 16),
        Text(
          title,
          textScaler: scaler,
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textScaler: scaler,
          style: CustomTypography()
              .bodyMedium(color: CustomColors.textTertiaryContent),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
