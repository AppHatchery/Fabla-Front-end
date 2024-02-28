import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyGoalPopup extends StatefulWidget {
  final AnimationController controller;
  const WeeklyGoalPopup({super.key, required this.controller});

  @override
  State<WeeklyGoalPopup> createState() => _WeeklyGoalPopupState();
}

class _WeeklyGoalPopupState extends State<WeeklyGoalPopup> {
  String thisWeek = "";

  // late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    thisWeek = getThisWeek();
    // _controller = AnimationController(
    //   duration: const Duration(milliseconds: 300),
    //   vsync: this,
    // );
    _animation =
        CurvedAnimation(parent: widget.controller, curve: Curves.fastOutSlowIn);
    //_controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    if (mounted) {
      widget.controller.reverse();
    }
    // _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -2),
        end: const Offset(0, 0),
      ).animate(_animation),
      child: Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //THIS WEEK
            Text(
              thisWeek,
              style: CustomTypography().caption(),
            ),
            const SizedBox(
              height: 6,
            ),

            //TAG
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(
                  Icons.restart_alt_outlined,
                  color: CustomColors.productNormal,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  "Repeatable Entry",
                  style: CustomTypography().bodyMedium(),
                )
              ],
            ),
            const SizedBox(
              height: 2,
            ),
            //INTRODUCTION
            Text(
              "Submit at least 4 repeatable entries this week to complete your goal.",
              style: CustomTypography().caption(),
            ),
            const SizedBox(
              height: 6,
            ),
            //PROGRESS
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: width - 32,
                  height: 45,
                  child: Stack(
                    children: [
                      //PROGRESS BAR BACKGROUND
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: width - 32,
                          height: 6,
                          constraints: const BoxConstraints(maxHeight: 6),
                          decoration: BoxDecoration(
                            color: CustomColors.productLightBackground,
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                      ),
                      //PROGRESS BAR
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: (width - 32) * 0.1,
                          height: 6,
                          decoration: BoxDecoration(
                            color: CustomColors.productNormal,
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                      ),
                      //PROGRESS INDICATOR
                      Positioned(
                        left: (width - 32) * 0.1,
                        top: 0,
                        bottom: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const SizedBox(height: 20, width: 20),
                            Text(
                              "1",
                              style: CustomTypography().caption(),
                            )
                          ],
                        ),
                      ),
                      //LOWER GOAL
                      Positioned(
                        left: (width - 32) * 0.7,
                        top: 0,
                        bottom: 0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(CupertinoIcons.flag_fill,
                                color: CustomColors.productNormal, size: 17),
                            Text(
                              "4",
                              style: CustomTypography().caption(),
                            )
                          ],
                        ),
                      ),
                      //HIGHER GOAL
                      Positioned(
                        // left: 70 * value - 10,
                        left: (width - 32) * 0.95,
                        top: 0,
                        bottom: 0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.emoji_events_rounded,
                                color: CustomColors.productNormal, size: 20),
                            Text(
                              "5",
                              style: CustomTypography().caption(),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  getThisWeek() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final DateFormat formatter = DateFormat("EEEE, MMM d");

    return "${formatter.format(monday)} - ${formatter.format(sunday)}";
  }
}
