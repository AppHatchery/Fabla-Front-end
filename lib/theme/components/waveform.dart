import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';

import '../custom_colors.dart';

/// A customizable widget for displaying a waveform representation of audio recording levels.
///
/// This widget integrates with the FlutterSoundRecorder to visualize audio recording levels
/// as a waveform. It takes a FlutterSoundRecorder instance, the maximum number of visible
/// waveform values, the maximum value of the waveform, and an optional color for the waveform.
///
/// The waveform is drawn using a CustomPainter, and the audio recording progress is updated
/// using the onProgress event of the recorder. The waveform values are updated in response to
/// the audio recording progress, and only the specified maximum number of visible values
/// are displayed on the screen at a time.
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
    Key? key,
    required this.recorder,
    required this.maxVisibleValues,
    required this.maxValue,
    this.color = CustomColors.textTertiaryContent,
    required this.onErase,
  }) : super(key: key);

  @override
  CustomWaveformState createState() => CustomWaveformState();
}

class CustomWaveformState extends State<CustomWaveform> {
  final List<double> _decibelValues = [];

  @override
  void initState() {
    super.initState();
    widget.recorder.onProgress!.listen(_updateDecibelValues);
  }

  void _updateDecibelValues(RecordingDisposition event) {
    if (mounted) {
      setState(() {
        _decibelValues.insert(0, event.decibels as double);
        if (_decibelValues.length > widget.maxVisibleValues) {
          _decibelValues.removeLast();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: widget.onErase,
        builder: (context, value, child) {
          if (value) _decibelValues.clear();

          return CustomPaint(
            painter: WaveformPainter(
              decibelValues: _decibelValues,
              maxValue: widget.maxValue,
              color: widget.color,
            ),
          );
        });
  }
}

/// CustomPainter for rendering a waveform visualization on a canvas.
///
/// This CustomPainter is responsible for rendering a waveform visualization
/// based on the provided decibel values, maximum value, and color. It takes a
/// list of decibel values representing audio levels over time, a maximum value
/// to determine the scaling of the waveform, and a color for drawing the bars.
/// The waveform consists of a series of bars drawn on a canvas, with each bar's
/// height determined by the corresponding decibel value.
///
/// The waveform is drawn using the provided decibel values as well as the maximum
/// value to calculate the scaling of the bars' heights. The middle bar, represented
/// by a spike, is drawn separately to indicate the current audio level. The waveform
/// is drawn with bars descending from the center and moving towards the edges.
///
/// Example usage:
/// ```dart
/// WaveformPainter(
///   decibelValues: myDecibelValues,
///   maxValue: 1.0,
///   color: Colors.blue,
/// )
/// ```
class WaveformPainter extends CustomPainter {
  final List<double> decibelValues;
  final double maxValue;
  final Color color;

  WaveformPainter(
      {required this.decibelValues,
      required this.maxValue,
      required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    const barWidth = 1.5;
    const barPadding = 6;

    final middleBarX = size.width / 2 - barWidth / 2;
    // Find the maximum decibel value
    final maxDecibel = decibelValues.isNotEmpty
        ? decibelValues.reduce((a, b) => a > b ? a : b)
        : 1.0;
    final scaledMaxValue = maxValue < maxDecibel
        ? maxDecibel
        : maxValue; // Ensure spike height doesn't exceed maxValue
    final spikeHeight = scaledMaxValue;
    final centerBarHeight = maxValue;
    final centerBarY = centerY - centerBarHeight / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 12.0
      ..style = PaintingStyle.fill;

    final middleSpikePaint = Paint()
      ..color = CustomColors.productNormalActive
      ..strokeWidth = 12.0
      ..style = PaintingStyle.fill;

    double x = size.width / 2 - barWidth / 2;

    for (final decibelValue in decibelValues) {
      final barHeight = max(1, (decibelValue / spikeHeight) * centerY);

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
        middleBarX,
        centerBarY,
        middleBarX + 2,
        centerBarY + centerBarHeight,
        const Radius.circular(10.0),
      ),
      middleSpikePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
