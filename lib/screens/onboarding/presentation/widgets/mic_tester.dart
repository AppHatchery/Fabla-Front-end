import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_icons.dart';

class MicTester extends StatefulWidget {
  final bool permission;
  final double width;
  final FlutterSoundRecorder recorder;
  final Function? request;
  const MicTester(
      {super.key,
      required this.permission,
      required this.width,
      required this.recorder,
      this.request});

  @override
  State<MicTester> createState() => _MicTesterState();
}

class _MicTesterState extends State<MicTester> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
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
              GestureDetector(
                onTap: (){
                  if(widget.request != null && mounted){
                    widget.request!();
                  }
                },
                child: const Icon(CustomIcons.keyboardVoice,
                    color: CustomColors.productNormal),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(child: MicGauge(recorder: widget.recorder)),
            ],
          ),
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
  double currentDecibel = 0.0;
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
        currentDecibel = decibel;
        updateBars();
      });
    }
  }

  /// Updates the colors of sound level indicator bars based on current decibel levels.
  ///
  /// This function calculates the range of decibel values based on the provided
  /// [minDecibel] and [maxDecibel] values. It then determines the range of decibel
  /// values per bar by dividing the total range by the number of bars (7). The function
  /// iterates through each bar, calculating the minimum and maximum decibel values
  /// that correspond to the current bar. It then evaluates the current decibel level
  /// [currentDecibel] against these ranges to determine the appropriate color for
  /// the bar. The bar's color is updated based on the decibel level and range.
  ///
  /// Note: The function makes use of a list called [barColors] to track and update
  /// the colors of the indicator bars.
  ///
  /// Example usage:
  /// ```dart
  /// updateBars(); // Update indicator bar colors based on current decibel levels.
  /// ```
  void updateBars() {
    double range = maxDecibel - minDecibel;
    double rangePerBar = range / 7;

    for (int i = 0; i < barColors.length; i++) {
      double minBarValue = minDecibel + rangePerBar * i;
      double maxBarValue = minBarValue + rangePerBar;

      // if (currentDecibel < 10) {
      //   currentDecibel = 10;
      // }

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
