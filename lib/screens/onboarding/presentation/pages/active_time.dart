import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/notification_access.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/list_active_times.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: CustomColors.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: CustomColors.backgroundSecondary,
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: CustomColors.fillWhite,
                size: 32,
              )),
        ),
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(builder: (context, constraints) {
            final constraintHeight = constraints.maxHeight;
            return SingleChildScrollView(
              child: SizedBox(
                height: constraintHeight,
                width: width,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "What time of day would you like to do your diary?",
                        style: CustomTypography()
                            .headlineLarge(color: CustomColors.textWhite),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Expanded(
                      child: SizedBox(
                        width: width,
                        child: AvatarBackground(
                            height: height,
                            width: width,
                            image: "assets/images/active_time.png",
                            onContinue: () => navigateToNextPage(),
                            children: [
                              Text(
                                "Reminder Time",
                                style: CustomTypography().titleLarge(),
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              ListActiveTimes(times: times),
                            ]),
                      ),
                    )
                  ],
                ),
              ),
            );
          }),
        ));
  }

  void navigateToNextPage() async {
    final value = times.map((e) => DateTime(0,0,0, e.hour, e.minute).toString()).toList();
    if(value.isNotEmpty){
      await PreferenceService().setStringListPreference(key: "reminder_times", value: value);
    }


    if (context.mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const NotificationAccessPage()));
    }
  }
}
