import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/study_login.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:audio_diaries_flutter/theme/dialogs/pop_ups.dart';
import 'package:flutter/material.dart';

class SettingsStudyDetails extends StatefulWidget {
  const SettingsStudyDetails({super.key});

  @override
  State<SettingsStudyDetails> createState() => _SettingsStudyDetailsState();
}

class _SettingsStudyDetailsState extends State<SettingsStudyDetails> {
  late ExperimentModel experiment;

  final repository = SetupRepository();

  @override
  initState() {
    super.initState();
    getStudyDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "Study Details",
              style: CustomTypography()
                  .titleLarge(color: CustomColors.textNormalContent),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: CustomColors.productBorderNormal, width: 1),
            color: CustomColors.fillWhite,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      experiment.name,
                      style: CustomTypography()
                          .bodyLarge(color: CustomColors.textNormalContent),
                    ),
                    Text(
                      experiment.organization,
                      style: CustomTypography()
                          .bodyMedium(color: CustomColors.textTertiaryContent),
                    ),
                    Text(
                      "Version: ${experiment.version}",
                      style: CustomTypography()
                          .bodyMedium(color: CustomColors.textTertiaryContent),
                    ),
                    const SizedBox(height: 12),
                    CustomOutlineButton(
                      onClick: () => viewStudyDetails(),
                      backgroundColor: CustomColors.productNormal,
                      color: CustomColors.productNormal,
                      borderRadius: 200,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 4.0),
                      children: Wrap(children: [
                        Text(
                          "View Details",
                          style: CustomTypography()
                              .button(color: CustomColors.textWhite),
                        )
                      ]),
                    )
                  ],
                ),
              ),
              Divider(
                thickness: 0.5,
                height: 24,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 12),
                child: SizedBox(
                    child: CustomOutlineButton(
                  onClick: () => leaveStudy(context),
                  backgroundColor: CustomColors.fillWhite,
                  color: CustomColors.warningActive,
                  borderRadius: 200,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 4.0),
                  children: Wrap(children: [
                    Text(
                      "Leave This Study",
                      style: CustomTypography()
                          .button(color: CustomColors.warningActive),
                    )
                  ]),
                )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void viewStudyDetails() async {
    await pendoTrack(experiment.login);
  }

  Future<void> pendoTrack(String login) async {
    final setupRepository = SetupRepository();
    final pendoID = setupRepository.getParticipant()!.studyCode;

    await PendoService.start(pendoID, login);
    await PendoService.track("StudyDetails", null);
  }

  getStudyDetails() async {
    final experiment = repository.getExperiment();

    setState(() {
      this.experiment = experiment;
    });
  }

  leaveStudy(BuildContext context) async {
    final results = await showDialog<bool>(
        context: context,
        builder: (context) => ExitPopUp(
              title: "Are you sure you want to leave this study?",
              subheader:
                  "This action will be final and all your data will be lost",
            ));

    if (results == true && mounted) {
      await repository.leaveStudy();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => StudyLogin(),
                settings: RouteSettings(name: "/StudyLogin")),
            (route) => false);
      }
    }
  }
}
