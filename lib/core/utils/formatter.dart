// import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/core/utils/dummy_data.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:tuple/tuple.dart';

import '../../screens/diary/data/options.dart';
import 'types.dart';

String twoDigits(int n) => n.toString().padLeft(2, "0");

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

/// Returns: Month/Day/Year
String formatDateOnly(DateTime date) {
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  return formatter.format(date);
}

/// Reverses the top function
DateTime stringDateOnlyToDateTime(String date) {
  List<String> dateParts = date.split('-');

  // Parse the month, day, and year as integers
  int year = int.parse(dateParts[0]);
  int month = int.parse(dateParts[1]);
  int day = int.parse(dateParts[2]);

  // Create a new DateTime object with just the date components
  // Time will be set to 00:00:00
  return DateTime(year, month, day, 0, 0, 0, 0);
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
  // String hours = twoDigits(duration.inHours.remainder(24));
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));

  return "$minutes:$seconds";
}

/// Format the date to a [String] of hours and minutes
String formatDurationToHHMM(DateTime date) {
  return DateFormat('HH:mm').format(date);
}

/// Format the date to a [String] of hours and minutes
String formatDurationToHHMMPP(DateTime date) {
  return DateFormat('hh:mm a').format(date);
}

Duration formatStringToDuration(String time) {
  List<String> parts =
      time.split(":"); // Split the string into minutes and seconds
  int hours = int.parse(parts[0]); // Parse the hours
  int minutes = int.parse(parts[1]); // Parse the minutes
  int seconds = int.parse(parts[2]); // Parse the seconds

  return Duration(hours: hours, minutes: minutes, seconds: seconds);
}

/// Returns ONLY the minutes of the duration
String formatDurationMMOnly(Duration duration) {
  return twoDigits(duration.inMinutes.remainder(60));
}

/// Returns ONLY the seconds of the Duration
String formatDurationSSOnly(Duration duration) {
  return twoDigits(duration.inSeconds.remainder(60));
}

/// Formats a duration into a string representation.
String formatDurationToString(Duration duration) {
  // Get hours directly
  int hours = duration.inHours;

  // Get minutes (modulo 60 to get just the minutes part)
  int minutes = duration.inMinutes.remainder(60);

  // Get seconds (modulo 60 to get just the seconds part)
  int seconds = duration.inSeconds.remainder(60);

  // Format each component to ensure 2 digits with leading zeros
  String hoursStr = hours.toString().padLeft(2, '0');
  String minutesStr = minutes.toString().padLeft(2, '0');
  String secondsStr = seconds.toString().padLeft(2, '0');

  return '$hoursStr:$minutesStr:$secondsStr';
}

// Returns Mintues and Seconds only

String formatMinsAndSecs(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final m = twoDigits(d.inMinutes.remainder(60));
  final s = twoDigits(d.inSeconds.remainder(60));
  return "$m:$s";
}

String formatDiaryCardDue(DateTime due, DateTime start, DiaryStatus status) {
  final now = DateTime.now();
  final difference = due.difference(now).inHours;

  final dateFormat = DateFormat("MMM d',' y");
  if (status == DiaryStatus.submitted) {
    return "Submitted";
  } else if (start.isAfter(now)) {
    return "Opens at: ${formatDurationToHHMMPP(start)}";
  } else if (now.isAfter(due) && difference < -24) {
    return "Closed on: ${dateFormat.format(due)}";
  } else if (now.isAfter(due)) {
    return "Closed at: ${formatDurationToHHMMPP(due)}";
  } else if (difference >= 24) {
    return "Available until: ${dateFormat.format(due)}";
  } else {
    return "Available until: ${formatDurationToHHMMPP(due)}";
  }
}

String formatDiaryDueSubmission(DateTime date) {
  final format = DateFormat("MMM d',' y · hh:mm a");

  return format.format(date);
}

