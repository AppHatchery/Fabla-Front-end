import 'dart:math';

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/ring_progress_indicator.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class TodayGoalWidget extends StatefulWidget {
  final int dailyGoal;
  final List<StudyModel> studies;
  final List<DiaryModel> diaries;
  final int weeklyEntries;
  final ValueNotifier<bool> isHomeTipClosed;

  const TodayGoalWidget(
      {super.key,
      required this.dailyGoal,
      required this.studies,
      required this.diaries,
      required this.weeklyEntries,
      required this.isHomeTipClosed});

  @override
  State<TodayGoalWidget> createState() => _TodayGoalWidgetState();
}

class _TodayGoalWidgetState extends State<TodayGoalWidget> {
  Map<StudyModel, List<DiaryModel>> data = {};

  late StateMachineController _controller;

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
    widget.isHomeTipClosed.addListener(() {
      if (widget.isHomeTipClosed.value) determineAnimation();
    });
    // create map of study to diaries
    for (var study in widget.studies) {
      final diaries = widget.diaries
          .where((diary) =>
              diary.studyID == study.studyId &&
              diary.due.day == DateTime.now().day)
          .toList();
      data[study] = diaries;
    }

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
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
                      goals: data,
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
                        child: RiveAnimation.asset(
                          'assets/animations/ghosts.riv',
                          onInit: _onInit,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(width: width, child: entries(data))
      ],
    );
  }

  Widget entries(Map<StudyModel, List<DiaryModel>> data) {
    List<Widget> entryWidgets = [];

    final entriesList = data.entries.toList();

    for (int i = 0; i < entriesList.length; i++) {
      final entry = entriesList[i];
      final study = entry.key;
      final diaries = entry.value;

      final completedCount = diaries
          .where((diary) => diary.status == DiaryStatus.submitted)
          .length;

      final displayText = "${study.name}: $completedCount/${study.goals.daily}"
          "${data.length > 1 && i != data.length - 1 ? ' | ' : ''}";
      var color = study.color ?? CustomColors.productNormal;

      entryWidgets.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restart_alt_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            displayText,
            style: CustomTypography().bodyMedium(),
          ),
        ],
      ));
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 0.0,
      runSpacing: 4.0,
      children: entryWidgets,
    );
  }

  determineAnimation() async {
    final coldStart =
        await PreferenceService().getBoolPreference(key: 'cold_start') ?? true;

    if (coldStart) {
      final arrival = _controller.findSMI('First arrival');
      if (arrival != null && mounted) {
        arrival.value = true;
      }

      //set cold start in shared pref
      await PreferenceService()
          .setBoolPreference(key: 'cold_start', value: false);

      // change animation after 30 seconds
      return Future.delayed(
          const Duration(seconds: 30), () => determineAnimation());
    }

    final diariesForToday = widget.diaries
        .where((diary) => diary.due.day == DateTime.now().day)
        .toList();

    final totalEntries =
        diariesForToday.where((diary) => diary.status == DiaryStatus.submitted).length;
    final totalGoal =
        widget.studies.fold(0, (prev, study) => prev + study.goals.daily);
    final weeklyGoal =
        widget.studies.fold(0, (prev, study) => prev + study.goals.weekly);


    //Show Searching 1 or Searching 2 if there is no entry
    // Make the animation random with a 50/50 chance of both showing up
    if (totalEntries == 0) {
      final searchingOne = _controller.findSMI('Searching_1');
      final searchingTwo = _controller.findSMI('Searching_2');

      final random = Random().nextInt(2);
      final animation = random == 0 ? searchingOne : searchingTwo;

      if (animation != null && mounted) {
        animation.value = true;
      }
      return;
    }

    // //Show Blinking + Blowing the horn if the daily goal is achieved
    if (totalEntries == totalGoal) {
      final blowing = _controller.findSMI('Blinking + Blowing the horn');

      if (blowing != null && mounted) {
        blowing.value = true;
      }
      return;
    }

    // //Show Achieving the goal if the weekly goal is achieved
    if (totalEntries == weeklyGoal) {
      final achieving = _controller.findSMI('Achieving the goal ');

      if (achieving != null && mounted) {
        achieving.value = true;
      }
      return;
    }

    // //Show Beyond the goal if the weekly goal is exceeded
    if (totalEntries > weeklyGoal) {
      final beyond = _controller.findSMI('Beyond the goal ');

      if (beyond != null && mounted) {
        beyond.value = true;
      }
      return;
    }

    // //Show Searching 3 if there is an entry or more
    if (totalEntries > 0) {
      final searchingThree = _controller.findSMI('Searching_3');
      if (searchingThree != null && mounted) {
        searchingThree.value = true;
      }
      return;
    }
  }
}
