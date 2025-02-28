import 'package:audio_diaries_flutter/core/utils/formatter.dart';

class Options {
  OptionsType type;
  // Radio & Multiple Choice
  List<String>? choices;
  //Slider
  String? minLabel;
  String? maxLabel;
  int? minValue;
  int? maxValue;
  int? defaultValue;
  //Audio & Video Variables
  Duration? suggestedLength;
  Duration? maxLength;
  bool? displayTime;
  //WebView
  String? link;
  //Timer
  Duration? timerLength;
  bool? userInteraction;
  bool? playbackControl;
  //Psychomotor
  int? stimuli;
  Duration? length;

  Options(
      {required this.type,
      this.choices,
      this.minLabel = "",
      this.maxLabel = "",
      this.minValue,
      this.maxValue,
      this.defaultValue,
      this.suggestedLength,
      this.maxLength,
      this.displayTime,
      this.link,
      this.timerLength,
      this.userInteraction,
      this.playbackControl,
      this.stimuli,
      this.length});

  factory Options.fromJson(
    Map<String, dynamic> json,
  ) {
    return Options(
      type: optionTypeFromResponse(responseTypeString(json['type'])),
      choices:
          json['options'] != null ? List<String>.from(json['options']) : null,
      minLabel: json['min_label'] ?? "",
      maxLabel: json['max_label'] ?? "",
      minValue: json['min_value'],
      maxValue: json['max_value'],
      defaultValue: json['default_value'],
      maxLength: json['max_length'] != null &&
              (json['max_length'] as String).isNotEmpty
          ? formatStringToDuration(json['max_length'])
          : null,
      suggestedLength: json['suggested_length'] != null &&
              (json['suggested_length'] as String).isNotEmpty
          ? formatStringToDuration(json['suggested_length'])
          : null,
      displayTime: json['display_time'],
      link: json['link'],
      timerLength: json['timer_length'] != null &&
              (json['timer_length'] as String).isNotEmpty
          ? formatStringToDuration(json['timer_length'])
          : null,
      userInteraction: json['user_interaction'],
      playbackControl: json['playback_control'],
      stimuli: json['number_of_stimulus'],
      length: json['length'] != null && (json['length'] as String).isNotEmpty
          ? formatStringToDuration(json['length'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': optionTypeToString(type),
      'options': choices,
      'min_label': minLabel,
      'max_label': maxLabel,
      'min_value': minValue,
      'max_value': maxValue,
      'default_value': defaultValue,
      'max_length':
          maxLength != null ? formatDurationToString(maxLength!) : null,
      'suggested_length': suggestedLength != null
          ? formatDurationToString(suggestedLength!)
          : null,
      'display_time': displayTime,
      'link': link,
      'timer_length':
          timerLength != null ? formatDurationToString(timerLength!) : null,
      'user_interaction': userInteraction,
      'playback_control': playbackControl,
      'number_of_stimulus': stimuli,
      'length': length != null ? formatDurationToString(length!) : null
    };
  }
}

/// It checks whether the option is an integer.
bool isInt(String option) {
  return int.tryParse(option) != null;
}

enum OptionsType {
  multiple,
  radio,
  slider,
}
