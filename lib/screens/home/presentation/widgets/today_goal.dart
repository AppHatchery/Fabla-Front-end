import 'dart:math';

import 'package:audio_diaries_flutter/core/utils/dummy_data.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/protocol.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/rings_progress_indicator.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class TodayGoalWidget extends StatefulWidget {
  final int dailyGoal;
  final Protocol protocol;
  final DiaryModel diary;
  final List<DiaryModel> diaries;
  final int weeklyEntries;
  final bool showWidget;
  final ValueNotifier<bool> isHomeTipClosed;

  const TodayGoalWidget(
      {super.key,
      required this.dailyGoal,
      required this.protocol,
      required this.diary,
      required this.weeklyEntries,
      required this.isHomeTipClosed,
      required this.showWidget,
      required this.diaries});

  @override
  State<TodayGoalWidget> createState() => _TodayGoalWidgetState();
}

class _TodayGoalWidgetState extends State<TodayGoalWidget> {
  StateMachineController? _controller;

  bool isSurvey = false;

  void _onInit(Artboard art) {
    var ctrl = StateMachineController.fromArtboard(art, "Ghosts");

    ctrl?.isActive = false;
    if (ctrl != null) {
      art.addController(ctrl);
      setState(() {
        _controller = ctrl;
      });

      if (widget.isHomeTipClosed.value) {
        Future.delayed(
            const Duration(milliseconds: 10), () => determineAnimation());
      }
    }
  }

  @override
  void initState() {
    getDay();
    widget.isHomeTipClosed.addListener(() {
      if (widget.isHomeTipClosed.value) _controller?.isActive = true;
    });

    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    print("isSurvey: $isSurvey");

    final data = {
      'EMA': widget.diaries
          .where((diary) => diary.type == DiaryTypes.ema)
          .toList(),
      'Diary': widget.diaries
          .where((diary) => diary.type == DiaryTypes.daily)
          .toList()
    };

    final surveyData = {
      'Survey': widget.diaries
          .where((diary) => diary.type == DiaryTypes.survey)
          .toList()
    };

    final emaEntries = data["EMA"]?.fold<int>(
            0, (previous, element) => element.currentEntry + previous) ??
        0;
    final dailyEntry = data["Diary"]?.fold<int>(
            0, (previous, element) => element.currentEntry + previous) ??
        0;

    final surveyEntries = widget.diaries
        .fold<int>(0, (previous, element) => element.currentEntry + previous);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Goal", style: CustomTypography().titleLarge()),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            // height: 150,
            width: width,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: GoalProgressIndicators(
                      goals: isSurvey ? surveyData : data,
                    ),
                  ),
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
                  bottom: 0,
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: SizedBox(
                        height: 120,
                        width: 180,
                        child: widget.showWidget
                            ? RiveAnimation.asset(
                                'assets/animations/ghosts.riv',
                                onInit: _onInit,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restart_alt_outlined,
              color: CustomColors.purpleNormal,
              size: 20,
            ),
            const SizedBox(width: 6),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                isSurvey
                    ? "Survey Entries: $surveyEntries"
                    : "EMA Entries: $emaEntries/${emaGoal.daily} | Daily Entries: $dailyEntry/${diaryGoal.daily} ",
                style: CustomTypography().bodyMedium(),
              ),
            ),
          ],
        )
      ],
    );
  }

  void getDay() async {
    //Get day here
    final now = DateTime.now();
    final lastString =
        await PreferenceService().getStringPreference(key: 'lastDay');
    final last = DateTime.parse(lastString!);
    final realDay = last.subtract(const Duration(days: 7));
    final isToday = DateTime(now.year, now.month, now.day).isAtSameMomentAs(
            DateTime(realDay.year, realDay.month, realDay.day)) ||
        DateTime(now.year, now.month, now.day)
            .isAtSameMomentAs(DateTime(last.year, last.month, last.day));

    setState(() {
      isSurvey = isToday;
    });
  }

  determineAnimation() async {
    final coldStart =
        await PreferenceService().getBoolPreference(key: 'cold_start') ?? true;

    if (coldStart) {
      final arrival = _controller?.findSMI('First arrival');
      if (arrival != null && mounted) {
        arrival.value = true;
      }

      //set cold start in shared pref
      await PreferenceService()
          .setBoolPreference(key: 'cold_start', value: false);

      // change animation after 30 seconds
      Future.delayed(const Duration(seconds: 30), () => determineAnimation());
    }

    //Show Searching 1 or Searching 2 if there is no entry
    // Make the animation random with a 50/50 chance of both showing up
    if (widget.diary.currentEntry == 0) {
      final searchingOne = _controller?.findSMI('Searching_1');
      final searchingTwo = _controller?.findSMI('Searching_2');

      final random = Random().nextInt(2);
      final animation = random == 0 ? searchingOne : searchingTwo;

      if (animation != null && mounted) {
        animation.value = true;
      }
      return;
    }

    //Show Blinking + Blowing the horn if the daily goal is achieved
    if (widget.diary.currentEntry == widget.protocol.dailyGoal) {
      final blowing = _controller?.findSMI('Blinking + Blowing the horn');

      if (blowing != null && mounted) {
        blowing.value = true;
      }
      return;
    }

    //Show Achieving the goal if the weekly goal is achieved
    if (widget.diary.currentEntry == widget.protocol.weeklyGoal ||
        widget.weeklyEntries == widget.protocol.weeklyGoal) {
      final achieving = _controller?.findSMI('Achieving the goal ');

      if (achieving != null && mounted) {
        achieving.value = true;
      }
      return;
    }

    //Show Beyond the goal if the weekly goal is exceeded
    if (widget.diary.currentEntry > widget.protocol.weeklyGoal ||
        widget.weeklyEntries > widget.protocol.weeklyGoal) {
      final beyond = _controller?.findSMI('Beyond the goal ');

      if (beyond != null && mounted) {
        beyond.value = true;
      }
      return;
    }

    //Show Searching 3 if there is an entry or more
    if (widget.diary.currentEntry > 0) {
      final searchingThree = _controller?.findSMI('Searching_3');
      if (searchingThree != null && mounted) {
        searchingThree.value = true;
      }
      return;
    }
  }
}
