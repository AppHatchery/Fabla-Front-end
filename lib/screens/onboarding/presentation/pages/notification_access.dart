import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
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
  bool canGoBack = false;
  // bool batteryOptimization = false;
  bool requested = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    if (Navigator.of(context).canPop()) {
      canGoBack = true;
    }
    // checkBattery();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // checkBattery();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
                          )
                          // : Container(
                          //     width: width,
                          //     padding: const EdgeInsets.all(16),
                          //     decoration: BoxDecoration(
                          //       color: CustomColors.warningFill,
                          //       border: Border.all(
                          //         color: CustomColors.warningActive,
                          //         width: 2,
                          //       ),
                          //       borderRadius: BorderRadius.circular(11),
                          //     ),
                          //     child: Column(
                          //       children: [
                          //         Row(
                          //           crossAxisAlignment:
                          //               CrossAxisAlignment.start,
                          //           children: [
                          //             const Icon(CustomIcons.cancel,
                          //                 size: 20,
                          //                 color: CustomColors
                          //                     .warningActive),
                          //             const SizedBox(
                          //               width: 10,
                          //             ),
                          //             Flexible(
                          //               child: Text(
                          //                 "Oops! We noticed your phone has a battery saving mode ON, this can impact receiving notifications to complete your diaries. To ensure the study runs smoothly for you we recommend you disable the power mode.",
                          //                 style: CustomTypography()
                          //                     .bodyLarge(
                          //                         color: CustomColors
                          //                             .warningActive),
                          //               ),
                          //             )
                          //           ],
                          //         ),
                          //         const SizedBox(height: 12),
                          //         Row(
                          //           crossAxisAlignment:
                          //               CrossAxisAlignment.start,
                          //           children: [
                          //             const SizedBox(
                          //                 height: 20, width: 20),
                          //             const SizedBox(
                          //               width: 10,
                          //             ),
                          //             TextButton(
                          //                 style: TextButton.styleFrom(
                          //                   padding: const EdgeInsets
                          //                       .symmetric(
                          //                       horizontal: 8,
                          //                       vertical: 4),
                          //                   alignment: Alignment.center,
                          //                   backgroundColor:
                          //                       CustomColors
                          //                           .warningActive,
                          //                   shape:
                          //                       RoundedRectangleBorder(
                          //                     borderRadius:
                          //                         BorderRadius.circular(
                          //                             11),
                          //                   ),
                          //                 ),
                          //                 onPressed: () =>
                          //                     openSetting(),
                          //                 child: Text("Open Settings",
                          //                     style: CustomTypography()
                          //                         .bodyLarge(
                          //                             color: CustomColors
                          //                                 .textWhite)))
                          //           ],
                          //         ),
                          //       ],
                          //     ),
                          //   )
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
              onClick: () => navigateToNextPage(context),
              text: "Continue",
              color: CustomColors.fillWhite,
              textColor: CustomColors.productNormalActive,
            ),
          ),
        ],
      ),
    );
  }

  void navigateToNextPage(BuildContext context) async {
    final results = await Permission.notification.request();
    await PreferenceService()
        .setBoolPreference(key: 'notification_requested', value: true);

    await PendoService.track("NotificationAccess", {"state": results.name});
    if (mounted) {
      setState(() {
        requested = true;
      });
    }
    // checkBattery();
    if (results.isGranted) {
      // if (context.mounted && batteryOptimization) {
      if (context.mounted) {
        RouteService()
            .navigate(null, context: context, current: 'notification_access');
      }
    } else {
      if (context.mounted) {
        RouteService()
            .navigate(null, context: context, current: 'notification_access');
      }
      //TODO: Show error
    }
  }

  // checkBattery() async {
  //   if (mounted) {
  //     if (Platform.isAndroid) {
  //       final _batteryOptimization =
  //           await DisableBatteryOptimization.isBatteryOptimizationDisabled ??
  //               true;
  //       setState(() {
  //         batteryOptimization = _batteryOptimization;
  //       });
  //     } else {
  //       setState(() {
  //         batteryOptimization = true;
  //       });
  //     }
  //   }
  // }

  // openSetting() async {
  //   bool? allowed = await DisableBatteryOptimization
  //       .showDisableBatteryOptimizationSettings();
  //   if (mounted) {
  //     setState(() {
  //       batteryOptimization = allowed ?? false;
  //     });
  //   }
  // }
}
