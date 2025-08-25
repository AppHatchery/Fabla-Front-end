import 'dart:convert';

import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';
import 'package:audio_diaries_flutter/screens/settings/cubit/settings_cubit.dart';
import 'package:audio_diaries_flutter/screens/settings/widgets/update_widgets.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsOnboarding extends StatefulWidget {
  final List<Questions> questions;
  const SettingsOnboarding({super.key, required this.questions});

  @override
  State<SettingsOnboarding> createState() => _SettingsOnboardingState();
}

class _SettingsOnboardingState extends State<SettingsOnboarding> {
  late SettingsCubit _cubit;

  bool updated = false;
  late MaterialLocalizations localizations;

  final List<Questions> _questions = [];

  @override
  void initState() {
    _cubit = context.read<SettingsCubit>();
    _questions.addAll(widget.questions);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    localizations = MaterialLocalizations.of(context);
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, bool? result) {
        if (didPop) {
          return;
        }

        Navigator.pop(context, updated);
      },
      child: Scaffold(
        backgroundColor: CustomColors.fillNormal,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: CustomColors.fillNormal,
          scrolledUnderElevation: 0.0,
          title: Text(
            "Participant Details",
            style: CustomTypography().titleLarge(),
          ),
          centerTitle: true,
          leading: IconButton(
              key: Key("back_button"),
              onPressed: () => Navigator.pop(context, updated),
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 32,
              )),
          shape: const Border(
              bottom: BorderSide(
            color: CustomColors.productBorderNormal,
            width: 2,
          )),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Important Note
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      child: Text(
                        "Important Note",
                        style: CustomTypography()
                            .titleLarge(color: CustomColors.textNormalContent),
                      ),
                    ),
                  ],
                ),

                Container(
                  width: width,
                  padding: const EdgeInsets.all(16),
                  decoration: ShapeDecoration(
                    color: Color(0xFFD0DEF4),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(width: 2, color: Color(0xFF4396FE)),
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        size: 24,
                        color: Color(0xFF0066E6),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: Text(
                          "Changing the settings here will change the properties related to the study. Please only do so under the researcher’s instructions.",
                          style: CustomTypography()
                              .bodyLarge(color: Color(0xFF0066E6)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 40,
                ),

                questionList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget questionList() {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: _questions.length,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Question ${index + 1}",
                  style: CustomTypography().titleLarge(),
                ),
                const SizedBox(
                  height: 12,
                ),
                questionTile(_questions[index], index),
              ],
            ),
          );
        });
  }

  Widget questionTile(Questions question, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
          color: CustomColors.fillWhite,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: CustomColors.productBorderNormal, width: 2)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.title,
                  style: CustomTypography()
                      .titleLarge(color: CustomColors.textNormalContent),
                ),
                Text(
                  getAnswer(question),
                  style: CustomTypography()
                      .bodyMedium(color: CustomColors.textSecondaryContent),
                ),
              ],
            ),
          ),
          IconButton(
              key: Key("edit_icon_button"),
              onPressed: () => edit(question, index),
              icon: Icon(
                Icons.edit_outlined,
                color: CustomColors.textSecondaryContent,
                size: 30,
              )),
        ],
      ),
    );
  }

  String getAnswer(Questions question) {
    final ans = question.answer;

    if (ans == null) {
      return "";
    }

    switch (question.type) {
      case "multiple":
        final List<String> _selected = json
            .decode(ans)
            .cast()
            .toList()
            .map<String>((element) => element.toString())
            .toList();
        final selected = question.options
            ?.map((option) =>
                _selected.contains(option.value) ? option.title : null)
            .whereType<String>()
            .toList();
        return selected?.join(", ") ?? "";
      case "radio":
        final Option? selected =
            question.options?.firstWhere((option) => option.value == ans);
        return selected?.title ?? "";
      case "time":
        final time = timeOfDayFromString(ans);
        return localizations.formatTimeOfDay(time);

      default:
        return ans;
    }
  }

  void edit(Questions question, int index) async {
    if (question.type == "time") {
      final time = timeOfDayFromString(question.answer!);
      final _time = await showModalBottomSheet(
          backgroundColor: CustomColors.fillWhite,
          isScrollControlled: true,
          enableDrag: false,
          context: context,
          routeSettings: RouteSettings(name: "/SettingsUpdateTimePickerModal"),
          builder: (context) => LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  child: UpdateTimePicker(
                    title: question.title,
                    subtitle: question.subtitle ?? "",
                    index: index + 1,
                    date: time,
                    minuteInterval: 1,
                  ),
                );
              }));

      if (_time != null) {
        update(question, '$_time:00');
      }
    } else if (question.type == 'text') {
      final result = await showModalBottomSheet(
          backgroundColor: CustomColors.fillWhite,
          isScrollControlled: true,
          enableDrag: false,
          context: context,
          routeSettings: RouteSettings(name: "/SettingsUpdateTextModal"),
          builder: (context) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: UpdateTextOption(
                      title: question.title,
                      subtitle: question.subtitle ?? "",
                      index: index + 1,
                      answer: question.answer,
                    ),
                  );
                }),
              ));

      if (result != null) {
        update(question, result);
      }
    } else if (question.type == 'slider') {
      final result = await showModalBottomSheet(
          backgroundColor: CustomColors.fillWhite,
          isScrollControlled: true,
          enableDrag: false,
          context: context,
          routeSettings: RouteSettings(name: "/SettingsUpdateSliderModal"),
          builder: (context) => LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  child: UpdateSliderOption(
                    title: question.title,
                    subtitle: question.subtitle ?? "",
                    index: index + 1,
                    min: question.min!,
                    max: question.max!,
                    value: question.answer ?? "0",
                    defaultValue: question.defaultValue ?? 0,
                    minLabel: question.minLabel ?? "",
                    maxLabel: question.maxLabel ?? "",
                  ),
                );
              }));
      if (result != null) {
        update(question, result);
      }
    } else if (question.type == "multiple") {
      final selected = question.answer != null
          ? json
              .decode(question.answer!)
              .cast()
              .toList()
              .map<String>((element) => element.toString())
              .toList()
          : <String>[];
      final result = await showModalBottomSheet(
          backgroundColor: CustomColors.fillWhite,
          isScrollControlled: true,
          enableDrag: false,
          context: context,
          routeSettings:
              RouteSettings(name: "/SettingsUpdateMultipleChoiceModal"),
          builder: (context) => LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  child: UpdateMultipleOptions(
                    title: question.title,
                    subtitle: question.subtitle ?? "",
                    index: index + 1,
                    selected: selected,
                    options: question.options!,
                  ),
                );
              }));
      if (result != null) {
        update(question, result);
      }
    } else if (question.type == 'radio') {
      final result = await showModalBottomSheet(
          backgroundColor: CustomColors.fillWhite,
          isScrollControlled: true,
          enableDrag: false,
          context: context,
          routeSettings: RouteSettings(name: "/SettingsUpdateRadioOptionModal"),
          builder: (context) => LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  child: UpdateRadioOptions(
                    title: question.title,
                    subtitle: question.subtitle ?? "",
                    index: index + 1,
                    selected: question.answer ?? "",
                    options: question.options!,
                  ),
                );
              }));
      if (result != null) {
        update(question, result);
      }
    } else if (question.type == 'date') {
      final date = question.answer != null
          ? stringDateOnlyToDateTime(question.answer!)
          : null;

      final result = await showModalBottomSheet(
          backgroundColor: CustomColors.fillWhite,
          isScrollControlled: true,
          enableDrag: false,
          context: context,
          routeSettings: RouteSettings(name: "/SettingsUpdateDateModal"),
          builder: (context) => LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  child: UpdateDateOption(
                      title: question.title,
                      subtitle: question.subtitle ?? "",
                      index: index + 1,
                      date: date ?? DateTime.now()),
                );
              }));
      if (result != null) {
        update(question, result);
      }
    }
  }

  void update(Questions question, dynamic answer) {
    _cubit.save(question, answer);
    if (mounted) {
      setState(() {
        updated = true;
      });
    }
    reload();
  }

  reload() async {
    final updated = await _cubit.reload();

    if (mounted) {
      setState(() {
        _questions.clear();
        _questions.addAll(updated);
      });
    }
  }
}