// First element is Background
// Second element is Text Color
List<Color> formatDiaryCardDueColors(
    DateTime due, DateTime start, DiaryStatus status, bool optional) {
  final now = DateTime.now();
  final difference = due.difference(now).inHours;

  // when the diary is due in 2 hr display the due time label in red
  // when the diary is due today but due time is more than 2h from now, display this label in yellow
  // when the diary is not due today or is optional, display the due time label with a transparent background
  if (status == DiaryStatus.submitted) {
    return [CustomColors.darkGreen, CustomColors.textWhite];
  } else if (start.isAfter(now) || now.isAfter(due)) {
    return [CustomColors.fillDisabled, CustomColors.midGrey];
  } else if (difference >= 24 || optional) {
    return [Colors.transparent, CustomColors.ashGrey];
  } else if (difference >= 2) {
    return [CustomColors.tangerine, CustomColors.textWhite];
  } else {
    return [CustomColors.warningActive, CustomColors.textWhite];
  }
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
  'audio': ResponseType.audio,
  'text': ResponseType.text,
  'textaudio': ResponseType.textAudio,
  'multiple': ResponseType.multiple,
  'radio': ResponseType.radio,
  'single': ResponseType.radio,
  'slider': ResponseType.slider,
  'webview': ResponseType.webview,
  'timer': ResponseType.timer,
  'visualResponse-image': ResponseType.image,
  'visualResponse-video': ResponseType.video,
  'visualResponse-imageVideo': ResponseType.imageVideo,
  'instruction': ResponseType.instruction,
  'image': ResponseType.mediaImage,
  'video': ResponseType.mediaVideo,
  'psychomotor': ResponseType.psychomotor,
  'timePicker': ResponseType.timePicker
};

/// Function that converts a string representation of a response type to its corresponding enum value.
/// Throws an exception if the provided string does not match any valid response type.
ResponseType responseTypeString(String value) {
  final responseType = _responseTypeMap[value];
  if (responseType == null) {
    throw Exception('Invalid response type: $value');
  }
  return responseType;
}

/// Map of ResponseType enum values with their corresponding string representations
final Map<ResponseType, String> _responseStringMap = {
  ResponseType.audio: 'audio',
  ResponseType.text: 'text',
  ResponseType.textAudio: 'textaudio',
  ResponseType.multiple: 'multiple',
  ResponseType.radio: 'radio',
  ResponseType.slider: 'slider',
  ResponseType.webview: 'webview',
  ResponseType.timer: 'timer',
  ResponseType.image: 'visualResponse-image',
  ResponseType.video: 'visualResponse-video',
  ResponseType.imageVideo: 'visualResponse-imageVideo',
  ResponseType.instruction: 'instruction',
  ResponseType.mediaImage: 'image',
  ResponseType.mediaVideo: 'video',
  ResponseType.psychomotor: 'psychomotor',
  ResponseType.timePicker: 'timePicker'
};

/// Function to convert ResponseType enum value to string
String responseTypeValue(ResponseType? responseType) {
  final value = _responseStringMap[responseType];
  if (value == null) {
    dev.log('Unmapped responseType: $responseType', name: 'Formatter');
    CrashlyticsService().log('Unmapped responseType: $responseType');
  }
  return value ?? 'unknown';
}

OptionsType optionTypeFromResponse(ResponseType? responseType) {
  switch (responseType) {
    case ResponseType.multiple:
      return OptionsType.multiple;
    case ResponseType.radio:
      return OptionsType.radio;
    default:
      return OptionsType.multiple;
  }
}

String optionTypeToString(OptionsType type) {
  switch (type) {
    case OptionsType.multiple:
      return 'multiple';
    case OptionsType.radio:
      return 'radio';
    case OptionsType.slider:
      return 'slider';
  }
}

