import 'package:flutter/material.dart';

class OnboardingScaledText extends StatelessWidget {
  final String data;
  final TextStyle style;
  final TextAlign? textAlign;

  const OnboardingScaledText(
    this.data, {
    super.key,
    required this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final fontSize = style.fontSize;
    return Text(
      data,
      textAlign: textAlign,
      textScaler: TextScaler.noScaling,
      style: fontSize == null
          ? style
          : style.copyWith(fontSize: scaler.scale(fontSize)),
    );
  }
}
