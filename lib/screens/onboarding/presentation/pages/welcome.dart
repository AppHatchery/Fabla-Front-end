import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/participant_details.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../../../../services/pendo_service.dart';
import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/resources/strings.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final SetupRepository repository = SetupRepository();

  @override
  void initState() {
    createMetadata();
    SetupRepository repos = SetupRepository();
    repos.apiCreateParticipant(repos.getParticipant()!.studyCode);
    startPendo();
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: CustomColors.backgroundSecondary,
      body: SafeArea(
          child: Stack(
        children: [
          SizedBox(
            height: height,
            width: width,
            child: const RiveAnimation.asset(
                'assets/animations/onboarding/onboarding_welcome.riv',
                fit: BoxFit.fitHeight),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Welcome, \nYou've checked in!",
                          style: CustomTypography()
                              .headlineLarge(color: CustomColors.textWhite)),
                      const SizedBox(
                        height: 16,
                      ),
                      Text(
                          "You are now checked into our study. Thank you so much for joining our research! ${Strings.confetti}",
                          style: CustomTypography()
                              .bodyLarge(color: CustomColors.textWhite)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(bottom: 34),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image.asset(
                      //   "assets/images/check_in_image.png",
                      //   width: width,
                      // ),
                      // const SizedBox(
                      //   height: 27,
                      // ),
                      CustomElevatedButton(
                        onClick: () => navigateToNextPage(),
                        text: "CONTINUE",
                        color: CustomColors.fillWhite,
                        shadowColor: CustomColors.productBorderNormal,
                        textColor: CustomColors.productNormalActive,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }

  void navigateToNextPage() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const ParticipantDetailsPage()));
  }

  startPendo() async {
    final repository = SetupRepository();
    final participant = repository.getParticipant();
    await PendoService.start(participant!.studyCode.toString());
  }

  void createMetadata() => repository.createMetadata();
}
