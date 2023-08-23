import 'package:audio_diaries_flutter/main.dart';
import 'package:flutter/material.dart';

import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

/// this is the last page in the New Daily Diary flow
/// The button leads to the home page
class DiaryCompletionPage extends StatelessWidget {
  const DiaryCompletionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.backgroundSecondary,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/avatar_diary.png",
                    width: 112,
                    height: 112,
                  ),
                  Text(
                    "Success!",
                    style: CustomTypography()
                        .headlineLarge(color: CustomColors.textWhite),
                  ),
                  Text(
                    "I submitted your diary",
                    style: CustomTypography()
                        .headlineMedium(color: CustomColors.textWhite),
                  ),
                  Text(
                    "I look forward to hearing from you next time",
                    style: CustomTypography()
                        .titleSmall(color: CustomColors.textWhite),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: CustomFlatButton(
                onClick: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const Hub()));
                },
                text: "Return Home",
                color: CustomColors.productLightPrimaryNormalWhite,
                textColor: CustomColors.productDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
