import 'package:audio_diaries_flutter/core/utils/types.dart';

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
}
