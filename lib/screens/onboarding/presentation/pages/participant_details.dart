import 'dart:async';
import 'package:audio_diaries_flutter/core/usecases/page_timer.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/participant.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/setup/setup_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/welcome.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/avatar_background.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/participant_name.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:rive/rive.dart';

import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

class ParticipantDetailsPage extends StatefulWidget {
  const ParticipantDetailsPage({super.key});

  @override
  State<ParticipantDetailsPage> createState() => _ParticipantDetailsPageState();
}

class _ParticipantDetailsPageState extends State<ParticipantDetailsPage>
    with WidgetsBindingObserver {
  late SetupCubit setupCubit;
  late StateMachineController _controller;

  SMIBool? lookDown;

  final TextEditingController controller = TextEditingController();
  double animationHeight = 0;
  late StreamSubscription<bool> keyboardSubscription;

  final PageTimer timer = PageTimer();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    timer.start();
    setupCubit = BlocProvider.of<SetupCubit>(context);
    load();
    var keyboardVisibilityController = KeyboardVisibilityController();

    keyboardSubscription =
        keyboardVisibilityController.onChange.listen((bool visible) {
      if (visible) {
        lookDown?.value = true;
      } else {
        lookDown?.value = false;
      }
    });
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      timer.start();
    } else if (state == AppLifecycleState.paused) {
      int spent = timer.stop();
      track(spent, "Paused");
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    keyboardSubscription.cancel();
    _controller.dispose();
    timer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    Widget bottomWidget = BlocConsumer<SetupCubit, SetupState>(
      builder: (context, state) {
        if (state is SetupInitial) {
          return intialDetails(height, width);
        } else if (state is SetupLoading) {
          return loadingDetails(height, width);
        } else if (state is SetupLoaded) {
          Participant? participant = state.participant;
          if (participant != null) {
            return loadedDetails(height, width, participant);
          } else {
            return intialDetails(height, width);
          }
        } else {
          return intialDetails(height, width);
        }
      },
      listener: (context, state) {
        if (state is SetupSuccess) {
          RouteService()
              .navigate(null, context: context, current: 'participant_details');
        }
      },
    );
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: CustomColors.fillWhite,
        appBar: AppBar(
          backgroundColor: CustomColors.backgroundSecondary,
          scrolledUnderElevation: 0.0,
          leading: IconButton(
            onPressed: () {
              track(timer.stop(), "Back");
              RouteService().navigateBackTo(context, const WelcomePage());
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: CustomColors.fillWhite,
              size: 32,
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(builder: (context, constraints) {
            final constraintHeight = constraints.maxHeight;
            return SingleChildScrollView(
              child: SizedBox(
                height: constraintHeight,
                child: Container(
                  color: CustomColors.fillWhite,
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraint) =>
                              SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minHeight: constraint.maxHeight),
                              child: IntrinsicHeight(
                                child: GestureDetector(
                                  onTap: () => FocusScope.of(context).unfocus(),
                                  child: Container(
                                    color: CustomColors.backgroundSecondary,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          child: Text(
                                            "Enter a nickname for the study.",
                                            style: CustomTypography()
                                                .headlineLarge(
                                                    color:
                                                        CustomColors.textWhite),
                                          ),
                                        ),
                                        Expanded(child: Container()),
                                        SizedBox(
                                            height: 400, child: bottomWidget)
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, bottom: 34),
                        child: CustomFlatButton(
                            onClick: () =>
                                {track(timer.stop(), "Finished"), saveName()},
                            text: "Continue"),
                      ),
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
        image: "",
        avatarType: "animation",
        animation: "assets/animations/onboarding/keyboard.riv",
        onContinue: () => {track(timer.stop(), "Finished"), saveName()},
        children: [
          ParticipantName(controller: controller),
        ]);
  }

  Widget loadingDetails(double height, double width) {
    return AvatarBackground(
        height: height,
        width: width,
        image: "",
        avatarType: "animation",
        animation: "assets/animations/onboarding/keyboard.riv",
        onContinue: () => {track(timer.stop(), "Finished"), saveName()},
        children: [
          ParticipantName(controller: controller),
        ]);
  }

  Widget loadedDetails(double height, double width, Participant participant) {
    return AvatarBackground(
        height: height,
        width: width,
        image: "",
        avatarType: "animation",
        animation: "assets/animations/onboarding/keyboard.riv",
        animationHeight: animationHeight,
        onInit: onInit,
        onContinue: () => {track(timer.stop(), "Finished"), saveName()},
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

  onInit(Artboard art) async {
    var ctrl = StateMachineController.fromArtboard(art, "Animation_100");
    setState(() {
      animationHeight = art.height;
    });
    ctrl?.isActive = false;

    if (ctrl != null) {
      art.addController(ctrl);
      setState(() {
        _controller = ctrl;
        art.addController(_controller);
        ctrl.isActive = true;
        lookDown = _controller.getBoolInput('Animation_1_Looks_Down');
      });
    }
  }

  track(int spent, String status) async {
    await PendoService.track(
        "Participant Details", {"time_on_page": spent, "status": status});
  }
}
