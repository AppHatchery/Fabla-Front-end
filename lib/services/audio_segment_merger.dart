import 'dart:async';

import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:flutter/services.dart';

/// Joins the segments of a take into one m4a, via
/// ios/Runner/AppDelegate.swift.
///
/// Only iOS splits a take, so only iOS implements the channel. See
/// `AudioRecordingService` for why.
///
/// Reports failure as a [SegmentMergeResult] rather than throwing, so a failed
/// join is an answer the caller can act on, not a crash.
class AudioSegmentMerger {
  /// [timeout] replaces the default, which grows with the number of segments.
  AudioSegmentMerger({Duration? timeout}) : _timeout = timeout;

  static const _channel = MethodChannel('diary/audio_segments');

  /// How long a join may take before it counts as failed. The caller holds
  /// the recorder lock throughout, so a native call that never answers would
  /// otherwise leave stop, record and interruption handling dead.
  ///
  /// Generous on purpose: a timed-out join is only retried, and an export
  /// that re-encodes a long take really can take a while.
  static const _baseTimeout = Duration(seconds: 30);
  static const _timeoutPerSegment = Duration(seconds: 15);

  final Duration? _timeout;

  /// The only native code that means no segment can ever be joined.
  static const _noUsableSegments = 'NO_USABLE_SEGMENTS';

  /// Writes [segments], in order, into [output]. The segments themselves are
  /// left alone whatever the result.
  ///
  /// A timed-out join may still be writing [output] natively, so a retry must
  /// ask for a different [output] rather than reuse this one.
  Future<SegmentMergeResult> merge(
    List<String> segments, {
    required String output,
  }) async {
    final timeout =
        _timeout ?? _baseTimeout + _timeoutPerSegment * segments.length;

    try {
      final reply = await _channel.invokeMapMethod<String, dynamic>('merge', {
        'segments': segments,
        'output': output,
      }).timeout(timeout);

      final skipped = reply?['skipped'] as List? ?? const [];
      if (skipped.isNotEmpty) {
        // The take was joined without these, so say so rather than lose them
        // silently.
        CrashlyticsService().recordError(
          StateError('Segments skipped while joining'),
          StackTrace.current,
          reason: 'Joined a take without some of its segments',
          context: {
            'segment_count': segments.length,
            'skipped': skipped.toString(),
          },
        );
      }

      final path = reply?['path'] as String?;
      return path == null ? const SegmentJoinFailed() : SegmentsJoined(path);
    } on PlatformException catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Joining the take\'s segments failed',
        context: {
          'segment_count': segments.length,
          'details': e.details?.toString() ?? 'null',
        },
      );

      // Trying again would read the same files and fail the same way. The
      // caller deletes the segments on this answer, so the code alone is not
      // enough: the native side must also account for every segment.
      if (e.code == _noUsableSegments && _skipsAll(e.details, segments)) {
        return const SegmentsUnusable();
      }

      return const SegmentJoinFailed();
    } on TimeoutException catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Joining the take\'s segments timed out',
        context: {
          'segment_count': segments.length,
          'timeout_seconds': timeout.inSeconds,
        },
      );

      return const SegmentJoinFailed();
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Joining the take\'s segments failed',
        context: {'segment_count': segments.length},
      );

      return const SegmentJoinFailed();
    }
  }

  /// Whether [details] lists a skip for every one of [segments], so none of
  /// them could have been joined.
  static bool _skipsAll(Object? details, List<String> segments) {
    if (details is! Map) return false;

    final skipped = details['segments'];
    if (skipped is! List) return false;

    final indexes = {
      for (final entry in skipped)
        if (entry is Map && entry['index'] is int) entry['index'] as int,
    };

    return indexes.length == segments.length &&
        indexes.every((i) => i >= 0 && i < segments.length);
  }
}

/// What [AudioSegmentMerger.merge] made of a take's segments.
sealed class SegmentMergeResult {
  const SegmentMergeResult();
}

/// The segments are joined into [path].
final class SegmentsJoined extends SegmentMergeResult {
  const SegmentsJoined(this.path);

  final String path;
}

/// The join failed in a way another attempt might not, such as the export.
/// The segments are still worth keeping.
final class SegmentJoinFailed extends SegmentMergeResult {
  const SegmentJoinFailed();
}

/// None of the segments held audio that could be read, so there is nothing
/// to join and retrying cannot change that.
final class SegmentsUnusable extends SegmentMergeResult {
  const SegmentsUnusable();
}
