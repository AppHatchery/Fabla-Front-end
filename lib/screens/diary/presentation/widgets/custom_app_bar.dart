import 'package:flutter/material.dart';

import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_icons.dart';
import '../../../../theme/custom_typography.dart';

/// this is a custom AppBar that is being used in the DiaryPageView
/// the skip button has no functionality yet
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: CustomColors.fillNormal,
      scrolledUnderElevation: 0.0,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context, true);
        },
        icon: const Icon(CustomIcons.close),
        iconSize: 15.0,
      ),
      title: Text(
        "New Daily Diary",
        style: CustomTypography()
            .titleSmall(color: CustomColors.textNormalContent),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: () {
            print("Skip clicked!");
          },
          child: Text(
            "Skip",
            style: CustomTypography()
                .titleSmall(color: CustomColors.textNormalContent),
          ),
        ),
      ],
    );
  }
}
