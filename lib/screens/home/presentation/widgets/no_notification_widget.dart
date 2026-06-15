import 'package:flutter/cupertino.dart';

import '../../../../services/notification_service.dart';
import '../../../../theme/components/cards.dart';

class NoNotificationWidget extends StatelessWidget {
  const NoNotificationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NotificationService.channelDisabled,
      builder: (_, channelDisabled, __) {
        if (!channelDisabled) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: NoNotificationCard(
            openSettings: NotificationService.openChannelSettings,
          ),
        );
      },
    );
  }
}