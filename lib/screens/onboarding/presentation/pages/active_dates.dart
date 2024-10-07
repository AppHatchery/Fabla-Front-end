import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/custom_calender.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/finish.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/preference_service.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import '../../domain/entities/participant.dart';
import '../cubit/setup/setup_cubit.dart';
import '../widgets/avatar_background.dart';

class ActiveDatesPage extends StatefulWidget {
  const ActiveDatesPage({super.key});

  @override
  State<ActiveDatesPage> createState() => _ActiveDatesPageState();
}

class _ActiveDatesPageState extends State<ActiveDatesPage> {
  late SetupCubit setupCubit;
  bool canGoBack = false;

  @override
  void initState() {
    if (Navigator.of(context).canPop()) {
      canGoBack = true;
    }
    setupCubit = BlocProvider.of<SetupCubit>(context);
    load();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: CustomColors.fillWhite,
        appBar: AppBar(
          backgroundColor: CustomColors.backgroundSecondary,
          scrolledUnderElevation: 0.0,
          leading: canGoBack
              ? IconButton(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: CustomColors.fillWhite,
                    size: 32,
                  ))
              : null,
        ),
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(builder: (context, constraints) {
            final constraintHeight = constraints.maxHeight;
            return Container(
              color: CustomColors.backgroundSecondary,
              child: SingleChildScrollView(
                child: SizedBox(
                    height: constraintHeight,
                    width: width,
                    child: BlocConsumer<SetupCubit, SetupState>(
                        builder: (context, state) {
                          if (state is SetupInitial) {
                            return initial();
                          } else if (state is SetupLoading) {
                            return loading();
                          } else if (state is SetupLoaded) {
                            final participant = state.participant;
                            if (participant != null) {
                              return loaded(height, width, participant);
                            } else {
                              return initial();
                            }
                          }
                          return initial();
                        },
                        listener: (context, state) {})),
              ),
            );
          }),
        ));
  }

  Widget initial() {
    return Container();
  }

  Widget loading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget loaded(double height, double width, Participant participant) {
    return Container(
      color: CustomColors.fillWhite,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Container(
                      color: CustomColors.backgroundSecondary,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              "All set ${participant.name}, here are your active dates",
                              style: CustomTypography()
                                  .headlineLarge(color: CustomColors.textWhite),
                              // textScaleFactor: 3.0,
                            ),
                          ),
                          const SizedBox(
                            height: 60,
                          ),
                          SizedBox(
                            height: height * 0.9,
                            width: width,
                            child: AvatarBackground(
                                height: height,
                                width: width,
                                image: "assets/images/active_dates.png",
                                avatarType: "animation",
                                animation:
                                    "assets/animations/onboarding/onboarding_activedays.riv",
                                    scrollable: false,
                                onContinue: navigateToNextPage,
                                children: [
                                  Text(
                                    "Study Plan",
                                    style: CustomTypography().titleLarge(),
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  description(),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  const CustomCalender(),

                                  const SizedBox(height: 6)
                                ]),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                CustomFlatButton(onClick: navigateToNextPage, text: "Continue"),
          ),
        ],
      ),
    );
  }

  void navigateToNextPage() async {
    await PreferenceService()
        .setBoolPreference(key: 'active_dates_seen', value: true);

    if (context.mounted) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const FinishPage()));
    }
  }

  void load() {
    setupCubit.load();
  }

  Widget description() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: CustomColors.productLightBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        "Blue dots on the calendar indicate that there is a submission deadline for the dates.",
        style: CustomTypography()
            .bodyLarge(color: CustomColors.textSecondaryContent),
        // textScaleFactor: 3.0,
      ),
    );
  }
}
