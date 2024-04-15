import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/participant.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/setup/setup_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/active_dates.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/avatar_background.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/participant_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

class ParticipantDetailsPage extends StatefulWidget {
  const ParticipantDetailsPage({super.key});

  @override
  State<ParticipantDetailsPage> createState() => _ParticipantDetailsPageState();
}

class _ParticipantDetailsPageState extends State<ParticipantDetailsPage> {
  late SetupCubit setupCubit;
  final TextEditingController controller = TextEditingController();
  double keyboardSpace = 0.0;
  @override
  void initState() {
    setupCubit = BlocProvider.of<SetupCubit>(context);
    load();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final textScale = MediaQuery.of(context).textScaler.scale(1);
    keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
        resizeToAvoidBottomInset: true,
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
        body: SafeArea(
          bottom: false,
          child: Container(
            color: CustomColors.backgroundSecondary,
            child: LayoutBuilder(builder: (context, constraints) {
              final constraintHeight = constraints.maxHeight;
              return SizedBox(
                height: height,
                child: SingleChildScrollView(
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: SizedBox(
                      height: constraintHeight > 400 && textScale < 1.1
                          ? constraintHeight > 440
                              ? constraintHeight
                              : height * 1.2
                          : constraintHeight > 550
                              ? constraintHeight
                              : height * 1.2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              "Enter a nickname for the study.",
                              style: CustomTypography()
                                  .headlineLarge(color: CustomColors.textWhite),
                            ),
                          ),
                          height > 700
                              ? const SizedBox(
                                  height: 60,
                                )
                              : AnimatedContainer(
                                  duration: const Duration(milliseconds: 700),
                                  curve: Curves.easeInOut,
                                  height: constraintHeight < 600
                                      ? keyboardSpace > 0
                                          ? 0
                                          : 0
                                      : keyboardSpace > 0
                                          ? 0
                                          : 60,
                                ),
                          Expanded(
                            child: SizedBox(
                              width: width,
                              child: BlocConsumer<SetupCubit, SetupState>(
                                  builder: (context, state) {
                                if (state is SetupInitial) {
                                  return intialDetails(height, width);
                                } else if (state is SetupLoading) {
                                  return loadingDetails(height, width);
                                } else if (state is SetupLoaded) {
                                  Participant? participant = state.participant;
                                  if (participant != null) {
                                    return loadedDetails(
                                        height, width, participant);
                                  } else {
                                    return intialDetails(height, width);
                                  }
                                } else {
                                  return intialDetails(height, width);
                                }
                              }, listener: (context, state) {
                                if (state is SetupSuccess) {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const ActiveDatesPage()));
                                }
                              }),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ));
  }

  Widget intialDetails(double height, double width) {
    return AvatarBackground(
        height: height,
        width: width,
        image: "",
        keyboardSpace: keyboardSpace,
        avatarType: "animation",
        animation: "assets/animations/onboarding/onboarding_nameinput.riv",
        onContinue: () => saveName(),
        children: [
          ParticipantName(controller: controller),
        ]);
  }

  Widget loadingDetails(double height, double width) {
    return AvatarBackground(
        height: height,
        width: width,
        image: "",
        keyboardSpace: keyboardSpace,
        avatarType: "animation",
        animation: "assets/animations/onboarding/onboarding_nameinput.riv",
        onContinue: () => saveName(),
        children: [
          ParticipantName(controller: controller),
        ]);
  }

  Widget loadedDetails(double height, double width, Participant participant) {
    return AvatarBackground(
        height: height,
        width: width,
        image: "",
        keyboardSpace: keyboardSpace,
        avatarType: "animation",
        animation: "assets/animations/onboarding/onboarding_nameinput.riv",
        onContinue: () => saveName(),
        children: [
          ParticipantName(controller: controller),
        ]);
  }

  void load() {
    setupCubit.load();
  }

  void saveName() {
    if (controller.text.isNotEmpty) {
      final lastNonSpaceIndex = controller.text.lastIndexOf(RegExp(r'[^ ]'));
      final name = controller.text.substring(0, lastNonSpaceIndex + 1);
      setupCubit.updateParticipant(name);
    }
  }
}
