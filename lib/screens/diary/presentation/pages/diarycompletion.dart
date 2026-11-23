import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/ghost_widget.dart';
import 'package:audio_diaries_flutter/theme/components/cards.dart'
    show FailedSubmissionCard;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/usecases/font_scaler_detector_and_adjuster.dart';
import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

/// this is the last page in the New Daily Diary flow
/// The button leads to the home page
class DiaryCompletionPage extends StatefulWidget {
  final bool? submissionFailed;

  /// Whether to load and play the ghost Rive animation. Tests pass false: there is
  /// no Rive renderer in `flutter test`, and loading a .riv file there aborts
  /// the test process (SIGABRT), which no try/catch can stop.
  final bool showRiveAnimation;

  const DiaryCompletionPage(
      {super.key, this.submissionFailed, this.showRiveAnimation = true});

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
          child: LayoutBuilder(builder: (context, constraints) {
            final height = constraints.maxHeight;
            return Stack(
              children: [
                // Confetti stays fixed behind the content while it scrolls.
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
                // The whole page scrolls so the message, the failed
                // submission card and the button all stay reachable at large
                // font sizes. minHeight keeps the normal layout (message
                // centred, button at the bottom) when everything fits. No
                // Expanded here: it needs a bounded height, and inside a
                // scroll view it throws and leaves the screen blank.
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: height - 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox.shrink(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              textScaler: getAdaptiveTextScaler(context),
                              "Thanks for your response!",
                              style: CustomTypography().headlineMedium(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              textScaler: getAdaptiveTextScaler(context),
                              "Your input is incredibly valuable for our study's progress. We can't wait to hear from you again soon!",
                              style: CustomTypography().bodyLarge(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 60),
                            SizedBox(
                              height: 355,
                              width: width,
                              child: widget.showRiveAnimation
                                  ? const GhostCompletionWidget()
                                  : null,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            if (widget.submissionFailed == true)
                              const FailedSubmissionCard(),
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
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
