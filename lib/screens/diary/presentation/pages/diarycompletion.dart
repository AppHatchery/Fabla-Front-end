import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/ghost_widget.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audio_diaries_flutter/theme/dialogs/pop_ups.dart';

import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

/// this is the last page in the New Daily Diary flow
/// The button leads to the home page
class DiaryCompletionPage extends StatefulWidget {
  const DiaryCompletionPage({super.key});

  @override
  State<DiaryCompletionPage> createState() => _DiaryCompletionPageState();
}

class _DiaryCompletionPageState extends State<DiaryCompletionPage>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(
            builder: (context) => const Hub(),
            settings: RouteSettings(name: "/Hub")),
            (route) => false);
      },
      child: Scaffold(
        backgroundColor: CustomColors.fillWhite,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: LayoutBuilder(builder: (context, constraints) {
                    final height = constraints.maxHeight;
                    // final halfHeight = height / 2;
                    return Stack(
                      children: [
                        // Column(
                        //   children: [
                        //     Container(
                        //       height: halfHeight,
                        //       width: width,
                        //       color: Colors.green,
                        //     ),
                        //     Container(
                        //       height: halfHeight,
                        //       width: width,
                        //       color: Colors.red,
                        //     )
                        //   ],
                        // ),
                        Lottie.asset("assets/animations/confetti.json",
                            controller: _controller, onLoaded: (composition) {
                          _controller.duration = composition.duration;
                          _controller.reset();

                          // Delay the animation start
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) {
                              _controller.repeat();
                            }
                          });
                        }, height: height, width: width, fit: BoxFit.cover),
                        SizedBox(
                          height: height,
                          width: width,
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
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
                                    height: 60,
                                  ),
                                  SizedBox(
                                    height: 355,
                                    width: width,
                                    child: const GhostCompletionWidget(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                CustomFlatButton(
                  onClick: () {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Hub(),
                            settings: RouteSettings(name: "/Hub")),
                        (route) => false);
                  },
                  text: "Return Home",
                  color: CustomColors.productNormal,
                  textColor: CustomColors.textWhite,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
