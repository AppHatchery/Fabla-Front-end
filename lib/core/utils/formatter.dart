// import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/core/utils/dummy_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:tuple/tuple.dart';

import '../../screens/diary/data/options.dart';
import 'types.dart';

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

  // String hours = twoDigits(duration.inHours.remainder(24));
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));

  return "$minutes:$seconds";
}

/// Format the date to a [String] of hours and minutes
String formatDurationToHHMM(DateTime date) {
  return DateFormat('HH:mm').format(date);
}

/// Formats a given date into a human-readable history date string.
///
/// This function formats the provided date into a string representing a historical date,
/// indicating if the date is today, yesterday, or in the past using specific date formats.
///
/// Parameters:
/// - [date]: The DateTime object representing the date to be formatted.
///
/// Returns:
/// A formatted string representing the historical date.
String formatHistoryDate(DateTime date) {
  // Get the current date
  DateTime today =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  // Define date formatters
  final DateFormat formatterOne = DateFormat("MMMM d',' y");
  final DateFormat formatterTwo = DateFormat("EEEE - MMMM d',' y");

  // Check if the provided date is today
  if (today == DateTime(date.year, date.month, date.day)) {
    // Format today's date
    return "Today - ${formatterOne.format(date)}";
  }
  // Check if the provided date is yesterday
  else if (today.subtract(const Duration(days: 1)) ==
      DateTime(date.year, date.month, date.day)) {
    // Format yesterday's date
    return "Yesterday - ${formatterOne.format(date)}";
  }
  // If the provided date is neither today nor yesterday, format it using a different format
  else {
    return formatterTwo.format(date);
  }
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
// Tuple2<Color, Color> getColorFromString(String text) {
//   final List<Color> backgroundColor = [
//     CustomColors.yellowLight,
//     CustomColors.orangeLight,
//     CustomColors.purpleLight
//   ];

//   final List<Color> foregroundColor = [
//     CustomColors.yellowDark,
//     CustomColors.orangeDark,
//     CustomColors.purpleDark,
//   ];

//   final int hashCode = text.hashCode;
//   final int backgroundIndex = hashCode % backgroundColor.length;
//   final int foregroundIndex = hashCode % foregroundColor.length;

//   return Tuple2(
//       backgroundColor[backgroundIndex], foregroundColor[foregroundIndex]);
// }

/// Converts a DateTime into a formatted post date string.
///
/// This function takes a [date] in DateTime format and converts it into a
/// formatted string representing a post date. The date is formatted in a human-
/// readable style, including the full day of the week, day of the month, month,
/// and year.
///
/// Parameters:
/// - [date]: The DateTime representing the date for conversion.
///
/// Returns:
/// - A formatted date string, e.g., "Thursday, 25 August 2023".
///
/// Example usage:
/// ```dart
/// DateTime audioDate = DateTime(2023, 8, 25);
/// String formattedDate = getPostDate(audioDate);
/// // Output: "Thursday, 25 August 2023"
/// ```
String getPostDate(DateTime date) {
  final DateFormat formatter = DateFormat("EEEE-d-MMMM-y");
  return formatter.format(date);
}

/// Map that associates string representations of response types with their corresponding enum values.
final Map<String, ResponseType> _responseTypeMap = {
  'audio': ResponseType.recording,
  'text': ResponseType.text,
  'multiple': ResponseType.multiple,
  'radio': ResponseType.radio,
  'single': ResponseType.radio,
  'slider': ResponseType.slider,
};

/// Function that converts a string representation of a response type to its corresponding enum value.
/// Throws an exception if the provided string does not match any valid response type.
ResponseType responseTypeString(String value) {
  final responseType = _responseTypeMap[value.toLowerCase()];
  if (responseType == null) {
    throw Exception('Invalid response type');
  }
  return responseType;
}

/// Map of ResponseType enum values with their corresponding string representations
final Map<ResponseType, String> _responseStringMap = {
  ResponseType.recording: 'audio',
  ResponseType.text: 'text',
  ResponseType.multiple: 'multiple',
  ResponseType.radio: 'radio',
  ResponseType.slider: 'slider',
};

/// Function to convert ResponseType enum value to string
String responseTypeValue(ResponseType responseType) {
  final stringRepresentation = _responseStringMap[responseType];
  if (stringRepresentation == null) {
    throw Exception('Invalid response type');
  }
  return stringRepresentation;
}

OptionsType optionTypeFromResponse(ResponseType responseType) {
  switch (responseType) {
    case ResponseType.multiple:
      return OptionsType.multiple;
    case ResponseType.radio:
      return OptionsType.radio;
    default:
      return OptionsType.multiple;
  }
}

/// Convert String to TimeOfDay
TimeOfDay timeOfDayFromString(String value) {
  final parts = value.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

Color getColorFromName(String name) {
  int hash = name.hashCode;
  int index = hash % studyColors.length;
  return studyColors[index];
}
