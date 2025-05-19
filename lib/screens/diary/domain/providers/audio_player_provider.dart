import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

// This class manages the state of the audio player across the app using Provider pattern
// It handles the audio playback, including play, pause, stop, and seek functionalities
class AudioPlayerProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;        
  double _currentPosition = 0;    
  double _maxDuration = 0;        
  String? _currentFilePath;

// Getters for accessing state
  bool get isPlaying => _isPlaying;
  double get currentPosition => _currentPosition;
  double get maxDuration => _maxDuration;
  String? get currentFilePath => _currentFilePath;

//sets up listeners for audio player events
  AudioPlayerProvider() {
    _setupListeners();
  }

// Sets up listeners for position changes, player state changes, and duration changes
  void _setupListeners() {
    // Listens for position changes during playback
    _audioPlayer.onPositionChanged.listen((Duration position) {
      _currentPosition = position.inMilliseconds.toDouble();
      notifyListeners();
    });
  
  // Listens for player state changes (playing/paused)
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

  //Listens for duration changes
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      _maxDuration = duration.inMilliseconds.toDouble();
      notifyListeners();
    });
  }

// Initializees audio with new file path
  Future<void> initializeAudio(String filePath) async {
    if (_currentFilePath != filePath) {
      await stop();
      _currentFilePath = filePath;
      await _audioPlayer.setSourceDeviceFile(filePath);
    
      final duration = await _audioPlayer.getDuration();
      if (duration != null) {
        _maxDuration = duration.inMilliseconds.toDouble();
        notifyListeners();
      }
    }
  }
// Plays the audio file
  Future<void> playFile(String filePath) async {
    if (_currentFilePath != filePath) {
      await stop();
      _currentFilePath = filePath;
      await _audioPlayer.setSourceDeviceFile(filePath);
    }
    await _audioPlayer.resume();
  }
// Pauses the current playback
  Future<void> pause() async {
    await _audioPlayer.pause();
  }
// Stops playback and resets state
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentPosition = 0;
    _currentFilePath = null;
    notifyListeners();
  }

// Seeks to a specific position in the audio
  Future<void> seek(double position) async {
    await _audioPlayer.seek(Duration(milliseconds: position.toInt()));
  }

// Rewinds the audio by 15 seconds
  Future<void> rewind() async {
    final int currentPositionMillis = _currentPosition.toInt();
    int reduce = 15000;

    if (currentPositionMillis - reduce < 0) {
      reduce = currentPositionMillis;
    }

    int position = currentPositionMillis - reduce;
    await seek(position.toDouble());
  }

 // Forwards the audio by 15 seconds
  Future<void> forward() async {
    final int currentPositionMillis = _currentPosition.toInt();
    int increase = 15000;

    if (currentPositionMillis + increase > _maxDuration) {
      increase = _maxDuration.toInt() - currentPositionMillis;
    }

    int position = currentPositionMillis + increase;
    await seek(position.toDouble());
  }

// Stop audio playback and reset state when the user submits the diary
// This method is called when the user presses the submit button in DiarySummary
// It stops the audio player and resets the state
Future<void> handleSubmission() async {
    // Force stop the audio player
    await _audioPlayer.stop();
    _isPlaying = false;
    _currentPosition = 0;
    _currentFilePath = null;
    notifyListeners();
  }
  
  // Clean up when provider is disposed
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
