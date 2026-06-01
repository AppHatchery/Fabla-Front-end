import 'dart:async';

import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/emailFunction.dart';
import '../../hub/presentation/cubit/hub_cubit.dart';
import '../../onboarding/domain/entities/participant.dart';

class SettingsStudyDetails extends StatefulWidget {
  const SettingsStudyDetails({super.key});

  @override
  State<SettingsStudyDetails> createState() => _SettingsStudyDetailsState();
}

class _SettingsStudyDetailsState extends State<SettingsStudyDetails> {
  late HubCubit _hubCubit;
  ExperimentModel? experiment;
  Participant? participant;

  String version = "1.0";
  String? lastUpdated;
  String? dateJoined;

  final repository = SetupRepository();

  @override
  initState() {
    super.initState();
    getStudyDetails();
    _hubCubit = context.read<HubCubit>();
    getAppVersion();
    getLastUpdated();
  }

  void getLastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lastUpdated = prefs.getString('last_Updated');
      dateJoined = prefs.getString('date_joined');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (experiment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      spacing: 12,
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
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          experiment!.name,
                          style: CustomTypography()
                              .bodyLarge(color: CustomColors.textNormalContent),
                        ),
                        if (lastUpdated != null)
                          Text(
                            "Last Updated: $lastUpdated",
                            style: CustomTypography().custom(
                                color: CustomColors.textTertiaryContent,
                                fontWeight: FontWeight.w400),
                          )
                      ],
                    ),
                    Text(
                      experiment!.organization,
                      style: CustomTypography()
                          .bodyMedium(color: CustomColors.textTertiaryContent),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: CustomOutlineButton(
                            key: Key("view_details_button"),
                            onClick: () => viewStudyDetails(),
                            backgroundColor: CustomColors.productNormal,
                            color: CustomColors.productNormal,
                            borderRadius: 200,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 4.0),
                            children: Wrap(children: [
                              Center(
                                child: Text(
                                  "View Details",
                                  style: CustomTypography()
                                      .button(color: CustomColors.textWhite),
                                ),
                              )
                            ]),
                          ),
                        ),
                        Expanded(
                          child: CustomOutlineButton(
                            key: Key("update_study"),
                            onClick: () => _hubCubit.update(),
                            backgroundColor: Colors.transparent,
                            color: CustomColors.productNormal,
                            borderRadius: 200,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 4.0),
                            children: Wrap(children: [
                              Center(
                                child: Text("Update Study",
                                    style: CustomTypography().button(
                                      color: CustomColors.productNormal,
                                    )),
                              )
                            ]),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: SizedBox(
            child: CustomFlatButton(
                color: CustomColors.fillWhite,
                textColor: CustomColors.productNormalActive,
                onClick: launchEmailMethod,
                text: "Contact Researcher"),
          ),
        ),
      ],
    );
  }

  void launchEmailMethod() {
    final dateJoinedEmail = (dateJoined != null) ? dateJoined : "";
    final lastUpdateEmail = (lastUpdated != null) ? lastUpdated : "";
    launchEmail(
        subject:
            'Fabla Participant Issue ${experiment!.login} ${participant!.studyCode}',
        body: '''
Describe the issue you are facing:
            
Study String: ${experiment!.login}
Participant ID: ${participant!.studyCode},
Date Joined: $dateJoinedEmail
Date last updated: $lastUpdateEmail
App Version: $version
Device and OS: <device OS>
''');
  }

  void getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;

    if (mounted) {
      this.version = version;
    }
  }

  void viewStudyDetails() async {
    if (experiment != null) {
      await pendoTrack(experiment!.login);
    }
  }

  Future<void> pendoTrack(String login) async {
    final setupRepository = SetupRepository();
    final pendoID = setupRepository.getParticipant()!.studyCode;

    await PendoService.start(pendoID, login);
    await PendoService.track("StudyDetails", null);
  }

  Future<void> getStudyDetails() async {
    final experiment = repository.getExperiment();
    final loadedParticipant = repository.getParticipant();
    setState(() {
      this.experiment = experiment;
      participant = loadedParticipant;
    });
  }
}
