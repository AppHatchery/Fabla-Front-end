import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:video_compress/video_compress.dart';

/// Compresses the video at [sourcePath] to 720p and returns the compressed
/// file's path, or `null` on failure so callers can fall back to the original.
///
/// Hardware encoders on some Android devices ignore the camera's requested
/// `videoBitrate`, producing files several times larger than intended. A
/// dedicated compression pass gives reliable, device-independent control.
Future<String?> compressVideo(String sourcePath) async {
  try {
    final info = await VideoCompress.compressVideo(
      sourcePath,
      quality: VideoQuality.Res1280x720Quality,
      includeAudio: true,
    );
    return info?.file?.path;
  } catch (e) {
    dev.log('Video compression failed: $e', name: 'Video Compression');
    return null;
  }
}

/// In-memory queue that compresses recorded videos in the background while the
/// participant keeps moving through the diary.
///
/// Compression runs serially (video_compress handles one file at a time) and is
/// held while the camera is active, because the device may share a single
/// hardware codec between recording and transcoding. At submission the uploader
/// takes whatever is ready via [compressedPathFor]; unfinished clips upload raw
/// and [cancelAll] stops the rest.
///
/// State is in-memory only by design — it does not survive the app closing. The
/// raw recordings stay on disk, so a later submission still works.
class VideoCompressionQueue {
  VideoCompressionQueue._();
  static final VideoCompressionQueue instance = VideoCompressionQueue._();

  final List<String> _queue = [];
  final Map<String, String> _completed = {}; // rawPath -> compressedPath
  String? _current;
  bool _working = false;
  bool _cameraActive = false;

  /// Queues [rawPath] for background compression. No-op if already known.
  void enqueue(String rawPath) {
    if (_completed.containsKey(rawPath) ||
        _queue.contains(rawPath) ||
        _current == rawPath) {
      return;
    }
    _queue.add(rawPath);
    unawaited(_pump());
  }

  /// Holds compression while the camera is in use. Cancels and requeues any
  /// in-flight job so the hardware codec is free for recording.
  void setCameraActive(bool active) {
    _cameraActive = active;
    if (active) {
      final current = _current;
      if (current != null) {
        _queue.insert(0, current);
        VideoCompress.cancelCompression();
      }
    } else {
      unawaited(_pump());
    }
  }

  /// The compressed file path for [rawPath] if compression finished, else null.
  String? compressedPathFor(String rawPath) => _completed[rawPath];

  /// Cancels in-flight/queued compression and clears state. Called once the
  /// uploader has taken what it needs at submission.
  void cancelAll() {
    _queue.clear();
    _completed.clear();
    if (_current != null) VideoCompress.cancelCompression();
  }

  /// Discards a single recording's compression when its source is deleted:
  /// drops it from the queue, cancels it if in-flight, and deletes any finished
  /// compressed output. Matches by file name, so callers can pass the relative
  /// (`videos/xxx.mp4`) or the absolute path.
  Future<void> discard(String recordingPath) async {
    final name = p.basename(recordingPath);

    _queue.removeWhere((rawPath) => p.basename(rawPath) == name);

    if (_current != null && p.basename(_current!) == name) {
      VideoCompress.cancelCompression();
    }

    String? matchedKey;
    for (final rawPath in _completed.keys) {
      if (p.basename(rawPath) == name) {
        matchedKey = rawPath;
        break;
      }
    }
    if (matchedKey == null) return;

    final compressedPath = _completed.remove(matchedKey);
    if (compressedPath == null) return;
    try {
      final file = File(compressedPath);
      if (await file.exists()) await file.delete();
      dev.log("Deleted one compressed video");
    } catch (e) {
      dev.log('Failed to delete compressed file: $e',
          name: 'Video Compression');
    }
  }

  Future<void> _pump() async {
    if (_working || _cameraActive || _queue.isEmpty) return;
    _working = true;
    try {
      while (_queue.isNotEmpty && !_cameraActive) {
        final rawPath = _queue.removeAt(0);
        _current = rawPath;
        final compressedPath = await compressVideo(rawPath);
        if (compressedPath != null) _completed[rawPath] = compressedPath;
        _current = null;
      }
    } finally {
      _current = null;
      _working = false;
      // Resume if work was re-queued (e.g. camera became active) mid-run.
      if (!_cameraActive && _queue.isNotEmpty) unawaited(_pump());
    }
  }
}
