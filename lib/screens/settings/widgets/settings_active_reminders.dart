import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/preference_service.dart';
import '../../../theme/components/buttons.dart';
import '../../../theme/components/time_picker.dart';
import '../../../theme/custom_colors.dart';
import '../../../theme/custom_typography.dart';
import '../../onboarding/presentation/widgets/active_time_tile.dart';

class ActiveReminders extends StatefulWidget {
  final List<TimeOfDay> times;
  final bool isEnabled;
  const ActiveReminders(
      {super.key, required this.times, required this.isEnabled});

  @override
  State<ActiveReminders> createState() => _ActiveRemindersState();
}

class _ActiveRemindersState extends State<ActiveReminders> {
  late String noReminderText = "No Scheduled Reminder Time";

  Future<List<String>?> getReminders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('reminder_times');
  }

  @override
  void initState() {
    super.initState();
    PreferenceService()
        .getStringListPreference(key: 'reminder_times')
        .then((reminders) {
      if (reminders == null || reminders.isEmpty) {
        setState(() {
          noReminderText = "No Scheduled Reminder Time";
        });
      } else {
        for (String reminder in reminders) {
          TimeOfDay time = TimeOfDay.fromDateTime(DateTime.parse(reminder));
          setState(() {
            widget.times.add(time);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
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
                        delete: () => {
                          deleteTime(widget.times[index]),
                        },
                        edit: (value) => editTime(index, value),
                        isEnabled: widget.isEnabled,
                      ),
                    );
                  },
                )
              : Text(
                  noReminderText,
                  style: CustomTypography()
                      .titleSmall(color: CustomColors.textTertiaryContent),
                  textAlign: TextAlign.start,
                ),
        ),
        const SizedBox(
          height: 12,
        ),
        CustomElevatedButton(
          onClick: widget.isEnabled ? () => pickDate() : null,
          text: "Add a Reminder Time",
          textColor: widget.isEnabled
              ? CustomColors.productNormalActive
              : CustomColors.textTertiaryContent,
          color: widget.isEnabled
              ? CustomColors.fillWhite
              : CustomColors.fillDisabled,
          border: Border.all(color: CustomColors.productBorderNormal, width: 2),
        ),
      ],
    );
  }

  void pickDate() async {
    final time = await showModalBottomSheet(
        backgroundColor: CustomColors.fillWhite,
        isScrollControlled: true,
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
    updatePreferences();
  }

  void deleteTime(TimeOfDay time) {
    if (widget.times.isNotEmpty) {
      setState(() {
        widget.times.remove(time);
      });
      updatePreferences();
    }
  }

  void editTime(int index, TimeOfDay time) async {
    setState(() {
      widget.times[index] = time;
    });
    updatePreferences();
  }

  void updatePreferences() async {
    final value = widget.times
        .map((e) => DateTime(0, 0, 0, e.hour, e.minute).toString())
        .toList();
    await PreferenceService()
        .setStringListPreference(key: "reminder_times", value: value);
  }
}
