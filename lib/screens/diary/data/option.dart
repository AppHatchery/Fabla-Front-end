import 'options.dart';

class Option {
  int id;
  String? option;
  Option({this.id = 0, required this.option});

  Option copyWith({
    String? option,
    OptionsType? optionType,
  }) {
    return Option(
      option: option ?? this.option,
    );
  }

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['id'],
      option: json['option'],
    );
  }
}
