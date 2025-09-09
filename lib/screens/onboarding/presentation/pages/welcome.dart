import 'package:audio_diaries_flutter/core/usecases/font_scaler_detector.dart';
import 'package:audio_diaries_flutter/core/usecases/page_timer.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/participant.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../../../../services/pendo_service.dart';
import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/resources/strings.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with WidgetsBindingObserver {
  bool canGoBack = false;
  final SetupRepository repository = SetupRepository();
  final PageTimer timer = PageTimer();
  TextScaler? scaler; // Get the size of the text scaler

  late StateMachineController _controller;

  late Participant _participant;
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    if (Navigator.of(context).canPop()) {
      canGoBack = true;
    }
    timer.start();
    _participant = repository.getParticipant()!;
    startPendo();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      scaler = await fontScaler(context);
    });
    super.initState();
  }

  onInit(Artboard art) async {
    var ctrl = StateMachineController.fromArtboard(art, "Animation_1");

    ctrl?.isActive = false;

    if (ctrl != null) {
      art.addController(ctrl);
      setState(() {
        _controller = ctrl;
        art.addController(_controller);
        ctrl.isActive = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    timer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
          backgroundColor: CustomColors.backgroundSecondary,
          scrolledUnderElevation: 0.0,
          leading: IconButton(
              onPressed: () => {
                    track(timer.stop(), "Back"),
                    RouteService()
                        .navigateBack(context: context, current: 'welcome')
                  },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: CustomColors.fillWhite,
                size: 32,
              ))),
      backgroundColor: CustomColors.backgroundSecondary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LayoutBuilder(builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: Container(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.only(top: 48),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Welcome P${_participant.studyCode}, \nYou've checked in!",
                                      style: CustomTypography().headlineLarge(
                                          color: CustomColors.textWhite),
                                    ),
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    Text(
                                      "You are now checked into our study. Thank you so much for joining our research! ${Strings.confetti}",
                                      style: CustomTypography().bodyLarge(
                                          color: CustomColors.textWhite),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 250,
                                width: width,
                                child: RiveAnimation.asset(
                                  'assets/animations/onboarding/onboarding.riv',
                                  fit: BoxFit.fitWidth,
                                  onInit: onInit,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomFlatButton(
                    onClick: () => navigateToNextPage(),
                    text: "Continue",
                    color: CustomColors.fillWhite,
                    textColor: CustomColors.productNormalActive,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void navigateToNextPage() {
    track(timer.stop(), "Finished");
    RouteService().navigate(null, context: context, current: 'welcome');
  }

  track(int spent, String status) async {
    await PendoService.track("Welcome", {
      "time_on_page": spent,
      "status": status,
      "Font Scaler": "$scaler"
    });
  }

  startPendo() async {
    final experiment = repository.getExperiment();
    await PendoService.start(
        _participant.studyCode.toString(), experiment.login);

    await PendoService.track(
        "StudyLogin", {"datetime": DateTime.now().toString()});
  }
}
