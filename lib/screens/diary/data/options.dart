class Options {
  OptionsType type;
  List<String>? choices;
  String? startText;
  String? endText;
  int? minValue;
  int? maxValue;
  int? defaultValue;

  Options({
    required this.type,
    this.choices,
    this.startText,
    this.endText,
    this.minValue,
    this.maxValue,
    this.defaultValue,
  });

  factory Options.fromJson(Map<String, dynamic> json) {
    return Options(
      type: OptionsType.values[json['type']],
      choices:
          json['choices'] != null ? List<String>.from(json['choices']) : null,
      startText: json['startText'],
      endText: json['endText'],
      minValue: json['minValue'],
      maxValue: json['maxValue'],
      defaultValue: json['defaultValue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'choices': choices,
      'startText': startText,
      'endText': endText,
      'minValue': minValue,
      'maxValue': maxValue,
      'defaultValue': defaultValue,
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
