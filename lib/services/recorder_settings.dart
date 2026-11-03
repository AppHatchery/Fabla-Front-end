import 'package:flutter_sound/flutter_sound.dart';

/// The encoder settings every take is recorded with.
///
/// Stated rather than left to flutter_sound, whose sample rate defaults to
/// whatever the device's hardware reports, so the same values hold on every
/// phone and can be reported with the submission.
class RecorderSettings {
  const RecorderSettings._();

  static const codec = Codec.aacMP4;
  static const sampleRate = 44100;
  static const numChannels = 1;
  static const bitRate = 64000;

  /// The settings as sent with each audio file in the submission.
  static Map<String, dynamic> toJson() => {
        'Codec': 'AAC',
        'SampleRate': sampleRate,
        'Channels': numChannels,
        'BitRate': bitRate,
      };
}
