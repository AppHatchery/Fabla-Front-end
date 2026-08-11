import 'package:audio_diaries_flutter/screens/settings/presentation/widgets/slider_shape.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Styled progress slider for a [VideoPlayerController], shared between the
/// quickstart modal (read-only) and the standalone quickstart video page
/// (seekable via [dragPositionMs] and the change callbacks).
class VideoProgressBar extends StatelessWidget {
  final VideoPlayerController controller;
  final double? dragPositionMs;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  const VideoProgressBar({
    super.key,
    required this.controller,
    this.dragPositionMs,
    this.onChangeStart,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final durationMs = value.duration.inMilliseconds.toDouble();
        final positionMs =
            dragPositionMs ?? value.position.inMilliseconds.toDouble();
        final maxMs = durationMs > 0 ? durationMs : 1.0;
        final sliderValue = positionMs.clamp(0.0, maxMs);

        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 12.0,
            activeTrackColor: CustomColors.yellowDark,
            inactiveTrackColor: CustomColors.greyTrack,
            disabledActiveTickMarkColor: CustomColors.yellowDark,
            disabledInactiveTickMarkColor: CustomColors.greyTrack,
            thumbColor: CustomColors.yellowDark,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
            overlayShape: SliderComponentShape.noOverlay,
            trackShape: const EqualHeightSliderTrackShape(),
          ),
          child: Slider(
            value: sliderValue,
            min: 0.0,
            max: maxMs,
            onChangeStart: durationMs > 0 ? onChangeStart : null,
            onChanged: durationMs > 0 ? onChanged : null,
            onChangeEnd: onChangeEnd,
          ),
        );
      },
    );
  }
}
