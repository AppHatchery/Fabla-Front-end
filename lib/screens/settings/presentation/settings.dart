import 'package:audio_diaries_flutter/screens/settings/widgets/settings_active_reminders.dart';
import 'package:audio_diaries_flutter/screens/settings/widgets/test_microphone_widget.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/preference_service.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> with WidgetsBindingObserver {
  bool micCheck = false;
  bool notificationCheck = false;
  List<TimeOfDay> times = [];
  bool isButtonVisible = true;

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

  void loadReminders() async {
    final reminders = await PreferenceService()
        .getStringListPreference(key: 'reminder_times');
    if (reminders != null) {
      for (String reminder in reminders) {
        TimeOfDay time = TimeOfDay.fromDateTime(DateTime.parse(reminder));
        setState(() {
          times.add(time);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: CustomColors.fillNormal,
        appBar: AppBar(
            backgroundColor: CustomColors.fillNormal,
            scrolledUnderElevation: 0.0,
            title: Text(
              "Settings",
              style: CustomTypography()
                  .titleLarge(color: CustomColors.textNormalContent),
            ),
            automaticallyImplyLeading: false,
            centerTitle: true,
            shape: const Border(
                bottom: BorderSide(
              color: CustomColors.productBorderNormal,
              width: 2,
            ))),
        body: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 12.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Microphone",
                              style: CustomTypography().titleLarge(
                                  color: CustomColors.textNormalContent),
                            ),
                          ],
                        ),
                        Visibility(
                            visible: !micCheck,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: CustomColors.productBorderNormal,
                                    width: 1),
                                color: CustomColors.fillWhite,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.mic,
                                        color: CustomColors.productNormalActive,
                                        size: 46,
                                      ),
                                      Positioned(
                                        right: 7,
                                        top: 3,
                                        child: Container(
                                          padding: const EdgeInsets.all(1),
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              border: Border.all(
                                                width: 1,
                                                color: Colors.white,
                                              )),
                                          constraints: const BoxConstraints(
                                            minWidth: 15,
                                            minHeight: 15,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(1),
                                            decoration: BoxDecoration(
                                              color: CustomColors
                                                  .productNormalActive,
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  Expanded(
                                      child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Enable Microphone Access',
                                        style: CustomTypography().bodyLarge(
                                            color:
                                                CustomColors.textNormalContent),
                                      ),
                                      Text(
                                        'You must enable microphone Access to record audio diaries.',
                                        style: CustomTypography().bodyMedium(
                                            color: CustomColors
                                                .textTertiaryContent),
                                      ),
                                      TextButton(
                                          onPressed: () {
                                            openAppSettings().then((_) {});
                                          },
                                          child: Text(
                                            'Open Settings',
                                            style: CustomTypography().button(
                                                color: CustomColors
                                                    .productNormalActive),
                                          ))
                                    ],
                                  ))
                                ],
                              ),
                            )),
                        const SizedBox(
                          height: 12,
                        ),
                        Visibility(
                            visible: micCheck, child: const TestMicrophone()),

                        ///REMINDERS
                        const SizedBox(
                          height: 24,
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Reminders",
                              style: CustomTypography().titleLarge(
                                  color: CustomColors.textNormalContent),
                            ),
                          ],
                        ),
                        Visibility(
                            visible: !notificationCheck,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: CustomColors.productBorderNormal,
                                    width: 1),
                                color: CustomColors.fillWhite,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.notifications,
                                        color: CustomColors.productNormalActive,
                                        size: 46,
                                      ),
                                      Positioned(
                                        right: 6,
                                        top: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(1),
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              border: Border.all(
                                                width: 1,
                                                color: Colors.white,
                                              )),
                                          constraints: const BoxConstraints(
                                            minWidth: 15,
                                            minHeight: 15,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(1),
                                            decoration: BoxDecoration(
                                              color: CustomColors
                                                  .productNormalActive,
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  Expanded(
                                      child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Enable Notifications',
                                        style: CustomTypography().bodyLarge(
                                            color:
                                                CustomColors.textNormalContent),
                                      ),
                                      Text(
                                        'We will keep you in the loop on your tasks and provide reminders for completion.',
                                        style: CustomTypography().bodyMedium(
                                            color: CustomColors
                                                .textTertiaryContent),
                                      ),
                                      TextButton(
                                          onPressed: () {
                                            openAppSettings().then((_) {});
                                          },
                                          child: Text(
                                            'Open Settings',
                                            style: CustomTypography().button(
                                                color: CustomColors
                                                    .productNormalActive),
                                          ))
                                    ],
                                  ))
                                ],
                              ),
                            )),
                        const SizedBox(height: 12.0),
                        ActiveReminders(
                          times: times,
                          isEnabled: notificationCheck,
                        ),
                        const SizedBox(height: 12.0),
                      ]),
                ),
                //
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    children: [
                      Text(
                        "Fabla 1.0",
                        style: CustomTypography().bodyMedium(
                            color: CustomColors.textSecondaryContent),
                      ),
                      const SizedBox(height: 12),
                      Image.asset(
                        "assets/images/emory_image.png",
                        width: 180,
                        height: 55,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Copyright © 2023 Emory University",
                        style: CustomTypography().bodyMedium(
                            color: CustomColors.textSecondaryContent),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          )
        ]));
  }
}
