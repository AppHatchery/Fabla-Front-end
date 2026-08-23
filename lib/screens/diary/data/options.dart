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
  //Affect Grid (v4): one label per edge, each shown with a directional arrow
  //pointing toward the grid. See docs/affect_grid_versions.md for the
  //version history of this question type.
  String? axisTopLabel;
  String? axisBottomLabel;
  String? axisLeftLabel;
  String? axisRightLabel;
  //Audio & Video Variables
  Duration? suggestedLength;
  Duration? maxLength;
  bool? displayTime;
  bool? multipleAnswers;
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
      this.axisTopLabel,
      this.axisBottomLabel,
      this.axisLeftLabel,
      this.axisRightLabel,
      this.suggestedLength,
      this.maxLength,
      this.displayTime,
      this.multipleAnswers,
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
      axisTopLabel: json['axis_top_label'],
      axisBottomLabel: json['axis_bottom_label'],
      axisLeftLabel: json['axis_left_label'],
      axisRightLabel: json['axis_right_label'],
      maxLength: json['max_length'] != null &&
              (json['max_length'] as String).isNotEmpty
          ? formatStringToDuration(json['max_length'])
          : null,
      suggestedLength: json['suggested_length'] != null &&
              (json['suggested_length'] as String).isNotEmpty
          ? formatStringToDuration(json['suggested_length'])
          : null,
      displayTime: json['display_time'],
      multipleAnswers: json['multiple_answers'],
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
      'axis_top_label': axisTopLabel,
      'axis_bottom_label': axisBottomLabel,
      'axis_left_label': axisLeftLabel,
      'axis_right_label': axisRightLabel,
      'max_length':
          maxLength != null ? formatDurationToString(maxLength!) : null,
      'suggested_length': suggestedLength != null
          ? formatDurationToString(suggestedLength!)
          : null,
      'display_time': displayTime,
      'multiple_answers': multipleAnswers,
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
  affectGrid,
}
