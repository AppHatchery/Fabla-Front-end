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
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(builder: (context, constraints) {
            final constraintHeight = constraints.maxHeight;
            return SingleChildScrollView(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SizedBox(
                  height: constraintHeight,
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "What is your name?",
                          style: CustomTypography()
                              .headlineLarge(color: CustomColors.textWhite),
                        ),
                      ),
                      const SizedBox(
                        height: 60,
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
            );
          }),
        ));
  }

  Widget intialDetails(double height, double width) {
    return AvatarBackground(
        height: height,
        width: width,
        image: "assets/images/avatar_ask_name.png",
        onContinue: () => saveName(),
        children: [
          ParticipantName(controller: controller),
        ]);
  }

  Widget loadingDetails(double height, double width) {
    return AvatarBackground(
        height: height,
        width: width,
        image: "assets/images/avatar_ask_name.png",
        onContinue: () => saveName(),
        children: [
          ParticipantName(controller: controller),
        ]);
  }

  Widget loadedDetails(double height, double width, Participant participant) {
    controller.text = participant.name;
    return AvatarBackground(
        height: height,
        width: width,
        image: "assets/images/avatar_ask_name.png",
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
      setupCubit.updateParticipant(controller.text);
    }
  }
}
