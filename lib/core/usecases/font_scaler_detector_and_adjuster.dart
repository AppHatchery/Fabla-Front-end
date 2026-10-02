import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';

Future<TextScaler> fontScaler(BuildContext context) async {
  final scaler = MediaQuery.of(context).textScaler;
  return scaler;
}

//fine control the scaling
double getTitleFontSize({
  required double textScale,
  required double iosThreshold,
  required double iosFontSize,
  required double androidThreshold,
  required double androidFontSize,
  required double defaultSize,
}) {
  if (Platform.isIOS && textScale >= iosThreshold) {
    return iosFontSize;
  }

  if (Platform.isAndroid && textScale >= androidThreshold) {
    return androidFontSize;
  }

  return defaultSize;
}

// clamp to avoid extreme large font and let flutter handle the scaling
TextScaler getAdaptiveTextScaler(BuildContext context) {
  final maxScaleFactor = Platform.isIOS ? 2.0 : 1.5;

  return MediaQuery.textScalerOf(context).clamp(
    minScaleFactor: 1.0,
    maxScaleFactor: maxScaleFactor,
  );
}


