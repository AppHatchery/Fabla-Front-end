import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;

/// Thrown when an ffmpeg/ffprobe invocation fails or produces no usable
/// output. Carries the session logs so a caller (or Crashlytics) can see why
/// without re-running the command.
class AudioProcessorException implements Exception {
  const AudioProcessorException(this.message, {this.logs});

  final String message;
  final String? logs;

  @override
  String toString() => logs == null
      ? 'AudioProcessorException: $message'
      : 'AudioProcessorException: $message\n$logs';
}

/// Manipulates audio files on disk via ffmpeg (through
/// `ffmpeg_kit_flutter_new`): trimming a range out of a file, merging
/// multiple files into one, and appending a new take onto an existing
/// recording.
///
/// Stateless and self-contained — every method takes file paths in and
/// returns a file path out, so it has no opinion on where those files live
/// or how the caller manages takes.
class AudioProcessor {
  const AudioProcessor();

  /// Returns the duration of the audio file at [path].
  Future<Duration> getDuration(String path) async {
    _requireExists(path);

    final session = await FFprobeKit.getMediaInformation(path);
    final durationSeconds = session.getMediaInformation()?.getDuration();
    final seconds =
        durationSeconds == null ? null : double.tryParse(durationSeconds);
    if (seconds == null) {
      throw AudioProcessorException(
        'Could not determine duration for $path',
        logs: await session.getAllLogsAsString(),
      );
    }
    return Duration(milliseconds: (seconds * 1000).round());
  }

  /// Writes the audio between [start] and [end] (or to the end of the file,
  /// if [end] is omitted) to [outputPath], re-encoding the audio stream so
  /// the cut lands exactly on [start]/[end] rather than the nearest keyframe.
  Future<File> trim({
    required String inputPath,
    required String outputPath,
    required Duration start,
    Duration? end,
  }) async {
    _requireExists(inputPath);
    if (start < Duration.zero) {
      throw ArgumentError.value(start, 'start', 'Must not be negative');
    }
    if (end != null && end <= start) {
      throw ArgumentError.value(end, 'end', 'Must be after start ($start)');
    }

    // -ss/-to as *output* options (i.e. placed after -i) both refer to the
    // source's original timeline and force ffmpeg to decode up to that exact
    // point rather than snapping to the nearest keyframe, which is what
    // makes the cut sample-accurate.
    final command = StringBuffer()
      ..write('-y -i "$inputPath" -ss ${_formatTimestamp(start)} ');
    if (end != null) {
      command.write('-to ${_formatTimestamp(end)} ');
    }
    command.write('-c:a aac -q:a 2 "$outputPath"');

    await _execute(command.toString());
    return _requireOutput(outputPath);
  }

  /// Concatenates [inputPaths], in order, into a single file at
  /// [outputPath].
  ///
  /// Uses ffmpeg's concat demuxer with `-c copy`, so it only re-orders
  /// existing packets rather than re-encoding — fast, but it assumes every
  /// input shares the same codec/sample rate/channel layout (true for takes
  /// recorded by this app, not for arbitrary audio files).
  Future<File> merge({
    required List<String> inputPaths,
    required String outputPath,
  }) async {
    if (inputPaths.length < 2) {
      throw ArgumentError.value(
        inputPaths,
        'inputPaths',
        'Need at least two files to merge',
      );
    }
    inputPaths.forEach(_requireExists);

    final listFile = File(
      p.join(
        Directory.systemTemp.path,
        'audio_processor_${DateTime.now().microsecondsSinceEpoch}.txt',
      ),
    );
    // The concat demuxer reads its inputs from a list file rather than the
    // command line, with each path single-quoted; escape any literal quotes
    // in the path itself so a stray one can't break out of the list syntax.
    await listFile.writeAsString(
      inputPaths
          .map((path) => "file '${path.replaceAll("'", r"'\''")}'")
          .join('\n'),
    );

    try {
      await _execute(
        '-y -f concat -safe 0 -i "${listFile.path}" -c copy "$outputPath"',
      );
    } finally {
      if (await listFile.exists()) {
        await listFile.delete();
      }
    }

    return _requireOutput(outputPath);
  }

  /// Appends [newTakePath] onto the end of [basePath], writing the combined
  /// audio to [outputPath].
  ///
  /// [outputPath] must differ from [basePath]: ffmpeg cannot read from and
  /// write to the same file in one pass, so the caller is responsible for
  /// moving the result over the original once it's written.
  Future<File> appendRecording({
    required String basePath,
    required String newTakePath,
    required String outputPath,
  }) {
    if (p.equals(outputPath, basePath)) {
      throw ArgumentError.value(
        outputPath,
        'outputPath',
        'Must differ from basePath — ffmpeg cannot overwrite an input file',
      );
    }
    return merge(inputPaths: [basePath, newTakePath], outputPath: outputPath);
  }

  /// Downsamples [path] into [sampleCount] amplitude peaks in `0.0–1.0`, for
  /// drawing a static waveform of an already-recorded file.
  ///
  /// Decodes to raw mono 16-bit PCM at a low sample rate — plenty for a
  /// visual waveform, and small enough that even a several-minute diary
  /// answer produces a temp file of a few megabytes — rather than parsing
  /// ffmpeg's filter/log output, which would be a second, fragile way of
  /// getting the same answer this file already gets deterministically for
  /// duration via [getDuration].
  Future<List<double>> extractWaveform(String path, {int sampleCount = 200}) async {
    _requireExists(path);
    if (sampleCount < 1) {
      throw ArgumentError.value(sampleCount, 'sampleCount', 'Must be at least 1');
    }

    const sampleRate = 8000;
    final pcmFile = File(
      p.join(
        Directory.systemTemp.path,
        'audio_processor_waveform_${DateTime.now().microsecondsSinceEpoch}.pcm',
      ),
    );

    try {
      await _execute(
        '-y -i "$path" -ac 1 -ar $sampleRate -f s16le -acodec pcm_s16le '
        '"${pcmFile.path}"',
      );

      if (!await pcmFile.exists()) {
        throw AudioProcessorException('ffmpeg produced no PCM output for $path');
      }

      final bytes = await pcmFile.readAsBytes();
      final samples = bytes.buffer.asInt16List(
        bytes.offsetInBytes,
        bytes.lengthInBytes ~/ 2,
      );

      if (samples.isEmpty) return List.filled(sampleCount, 0.0);

      final bucketSize = (samples.length / sampleCount).ceil();
      return List<double>.generate(sampleCount, (bucket) {
        final start = bucket * bucketSize;
        if (start >= samples.length) return 0.0;
        final end = (start + bucketSize).clamp(0, samples.length);

        var peak = 0;
        for (var i = start; i < end; i++) {
          final abs = samples[i].abs();
          if (abs > peak) peak = abs;
        }
        return peak / 32768;
      });
    } finally {
      if (await pcmFile.exists()) {
        await pcmFile.delete();
      }
    }
  }

  Future<void> _execute(String command) async {
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      throw AudioProcessorException(
        'ffmpeg command failed (rc=$returnCode): $command',
        logs: await session.getAllLogsAsString(),
      );
    }
  }

  void _requireExists(String path) {
    if (!File(path).existsSync()) {
      throw ArgumentError.value(path, 'path', 'Audio file does not exist');
    }
  }

  File _requireOutput(String outputPath) {
    final file = File(outputPath);
    if (!file.existsSync() || file.lengthSync() == 0) {
      throw AudioProcessorException('ffmpeg produced no output at $outputPath');
    }
    return file;
  }

  String _formatTimestamp(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    final millis = d.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds.$millis';
  }
}
