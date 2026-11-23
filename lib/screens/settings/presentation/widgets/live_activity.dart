import 'dart:io';

import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../services/live_activity_channel.dart';
import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';

class LiveActivity extends StatefulWidget {
  const LiveActivity({super.key});

  @override
  State<LiveActivity> createState() => _LiveActivityState();
}

class _LiveActivityState extends State<LiveActivity> {
  bool isSwitched = true;

  /// iOS: the system's Live Activities setting for Fabla, null until read.
  /// Only iOS Settings can change it, so the switch mirrors it and never
  /// flips locally.
  bool? _iosEnabled;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _refreshIosStatus();
      // Re-read on return from Settings, where the user may have changed it.
      _lifecycle = AppLifecycleListener(onResume: _refreshIosStatus);
    }
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<void> _refreshIosStatus() async {
    final enabled = await LiveActivityChannel.areActivitiesEnabled();
    if (!mounted || enabled == _iosEnabled) return;
    setState(() => _iosEnabled = enabled);
  }

  Future<void> _openIosSettings() => openAppSettings();

  @override
  Widget build(BuildContext context) {
    final iosEnabled = _iosEnabled ?? false;
    return Platform.isIOS
        ?
        //iOS
        Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: CustomColors.productBorderNormal, width: 1),
              color: iosEnabled
                  ? CustomColors.fillWhite
                  : CustomColors.fillDisabled,
            ),
            child: Padding(
              padding:
                  EdgeInsetsGeometry.symmetric(vertical: 12, horizontal: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/icons/liveActivity.png',
                        height: 60,
                        width: 60,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Activity',
                              style: CustomTypography()
                                  .bodyLarge(weight: FontWeight.w500),
                            ),
                            Text(
                              "Recording, diary and upload progress on the Lock Screen and in the Dynamic Island",
                              style: CustomTypography()
                                  .bodyMedium(color: Color(0xFFA3A3A3)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoSwitch(
                        thumbColor:
                            CustomColors.fillWhite, // Circle color when ON
                        activeTrackColor:
                            CustomColors.productNormal, // Track color when ON
                        value: iosEnabled,
                        // Disabled until the status is known; then either way the
                        // change is made in iOS Settings.
                        onChanged: _iosEnabled == null
                            ? null
                            : (_) => _openIosSettings(),
                      )
                    ],
                  ),
                  _iosEnabled != false
                      ? SizedBox.shrink()
                      : Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Off in iOS Settings.',
                                style: CustomTypography()
                                    .bodyMedium(color: Color(0xFF5C5C5C)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomTextButton(
                              onClick: _openIosSettings,
                              text: 'Open Settings',
                              textColor: CustomColors.productNormalActive,
                            ),
                          ],
                        )
                ],
              ),
            ),
          )
        :
        //Android
        Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: CustomColors.productBorderNormal, width: 1),
              color: isSwitched
                  ? CustomColors.fillWhite
                  : CustomColors.fillDisabled,
            ),
            child: Padding(
              padding:
                  EdgeInsetsGeometry.symmetric(vertical: 12, horizontal: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/icons/liveActivity.png',
                        height: 60,
                        width: 60,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live updates',
                              style: CustomTypography()
                                  .bodyLarge(weight: FontWeight.w500),
                            ),
                            Text(
                              "Recording, diary and upload progress in your notifications and on the lock screen",
                              style: CustomTypography()
                                  .bodyMedium(color: Color(0xFFA3A3A3)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoSwitch(
                        thumbColor:
                            CustomColors.fillWhite, // Circle color when ON
                        activeTrackColor:
                            CustomColors.productNormal, // Track color when ON
                        value: isSwitched,
                        onChanged: (bool newValue) {
                          setState(() {
                            isSwitched = newValue;
                          });
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
  }
}
