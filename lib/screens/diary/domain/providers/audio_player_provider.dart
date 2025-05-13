import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  double _currentPosition = 0;
  double _maxDuration = 0;
  String? _currentFilePath;

  bool get isPlaying => _isPlaying;
  double get currentPosition => _currentPosition;
  double get maxDuration => _maxDuration;
  String? get currentFilePath => _currentFilePath;

  AudioPlayerProvider() {
    _setupListeners();
  }

  void _setupListeners() {
    _audioPlayer.onPositionChanged.listen((Duration position) {
      _currentPosition = position.inMilliseconds.toDouble();
      notifyListeners();
    });

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      _maxDuration = duration.inMilliseconds.toDouble();
      notifyListeners();
    });
  }

  Future<void> playFile(String filePath) async {
    if (_currentFilePath != filePath) {
      await stop();
      _currentFilePath = filePath;
      await _audioPlayer.setSourceDeviceFile(filePath);
    }
    await _audioPlayer.resume();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentPosition = 0;
    _currentFilePath = null;
    notifyListeners();
  }

  Future<void> seek(double position) async {
    await _audioPlayer.seek(Duration(milliseconds: position.toInt()));
  }

  Future<void> rewind() async {
    final int currentPositionMillis = _currentPosition.toInt();
    int reduce = 15000;

    if (currentPositionMillis - reduce < 0) {
      reduce = currentPositionMillis;
    }

    int position = currentPositionMillis - reduce;
    await seek(position.toDouble());
  }

  Future<void> forward() async {
    final int currentPositionMillis = _currentPosition.toInt();
    int increase = 15000;

    if (currentPositionMillis + increase > _maxDuration) {
      increase = _maxDuration.toInt() - currentPositionMillis;
    }

    int position = currentPositionMillis + increase;
    await seek(position.toDouble());
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
