import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

/// Formats a DateTime object into a string representation with a specific format.
/// This function converts a given DateTime value into a formatted string following the pattern 'yyyy-MM-dd-HH-mm-ss'.
///
/// Parameters:
/// - [dateTime]: The DateTime object to be formatted.
///
/// Returns:
/// A formatted string representing the provided DateTime value.
///
String formatDate(DateTime dateTime) {
  final DateFormat formatter = DateFormat('yyyy-MM-dd-HH-mm-ss');
  return formatter.format(dateTime);
}

/// Formats a DateTime object into a short string representation with time.
/// This function converts a given DateTime value into a formatted string containing the abbreviated time following the pattern 'HH-mm AM'.
///
/// Parameters:
/// - [dateTime]: The DateTime object to be formatted.
///
/// Returns:
/// A short formatted string representing the provided DateTime
///
String formatDateShort(DateTime dateTime) {
  final DateFormat formatter = DateFormat().add_jm();
  return formatter.format(dateTime);
}

/// Formats a duration in milliseconds into a human-readable time format.
/// This function converts a given duration in milliseconds into a formatted string that represents the duration as hours, minutes, and seconds.
///
/// Parameters:
/// - [milli]: The duration in milliseconds to be formatted.
///
/// Returns:
/// A formatted string representing the provided duration in hours, minutes, and seconds.
///
String formatDuration(int milli) {
  Duration duration = Duration(milliseconds: milli);

  String twoDigits(int n) => n.toString().padLeft(2, "0");

  return duration.inHours > 0
      ? "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}"
      : "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";
}

/// Formats a duration in milliseconds into a human-readable time format.
/// This function converts a given duration in milliseconds into a formatted string that represents the duration as hours, minutes, and seconds.
///
/// Parameters:
/// - [duaration]: The duration to be formatted.
///
/// Note:
/// - Used for the timer on the bottom recording dialog
///
/// Returns:
/// A formatted string representing the provided duration in hours, minutes, and seconds.
///
String formatDurationtoHHMMSS(Duration duration) {
  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String hours = twoDigits(duration.inHours.remainder(24));
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));

  return "$hours:$minutes:$seconds";
}

/// Retrieves a pair of colors based on a given text, ensuring consistency.
/// This function calculates color indices from the hash code of the input text and maps them to predefined background and foreground color lists.
///
/// Parameters:
/// - [text]: The input text for which colors are to be determined.
///
/// Returns:
/// A Tuple2<Color, Color> representing a pair of background and foreground colors selected based on the input text's hash code.
///
Tuple2<Color, Color> getColorFromString(String text) {
  final List<Color> backgroundColor = [
    CustomColors.yellowLight,
    CustomColors.orangeLight,
    CustomColors.purpleLight
  ];

  final List<Color> foregroundColor = [
    CustomColors.yellowDark,
    CustomColors.orangeDark,
    CustomColors.purpleDark,
  ];

  final int hashCode = text.hashCode;
  final int backgroundIndex = hashCode % backgroundColor.length;
  final int foregroundIndex = hashCode % foregroundColor.length;

  return Tuple2(
      backgroundColor[backgroundIndex], foregroundColor[foregroundIndex]);
}
