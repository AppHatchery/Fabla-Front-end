import 'package:flutter/cupertino.dart';

import '../../../../services/notification_service.dart';
import '../../../../theme/components/cards.dart';

/// Warns the participant when reminders are off, or (Android) likely to be
/// late because exact alarms are denied or battery optimization is on.
class NoNotificationWidget extends StatelessWidget {
  const NoNotificationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NotificationService.channelDisabled,
      builder: (_, channelDisabled, __) {
        if (channelDisabled) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: NoNotificationCard(
              openSettings: NotificationService.openChannelSettings,
            ),
          );
        }
        return ValueListenableBuilder<ReminderReliabilityIssue?>(
          valueListenable: NotificationService.reliabilityIssue,
          builder: (_, issue, __) {
            if (issue == null) return const SizedBox.shrink();
            final (title, message) = switch (issue) {
              ReminderReliabilityIssue.exactAlarmsOff => (
                  "Reminders may arrive late",
                  "Allow \"Alarms & reminders\" for Fabla in Settings so diary reminders arrive on time.",
                ),
              ReminderReliabilityIssue.batteryOptimized => (
                  "Reminders may arrive late",
                  "Battery saving can delay Fabla's reminders. In Settings, open Battery and choose \"Unrestricted\" for Fabla.",
                ),
            };
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: NoNotificationCard(
                title: title,
                message: message,
                openSettings: NotificationService.openReliabilitySettings,
              ),
            );
          },
        );
      },
    );
  }
}
