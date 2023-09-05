import 'package:audio_diaries_flutter/core/utils/dummy_data.dart';
import 'package:flutter/material.dart';

import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import 'active_time_tile.dart';
import '../../../../theme/components/time_picker.dart';

class ListActiveTimes extends StatefulWidget {
  const ListActiveTimes({super.key});

  @override
  State<ListActiveTimes> createState() => _ListActiveTimesState();
}

class _ListActiveTimesState extends State<ListActiveTimes> {
  List<TimeOfDay> times = [];

  @override
  void initState() {
    times.insert(0, fixedTime);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          child: ListView.builder(
              padding: const EdgeInsets.all(0),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: times.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index == times.length - 1 ? 0 : 10.0),
                  child: ActiveTimeTile(
                    time: times[index],
                    delete: () =>
                        {deleteTime(times[index]), Navigator.pop(context)},
                  ),
                );
              }),
        ),
        const SizedBox(
          height: 12,
        ),
        CustomElevatedButton(
          onClick: () => pickDate(),
          text: "ADD A DIARY TIME",
          textColor: CustomColors.productNormalActive,
          color: CustomColors.fillWhite,
          border: Border.all(color: CustomColors.productBorderNormal, width: 2),
          shadowColor: CustomColors.productBorderNormal,
        )
      ],
    );
  }

  void pickDate() async {
    final time = await showModalBottomSheet(
        backgroundColor: CustomColors.fillWhite,
        context: context,
        builder: (context) => const Wrap(
              children: [
                CustomTimePicker(date: null),
              ],
            ));
    if (time != null) {
      if (!times.contains(time)) {
        setState(() {
          times.add(time);
        });
      }
    }
  }

  void deleteTime(TimeOfDay time) {
    if (times.length > 1) {
      setState(() {
        times.remove(time);
      });
    }
  }
}
