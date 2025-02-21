import 'package:audio_diaries_flutter/core/utils/formatter.dart';

class Options {
  OptionsType type;
  List<String>? choices;
  String? minLabel;
  String? maxLabel;
  int? minValue;
  int? maxValue;
  int? defaultValue;
  Duration? audioLength;

  Options({
    required this.type,
    this.choices,
    this.minLabel = "",
    this.maxLabel = "",
    this.minValue,
    this.maxValue,
    this.defaultValue,
    this.audioLength,
  });

  factory Options.fromJson(Map<String, dynamic> json) {
    return Options(
      type: OptionsType.values[json['type']],
      choices:
          json['choices'] != null ? List<String>.from(json['choices']) : null,
      minLabel: json['minLabel'] ?? "",
      maxLabel: json['maxLabel'] ?? "",
      minValue: json['minValue'],
      maxValue: json['maxValue'],
      defaultValue: json['defaultValue'],
      audioLength: json['audio_length'] != null
          ? formatStringToDuration(json['audio_length'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'choices': choices,
      'minLabel': minLabel,
      'maxLabel': maxLabel,
      'minValue': minValue,
      'maxValue': maxValue,
      'defaultValue': defaultValue,
      'audio_length':
          audioLength != null ? formatDurationToString(audioLength!) : null,
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
