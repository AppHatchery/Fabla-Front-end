import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:flutter/services.dart';

/// Joins the segments of a take into one m4a, via
/// ios/Runner/AppDelegate.swift.
///
/// Only iOS splits a take, so only iOS implements the channel. See
/// `AudioRecordingService` for why.
///
/// Reports failure as `null` rather than throwing: the caller keeps the
/// segments and lets the participant try again, so a failed join has to be an
/// answer it can act on, not a crash.
class AudioSegmentMerger {
  static const _channel = MethodChannel('diary/audio_segments');

  /// Writes [segments], in order, into [output] and returns its path, or
  /// `null` if they could not be joined. The segments themselves are left
  /// alone either way.
  Future<String?> merge(
    List<String> segments, {
    required String output,
  }) async {
    try {
      return await _channel.invokeMethod<String>('merge', {
        'segments': segments,
        'output': output,
      });
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Joining the take\'s segments failed',
        context: {'segment_count': segments.length},
      );

      return null;
    }
  }
}
