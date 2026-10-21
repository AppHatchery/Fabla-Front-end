import 'package:flutter/painting.dart' show Size;
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Returns [value], or [fallback] if NaN/Infinity (scaleFontSize crash).
double safeFontSize(double value, {required double fallback}) =>
    isUsableFontSize(value) ? value : fallback;

bool isUsableFontSize(double value) => value.isFinite && value > 0;

/// False for a 0x0 first-frame size, which makes every `.sp` NaN/Infinity.
bool isValidDesignSize(double width, double height) =>
    width.isFinite && width > 0 && height.isFinite && height > 0;

/// The given size if valid, else [ScreenUtil.defaultSize].
Size resolveDesignSize(double width, double height) =>
    isValidDesignSize(width, height)
        ? Size(width, height)
        : ScreenUtil.defaultSize;

/// Like [FontSizeResolvers.width], but falls back to the design font size.
FontSizeResolver safeWidthFontSizeResolver(
    {void Function(double scaled, num fontSize)? onFallback}) {
  return (num fontSize, ScreenUtil instance) {
    final scaled = FontSizeResolvers.width(fontSize, instance);
    if (isUsableFontSize(scaled)) return scaled;
    onFallback?.call(scaled, fontSize);
    return fontSize.toDouble();
  };
}
