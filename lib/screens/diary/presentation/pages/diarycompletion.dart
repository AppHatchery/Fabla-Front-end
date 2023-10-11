import 'package:audio_diaries_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import '../widgets/circle_transition_clipper.dart';

/// this is the last page in the New Daily Diary flow
/// The button leads to the home page
class DiaryCompletionPage extends StatelessWidget {
  const DiaryCompletionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: CustomColors.backgroundSecondary,
      body: Stack(
        children: [
          FutureBuilder(
            future: Future.delayed(const Duration(milliseconds: 250)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return SizedBox(
                    height: height,
                    width: width,
                    child: Lottie.asset(
                      "assets/animations/confetti.json",
                      fit: BoxFit.cover,
                      repeat: false,
                    ));
              }
              return const SizedBox.shrink();
            },
          ),
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
                      Navigator.of(context).push(_completionRoute());
                      // Navigator.push(context,
                      //     MaterialPageRoute(builder: (context) => const Hub()));
                    },
                    text: "Return Home",
                    color: CustomColors.productLightPrimaryNormalWhite,
                    textColor: CustomColors.productDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Route _completionRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const Hub(),
      transitionDuration: const Duration(milliseconds: 1000),
      reverseTransitionDuration: const Duration(milliseconds: 1000),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var screenSize = MediaQuery.of(context).size;
        var centerCircleClipper =
            Offset(screenSize.width / 2, screenSize.height / 2);

        double beginRadius = 0.0;
        double endRadius = screenSize.height * 1.2;

        var radiusTween = Tween(begin: beginRadius, end: endRadius);
        var radiusTweenAnimation = animation.drive(radiusTween);

        return ClipPath(
          clipper: CircleTransitionClipper(
              center: centerCircleClipper, radius: radiusTweenAnimation.value),
          child: child,
        );
      },
    );
  }
}
