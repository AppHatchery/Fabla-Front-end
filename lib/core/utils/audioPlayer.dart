import 'dart:developer' as dev;
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../services/crashlytics_service.dart';
import 'statuses.dart';

mixin AudioPlaybackMixin<T extends StatefulWidget> on State<T> {
  AudioPlayer? audioPlayer;
  AudioStatus audioStatus = AudioStatus.loading;
  bool isPlaying = false;
  double currentSliderPosition = 0;
  double maxSliderPosition = 0;
  Duration maxDuration = Duration.zero;

  /// Retained so failure reports identify which recording broke.
  String _recordingPath = '';

  bool get canPlay => audioStatus == AudioStatus.available;

  /// Loads [relativePath], resolved against the documents directory.
  Future<void> initAudio(String relativePath) async {
    _recordingPath = relativePath;

    final String path;
    final File file;
    try {
      final dir = await getApplicationDocumentsDirectory();
      path = p.join(dir.path, relativePath);
      file = File(path);
    } catch (e, s) {
      dev.log('Could not resolve recording path',
          error: e, stackTrace: s, name: 'AudioPathResolveFailed');
      _fail(AudioStatus.canNotPlay, e, s);
      onAudioStatusResolved(AudioStatus.canNotPlay, duringLoad: true);
      return;
    }

    try {
      if (!await file.exists()) {
        _fail(
          AudioStatus.fileNotFound,
          FileSystemException('Recording file not found', path),
        );
        onAudioStatusResolved(AudioStatus.fileNotFound, duringLoad: true);
        return;
      }
    } catch (e, s) {
      dev.log('Could not check if file exists or not',
          error: e, stackTrace: s, name: 'AudioNotFoundCheckFailed');
      _fail(AudioStatus.fileNotFound, e, s);
      onAudioStatusResolved(AudioStatus.fileNotFound, duringLoad: true);
      return;
    }

    try {
      if (await file.length() == 0) {
        _fail(
          AudioStatus.noAudioLength,
          FileSystemException('Recording file is empty', path),
        );
        onAudioStatusResolved(AudioStatus.noAudioLength, duringLoad: true);
        return;
      }
    } catch (e, s) {
      dev.log('Could not check recording file length',
          error: e, stackTrace: s, name: 'AudioLengthCheckFailed');
      _fail(AudioStatus.noAudioLength, e, s);
      onAudioStatusResolved(AudioStatus.noAudioLength, duringLoad: true);
      return;
    }

    final player = AudioPlayer();
    try {
      await player.setSourceDeviceFile(path);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setPlayerMode(PlayerMode.mediaPlayer);

      final duration = await _probeDuration(player);
      if (duration == null || duration <= Duration.zero) {
        await player.dispose();
        // canNotPlay, not noAudioLength: the file was already confirmed to
        // exist and hold bytes above, so this is the decoder declining to
        // report a duration, not an empty recording. The distinction decides
        // whether the row is deleted — see [RecordingAnswerChecker.report].
        _fail(
          AudioStatus.canNotPlay,
          FileSystemException('Recording has no playable duration', path),
        );
        onAudioStatusResolved(AudioStatus.canNotPlay, duringLoad: true);
        return;
      }

      // The card may have been popped while the source was loading.
      if (!mounted) {
        await player.dispose();
        return;
      }

      player.onPositionChanged.listen((position) {
        if (mounted) {
          setState(
                  () => currentSliderPosition = position.inMilliseconds.toDouble());
        }
      });
      player.onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => isPlaying = state == PlayerState.playing);
      });

      setState(() {
        audioPlayer = player;
        maxDuration = duration;
        maxSliderPosition = duration.inMilliseconds.toDouble();
        audioStatus = AudioStatus.available;
      });

      onAudioStatusResolved(AudioStatus.available, duringLoad: true);
    } catch (e, s) {
      await player.dispose();
      _fail(AudioStatus.canNotPlay, e, s);
      onAudioStatusResolved(AudioStatus.canNotPlay, duringLoad: true);
    }
  }

  /// Asks the platform for the recording's duration, retrying once.
  ///
  /// A first call can come back null on a perfectly good file — the decoder
  /// has not finished preparing the source yet, which shows up on AAC on some
  /// Android devices. A single null used to be treated as proof the recording
  /// was empty, and that verdict deletes the participant's audio, so it is
  /// worth one bounded second look before believing it.
  Future<Duration?> _probeDuration(AudioPlayer player) async {
    final first = await player.getDuration();
    if (first != null && first > Duration.zero) return first;

    await Future<void>.delayed(const Duration(milliseconds: 250));

    return player.getDuration();
  }

  /// Called once the card settles on a terminal status, so a parent can react
  /// to a recording that turned out to be unplayable.
  ///
  /// [duringLoad] separates "this file could not be loaded" from "playback of
  /// an already-loaded file failed". The second can be transient — an
  /// interrupted session, a route change — so a caller that discards broken
  /// recordings must not act on it.
  void onAudioStatusResolved(AudioStatus status, {required bool duringLoad}) {}

  void disposeAudio() => audioPlayer?.dispose();

  Future<void> play() =>
      _run((player) => isPlaying ? player.pause() : player.resume());

  Future<void> seek(double value) => _run((player) async {
    await player.seek(Duration(milliseconds: value.toInt()));
    if (!isPlaying) await player.resume();
  });

  /// Seeks [milliseconds] relative to the current position, clamped to the
  /// recording's bounds. Negative values rewind.
  Future<void> skip(int milliseconds) => _run((player) => player.seek(Duration(
    milliseconds: (currentSliderPosition.toInt() + milliseconds)
        .clamp(0, maxSliderPosition.toInt()),
  )));

  /// Runs [action] against the active player, retiring the player and falling
  /// back to an error state if the platform rejects it.
  Future<void> _run(Future<void> Function(AudioPlayer player) action) async {
    final player = audioPlayer;
    if (player == null || !canPlay) return;

    try {
      await action(player);
    } catch (e, s) {
      audioPlayer = null;
      await player.dispose();
      _fail(AudioStatus.canNotPlay, e, s);
      onAudioStatusResolved(AudioStatus.canNotPlay, duringLoad: false);
    }
  }

  /// Moves the card into a failure [status] and reports [error] as a non-fatal.
  ///
  /// Every failure path routes through here, so each one is reported exactly
  /// once with the recording that caused it.
  void _fail(AudioStatus status, Object error, [StackTrace? stackTrace]) {
    CrashlyticsService().recordError(
      error,
      stackTrace ?? StackTrace.current,
      reason: 'Recording unplayable: ${status.name}',
      context: {
        'recording_path': _recordingPath,
        'audio_status': status.name,
      },
    );

    if (!mounted) return;
    setState(() {
      audioStatus = status;
      isPlaying = false;
      currentSliderPosition = 0;
      maxSliderPosition = 0;
      maxDuration = Duration.zero;
    });
  }
}