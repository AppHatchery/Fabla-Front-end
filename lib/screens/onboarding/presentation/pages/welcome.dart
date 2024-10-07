import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/participant.dart';
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

  late Participant _participant;
  @override
  void initState() {
    _participant = repository.getParticipant()!;
    startPendo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: CustomColors.backgroundSecondary,
        scrolledUnderElevation: 0.0,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: CustomColors.fillWhite,
              size: 32,
            )),
      ),
      backgroundColor: CustomColors.backgroundSecondary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LayoutBuilder(builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: Container(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
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
                                      "Welcome P${_participant.studyCode}, \nYou've checked in!",
                                      style: CustomTypography().headlineLarge(
                                          color: CustomColors.textWhite),
                                    ),
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    Text(
                                      "You are now checked into our study. Thank you so much for joining our research! ${Strings.confetti}",
                                      style: CustomTypography().bodyLarge(
                                          color: CustomColors.textWhite),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 250,
                                width: width,
                                child: const RiveAnimation.asset(
                                  'assets/animations/onboarding/onboarding_welcome.riv',
                                  fit: BoxFit.fitWidth,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomFlatButton(
                    onClick: () => navigateToNextPage(),
                    text: "Continue",
                    color: CustomColors.fillWhite,
                    textColor: CustomColors.productNormalActive,
                  ),
                ),
              ],
            ),
          );
        },
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
    final experiment = repository.getExperiment();
    await PendoService.start(_participant.studyCode.toString(), experiment.login);

    await PendoService.track(
        "StudyLogin", {"datetime": DateTime.now().toString()});
  }
}
