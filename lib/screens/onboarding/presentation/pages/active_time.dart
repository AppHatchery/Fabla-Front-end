import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/notification_access.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/list_active_times.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:flutter/material.dart';

import '../../../../services/pendo_service.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import '../widgets/avatar_background.dart';

class ActiveTimePage extends StatefulWidget {
  const ActiveTimePage({super.key});

  @override
  State<ActiveTimePage> createState() => _ActiveTimePageState();
}

class _ActiveTimePageState extends State<ActiveTimePage> {
  List<TimeOfDay> times = [];
  bool canGoBack = false;

  @override
  void initState() {
    if (Navigator.of(context).canPop()) {
      canGoBack = true;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: CustomColors.fillWhite,
        appBar: AppBar(
          backgroundColor: CustomColors.backgroundSecondary,
          scrolledUnderElevation: 0.0,
          leading: canGoBack
              ? IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: CustomColors.fillWhite,
                    size: 32,
                  ))
              : null,
        ),
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(builder: (context, constraints) {
            return Container(
              color: CustomColors.fillWhite,
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraint) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraint.maxHeight),
                          child: IntrinsicHeight(
                            child: Container(
                              color: CustomColors.backgroundSecondary,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Text(
                                      "When would you like to receive reminders?",
                                      style: CustomTypography().headlineLarge(
                                          color: CustomColors.textWhite),
                                    ),
                                  ),
                                  Expanded(child: Container()),
                                  SizedBox(
                                    height: 500,
                                    child: AvatarBackground(
                                        height: height,
                                        width: width,
                                        image: "assets/images/active_time.png",
                                        avatarType: "animation",
                                        animation:
                                            "assets/animations/onboarding/onboarding_remindersetting.riv",
                                        onContinue: () => navigateToNextPage(),
                                        children: [
                                          Text(
                                            "Reminder",
                                            style:
                                                CustomTypography().titleLarge(),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          ListActiveTimes(times: times),
                                        ]),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: CustomFlatButton(
                        onClick: navigateToNextPage, text: "Continue"),
                  ),
                ],
              ),
            );
          }),
        ));
  }

  void navigateToNextPage() async {
    final value = times
        .map((e) => DateTime(0, 0, 0, e.hour, e.minute).toString())
        .toList();

    if (value.isNotEmpty) {
      await PreferenceService()
          .setStringListPreference(key: "reminder_times", value: value);
    }

    await PendoService.track("ReminderSetting", {
      "page": "onboarding",
      "number_of_reminders": times.length.toString(),
      "reminders": times.toString(),
    });

    await PreferenceService()
        .setBoolPreference(key: 'reminders_set', value: true);
    if (context.mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const NotificationAccessPage()));
    }
  }
}
