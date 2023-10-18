import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/mic_access.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../services/preference_service.dart';
import '../../../../theme/custom_colors.dart';

class NotificationAccessPage extends StatefulWidget {
  const NotificationAccessPage({super.key});

  @override
  State<NotificationAccessPage> createState() => _NotificationAccessPageState();
}

class _NotificationAccessPageState extends State<NotificationAccessPage> {
  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 34.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              child: Column(children: [
                Text(
                  "Turn on notifications for timely reminders!",
                  style: CustomTypography()
                      .headlineLarge(color: CustomColors.textWhite),
                ),
                const SizedBox(height: 16.0),
                Image.asset(
                  "assets/images/notification_access.png",
                  width: width,
                ),
              ]),
            ),
            CustomElevatedButton(
              onClick: () => navigateToNextPage(),
              text: "CONTINUE",
              color: CustomColors.fillWhite,
              shadowColor: CustomColors.productBorderNormal,
              textColor: CustomColors.productNormalActive,
            )
          ],
        ),
      ),
    );
  }

  void navigateToNextPage() async {
    final results = await Permission.notification.request();
    await PreferenceService()
        .setBoolPreference(key: 'notification_requested', value: true);

    if (results.isGranted) {
      final repository = SetupRepository();
      repository.createNotifications();

      if (context.mounted) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const MicAccessPage()));
      }
    } else {
      //TODO: Show error
    }
  }
}
