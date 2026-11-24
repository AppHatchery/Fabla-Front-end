import 'dart:io';

import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/utils/statuses.dart';
import '../../../../services/live_activity_channel.dart';
import '../../../../services/live_updates_channel.dart';
import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';

class LiveActivity extends StatefulWidget {
  const LiveActivity({super.key});

  @override
  State<LiveActivity> createState() => _LiveActivityState();
}

class _LiveActivityState extends State<LiveActivity> {
  /// iOS: whether this iOS has Live Activities (16.2+), null until read.
  /// The section stays hidden until it's known to be true.
  bool? _iosSupported;

  /// iOS: the system's Live Activities setting for Fabla, null until read.
  /// Only iOS Settings can change it, so the switch mirrors it and never
  /// flips locally.
  bool? _iosEnabled;

  /// Bumped by each refresh, so a slower, older read can't overwrite a newer
  /// one when the first read and a resume overlap.
  int _refreshGeneration = 0;

  /// Android: notifications and Live Updates, null until read. Both are
  /// changed in Android Settings, so the card mirrors them.
  LiveUpdatesStatus? _androidStatus;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) _checkIosSupport();
    final refresh = Platform.isIOS ? _refreshIosStatus : _refreshAndroidStatus;
    refresh();
    // Re-read on return from Settings, where the user may have changed it.
    _lifecycle = AppLifecycleListener(onResume: refresh);
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  /// Once: the iOS version can't change while the app runs.
  Future<void> _checkIosSupport() async {
    final supported = await LiveActivityChannel.isSupported();
    if (!mounted) return;
    setState(() => _iosSupported = supported);
  }

  Future<void> _refreshIosStatus() async {
    final generation = ++_refreshGeneration;
    final enabled = await LiveActivityChannel.areActivitiesEnabled();
    if (!mounted || generation != _refreshGeneration) return;
    if (enabled == _iosEnabled) return;
    setState(() => _iosEnabled = enabled);
  }

  Future<void> _refreshAndroidStatus() async {
    final generation = ++_refreshGeneration;
    final status = await LiveUpdatesChannel.status();
    if (!mounted || generation != _refreshGeneration) return;
    if (status == _androidStatus) return;
    setState(() => _androidStatus = status);
  }

  Future<void> _openIosSettings() => openAppSettings();

  /// The blocked category's page when only one is off, else the app's.
  Future<void> _openNotificationSettings() =>
      LiveUpdatesChannel.openNotificationSettings();

  @override
  Widget build(BuildContext context) {
    // Hidden until support is known, and on iOS before 16.2.
    if (Platform.isIOS && _iosSupported != true) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Lock Screen", style: CustomTypography().titleLarge()),
        const SizedBox(height: 12),
        _card(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _card() {
    final iosEnabled = _iosEnabled ?? false;
    final notificationsOn = _androidStatus != null &&
        _androidStatus != LiveUpdatesStatus.notificationsOff;
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
              color: notificationsOn
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
                        value: notificationsOn,
                        // Disabled until the status is known; then either way
                        // the change is made in Android Settings.
                        onChanged: _androidStatus == null
                            ? null
                            : (_) => _openNotificationSettings(),
                      )
                    ],
                  ),
                  switch (_androidStatus) {
                    LiveUpdatesStatus.notificationsOff => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Notifications are off.",
                              style: CustomTypography()
                                  .bodyMedium(color: Color(0xFF5C5C5C)),
                            ),
                          ),
                          CustomTextButton(
                            onClick: _openNotificationSettings,
                            text: 'Open Settings',
                            textColor: CustomColors.productNormalActive,
                          ),
                        ],
                      ),
                    LiveUpdatesStatus.plain => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Shown as plain notifications.",
                              style: CustomTypography()
                                  .bodyMedium(color: Color(0xFF5C5C5C)),
                            ),
                          ),
                          CustomTextButton(
                            onClick: LiveUpdatesChannel.openLiveUpdateSettings,
                            text: 'Show as Live Update',
                            textColor: CustomColors.productNormalActive,
                          ),
                        ],
                      ),
                    LiveUpdatesStatus.liveUpdates ||
                    LiveUpdatesStatus.unsupported ||
                    null =>
                      const SizedBox.shrink(),
                  },
                ],
              ),
            ),
          );
  }
}
