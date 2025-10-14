import 'dart:io' show Platform;

import 'package:app_settings/app_settings.dart';
import 'package:audio_diaries_flutter/core/usecases/font_scaler_detector.dart';
import 'package:audio_diaries_flutter/core/usecases/page_timer.dart';
import 'package:audio_diaries_flutter/services/battery_service.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_icons.dart';
// import 'package:audio_diaries_flutter/theme/custom_icons.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
// import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rive/rive.dart' as rive;
// import 'dart:io' show Platform;

import '../../../../services/pendo_service.dart';
import '../../../../services/preference_service.dart';
import '../../../../theme/custom_colors.dart';

class NotificationAccessPage extends StatefulWidget {
  const NotificationAccessPage({super.key});

  @override
  State<NotificationAccessPage> createState() => _NotificationAccessPageState();
}

class _NotificationAccessPageState extends State<NotificationAccessPage>
    with WidgetsBindingObserver {
  bool batteryOptimization = false;
  bool requested = false;
  bool? granted;

  //Animations
  late rive.StateMachineController _controller;
  rive.SMITrigger? showTip;

  final PageTimer timer = PageTimer();
  TextScaler? scaler; // Get the size of the text scaler

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    timer.start();
    checkBattery();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      scaler = await fontScaler(context);
    });
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkBattery();
      checkForPermission();
      timer.start();
    } else if (state == AppLifecycleState.paused) {
      int spent = timer.stop();
      track(spent, "Paused");
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    _controller.dispose();
    timer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isIos = Platform.isIOS;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: CustomColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: CustomColors.backgroundSecondary,
        scrolledUnderElevation: 0.0,
        leading: IconButton(
            onPressed: () => {
                  track(timer.stop(), "Back"),
                  RouteService().navigateBack(
                      context: context, current: 'notification_access')
                },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: CustomColors.fillWhite,
              size: 32,
            )),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
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
                              granted != null && granted == true
                                  ? "Make sure you have sound on to catch these alerts on time"
                                  : "Turn on notifications for timely reminders!",
                              style: CustomTypography()
                                  .headlineLarge(color: CustomColors.textWhite),
                            ),
                            const SizedBox(height: 40.0),
                            illustrations(width)
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: height >= 700 ? 300 : height * 0.65,
                      width: width,
                      child: rive.RiveAnimation.asset(
                        'assets/animations/onboarding/notification_access.riv',
                        fit: BoxFit.fitWidth,
                        onInit: onInit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: bottomPadding > 0
                      ? bottomPadding + 34
                      : (isIos ? 34 + 34 : 34)),
              child: CustomFlatButton(
                onClick: () => navigateToNextPage(context),
                text: "Continue",
                color: CustomColors.fillWhite,
                textColor: CustomColors.productNormalActive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget illustrations(double width) {
    if (granted == null || (granted == true && batteryOptimization)) {
      return Image.asset(
        "assets/images/notification_example.png",
        width: width,
      );
    } else if (granted == false && requested) {
      return Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CustomColors.fillVanilla,
          border: Border.all(
            color: CustomColors.pumpkinOrange,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_rounded,
                    size: 24, color: CustomColors.pumpkinOrange),
                const SizedBox(
                  width: 10,
                ),
                Flexible(
                  child: Text(
                    "Oops! We recommend you turn ON notifications to allow Fabla to send you reminders to complete the study, otherwise you might not know when to submit the diaries and measures needed for this study.",
                    style: CustomTypography()
                        .bodyLarge(color: CustomColors.pumpkinOrange),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20, width: 20),
                const SizedBox(
                  width: 10,
                ),
                TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      alignment: Alignment.center,
                      backgroundColor: CustomColors.pumpkinOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    onPressed: openPermissionSettings,
                    child: Text("Open Settings",
                        style: CustomTypography()
                            .bodyLarge(color: CustomColors.textWhite)))
              ],
            ),
          ],
        ),
      );
    } else if (!batteryOptimization && requested) {
      return Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CustomColors.warningFill,
          border: Border.all(
            color: CustomColors.warningActive,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(CustomIcons.cancel,
                    size: 20, color: CustomColors.warningActive),
                const SizedBox(
                  width: 10,
                ),
                Flexible(
                  child: Text(
                    "Oops! We noticed your phone has a battery saving mode ON, this can impact receiving notifications to complete your diaries. To ensure the study runs smoothly for you we recommend you disable the power mode.",
                    style: CustomTypography()
                        .bodyLarge(color: CustomColors.warningActive),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20, width: 20),
                const SizedBox(
                  width: 10,
                ),
                TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      alignment: Alignment.center,
                      backgroundColor: CustomColors.warningActive,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    onPressed: () => openSetting(),
                    child: Text("Open Settings",
                        style: CustomTypography()
                            .bodyLarge(color: CustomColors.textWhite)))
              ],
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  onInit(rive.Artboard art) async {
    var ctrl = rive.StateMachineController.fromArtboard(art, "Animation_3");
    ctrl?.isActive = false;

    if (ctrl != null) {
      art.addController(ctrl);
      setState(() {
        _controller = ctrl;
        art.addController(_controller);
        ctrl.isActive = true;
        showTip = _controller.getTriggerInput('tip');
      });
    }
  }

  void navigateToNextPage(BuildContext context) async {
    final results = await Permission.notification.request();

    await PendoService.track("NotificationAccess", {"state": results.name});
    if (mounted) setState(() => granted = results.isGranted);
    if (granted != null && granted == true) {
      showTip?.fire();
    }
    checkBattery();
    if (requested) {
      await PreferenceService()
          .setBoolPreference(key: 'notification_requested', value: true);
      track(timer.stop(), "Finished");
      if (context.mounted) {
        RouteService()
            .navigate(null, context: context, current: 'notification_access');
      }
    }

    if (mounted) setState(() => requested = true);
  }

  track(int spent, String status) async {
    await PendoService.track("Notification Access",
        {"time_on_page": spent, "status": status, "Font Scaler": "$scaler"});
  }

  checkBattery() async {
    if (mounted) {
      if (Platform.isAndroid) {
        final _batteryOptimization =
            await BatteryService().isBatteryOptimizationDisabled();
        setState(() {
          batteryOptimization = _batteryOptimization;
        });
      } else {
        setState(() {
          batteryOptimization = true;
        });
      }
    }
  }

  openSetting() async =>
      await AppSettings.openAppSettings(type: AppSettingsType.settings);

  checkForPermission() async {
    final result = await Permission.notification.isGranted;
    if (mounted) setState(() => granted = result);
  }

  void openPermissionSettings() async =>
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
}
