import 'dart:async';

import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/login.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/confirm_tile.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io' show Platform;

import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/dialogs/pop_ups.dart';
import '../../../../theme/resources/strings.dart';

class ConfrimJoiningPage extends StatefulWidget {
  final ExperimentModel experiment;
  const ConfrimJoiningPage({super.key, required this.experiment});

  @override
  State<ConfrimJoiningPage> createState() => _ConfrimJoiningPageState();
}

class _ConfrimJoiningPageState extends State<ConfrimJoiningPage> {
  Timer? timer;
  int secondsSpent = 0;
  late bool isIos;

  @override
  void initState() {
    setState(() {
      isIos = Platform.isIOS;
    });
    super.initState();
  }

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
        scrolledUnderElevation: 0.0,
        automaticallyImplyLeading: false,
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
                  "Below is the study information associated with this study code.",
                  style: CustomTypography()
                      .bodyLarge(color: CustomColors.textWhite)),
              const SizedBox(
                height: 24,
              ),
              ConfrimTile(
                title: "Study Name",
                info: widget.experiment.name,
                icon: const Icon(
                  Icons.assured_workload_rounded,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              ConfrimTile(
                title: "Study Duration",
                info: widget.experiment.duration,
                icon: const Icon(
                  Icons.calendar_month_outlined,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              ConfrimTile(
                title: "Researcher Name",
                info: widget.experiment.researcher,
                icon: const Icon(
                  Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              TextButton(
                  onPressed: () => showResearchDetails(context, widget.experiment.name,
                      widget.experiment.duration, widget.experiment.organization, widget.experiment.researcher),
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
      bottomNavigationBar: SizedBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            children: [
              CustomFlatButton(
                onClick: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const LoginPage())),
                text: "Confirm Joining",
                color: CustomColors.fillWhite,
                textColor: CustomColors.productNormalActive,
              ),

              const SizedBox(
                height: 12,
              ),

              CustomFlatButton(
                onClick: () => Navigator.pop(context),
                text: "This isn’t right - take me back",
                color: CustomColors.fillWhite,
                textColor: CustomColors.productNormalActive,
              ),

              isIos
                  ? const SizedBox(
                      height: 24,
                      width: double.infinity,
                    )
                  : const SizedBox.shrink()
              //CustomTextButton(onClick: ()=> null, text: "I HAVE A PROBLEM JOINING THE STUDY", textColor: CustomColors.textWhite,)
            ],
          ),
        ),
      ),
    );
  }

  void showResearchDetails(BuildContext context, String name, String duration, String organization, 
      String researcher) {
    startTimer();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Wrap(
              children: [
                BottomStudyInfoPopUp(
                    studyName: name,
                    description: description,
                    organisation: organization,
                    duration: duration,
                    researcher: researcher)
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

  String description = "<h1>Heading 1</h1>\n\n<h2>Heading 2</h2>\n\n<h3>Heading 3</h3>\n\nWelcome to our study exploring the benefits of marriage in today’s society. As we navigate evolving social norms and lifestyles, this research aims to understand whether traditional benefits of marriage still hold true in modern times, and if so, how they manifest in various aspects of life.\n\nWe are looking for participants to freely share their experiences and perspectives on marriage, including areas such as \n>2 1. Emotional well-being\n>2 2. Financial stability\n>2 3. Social relationships\n>2 4. Personal growth.\nWhether you are married, previously married, or have never been married, your insights are valuable to this research.\n\nBy participating in this study, you will contribute to a better understanding of marriage’s impact in the current age, helping shape future discussions and policies around relationships. You'll be required to submit a log of your counselling sessions, these logs have audio questions please record up to **__10 minutes__** for better results.\n \nIf you have any questions or need further information, feel free to reach out to the research team at **+265(0)88-888-888**. We are here to assist you and ensure you have a positive experience throughout the study.\n \nThank you for your time and contribution to this ~~important~~ research!";
}
