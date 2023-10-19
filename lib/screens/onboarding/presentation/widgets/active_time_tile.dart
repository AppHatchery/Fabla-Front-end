import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

import '../../../../theme/custom_colors.dart';
import '../../../../theme/components/time_picker.dart';
import '../../../../theme/custom_icons.dart';

class ActiveTimeTile extends StatefulWidget {
  final TimeOfDay time;
  final VoidCallback delete;
  final ValueChanged<TimeOfDay>? edit;
  final bool isEnabled;
  const ActiveTimeTile(
      {super.key,
      required this.time,
      required this.delete,
      this.edit,
      required this.isEnabled});

  @override
  State<ActiveTimeTile> createState() => _ActiveTimeTileState();
}

class _ActiveTimeTileState extends State<ActiveTimeTile> {
  late MaterialLocalizations localizations = MaterialLocalizations.of(context);
  late TimeOfDay timeOfDay = widget.time;
  late String period = "";

  @override
  void initState() {
    getPeriod(timeOfDay.hour);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
          color: widget.isEnabled
              ? CustomColors.fillWhite
              : CustomColors.fillDisabled,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: CustomColors.productBorderNormal, width: 2)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                period,
                style: CustomTypography().titleLarge(
                    color: widget.isEnabled
                        ? CustomColors.textNormalContent
                        : CustomColors.textTertiaryContent),
              ),
              Text(
                localizations.formatTimeOfDay(timeOfDay),
                style: CustomTypography().titleMedium(
                    color: widget.isEnabled
                        ? CustomColors.textNormalContent
                        : CustomColors.textTertiaryContent),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                  onPressed:
                      widget.isEnabled ? () => pickDate(timeOfDay) : null,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: widget.isEnabled
                        ? CustomColors.productNormal
                        : CustomColors.textTertiaryContent,
                    size: 24,
                  )),
              IconButton(
                  onPressed: widget.isEnabled
                      ? () {
                          widget.delete();
                        }
                      : null,
                  icon: Icon(
                    CustomIcons.delete,
                    color: widget.isEnabled
                        ? CustomColors.warningActive
                        : CustomColors.textTertiaryContent,
                    size: 24,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  void getPeriod(int hour) {
    if (hour >= 4 && hour <= 12) {
      period = "Morning";
    } else if (hour >= 12 && hour <= 17) {
      period = "Afternoon";
    } else if (hour >= 17 && hour <= 22) {
      period = "Evening";
    } else if (hour >= 22 || hour <= 4) {
      period = "Late Night";
    }
  }

  void pickDate(TimeOfDay? date) async {
    final time = await showModalBottomSheet(
        backgroundColor: CustomColors.fillWhite,
        isScrollControlled: true,
        enableDrag: false,
        context: context,
        builder: (context) => LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                child: CustomTimePicker(
                  date: date,
                  onDelete: () => date != null ? widget.delete() : null,
                ),
              );
            }));

    if (time != null) {
      setState(() {
        timeOfDay = time;
        getPeriod(timeOfDay.hour);
      });
      widget.edit!(timeOfDay);
    }
  }
}
