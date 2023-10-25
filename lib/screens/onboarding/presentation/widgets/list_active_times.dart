import 'package:audio_diaries_flutter/core/utils/dummy_data.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import 'active_time_tile.dart';
import '../../../../theme/components/time_picker.dart';

class ListActiveTimes extends StatefulWidget {
  final List<TimeOfDay> times;
  const ListActiveTimes({super.key, required this.times});

  @override
  State<ListActiveTimes> createState() => _ListActiveTimesState();
}

class _ListActiveTimesState extends State<ListActiveTimes> {
  @override
  void initState() {
    if (widget.times.isEmpty) {
      widget.times.insert(0, fixedTime);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          child: widget.times.isNotEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.all(0),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: widget.times.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: index == widget.times.length - 1 ? 0 : 10.0),
                      child: ActiveTimeTile(
                        time: widget.times[index],
                        delete: () => deleteTime(widget.times[index]),
                        edit: (value) => editTime(index, value),
                        isEnabled: true,
                      ),
                    );
                  })
              : Row(
                  children: [
                    Text(
                      "No scheduled diary time",
                      style: CustomTypography()
                          .titleSmall(color: CustomColors.textSecondaryContent),
                    ),
                  ],
                ),
        ),
        const SizedBox(
          height: 12,
        ),
        CustomElevatedButton(
          onClick: () => pickDate(),
          text: "Add a Reminder",
          textColor: CustomColors.productNormalActive,
          color: CustomColors.fillWhite,
          border: Border.all(color: CustomColors.productBorderNormal, width: 2),
          // shadowColor: CustomColors.productBorderNormal,
        )
      ],
    );
  }

  void pickDate() async {
    final time = await showModalBottomSheet(
        backgroundColor: CustomColors.fillWhite,
        isScrollControlled: true,
        enableDrag: false,
        context: context,
        builder: (context) => LayoutBuilder(builder: (context, constraints) {
              return const SingleChildScrollView(
                child: CustomTimePicker(date: null),
              );
            }));
    if (time != null) {
      if (!widget.times.contains(time)) {
        setState(() {
          widget.times.add(time);
        });
      }
    }
  }

  void deleteTime(TimeOfDay time) {
    setState(() {
      widget.times.remove(time);
    });
  }

  void editTime(int index, TimeOfDay time) async {
    setState(() {
      widget.times[index] = time;
    });
  }
}
