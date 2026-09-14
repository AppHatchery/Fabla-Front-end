import 'package:flutter/material.dart';

import '../custom_colors.dart';

/// Renders a fixed waveform for an already-recorded file, with a scrubbable
/// playhead and two draggable trim handles.
///
/// Unlike [CustomWaveform] (which visualizes a *live* decibel stream, newest
/// bar at the center, older bars scrolling off to one side), every peak here
/// is known up front, so all of them are laid out evenly across the full
/// width at once.
class StaticWaveform extends StatelessWidget {
  /// Amplitude peaks in `0.0–1.0`, one per bar, evenly spaced across the
  /// recording — see `AudioProcessor.extractWaveform`.
  final List<double> peaks;

  /// Current playback position, as a fraction of the total duration.
  final double playheadFraction;

  /// The selected range's bounds, as fractions of the total duration.
  /// Audio outside `[trimStartFraction, trimEndFraction]` is dimmed to show
  /// what a trim would discard.
  final double trimStartFraction;
  final double trimEndFraction;

  final Color color;

  /// Fires while a trim handle is being dragged, with its new fraction.
  /// The caller is responsible for clamping (keeping a minimum gap between
  /// the two handles, keeping both within `0.0–1.0`).
  final ValueChanged<double>? onTrimStartChanged;
  final ValueChanged<double>? onTrimEndChanged;

  /// Fires on a tap anywhere on the waveform body, to seek playback.
  ///
  /// Tap-only, not drag: the handles below need exclusive claim on horizontal
  /// drags, and a drag recognizer here would compete with theirs in the same
  /// gesture arena with no reliable winner.
  final ValueChanged<double>? onSeek;

  static const _handleWidth = 28.0;
  static const _handleHitWidth = 44.0;

  const StaticWaveform({
    super.key,
    required this.peaks,
    required this.playheadFraction,
    required this.trimStartFraction,
    required this.trimEndFraction,
    this.color = CustomColors.textTertiaryContent,
    this.onTrimStartChanged,
    this.onTrimEndChanged,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (details) => _seekTo(details.localPosition.dx, width),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: StaticWaveformPainter(
                  peaks: peaks,
                  playheadFraction: playheadFraction,
                  trimStartFraction: trimStartFraction,
                  trimEndFraction: trimEndFraction,
                  color: color,
                ),
              ),
            ),
            if (onTrimStartChanged != null)
              _handle(width * trimStartFraction, width, onTrimStartChanged!),
            if (onTrimEndChanged != null)
              _handle(width * trimEndFraction, width, onTrimEndChanged!),
          ],
        ),
      );
    });
  }

  void _seekTo(double dx, double width) {
    if (width <= 0) return;
    onSeek?.call((dx / width).clamp(0.0, 1.0));
  }

  Widget _handle(double centerX, double width, ValueChanged<double> onChanged) {
    return Positioned(
      left: centerX - _handleHitWidth / 2,
      top: 0,
      bottom: 0,
      width: _handleHitWidth,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) {
          if (width <= 0) return;
          final fraction =
              ((centerX + details.delta.dx) / width).clamp(0.0, 1.0);
          onChanged(fraction);
        },
        child: Center(
          child: Container(
            width: _handleWidth * 0.2,
            decoration: BoxDecoration(
              color: CustomColors.productNormalActive,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class StaticWaveformPainter extends CustomPainter {
  final List<double> peaks;
  final double playheadFraction;
  final double trimStartFraction;
  final double trimEndFraction;
  final Color color;

  StaticWaveformPainter({
    required this.peaks,
    required this.playheadFraction,
    required this.trimStartFraction,
    required this.trimEndFraction,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) return;

    final centerY = size.height / 2;
    final barSpace = size.width / peaks.length;
    final barWidth = (barSpace * 0.6).clamp(1.0, 4.0);

    final keptPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final trimmedPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < peaks.length; i++) {
      final fraction = (i + 0.5) / peaks.length;
      final kept =
          fraction >= trimStartFraction && fraction <= trimEndFraction;

      final barHeight = (peaks[i] * centerY).clamp(1.5, centerY);
      final x = i * barSpace + (barSpace - barWidth) / 2;

      canvas.drawRRect(
        RRect.fromLTRBR(
          x,
          centerY - barHeight,
          x + barWidth,
          centerY + barHeight,
          const Radius.circular(4.0),
        ),
        kept ? keptPaint : trimmedPaint,
      );
    }

    final playheadX = size.width * playheadFraction;
    final playheadPaint = Paint()
      ..color = CustomColors.productNormalActive
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      playheadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant StaticWaveformPainter oldDelegate) =>
      oldDelegate.peaks != peaks ||
      oldDelegate.playheadFraction != playheadFraction ||
      oldDelegate.trimStartFraction != trimStartFraction ||
      oldDelegate.trimEndFraction != trimEndFraction ||
      oldDelegate.color != color;
}
