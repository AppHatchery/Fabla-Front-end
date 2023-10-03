import 'package:audio_diaries_flutter/screens/settings/widgets/test_microphone_widget.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> with WidgetsBindingObserver {
  bool micCheck = false;
  bool notificationCheck = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checkNotificationPermission();
    checkMicrophonePermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkNotificationPermission();
      checkMicrophonePermission();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      notificationCheck = status == PermissionStatus.granted;
    });
  }

  Future<void> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    setState(() {
      micCheck = status == PermissionStatus.granted;
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
                  value: micCheck,
                  onChanged: (bool value) async {
                    if (!value) {
                      final status = await Permission.microphone.request();
                      if (status == PermissionStatus.granted) {
                        setState(() {
                          micCheck = value;
                        });
                      }
                    }
                    openAppSettings().then((_) {});
                  },
                  activeColor: CustomColors.productNormal,
                  trackColor: CustomColors.productBorderNormal,
                )
              ],
            ),
            Visibility(
              visible: !micCheck,
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
            const SizedBox(
              height: 12,
            ),
            Visibility(visible: micCheck, child: const TestMicrophone()),

            ///REMINDERS
            const SizedBox(
              height: 24,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Notifications",
                  style: CustomTypography()
                      .titleLarge(color: CustomColors.textNormalContent),
                ),
                CupertinoSwitch(
                  value: notificationCheck,
                  onChanged: (bool value) async {
                    if (!value) {
                      final status = await Permission.notification.request();
                      if (status == PermissionStatus.granted) {
                        setState(() {
                          notificationCheck = value;
                        });
                      }
                    }
                    openAppSettings().then((_) {});
                  },
                  activeColor: CustomColors.productNormal,
                  trackColor: CustomColors.productBorderNormal,
                )
              ],
            ),
            Visibility(
              visible: !notificationCheck,
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
            TextButton(
              onPressed: () => throw Exception(),
              child: const Text("Throw Test Exception"),
            ),
            // Visibility(
            //     visible: notificationCheck, child: const ListActiveTimes()),
            // const SizedBox(height: 12.0),
          ]),
        )),
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
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  "Copyright © 2023 Emory University",
                  style: CustomTypography()
                      .bodyMedium(color: CustomColors.textSecondaryContent),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}
