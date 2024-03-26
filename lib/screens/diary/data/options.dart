import 'option.dart';

class Options {
  OptionsType type;
  List<Option>? choices;
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

  void _createRange(int start, int end) {
    List<Option> range = List<Option>.generate((end + 1) - start,
        (index) => Option(id: index, option: (start + index).toString()));
    choices = range;
  }

  factory Options.returnOptions(
      {required OptionsType type,
      List<Option>? choices,
      String? startText,
      String? endText,
      int? rangeStart,
      int? rangeEnd}) {
    switch (type) {
      case OptionsType.multiple:
        return Options(type: type, choices: choices);
      case OptionsType.radio:
        return Options(type: type, choices: choices);
      case OptionsType.slider:
        Options options = Options(
            type: type,
            startText: startText,
            endText: endText,
            choices: choices);
        if (rangeEnd != null && rangeStart != null) {
          options._createRange(rangeStart, rangeEnd);
        }
        return options;
    }
  }

  factory Options.fromJson(Map<String, dynamic> json) {
    return Options(
      type: OptionsType.values[json['type']],
      choices: json['choices'] != null
          ? List<Option>.from(json['choices'].map((x) => Option.fromJson(x)))
          : null,
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
      'choices': choices?.toString(),
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
