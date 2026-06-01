import 'dart:async';

import 'package:audio_diaries_flutter/screens/settings/widgets/participant_details.dart';
import 'package:audio_diaries_flutter/screens/settings/widgets/settings_active_reminders.dart';
import 'package:audio_diaries_flutter/screens/settings/widgets/study_details.dart';
import 'package:audio_diaries_flutter/screens/settings/widgets/test_microphone_widget.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/getDeviceAndAppInfor.dart';
import '../../../services/preference_service.dart';
import '../../../theme/dialogs/pop_ups.dart';
import '../../onboarding/domain/repository/setup_repository.dart';
import '../../onboarding/presentation/pages/study_login.dart';

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
  final DateTime _date = DateTime.now();

  final repository = SetupRepository();

  String version = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checkNotificationPermission();
    checkMicrophonePermission();
    getAppVersion();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final v = await getAppVersion();
    if (mounted) {
      setState(() {
        version = v;
      });
    }
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
    String formattedDate = DateFormat('yyyy').format(_date);
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
        body: SingleChildScrollView(
          child: Column(children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                const SettingsStudyDetails(),

                const SizedBox(
                  height: 24,
                ),

                const ParticipantDetails(),

                const SizedBox(
                  height: 24,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Microphone",
                      style: CustomTypography()
                          .titleLarge(color: CustomColors.textNormalContent),
                    ),
                  ],
                ),
                SizedBox(
                  height: 12,
                ),
                Visibility(
                    visible: !micCheck,
                    replacement: const TestMicrophone(),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: CustomColors.fillWhite,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0, left: 16),
                            child: Stack(
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
                                        borderRadius: BorderRadius.circular(50),
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
                                        color: CustomColors.productNormalActive,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enable Microphone Access',
                                  style: CustomTypography().bodyLarge(
                                      color: CustomColors.textNormalContent),
                                ),
                                Text(
                                  'You must enable microphone Access to record audio diaries.',
                                  style: CustomTypography().bodyMedium(
                                      color: CustomColors.textSecondaryContent),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            thickness: 0.5,
                            height: 24,
                          ),
                          Center(
                            child: CustomOutlineButton(
                              onClick: () => openAppSettings().then((_) {}),
                              backgroundColor: CustomColors.productNormal,
                              color: CustomColors.productNormal,
                              borderRadius: 200,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 4.0),
                              children: Wrap(children: [
                                Text(
                                  "Open Settings",
                                  style: CustomTypography()
                                      .title(color: CustomColors.textWhite),
                                )
                              ]),
                            ),
                          ),
                          SizedBox(
                            height: 18,
                          )
                        ],
                      ),
                    )),

                ///REMINDERS
                const SizedBox(
                  height: 24,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Reminders",
                      style: CustomTypography()
                          .titleLarge(color: CustomColors.textNormalContent),
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
                            color: CustomColors.productBorderNormal, width: 1),
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
                                      borderRadius: BorderRadius.circular(50),
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
                                      color: CustomColors.productNormalActive,
                                      borderRadius: BorderRadius.circular(50),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable Notifications',
                                style: CustomTypography().bodyLarge(
                                    color: CustomColors.textNormalContent),
                              ),
                              Text(
                                'We will keep you in the loop on your entries and provide reminders for completion.',
                                style: CustomTypography().bodyMedium(
                                    color: CustomColors.textTertiaryContent),
                              ),
                              TextButton(
                                  onPressed: () {
                                    openAppSettings().then((_) {});
                                  },
                                  child: Text(
                                    'Open Settings',
                                    style: CustomTypography().button(
                                        color:
                                            CustomColors.productNormalActive),
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
                SizedBox(
                  height: 24,
                ),
                CustomFlatButton(
                    borderColor: CustomColors.warningActive,
                    color: CustomColors.fillWhite,
                    textColor: CustomColors.warningActive,
                    onClick: () => leaveStudy(context),
                    text: "Leave Study"),
                SizedBox(
                  height: 24,
                ),
              ]),
            ),
            //
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                children: [
                  Text(
                    "Fabla v$version",
                    style: CustomTypography()
                        .bodyMedium(color: CustomColors.textSecondaryContent),
                  ),
                  const SizedBox(height: 12),
                  Image.asset(
                    key: Key("emory_image"),
                    "assets/images/emory_image.png",
                    width: 180,
                    height: 55,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Copyright © $formattedDate Emory University",
                    style: CustomTypography()
                        .bodyMedium(color: CustomColors.textSecondaryContent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    "Powered by AppHatchery",
                    style: CustomTypography()
                        .bodyMedium(color: CustomColors.textSecondaryContent),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ));
  }

  void leaveStudy(BuildContext context) async {
    final results = await showDialog<bool>(
      context: context,
      builder: (context) => ExitPopUp(
        content: [
          Text(
            "Are you sure you want to leave this study?",
            style: CustomTypography().headlineMedium(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text.rich(
            TextSpan(
              text:
                  "This action is final. All data stored on this device will be ",
              style: CustomTypography().bodyLarge(),
              children: [
                TextSpan(
                  text: " permanently removed.",
                  style: CustomTypography().bodyLarge(color: Color(0xFFFC0909)),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text.rich(
            TextSpan(
              text: "Note: ",
              style: CustomTypography().bodyLarge(weight: FontWeight.w600),
              children: [
                TextSpan(
                  text: "You are exiting the daily diary component ",
                  style: CustomTypography().bodyLarge(),
                ),
                TextSpan(
                  text: "only. ",
                  style: CustomTypography().bodyLarge(weight: FontWeight.w600),
                ),
                TextSpan(
                  text:
                      "To completely withdraw from the research study and have your data removed, please contact the research team.",
                  style: CustomTypography().bodyLarge(),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    if (results == true && mounted) {
      unawaited(repository.leaveStudy());
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => StudyLogin(),
                settings: RouteSettings(name: "/StudyLogin")),
            (route) => false);
      }
    }
  }
}