/// Capitalizes the first letter of a given string.
String capitalizeFirstLetter(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

String formatMoney(double amount, {String? currency}) {
  final formatter = NumberFormat.currency(
    decimalDigits: 2,
    symbol: currency ?? '',
  );
  return formatter.format(amount);
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

Future<Color> getColorFromSharedPreferences(String name) async {
  final pref = PreferenceService();
  final source = await pref.getStringPreference(key: 'study_color_source');
  final Map<String, String> data =
      source != null ? Map<String, String>.from(json.decode(source)) : {};

  return data.containsKey(name)
      ? Color(int.parse(data[name]!, radix: 16))
      : CustomColors.productNormal;
}

/// FORMATS
/// [** text **] -> bold
/// [__ text __] -> underline
/// [~~ text ~~] -> italic
/// [**__ text __**] -> bold and underline
/// [**~~ text ~~**] -> bold and italic
/// [__~~ text ~~__] -> underline and italic
/// [<h1> text </h1>] -> heading 1
/// [<h2> text </h2>] -> heading 2
/// [<h3> text </h3>] -> heading 3
/// [>*] -> indentation (* space replace the * with a number)
/// [\\n] -> line break
class CustomFormatterText extends StatelessWidget {
  final String text;

  const CustomFormatterText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: CustomTypography().bodyMedium(), // Default text style
        children: _formatText(text),
      ),
    );
  }

  List<TextSpan> _formatText(String text) {
    // Handle line breaks
    text = text.replaceAll(r'\\n', '\n');

    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(
        r'(>[0-9]+|<h1>.*?<\/h1>|<h2>.*?<\/h2>|<h3>.*?<\/h3>|\*\*__.*?__\*\*|__\*\*.*?\*\*__|\*\*~~.*?~~\*\*|~~\*\*.*?\*\*~~|__~~.*?~~__|~~__.*?__~~|\*\*.*?\*\*|__.*?__|~~.*?~~)');
    final matches = regExp.allMatches(text);

    int start = 0;

    for (final match in matches) {
      // Add text before the match
      if (match.start > start) {
        spans.addAll(_handleLineBreaks(text.substring(start, match.start)));
      }

      String matchText = match.group(0)!;

      // Indentation
      if (matchText.startsWith('>') && RegExp(r'>[0-9]+').hasMatch(matchText)) {
        int indentLevel = int.tryParse(matchText.substring(1)) ?? 0;
        spans.add(TextSpan(
          text: ' ' * indentLevel, // Add spaces for indentation
        ));
      }
      // Heading 1
      else if (matchText.startsWith('<h1>') && matchText.endsWith('</h1>')) {
        spans.add(TextSpan(
          text: matchText.substring(4, matchText.length - 5),
          style: CustomTypography().titleLarge(),
        ));
      }
      // Heading 2
      else if (matchText.startsWith('<h2>') && matchText.endsWith('</h2>')) {
        spans.add(TextSpan(
          text: matchText.substring(4, matchText.length - 5),
          style: CustomTypography().titleMedium(),
        ));
      }
      // Heading 3
      else if (matchText.startsWith('<h3>') && matchText.endsWith('</h3>')) {
        spans.add(TextSpan(
          text: matchText.substring(4, matchText.length - 5),
          style: CustomTypography().titleSmall(),
        ));
      }
      // Bold and Underline
      else if (matchText.startsWith('**__') && matchText.endsWith('__**')) {
        spans.add(TextSpan(
          text: matchText.substring(4, matchText.length - 4),
          style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline),
        ));
      }
      // Underline and Bold
      else if (matchText.startsWith('__**') && matchText.endsWith('**__')) {
        spans.add(TextSpan(
          text: matchText.substring(4, matchText.length - 4),
          style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline),
        ));
      }
      // Bold and Italics
      else if (matchText.startsWith('**~~') && matchText.endsWith('~~**')) {
        spans.add(TextSpan(
          text: matchText.substring(4, matchText.length - 4),
          style: TextStyle(
              fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
        ));
      }
      // Italics and Bold
      else if (matchText.startsWith('~~**') && matchText.endsWith('**~~')) {
        spans.add(TextSpan(
          text: matchText.substring(4, matchText.length - 4),
          style: TextStyle(
              fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
        ));
      }
      // Underline and Italics
      else if (matchText.startsWith('__~~') && matchText.endsWith('~~__')) {
        spans.add(TextSpan(
          text: matchText.substring(4, matchText.length - 4),
          style: TextStyle(
              decoration: TextDecoration.underline,
              fontStyle: FontStyle.italic),
        ));
      }
      // Italics and Underline
      else if (matchText.startsWith('~~__') && matchText.endsWith('__~~')) {
        spans.add(TextSpan(
          text: matchText.substring(4, matchText.length - 4),
          style: TextStyle(
              decoration: TextDecoration.underline,
              fontStyle: FontStyle.italic),
        ));
      }
      // Bold
      else if (matchText.startsWith('**') && matchText.endsWith('**')) {
        spans.add(TextSpan(
          text: matchText.substring(2, matchText.length - 2),
          style: TextStyle(fontWeight: FontWeight.bold),
        ));
      }
      // Underline
      else if (matchText.startsWith('__') && matchText.endsWith('__')) {
        spans.add(TextSpan(
          text: matchText.substring(2, matchText.length - 2),
          style: TextStyle(decoration: TextDecoration.underline),
        ));
      }
      // Italics
      else if (matchText.startsWith('~~') && matchText.endsWith('~~')) {
        spans.add(TextSpan(
          text: matchText.substring(2, matchText.length - 2),
          style: TextStyle(fontStyle: FontStyle.italic),
        ));
      }

      start = match.end;
    }

    // Add remaining text after the last match
    if (start < text.length) {
      spans.addAll(_handleLineBreaks(text.substring(start)));
    }

    return spans;
  }

  // Function to handle line breaks by splitting text on '\n' and adding a new line
  List<TextSpan> _handleLineBreaks(String text) {
    List<TextSpan> spans = [];
    List<String> lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      spans.add(TextSpan(text: lines[i]));
      if (i < lines.length - 1) {
        spans.add(TextSpan(text: '\n')); // Add a line break
      }
    }

    return spans;
  }
}
