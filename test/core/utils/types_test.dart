import 'package:flutter_test/flutter_test.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';

void main() {
  group('ResponseType Tests', () {
    test('ResponseType enum should have all expected values', () {
      expect(ResponseType.values.length, equals(18));
      expect(ResponseType.values, contains(ResponseType.audio));
      expect(ResponseType.values, contains(ResponseType.text));
      expect(ResponseType.values, contains(ResponseType.multiple));
      expect(ResponseType.values, contains(ResponseType.radio));
      expect(ResponseType.values, contains(ResponseType.slider));
      expect(ResponseType.values, contains(ResponseType.textAudio));
      expect(ResponseType.values, contains(ResponseType.webview));
      expect(ResponseType.values, contains(ResponseType.timer));
      expect(ResponseType.values, contains(ResponseType.image));
      expect(ResponseType.values, contains(ResponseType.video));
      expect(ResponseType.values, contains(ResponseType.imageVideo));
      expect(ResponseType.values, contains(ResponseType.instruction));
      expect(ResponseType.values, contains(ResponseType.psychomotor));
      expect(ResponseType.values, contains(ResponseType.mediaImage));
      expect(ResponseType.values, contains(ResponseType.mediaVideo));
      expect(ResponseType.values, contains(ResponseType.timePicker));
      expect(ResponseType.values, contains(ResponseType.teleprompter));
      expect(ResponseType.values, contains(ResponseType.reference));
    });
  });

  group('OptionType Tests', () {
    test('OptionType enum should have all expected values', () {
      expect(OptionType.values.length, equals(3));
      expect(OptionType.values, contains(OptionType.radio));
      expect(OptionType.values, contains(OptionType.slider));
      expect(OptionType.values, contains(OptionType.multiple));
    });
  });

  group('TagType Tests', () {
    test('TagType enum should have all expected values', () {
      expect(TagType.values.length, equals(3));
      expect(TagType.values, contains(TagType.time));
      expect(TagType.values, contains(TagType.questions));
      expect(TagType.values, contains(TagType.remainder));
    });
  });
}
