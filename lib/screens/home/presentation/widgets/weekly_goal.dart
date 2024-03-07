import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WeeklyGoalWidget extends StatefulWidget {
  final bool isExpanded;
  const WeeklyGoalWidget({super.key, required this.isExpanded});

  @override
  State<WeeklyGoalWidget> createState() => _WeeklyGoalWidgetState();
}

class _WeeklyGoalWidgetState extends State<WeeklyGoalWidget> {
  final value = 0.0;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Weekly Goal", style: CustomTypography().bodyLarge()),
            const SizedBox(width: 6),
            GestureDetector(
              child: Icon(
                widget.isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: CustomColors.textTertiaryContent,
                size: 20,
              ),
            )
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 15,
              child: Stack(
                children: [
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: 70,
                      height: 6,
                      decoration: BoxDecoration(
                        color: CustomColors.productLightBackground,
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: 10,
                      height: 6,
                      decoration: BoxDecoration(
                        color: CustomColors.productNormal,
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                  ),
                  const Positioned(
                    // left: 70 * value - 10,
                    left: 50,
                    top: 0,
                    child: Icon(CupertinoIcons.flag_fill,
                        color: CustomColors.productNormal, size: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "1/5",
              style:
                  CustomTypography().caption(color: CustomColors.productNormal),
            )
          ],
        ),
      ],
    );
  }
}
