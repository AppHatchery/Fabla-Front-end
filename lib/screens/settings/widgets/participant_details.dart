import 'package:audio_diaries_flutter/screens/hub/presentation/cubit/hub_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';
import 'package:audio_diaries_flutter/screens/settings/cubit/settings_cubit.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/settings_onboarding.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ParticipantDetails extends StatefulWidget {
  const ParticipantDetails({super.key});

  @override
  State<ParticipantDetails> createState() => _ParticipantDetailsState();
}

class _ParticipantDetailsState extends State<ParticipantDetails> {
  late SettingsCubit cubit;
  late HubCubit _hubCubit;

  @override
  void initState() {
    cubit = context.read<SettingsCubit>();
    _hubCubit = context.read<HubCubit>();
    cubit.load();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (context, state) {
        // TODO: implement listener
      },
      builder: (context, state) {
        if (state is SettingsLoaded) {
          return loaded(width, state.completedDate, state.onboardingQuestion);
        }

        return initial(width);
      },
    );
  }

  Widget initial(double width) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "Participant Details",
              style: CustomTypography()
                  .titleLarge(color: CustomColors.textNormalContent),
            ),
          ],
        ),
        Container(
          width: width,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Onboarding Survey",
                          style: CustomTypography()
                              .bodyLarge(color: CustomColors.textNormalContent),
                        ),
                        Text(
                          "",
                          style: CustomTypography().bodyMedium(
                              color: CustomColors.textTertiaryContent),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget loaded(double width, String date, List<Questions> questions) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "Participant Details",
              style: CustomTypography()
                  .titleLarge(color: CustomColors.textNormalContent),
            ),
          ],
        ),
        InkWell(
          onTap: () => update(questions),
          child: Container(
            width: width,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Onboarding Survey",
                            style: CustomTypography().bodyLarge(
                                color: CustomColors.textNormalContent),
                          ),
                          Text(
                            "Completed $date",
                            style: CustomTypography().bodyMedium(
                                color: CustomColors.textTertiaryContent),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  update(List<Questions> questions) async {
    if (mounted) {
      final result = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SettingsOnboarding(questions: questions), settings: RouteSettings(name: "/SettingsOnboarding")));

      if (result == true) {
        // Update
        _hubCubit.update();
      }
    }
  }
}
