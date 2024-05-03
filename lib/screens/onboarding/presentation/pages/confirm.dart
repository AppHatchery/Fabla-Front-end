import 'dart:async';

import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/welcome.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/confirm_tile.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/dialogs/pop_ups.dart';
import '../../../../theme/resources/strings.dart';

class ConfrimJoiningPage extends StatefulWidget {
  const ConfrimJoiningPage({super.key});

  @override
  State<ConfrimJoiningPage> createState() => _ConfrimJoiningPageState();
}

class _ConfrimJoiningPageState extends State<ConfrimJoiningPage> {
  Timer? timer;
  int secondsSpent = 0;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: CustomColors.backgroundSecondary,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: CustomColors.fillWhite,
              size: 32,
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Study Information",
                  style: CustomTypography()
                      .headlineLarge(color: CustomColors.textWhite)),
              const SizedBox(
                height: 16,
              ),
              Text(
                  "Below is the study information associated with your participant ID.",
                  style: CustomTypography()
                      .bodyLarge(color: CustomColors.textWhite)),
              const SizedBox(
                height: 24,
              ),
              ConfrimTile(
                title: "Study Name",
                info: Strings.studyName,
                icon: const Icon(
                  Icons.assured_workload_rounded,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              ConfrimTile(
                title: "Study Duration",
                info: Strings.studyDuration,
                icon: const Icon(
                  Icons.calendar_month_outlined,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              ConfrimTile(
                title: "Researcher Name",
                info: Strings.researcherName,
                icon: const Icon(
                  Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              TextButton(
                  onPressed: () => showResearchDetails(context),
                  child: Text(
                    "View Study Details",
                    style: TextStyle(
                        color: CustomColors.textWhite,
                        fontFamily: CustomTypography.fontName,
                        fontSize: 18.sp,
                        decoration: TextDecoration.underline,
                        decorationColor: CustomColors.textWhite),
                  ))
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: MediaQuery.of(context).size.height * .15,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: CustomColors.backgroundSecondary,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomFlatButton(
              onClick: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                  (route) => false),
              text: "Confirm Joining",
              color: CustomColors.fillWhite,
              textColor: CustomColors.productNormalActive,
            ),

            //CustomTextButton(onClick: ()=> null, text: "I HAVE A PROBLEM JOINING THE STUDY", textColor: CustomColors.textWhite,)
          ],
        ),
      ),
    );
  }

  void showResearchDetails(BuildContext context) {
    startTimer();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Wrap(
              children: [
                BottomStudyInfoPopUp(
                    studyName: Strings.studyName,
                    //studyDescription: Strings.studyDescription,
                    organisation: Strings.organisation,
                    duration: Strings.studyDuration,
                    researcher: Strings.researcherName)
              ],
            )).then((value) async => {
          stopTimer(),
          await PendoService.track("ResearchDetails",
              {"page": "onboarding", "time_on_page": "$secondsSpent"})
        });
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        secondsSpent++;
      });
    });
  }

  void stopTimer() {
    timer?.cancel();
  }

  void resetTimer() => setState(() => secondsSpent = 0);
}
