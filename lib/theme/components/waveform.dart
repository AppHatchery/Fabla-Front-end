import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';

import '../custom_colors.dart';

/// A customizable widget for displaying a waveform representation of audio recording levels.
///
/// This widget integrates with the FlutterSoundRecorder to visualize audio recording levels
/// as a waveform. It takes a FlutterSoundRecorder instance, the maximum number of visible
/// waveform values, a reference loudness level used to scale the bars, and an optional
/// color for the waveform.
///
/// The waveform is drawn using a CustomPainter, and the audio recording progress is updated
/// using the onProgress event of the recorder. Incoming levels are smoothed (fast attack,
/// slower release) and normalized against a fixed reference so a bar's height always reflects
/// its actual loudness, and new bars ease in smoothly instead of popping in at full height.
///
/// The onErase ValueNotifier is used to clear the waveform when the user erases the recording.
///
/// Example usage:
/// ```dart
/// CustomWaveform(
///   recorder: myFlutterSoundRecorder,
///   maxVisibleValues: 100,
///   maxValue: 1.0,
///   color: Colors.blue,
/// )
/// `
class CustomWaveform extends StatefulWidget {
  final FlutterSoundRecorder recorder;
  final int maxVisibleValues;
  final double maxValue;
  final Color color;
  final ValueNotifier<bool> onErase;

  const CustomWaveform({
    super.key,
    required this.recorder,
    required this.maxVisibleValues,
    required this.maxValue,
    this.color = CustomColors.textTertiaryContent,
    required this.onErase,
  });

  @override
  CustomWaveformState createState() => CustomWaveformState();
}

/// A single recorded level, already normalized to [0.0, 1.0], along with the
/// time it was captured so the painter can ease it in as it appears.
class WaveformSample {
  WaveformSample(this.level) : insertedAt = DateTime.now();

  final double level;
  final DateTime insertedAt;
}

class CustomWaveformState extends State<CustomWaveform>
    with SingleTickerProviderStateMixin {
  /// How long a new bar takes to grow from nothing to its full height.
  static const _growDuration = Duration(milliseconds: 220);

  // Attack/release smoothing: react quickly to louder audio but settle
  // gently on quieter audio, so the meter doesn't jitter on raw mic noise.
  static const _attack = 0.6;
  static const _release = 0.2;

  final List<WaveformSample> _samples = [];
  double _smoothedLevel = 0;
  StreamSubscription<RecordingDisposition>? _subscription;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _subscription = widget.recorder.onProgress!.listen(_onProgress);
    // Repaints while a bar is still easing in. Idle otherwise to save battery.
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration _) {
    if (!mounted) return;
    setState(() {});

    final newest = _samples.isEmpty ? null : _samples.first;
    final stillGrowing = newest != null &&
        DateTime.now().difference(newest.insertedAt) < _growDuration;
    if (!stillGrowing) _ticker.stop();
  }

  void _onProgress(RecordingDisposition event) {
    // Normalize against a fixed reference level instead of the running max of
    // the visible buffer, so a bar's height always reflects its actual
    // loudness rather than shifting whenever a louder or quieter sample
    // scrolls into view.
    final target = ((event.decibels ?? 0) / widget.maxValue).clamp(0.0, 1.0);
    _smoothedLevel += (target - _smoothedLevel) *
        (target > _smoothedLevel ? _attack : _release);

    if (!mounted) return;
    setState(() {
      _samples.insert(0, WaveformSample(_smoothedLevel));
      if (_samples.length > widget.maxVisibleValues) {
        _samples.removeLast();
      }
    });

    if (!_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: widget.onErase,
        builder: (context, value, child) {
          if (value) {
            _samples.clear();
            _smoothedLevel = 0;
          }

          return CustomPaint(
            painter: WaveformPainter(
              samples: _samples,
              growDuration: _growDuration,
              color: widget.color,
            ),
          );
        });
  }
}

/// CustomPainter for rendering a waveform visualization on a canvas.
///
/// This CustomPainter is responsible for rendering a waveform visualization
/// based on a list of already-normalized, smoothed level samples. Each bar's
/// height is a fixed fraction of the available height (no per-frame
/// rescaling), and newly inserted bars ease in over [growDuration] for a
/// smooth, continuous scroll rather than an abrupt pop-in. A static indicator
/// bar marks the center where new bars appear.
class WaveformPainter extends CustomPainter {
  final List<WaveformSample> samples;
  final Duration growDuration;
  final Color color;

  WaveformPainter({
    required this.samples,
    required this.growDuration,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    const barWidth = 2.0;
    const barPadding = 3.0;
    const indicatorWidth = 2.0;
    final indicatorHeight = size.height * 0.9;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final indicatorPaint = Paint()
      ..color = CustomColors.productNormalActive
      ..style = PaintingStyle.fill;

    final now = DateTime.now();
    final growthMs = growDuration.inMilliseconds;
    double x = size.width / 2 - barWidth / 2;

    for (final sample in samples) {
      if (x < -barWidth) break;

      final age = now.difference(sample.insertedAt).inMilliseconds;
      final growth = Curves.easeOut.transform((age / growthMs).clamp(0.0, 1.0));
      final barHeight = max(1.0, sample.level * growth * centerY);

      canvas.drawRRect(
        RRect.fromLTRBR(
          x,
          centerY - barHeight,
          x + barWidth,
          centerY + barHeight,
          const Radius.circular(10.0),
        ),
        paint,
      );
      x -= barWidth + barPadding;
    }

    canvas.drawRRect(
      RRect.fromLTRBR(
        size.width / 2 - indicatorWidth / 2,
        centerY - indicatorHeight / 2,
        size.width / 2 + indicatorWidth / 2,
        centerY + indicatorHeight / 2,
        const Radius.circular(10.0),
      ),
      indicatorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => true;
}
