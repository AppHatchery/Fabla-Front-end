import 'dart:math';

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/protocol.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class TodayGoalWidget extends StatefulWidget {
  final int dailyGoal;
  final Protocol protocol;
  final DiaryModel diary;
  final bool coldStart;
  final int weeklyEntries;
  const TodayGoalWidget(
      {super.key,
      required this.dailyGoal,
      required this.protocol,
      required this.diary,
      required this.coldStart,
      required this.weeklyEntries});

  @override
  State<TodayGoalWidget> createState() => _TodayGoalWidgetState();
}

class _TodayGoalWidgetState extends State<TodayGoalWidget> {
  late StateMachineController _controller;

  void _onInit(Artboard art) {
    var ctrl = StateMachineController.fromArtboard(art, "Ghosts");

    ctrl?.isActive = false;
    if (ctrl != null) {
      art.addController(ctrl);
      setState(() {
        _controller = ctrl;
      });

      Future.delayed(
          const Duration(milliseconds: 10), () => determineAnimation());
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.diary.status == DiaryStatus.submitted
        ? widget.diary.entries
        : widget.diary.currentEntry;

    //calculate the daily goal progress bar width
    final dailyValue = ((entry) / widget.protocol.dailyGoal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Goal", style: CustomTypography().titleLarge()),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.center,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: SizedBox(
                    height: 120,
                    width: 120,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 0.5),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, value, _) => CircularProgressIndicator(
                        strokeWidth: 5,
                        value: dailyValue,
                        backgroundColor: CustomColors.productLightBackground,
                        color: CustomColors.productNormal,
                      ),
                    )),
              ),
              Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 5,
                        height: 10,
                        color: Colors.white,
                      ),
                    ],
                  )),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                left: 0,
                child: RiveAnimation.asset(
                  'assets/animations/ghosts.riv',
                  onInit: _onInit,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restart_alt_outlined,
              color: CustomColors.productNormal,
              size: 20,
            ),
            const SizedBox(width: 6),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                "Repeatable Entries: $entry/${widget.protocol.dailyGoal}",
                style: CustomTypography().bodyMedium(),
              ),
            ),
          ],
        )
      ],
    );
  }

  determineAnimation() async {
    if (widget.coldStart) {
      final arrival = _controller.findSMI('First arrival');
      if (arrival != null) {
        arrival.value = true;
      }

      //set cold start in shared pref
      await PreferenceService()
          .setBoolPreference(key: 'cold_start', value: false);
    }

    //Show Searching 1 or Searching 2 if there is no entry
    // Make the animation random with a 50/50 chance of both showing up
    if (widget.diary.currentEntry == 0) {
      final searchingOne = _controller.findSMI('Searching_1');
      final searchingTwo = _controller.findSMI('Searching_2');

      final random = Random().nextInt(2);
      final animation = random == 0 ? searchingOne : searchingTwo;

      if (animation != null) {
        animation.value = true;
      }
      return;
    }

    //Show Blinking + Blowing the horn if the daily goal is achieved
    if (widget.diary.currentEntry == widget.protocol.dailyGoal) {
      final blowing = _controller.findSMI('Blinking + Blowing the horn');

      if (blowing != null) {
        blowing.value = true;
      }
      return;
    }

    //Show Achieving the goal if the weekly goal is achieved
    if (widget.diary.currentEntry == widget.protocol.weeklyGoal ||
        widget.weeklyEntries == widget.protocol.weeklyGoal) {
      final achieving = _controller.findSMI('Achieving the goal ');

      if (achieving != null) {
        achieving.value = true;
      }
      return;
    }

    //Show Beyond the goal if the weekly goal is exceeded
    if (widget.diary.currentEntry > widget.protocol.weeklyGoal ||
        widget.weeklyEntries > widget.protocol.weeklyGoal) {
      final beyond = _controller.findSMI('Beyond the goal ');

      if (beyond != null) {
        beyond.value = true;
      }
      return;
    }

    //Show Searching 3 if there is an entry or more
    if (widget.diary.currentEntry > 0) {
      final searchingThree = _controller.findSMI('Searching_3');
      if (searchingThree != null) {
        searchingThree.value = true;
      }
      return;
    }
  }
}
