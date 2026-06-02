import 'dart:async';

import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:audio_diaries_flutter/theme/dialogs/pop_ups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/getDeviceAndAppInfor.dart';
import '../../../core/utils/participantAndExperimentDetails.dart';
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

  String version = '';
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
    _loadInfo();
  }

  void getLastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lastUpdated = prefs.getString('last_Updated');
      dateJoined = prefs.getString('date_joined');
    });
  }
  Future<void> _loadInfo() async {
    final v = await getAppVersion();
    if (mounted) {
      setState(() {
        version = v;
      });
    }
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
                                horizontal: 24.0, vertical: 8.0),
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
                            onClick: _showUpdateWarning,
                            backgroundColor: Colors.transparent,
                            color: CustomColors.productNormal,
                            borderRadius: 200,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 8.0),
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
        CustomFlatButton(
            color: CustomColors.fillWhite,
            textColor: CustomColors.productNormalActive,
            onClick: launchEmailMethod,
            text: "Contact Researcher"),
      ],
    );
  }

  Future<void> launchEmailMethod() =>
      ParticipantAndExperimentDetails().launchSupportEmail();


  /// Shows the manual-update warning. The user must confirm before any
  /// gating check or update runs.
  void _showUpdateWarning() {
    showDialog(
      context: context,
      builder: (_) => StudyUpdatePopUp(onProceed: _onUpdateProceed),
    );
  }

  /// Runs after the user confirms the warning. Blocks the update when today
  /// already has submitted or pending diaries; otherwise triggers the update.
  void _onUpdateProceed() {
    if (_hubCubit.hasPendingOrSubmittedToday()) {
      showDialog(
        context: context,
        builder: (_) => const StudyUpdatingPopUp(pendingOrSubmitted: true),
      );
      return;
    }
    _hubCubit.update();
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
