import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTypography {
  static const String fontName = 'Rubik';

  TextStyle headlineLargeCustom(
      {Color color = Colors.black, double fontSize = 32}) {
    return TextStyle(
      fontFamily: fontName,
      fontWeight: FontWeight.w600,
      fontSize: fontSize,
      color: color,
      letterSpacing: 0,
    );
  }

  TextStyle headlineLarge({Color color = Colors.black}) {
    return TextStyle(
      fontFamily: fontName,
      fontWeight: FontWeight.w600,
      fontSize: 32.sp,
      color: color,
      letterSpacing: 0,
    );
  }

  TextStyle headlineMedium({Color color = Colors.black}) {
    return TextStyle(
      fontFamily: fontName,
      fontWeight: FontWeight.w500,
      fontSize: 24.sp,
      color: color,
      letterSpacing: 0,
    );
  }

  TextStyle headlineSmall({Color color = Colors.black}) {
    return TextStyle(
      fontFamily: fontName,
      fontWeight: FontWeight.normal,
      fontSize: 24.sp,
      color: color,
      letterSpacing: 0,
    );
  }

  TextStyle titleLarge({Color color = Colors.black}) {
    return TextStyle(
      fontFamily: fontName,
      fontWeight: FontWeight.w500,
      fontSize: 20.sp,
      color: color,
      letterSpacing: 0,
    );
  }

  TextStyle titleMedium({Color color = Colors.black}) {
    return TextStyle(
      fontFamily: fontName,
      fontWeight: FontWeight.normal,
      fontSize: 20.sp,
      color: color,
      letterSpacing: 0,
    );
  }

  TextStyle titleSmall({Color color = Colors.black}) {
    return TextStyle(
      fontFamily: fontName,
      fontWeight: FontWeight.normal,
      fontSize: 18.sp,
      color: color,
      letterSpacing: 0,
    );
  }

  TextStyle titleSmallCustom({Color color = Colors.black}) {
    return TextStyle(
      fontFamily: fontName,
      fontWeight: FontWeight.w600,
      fontSize: 18.sp,
      color: color,
      letterSpacing: 0,
    );
  }

  TextStyle bodyLarge(
      {Color color = Colors.black, weight = FontWeight.normal}) {
    return TextStyle(
      fontFamily: fontName,
      fontWeight: weight,
      fontSize: 16.sp,
      color: color,
      letterSpacing: 0,
    );
  }

  TextStyle bodyMedium(
      {Color color = Colors.black, weight = FontWeight.normal}) {
    return TextStyle(
      fontFamily: fontName,
      fontWeight: weight,
      fontSize: 14.sp,
      color: color,
      letterSpacing: 0,
    );
  }

  TextStyle body({Color color = Colors.black}) {
    return TextStyle(
      fontFamily: fontName,
      fontWeight: FontWeight.normal,
      fontSize: 17.sp,
      color: color,
      letterSpacing: 0,
    );
  }

  TextStyle bodyLight({Color color = Colors.grey}) {
    return TextStyle(
      fontFamily: fontName,
      fontWeight: FontWeight.normal,
      fontSize: 15.sp,
      color: color,
      letterSpacing: 0,
    );
  }

  TextStyle title({Color color = Colors.black}) {
    return TextStyle(
      fontFamily: fontName,
      fontWeight: FontWeight.w500,
      fontSize: 14.sp,
      color: color,
      letterSpacing: 0,
    );
  }

  TextStyle titleRegular({Color color = Colors.black}) {
    return TextStyle(
      fontFamily: fontName,
      fontWeight: FontWeight.normal,
      fontSize: 14.sp,
      color: color,
      letterSpacing: 0,
    );
  }

  TextStyle button({Color color = Colors.black}) {
    return TextStyle(
      fontFamily: fontName,
      fontWeight: FontWeight.w500,
      fontSize: 16.sp,
      color: color,
      letterSpacing: 0,
    );
  }

  TextStyle caption({Color color = Colors.black}) {
    return TextStyle(
      fontFamily: fontName,
      fontWeight: FontWeight.normal,
      fontSize: 12.sp,
      color: color,
      letterSpacing: 0,
    );
  }
}
