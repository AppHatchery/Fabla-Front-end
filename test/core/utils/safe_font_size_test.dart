import 'package:flutter/widgets.dart' show MediaQueryData, Size;

import 'package:audio_diaries_flutter/core/utils/safe_font_size.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const badValues = [
    double.nan,
    double.infinity,
    double.negativeInfinity,
    0.0,
    -4.0,
  ];

  group('safeFontSize', () {
    test('passes through finite positive values', () {
      expect(safeFontSize(16, fallback: 12), 16);
    });

    test('uses fallback for NaN, infinity, zero and negatives', () {
      for (final bad in badValues) {
        expect(safeFontSize(bad, fallback: 12), 12, reason: '$bad');
      }
    });
  });

  group('resolveDesignSize', () {
    test('uses the given size when valid', () {
      expect(resolveDesignSize(390, 844), const Size(390, 844));
    });

    test('falls back to ScreenUtil.defaultSize for unusable sizes', () {
      for (final bad in badValues) {
        expect(resolveDesignSize(bad, 844), ScreenUtil.defaultSize,
            reason: 'width $bad');
        expect(resolveDesignSize(390, bad), ScreenUtil.defaultSize,
            reason: 'height $bad');
      }
    });
  });

  group('safeWidthFontSizeResolver', () {
    tearDown(() => ScreenUtil.configure(
        minTextAdapt: true,
        splitScreenMode: false,
        designSize: ScreenUtil.defaultSize,
        fontSizeResolver: FontSizeResolvers.width));

    test('matches FontSizeResolvers.width for a valid size', () {
      ScreenUtil.configure(
          minTextAdapt: true,
          splitScreenMode: false,
          data: const MediaQueryData(size: Size(390, 844)),
          designSize: const Size(390, 844));
      final resolver = safeWidthFontSizeResolver();
      expect(resolver(16, ScreenUtil()), 16);
    });

    test('falls back to the design font size when the screen is 0x0', () {
      ScreenUtil.configure(
          minTextAdapt: true,
          splitScreenMode: false,
          data: const MediaQueryData(size: Size.zero),
          designSize: Size.zero);
      // Unguarded, 0 / 0 makes the scale NaN.
      expect(FontSizeResolvers.width(16, ScreenUtil()).isNaN, isTrue);

      final calls = <double>[];
      final resolver =
          safeWidthFontSizeResolver(onFallback: (s, _) => calls.add(s));
      expect(resolver(16, ScreenUtil()), 16);
      expect(calls, hasLength(1));
    });

    test('falls back when only the design size is zero', () {
      ScreenUtil.configure(
          minTextAdapt: true,
          splitScreenMode: false,
          data: const MediaQueryData(size: Size(390, 844)),
          designSize: Size.zero);
      expect(safeWidthFontSizeResolver()(16, ScreenUtil()), 16);
    });
  });
}
