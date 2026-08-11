import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/hub/presentation/cubit/hub_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/cubit/settings_cubit.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/pages/settings_onboarding.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/participant_experiment_details.dart';
import '../../../../theme/dialogs/pop_ups.dart';
import '../../../home/data/experiment.dart';
import '../../../onboarding/domain/entities/participant.dart';

class ParticipantDetails extends StatefulWidget {
  const ParticipantDetails({super.key});

  @override
  State<ParticipantDetails> createState() => _ParticipantDetailsState();
}

class _ParticipantDetailsState extends State<ParticipantDetails> {
  late SettingsCubit cubit;
  late HubCubit _hubCubit;

  final ParticipantAndExperimentDetails _details =
      ParticipantAndExperimentDetails();

  ExperimentModel? experiment;
  Participant? participant;

  String? dateJoined;

  @override
  void initState() {
    super.initState();
    cubit = context.read<SettingsCubit>();
    _hubCubit = context.read<HubCubit>();
    cubit.load();
    _loadDetails();
  }

  void _loadDetails() async {
    final loadedExperiment = _details.experiment;
    final loadedParticipant = _details.participant;
    final dates = await _details.getStudyDates();
    if (!mounted) return;
    setState(() {
      experiment = loadedExperiment;
      participant = loadedParticipant;
      dateJoined = dates.dateJoined;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Hold the frame until participant + experiment are hydrated.
    // loaded() asserts both are non-null, so this guard is the single
    // gate that lets the rest of the tree dereference them safely.
    if (participant == null || experiment == null) {
      return _placeholder(width);
    }

    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (context, state) {
        // TODO: implement listener
      },
      builder: (context, state) {
        if (state is SettingsLoaded) {
          return loaded(
            width,
            date: state.completedDate,
            questions: state.onboardingQuestion,
          );
        }
        return loaded(width);
      },
    );
  }

  Widget _placeholder(double width) {
    return SizedBox(
      width: width,
      height: 220,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget loaded(double width, {String? date, List<Questions>? questions}) {
    final bool hasNoOBQuestions = questions == null || questions.isEmpty;
    return Column(
      spacing: 12,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                "Participant Details",
                style: CustomTypography()
                    .titleLarge(color: CustomColors.textNormalContent),
              ),
            ),
          ],
        ),
        Container(
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: CustomColors.productBorderNormal, width: 1),
            color: CustomColors.fillWhite,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  spacing: 8,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            "Participant ID",
                            style: CustomTypography().bodyLarge(
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            participant!.studyCode,
                            style: CustomTypography().bodyMedium(
                                color: CustomColors.textSecondaryContent),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            "Study String",
                            style: CustomTypography().bodyLarge(
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            experiment!.login,
                            style: CustomTypography().bodyMedium(
                                color: CustomColors.textSecondaryContent),
                          ),
                        ),
                      ],
                    ),
                    (dateJoined != null)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  "Date Joined",
                                  style: CustomTypography().bodyLarge(
                                    weight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  dateJoined ?? "-",
                                  style: CustomTypography().bodyMedium(
                                      color:
                                          CustomColors.textSecondaryContent),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!hasNoOBQuestions)
          surveyTile(width, date: date, questions: questions)
      ],
    );
  }

  Widget surveyTile(double width, {String? date, List<Questions>? questions}) {
    final hasSurvey = date != null && questions != null;

    final tile = Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomColors.productBorderNormal, width: 1),
        color: CustomColors.fillWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Onboarding Survey",
                        style: CustomTypography()
                            .bodyLarge(color: CustomColors.productNormalActive, weight: FontWeight.w500),
                      ),
                      Text(
                        hasSurvey ? "Completed $date" : "",
                        style: CustomTypography()
                            .bodyMedium(color: CustomColors.textTertiaryContent),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: CustomColors.productNormalActive,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!hasSurvey) return tile;
    return InkWell(onTap: () => update(questions), child: tile);
  }

  update(List<Questions> questions) async {
    if (!mounted) return;

    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SettingsOnboarding(questions: questions),
            settings: RouteSettings(name: "/SettingsOnboarding")));

    if (result != true || !mounted) return;

    // Editing the answers already confirms intent, so skip the warning: block
    // if there are pending/submitted diaries today, otherwise go straight to
    // the updating phase.
    if (_hubCubit.hasPendingOrSubmittedToday()) {
      showDialog(
        context: context,
        builder: (_) => const StudyUpdateBlockedPopUp(),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StudyUpdatePopUp(state: UpdateState.updating),
    );
  }
}
