import 'dart:async';
import 'package:audio_diaries_flutter/core/usecases/font_scaler_detector.dart';
import 'package:audio_diaries_flutter/core/usecases/page_timer.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/participant.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/setup/setup_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/avatar_background.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/participant_name.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:rive/rive.dart';
import 'dart:io' show Platform;

import '../../../../theme/custom_colors.dart';

class ParticipantDetailsPage extends StatefulWidget {
  const ParticipantDetailsPage({super.key});

  @override
  State<ParticipantDetailsPage> createState() => _ParticipantDetailsPageState();
}

class _ParticipantDetailsPageState extends State<ParticipantDetailsPage>
    with WidgetsBindingObserver {
  late SetupCubit setupCubit;
  BooleanInput? _lookDown;

  final TextEditingController controller = TextEditingController();
  late StreamSubscription<bool> keyboardSubscription;

  final PageTimer timer = PageTimer();
  TextScaler? scaler; // Get the size of the text scaler

  final scrollController = ScrollController();
  final focusNode = FocusNode();
  final fieldKey = GlobalKey();

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
        _lookDown?.value = true;
      } else {
        _lookDown?.value = false;
      }
    });

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        Future.delayed(
            const Duration(milliseconds: 300), maybeScrollToTextField);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      scaler = await fontScaler(context);
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
    _lookDown?.dispose();
    scrollController.dispose();
    timer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void maybeScrollToTextField() {
    final renderBox = fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final textFieldBottom = position.dy + renderBox.size.height;

    final keyboardTop = MediaQuery.of(context).size.height -
        MediaQuery.of(context).viewInsets.bottom;

    // If the TextField is below the keyboard
    if (textFieldBottom > keyboardTop) {
      Scrollable.ensureVisible(
        fieldKey.currentContext!,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final isIos = Platform.isIOS;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
      resizeToAvoidBottomInset: false,
      backgroundColor: CustomColors.fillWhite,
      appBar: AppBar(
        backgroundColor: CustomColors.backgroundSecondary,
        scrolledUnderElevation: 0.0,
        leading: IconButton(
            onPressed: () => {
                  track(timer.stop(), "Back"),
                  RouteService().navigateBack(
                      context: context, current: 'participant_details')
                },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: CustomColors.fillWhite,
              size: 32,
            )),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(builder: (context, constraints) {
          final constraintHeight = constraints.maxHeight;
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: constraintHeight,
              width: width,
              color: CustomColors.fillWhite,
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraint) => GestureDetector(
                        onTap: () => FocusScope.of(context).unfocus(),
                        child: Container(
                          height: constraint.maxHeight,
                          width: width,
                          color: CustomColors.backgroundSecondary,
                          child: bottomWidget,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: bottomPadding > 0
                            ? bottomPadding + 34
                            : (isIos ? 34 + 34 : 34)),
                    child: CustomFlatButton(
                        onClick: () =>
                            {track(timer.stop(), "Finished"), saveName()},
                        text: "Continue"),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
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
          ParticipantName(
            controller: controller,
            node: focusNode,
            globalKey: fieldKey,
          ),
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
          ParticipantName(
            controller: controller,
            node: focusNode,
            key: fieldKey,
            globalKey: fieldKey,
          ),
        ]);
  }

  Widget loadedDetails(double height, double width, Participant participant) {
    return AvatarBackground(
        height: height,
        width: width,
        image: "",
        avatarType: "animation",
        animation: "assets/animations/onboarding/keyboard.riv",
        stateMachineName: "Animation_100",
        onControllerReady: (ctrl) {
          setState(() {
            _lookDown = ctrl.stateMachine.boolean('Animation_1_Looks_Down');
          });
        },
        onContinue: () => {track(timer.stop(), "Finished"), saveName()},
        children: [
          ParticipantName(
            controller: controller,
            node: focusNode,
            globalKey: fieldKey,
          ),
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

  track(int spent, String status) async {
    await PendoService.track("Participant Details",
        {"time_on_page": spent, "status": status, "Font Scaler": "$scaler"});
  }
}
