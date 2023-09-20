import 'option.dart';

class Options {
  OptionsType type;
  List<Option>? choices;
  String? startText;
  String? endText;

  Options({
    required this.type,
    this.choices,
    this.startText,
    this.endText,
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
}

enum OptionsType {
  multiple,
  radio,
  slider,
}
