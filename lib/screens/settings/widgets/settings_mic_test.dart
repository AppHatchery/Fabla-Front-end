import 'package:audio_diaries_flutter/theme/custom_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

import '../../../theme/custom_colors.dart';

class SettingsMIcTest extends StatefulWidget {
  final FlutterSoundRecorder recorder;
  const SettingsMIcTest({super.key, required this.recorder});

  @override
  State<SettingsMIcTest> createState() => _SettingsMIcTestState();
}

class _SettingsMIcTestState extends State<SettingsMIcTest> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
      decoration: BoxDecoration(
          color: CustomColors.productNormal,
          borderRadius: BorderRadius.circular(11)),
      child: Row(children: [
        const Icon(
          CustomIcons.keyboardVoice,
          color: CustomColors.productLightPrimaryNormalWhite,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Gauge(recorder: widget.recorder),
        ),
      ]),
    );
  }
}

class Gauge extends StatefulWidget {
  final FlutterSoundRecorder recorder;
  const Gauge({super.key, required this.recorder});

  @override
  State<Gauge> createState() => _GaugeState();
}

class _GaugeState extends State<Gauge> {
  double currentDecibel = 0.0;
  final minDecibel = 0.0;
  final maxDecibel = 70;
  List<Color> barColors = List.filled(5, CustomColors.fillNormal);

  @override
  void initState() {
    widget.recorder.onProgress!.listen((event) {
      updateDecibel(event.decibels?.roundToDouble() ?? 0);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: barColors
          .map(
            (e) => Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: e,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  void updateDecibel(double decibel) {
    if (mounted) {
      setState(() {
        currentDecibel = decibel;
        updateBars();
      });
    }
  }

  void updateBars() {
    double range = maxDecibel - minDecibel;
    double rangePerBar = range / 7;

    for (int i = 0; i < barColors.length; i++) {
      double minBarValue = minDecibel + rangePerBar * i;
      double maxBarValue = minBarValue + rangePerBar;
      Color color;
      if (currentDecibel <= 19) {
        color = CustomColors.warningActive;
      } else if (currentDecibel <= 39) {
        color = CustomColors.yellowDark;
      } else {
        color = const Color(0xFF00ED26);
      }

      if (currentDecibel >= maxBarValue) {
        setState(() {
          barColors[i] = color;
        });
      } else {
        setState(() {
          barColors[i] = CustomColors.fillNormal;
        });
      }
    }
  }
}
