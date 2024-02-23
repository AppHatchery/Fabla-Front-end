import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/calendar_widget.dart';
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
      backgroundColor: CustomColors.fillWhite,
      body: Stack(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: SizedBox(
                                height: 120,
                                width: 120,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.5, end: 0.8),
                                  duration: const Duration(milliseconds: 1000),
                                  builder: (context, value, _) =>
                                      CircularProgressIndicator(
                                    strokeWidth: 5,
                                    value: value,
                                    backgroundColor:
                                        CustomColors.productLightBackground,
                                    color: CustomColors.productNormal,
                                  ),
                                )),
                          ),
                          Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 10,
                                    color: Colors.white,
                                  ),
                                ],
                              )),
                          Container(
                            height: 120,
                            width: 120,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.only(top: 5),
                            child: Image.asset(
                              "assets/images/avatar_complete.png",
                              width: 80,
                              height: 80,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Text(
                        "Thanks for your response!",
                        style: CustomTypography().headlineMedium(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Text(
                        "Your input is incredibly valuable for our study's progress. We can't wait to hear from you again soon!",
                        style: CustomTypography().bodyLarge(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      const CompleteCalendarWidget()
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
                    color: CustomColors.productNormal,
                    textColor: CustomColors.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
