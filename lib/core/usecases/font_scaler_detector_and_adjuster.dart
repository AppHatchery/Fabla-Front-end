import 'dart:io';

import 'package:flutter/material.dart';

Future<TextScaler> fontScaler(BuildContext context) async {
  final scaler = MediaQuery.of(context).textScaler;
  return scaler;
}


// clamp to avoid extreme large font and let flutter handle the scaling
TextScaler getAdaptiveTextScaler(BuildContext context) {
  final maxScaleFactor = Platform.isIOS ? 2.0 : 1.5;

  return MediaQuery.textScalerOf(context).clamp(
    minScaleFactor: 0.8,
    maxScaleFactor: maxScaleFactor,
  );
}

/// Applies [getAdaptiveTextScaler]'s cap to everything below it, so every
/// Text and text-scaling Icon in a component grows with the system font size
/// but never past what its layout is sized for.
class AdaptiveTextScaleScope extends StatelessWidget {
  final Widget child;
  const AdaptiveTextScaleScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: getAdaptiveTextScaler(context)),
      child: child,
    );
  }
}

/// A [Text] that grows with the system font size but never breaks a word
/// across lines: it measures the width it is given and applies
/// [getWordSafeTextScaler] for it.
///
/// Cost per build is O(w) text layouts for w words (plus up to 10 re-measures
/// when shrinking), which is fine for short labels such as answer options.
class WordSafeText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  const WordSafeText(this.text,
      {super.key, required this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Text(
        text,
        style: style,
        textAlign: textAlign,
        textScaler:
            getWordSafeTextScaler(context, text, style, constraints.maxWidth),
      ),
    );
  }
}

/// Like getAdaptiveTextScaler, but caps the scale so the widest single word
/// in [text] fits in [maxWidth]. Stops headlines breaking mid-word.
TextScaler getWordSafeTextScaler(
  BuildContext context,
  String text,
  TextStyle style,
  double maxWidth,
) {
  // Measure with the same merged style the Text widget will paint with.
  final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
  final words = text.split(RegExp(r'\s+'));

  double widestWord(TextScaler scaler) {
    double widest = 0;
    for (final word in words) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: effectiveStyle),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    return widest;
  }

  final base = getAdaptiveTextScaler(context);
  final widest = widestWord(base);
  if (widest <= maxWidth) return base;

  final fontSize = effectiveStyle.fontSize ?? 14;
  var factor = base.scale(fontSize) / fontSize * maxWidth / widest;
  // Glyph widths don't scale exactly in proportion to font size, so the
  // estimate can still be a hair too wide. Re-measure and step down until
  // the widest word really fits.
  for (var i = 0; i < 10; i++) {
    if (widestWord(TextScaler.linear(factor)) <= maxWidth) break;
    factor *= 0.97;
  }
  return TextScaler.linear(factor);
}
