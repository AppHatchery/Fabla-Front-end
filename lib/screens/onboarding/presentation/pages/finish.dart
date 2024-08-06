import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import '../../../../theme/resources/strings.dart';

class FinishPage extends StatefulWidget {
  const FinishPage({super.key});

  @override
  State<FinishPage> createState() => _FinishPageState();
}

class _FinishPageState extends State<FinishPage> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: CustomColors.backgroundSecondary,
      body: SafeArea(
          child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: height * .7,
                        width: width,
                        child: FutureBuilder(
                            future: Future.delayed(
                                const Duration(milliseconds: 150)),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.done) {
                                return const RiveAnimation.asset(
                                    'assets/animations/onboarding/onboarding_congrats.riv',
                                    fit: BoxFit.cover);
                              }

                              return const SizedBox.shrink();
                            }),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                  padding: const EdgeInsets.only(top: 64),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Welcome, \nLet's Get Started",
                                        style: CustomTypography().headlineLarge(
                                            color: CustomColors.textWhite),
                                      ),
                                      const SizedBox(
                                        height: 16,
                                      ),
                                      Text(
                                        "Congratulations! ${Strings.confetti} You are all set! Your participation is invaluable to our research. We're thrilled to have you on board!",
                                        style: CustomTypography().bodyLarge(
                                            color: CustomColors.textWhite),
                                      ),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image.asset(
                //   "assets/images/finish_image.png",
                //   width: width,
                // ),
                // const SizedBox(
                //   height: 38,
                // ),
                CustomFlatButton(
                  onClick: _next,
                  text: "Get Started",
                  color: CustomColors.fillWhite,
                  textColor: CustomColors.productNormalActive,
                )
              ],
            ),
          ),
        ],
      )),
    );
  }

  void _next() async {
    await PreferenceService().setBoolPreference(key: 'setup', value: true);
    final start = DateTime.fromMillisecondsSinceEpoch(
        await PreferenceService().getIntPreference(key: 'startDate') ?? 0);

    await PendoService.track("FinishOnBoarding",
        {"datetime": DateTime.now().toString(), "startDate": start.toString()});

    // removing all onboarding dynamic questions (if any)
    final setupRepository = SetupRepository();
    setupRepository.removeAllQuestions();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Hub()),
          (route) => false);
    }
  }
}
