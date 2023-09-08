import 'package:app_settings/app_settings.dart';
import 'package:audio_diaries_flutter/screens/settings/widgets/test_microphone_widget.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../onboarding/presentation/widgets/list_active_times.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool light = false;
  bool light2 = false;

  @override
  void initState() {
    super.initState();
    checkNotificationPermission();
    checkMicrophonePermission();
  }

  Future<void> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      light2 = status == PermissionStatus.granted;
    });
  }

  Future<void> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    setState(() {
      light = status == PermissionStatus.granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.fillNormal,
      appBar: AppBar(
        backgroundColor: CustomColors.fillNormal,
        title: Text(
          "Settings",
          style: CustomTypography()
              .titleLarge(color: CustomColors.textNormalContent),
        ),
        centerTitle: true,
      ),
      body: Column(children: [
        Expanded(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Microphone Access",
                  style: CustomTypography()
                      .titleLarge(color: CustomColors.textNormalContent),
                ),
                CupertinoSwitch(
                  value: light,
                  onChanged: (bool value) {
                    setState(() {
                      light = value;
                    });
                  },
                  activeColor: CustomColors.productNormal,
                  trackColor: CustomColors.productBorderNormal,
                )
              ],
            ),
            Visibility(
              visible: !light,
              child: Column(
                children: [
                  Text(
                    "You must enable microphone access to record audio diaries.",
                    style: CustomTypography()
                        .bodyMedium(color: CustomColors.textTertiaryContent),
                  )
                ],
              ),
            ),
            Visibility(visible: light, child: const TestMicrophone()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Reminders",
                  style: CustomTypography()
                      .titleLarge(color: CustomColors.textNormalContent),
                ),
                CupertinoSwitch(
                  value: light2,
                  onChanged: (bool value) {
                    setState(() {
                      light2 = value;
                    });
                  },
                  activeColor: CustomColors.productNormal,
                  trackColor: CustomColors.productBorderNormal,
                )
              ],
            ),
            Visibility(
              visible: !light2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Enable notifications so you won't miss the diary!",
                        style: CustomTypography().bodyMedium(
                            color: CustomColors.textTertiaryContent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
            Visibility(visible: light2, child: const ListActiveTimes()),
            const SizedBox(height: 12.0),
          ]),
        )),
        // ElevatedButton(
        //   onPressed: () {
        //     openAppSettings();
        //     //AppSettings.openAppSettings(type: AppSettingsType.settings);
        //   },
        //   child: const Text('Open Microphone Settings'),
        // ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "Privacy & Terms",
                    style: CustomTypography()
                        .bodyMedium(color: CustomColors.textSecondaryContent),
                  ),
                ),
                Text(
                  "|",
                  style: CustomTypography()
                      .bodyMedium(color: CustomColors.textSecondaryContent),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "Provide Feedback",
                    style: CustomTypography()
                        .bodyMedium(color: CustomColors.textSecondaryContent),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Image.asset(
                "assets/images/emory_logo.png",
              ),
              const SizedBox(height: 24),
              Text(
                "Dayrio Version 1.1",
                style: CustomTypography()
                    .bodyMedium(color: CustomColors.textSecondaryContent),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}
