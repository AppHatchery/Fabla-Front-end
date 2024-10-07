import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/dynamic_page.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rive/rive.dart' as rive;

import '../../../../services/pendo_service.dart';
import '../../../../services/preference_service.dart';
import '../../../../theme/custom_colors.dart';

class NotificationAccessPage extends StatefulWidget {
  const NotificationAccessPage({super.key});

  @override
  State<NotificationAccessPage> createState() => _NotificationAccessPageState();
}

class _NotificationAccessPageState extends State<NotificationAccessPage> {
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
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: CustomColors.backgroundSecondary,
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, bottom: 34.0),
                      child: Column(
                        children: [
                          Text(
                            "Turn on notifications for timely reminders!",
                            style: CustomTypography()
                                .headlineLarge(color: CustomColors.textWhite),
                          ),
                          const SizedBox(height: 40.0),
                          Image.asset(
                            "assets/images/notification_example.png",
                            width: width,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: height >= 700 ? 300 : height * 0.65,
                    width: width,
                    child: const rive.RiveAnimation.asset(
                        stateMachines: [],
                        'assets/animations/onboarding/onboarding_getnotified.riv',
                        fit: BoxFit.fitWidth),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: CustomFlatButton(
              onClick: () => navigateToNextPage(),
              text: "Continue",
              color: CustomColors.fillWhite,
              textColor: CustomColors.productNormalActive,
            ),
          ),
        ],
      ),
    );
  }

  void navigateToNextPage() async {
    final results = await Permission.notification.request();
    await PreferenceService()
        .setBoolPreference(key: 'notification_requested', value: true);

    await PendoService.track("NotificationAccess", {"state": results.name});
    if (results.isGranted) {

      if (context.mounted) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const DynamicOnBoardingHub()));
      }
    } else {
      if (context.mounted) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const DynamicOnBoardingHub()));
      }
      //TODO: Show error
    }
  }
}
