import 'package:audio_diaries_flutter/core/utils/dummy_data.dart';
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
    final code = repository.getParticipant()!.studyCode;
    createMetadata();
    repository.apiCreateParticipant(code);
    startPendo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    Widget welcomeContents = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
                    Text(
                      "Welcome, \nYou've checked in!",
                      style: CustomTypography()
                          .headlineLarge(color: CustomColors.textWhite),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Text(
                      "You are now checked into our study. Thank you so much for joining our research! ${Strings.confetti}",
                      style: CustomTypography()
                          .bodyLarge(color: CustomColors.textWhite),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          width: width,
          child: const RiveAnimation.asset(
            'assets/animations/onboarding/onboarding_welcome.riv',
            fit: BoxFit.fitWidth,
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: CustomColors.backgroundSecondary,
      body: LayoutBuilder(builder: (context, constraints) {
        final constraintHeight = constraints.maxHeight;

        final textScale = MediaQuery.of(context).textScaler.scale(1);
        return SafeArea(
            child: constraintHeight < 550
                ? textScale < 1.1
                    ? welcomeContents
                    : SingleChildScrollView(child: welcomeContents)
                : constraintHeight < 750
                    ? textScale >= 1.4
                        ? SingleChildScrollView(child: welcomeContents)
                        : welcomeContents
                    : textScale >= 2
                        ? SingleChildScrollView(
                            child: welcomeContents,
                          )
                        : welcomeContents);
      }),
      bottomNavigationBar: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Center(
          child: CustomFlatButton(
            onClick: () => navigateToNextPage(),
            text: "Continue",
            color: CustomColors.fillWhite,
            textColor: CustomColors.productNormalActive,
          ),
        ),
      ),
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

    await PendoService.track(
        "StudyLogin", {"datetime": DateTime.now().toString()});
  }

  void createMetadata() => repository.createMetadata();
}
