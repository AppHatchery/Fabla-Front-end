import 'dart:math';

import 'package:audio_diaries_flutter/core/usecases/daily_goal_service.dart'
    show DailyGoalData;
import 'package:audio_diaries_flutter/core/usecases/homepage.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/ring_progress_indicator.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import 'dart:developer' as dev;

class TodayGoalWidget extends StatefulWidget {
  final Map<StudyModel, DailyGoalData> dailyGoal;
  final int weeklyEntries;
  final ValueNotifier<bool> isHomeTipClosed;

  const TodayGoalWidget(
      {super.key,
      required this.dailyGoal,
      required this.weeklyEntries,
      required this.isHomeTipClosed});

  @override
  State<TodayGoalWidget> createState() => _TodayGoalWidgetState();
}

class _TodayGoalWidgetState extends State<TodayGoalWidget> {
  late rive.StateMachineController _controller;

  void _onInit(rive.Artboard art) {
    var ctrl = rive.StateMachineController.fromArtboard(art, "Ghosts");

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
      spacing: 16,
      children: [
        widget.dailyGoal.isNotEmpty
            ? Text("Today's Goal", style: CustomTypography().titleLarge())
            : const SizedBox.shrink(),
        Align(
            alignment: Alignment.center,
            child: SizedBox(
              height: widget.dailyGoal.isEmpty ? 120 : null,
              width: width,
              child: Stack(
                children: [
                  widget.dailyGoal.isNotEmpty
                      ? Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: GoalProgressIndicators(
                              goalData: widget.dailyGoal,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
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
                          child: rive.RiveAnimation.asset(
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
            )),
        SizedBox(
            width: width,
            child: DailyGoalEntries(
              goalData: widget.dailyGoal,
            ))
      ],
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

    final goalData = widget.dailyGoal;

    // If no goals are available for today
    if (goalData.isEmpty) {
      final animation = _controller.findSMI('Searching_2');
      if (animation != null && mounted) {
        animation.value = true;
      }
      return;
    }

    // Calculate totals from goal data
    final goalStats = _calculateGoalStatistics(goalData);



    // Determine animation based on goal progress
    _setAnimationBasedOnProgress(goalStats);
  }

  /// Calculates overall goal statistics from the goal data
  GoalStatistics _calculateGoalStatistics(
      Map<StudyModel, DailyGoalData> goalData) {
    int totalCompleted = 0;
    int totalDailyGoal = 0;
    int totalWeeklyGoal = 0;

    for (var entry in goalData.entries) {
      final study = entry.key;
      final data = entry.value;

      totalCompleted += data.completed;
      totalDailyGoal += data.target;
      totalWeeklyGoal += study.goals.weekly;
    }

    return GoalStatistics(
      totalCompleted: totalCompleted,
      totalDailyGoal: totalDailyGoal,
      totalWeeklyGoal: totalWeeklyGoal,
      dailyProgress: totalDailyGoal > 0 ? totalCompleted / totalDailyGoal : 0.0,
      weeklyProgress:
          totalWeeklyGoal > 0 ? totalCompleted / totalWeeklyGoal : 0.0,
    );
  }

  /// Sets the appropriate animation based on goal progress
  void _setAnimationBasedOnProgress(GoalStatistics stats) {
    // No entries completed yet - show random searching animation
    if (stats.totalCompleted == 0) {
      _showRandomSearchingAnimation();
      return;
    }

    // Daily goal achieved - celebrate!
    if (stats.totalCompleted >= stats.totalDailyGoal &&
        stats.totalDailyGoal > 0) {
      _showAnimation('Blinking + Blowing the horn');
      return;
    }

    // Weekly goal achieved
    if (stats.totalCompleted >= stats.totalWeeklyGoal &&
        stats.totalWeeklyGoal > 0) {
      _showAnimation('Achieving the goal ');
      return;
    }

    // Beyond weekly goal - exceptional performance!
    if (stats.totalCompleted > stats.totalWeeklyGoal &&
        stats.totalWeeklyGoal > 0) {
      _showAnimation('Beyond the goal ');
      return;
    }

    // Some progress made but goals not yet achieved
    if (stats.totalCompleted > 0) {
      _showAnimation('Searching_3');
      return;
    }
  }

  /// Shows a random searching animation (50/50 chance between Searching_1 and Searching_2)
  void _showRandomSearchingAnimation() {
    final searchingOne = _controller.findSMI('Searching_1');
    final searchingTwo = _controller.findSMI('Searching_2');

    final random = Random().nextInt(2);
    final animation = random == 0 ? searchingOne : searchingTwo;

    if (animation != null && mounted) {
      animation.value = true;
    }
  }

  /// Helper method to show a specific animation
  void _showAnimation(String animationName) {
    final animation = _controller.findSMI(animationName);
    if (animation != null && mounted) {
      animation.value = true;
    }
  }
}

class DailyGoalEntries extends StatelessWidget {
  final Map<StudyModel, DailyGoalData> goalData;
  const DailyGoalEntries({super.key, required this.goalData});

  @override
  Widget build(BuildContext context) {
    if (goalData.isEmpty) {
      return Row(
          spacing: 6,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: CustomColors.darkGreen,
              size: 20,
            ),
            Text(
              "There's no daily goal today",
              style: CustomTypography().bodyMedium(),
            ),
          ]);
    }

    List<Widget> entryWidgets = [];
    final entries = goalData.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final study = entry.key;
      final data = entry.value;

      final displayText = "${study.name}: ${data.completed}/${data.target}"
          "${entries.length > 1 && i != entries.length - 1 ? ' | ' : ''}";

      final color = study.color ?? CustomColors.productNormal;
      final icon = determineDiaryIcon(data.diaries.first);

      entryWidgets.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            icon,
            color: color,
            height: 20,
            width: 20,
          ),
          const SizedBox(width: 6),
          Text(
            key: const Key('displayText'),
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
}

/// Data class to hold goal statistics
class GoalStatistics {
  final int totalCompleted;
  final int totalDailyGoal;
  final int totalWeeklyGoal;
  final double dailyProgress;
  final double weeklyProgress;

  GoalStatistics({
    required this.totalCompleted,
    required this.totalDailyGoal,
    required this.totalWeeklyGoal,
    required this.dailyProgress,
    required this.weeklyProgress,
  });

  bool get hasDailyGoals => totalDailyGoal > 0;
  bool get hasWeeklyGoals => totalWeeklyGoal > 0;
  bool get isDailyGoalAchieved =>
      totalCompleted >= totalDailyGoal && hasDailyGoals;
  bool get isWeeklyGoalAchieved =>
      totalCompleted >= totalWeeklyGoal && hasWeeklyGoals;
  bool get isBeyondWeeklyGoal =>
      totalCompleted > totalWeeklyGoal && hasWeeklyGoals;
  bool get hasProgress => totalCompleted > 0;
}
