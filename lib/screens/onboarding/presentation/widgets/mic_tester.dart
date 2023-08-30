import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_icons.dart';

class MicTester extends StatefulWidget {
  final double width;
  final FlutterSoundRecorder recorder;
  const MicTester({super.key, required this.width, required this.recorder});

  @override
  State<MicTester> createState() => _MicTesterState();
}

class _MicTesterState extends State<MicTester> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: Image.asset(
              "assets/images/mic_access.png",
              width: widget.width,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              width: widget.width,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
              decoration: BoxDecoration(
                color: CustomColors.fillWhite,
                border: Border.all(
                    color: CustomColors.productBorderNormal, width: 2),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: CustomColors.productBorderNormal,
                    blurRadius: 0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CustomIcons.keyboardVoice,
                      color: CustomColors.productNormal),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(child: MicGauge(recorder: widget.recorder)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MicGauge extends StatefulWidget {
  final FlutterSoundRecorder recorder;
  const MicGauge({super.key, required this.recorder});

  @override
  State<MicGauge> createState() => _MicGaugeState();
}

class _MicGaugeState extends State<MicGauge> {
  double _currentDecibel = 0.0;
  final minDecibel = 0.0;
  final maxDecibel = 70;
  List<Color> barColors = List.filled(7, CustomColors.fillNormal);

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
                  height: 20,
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
        _currentDecibel = decibel;
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

      if (_currentDecibel < 10) {
        _currentDecibel = 10;
      }

      Color color;
      if (_currentDecibel <= 19) {
        color = CustomColors.warningActive;
      } else if (_currentDecibel <= 39) {
        color = CustomColors.yellowDark;
      } else {
        color = const Color(0xFF00ED26);
      }

      if (_currentDecibel >= maxBarValue) {
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
