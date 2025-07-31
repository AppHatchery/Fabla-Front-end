import 'package:audio_diaries_flutter/core/usecases/font_scaler_detector.dart';
import 'package:audio_diaries_flutter/core/usecases/page_timer.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/custom_calender.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rive/rive.dart';

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

class _ActiveDatesPageState extends State<ActiveDatesPage>
    with WidgetsBindingObserver {
  late SetupCubit setupCubit;

  //Animations
  late StateMachineController _controller;
  double animationHeight = 0;

  final PageTimer timer = PageTimer();
  TextScaler? scaler; // Get the size of the text scaler

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    timer.start();
    setupCubit = BlocProvider.of<SetupCubit>(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      scaler = await fontScaler(context);
    });
    load();
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
    _controller.dispose();
    timer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
          leading: IconButton(
              onPressed: () => {
                    track(timer.stop(), "Back"),
                    RouteService()
                        .navigateBack(context: context, current: 'active_dates')
                  },
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
                listener: (context, state) {}),
          ),
        ));
  }

  Widget initial() {
    return Container();
  }

  Widget loading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget loaded(double height, double width, Participant participant) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        color: CustomColors.fillWhite,
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(builder: (context, constraint) {
                return Container(
                  color: CustomColors.backgroundSecondary,
                  height: constraint.maxHeight,
                  width: width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: constraint.maxHeight,
                        width: width,
                        child: AvatarBackground(
                            height: height,
                            width: width,
                            image: "",
                            avatarType: "animation",
                            animation:
                                "assets/animations/onboarding/active_dates.riv",
                            scrollable: false,
                            animationHeight: animationHeight,
                            foregroundHeight: 0.6,
                            onInit: onInit,
                            onContinue: () => navigateToNextPage(context),
                            children: [
                              Text(
                                "Study Plan",
                                style: CustomTypography().titleLarge(),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Text(
                                "All set ${participant.name}, here are your active dates",
                                style: CustomTypography().titleMedium(
                                    color: CustomColors.textNormalContent),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              description(),
                              const SizedBox(
                                height: 12,
                              ),
                              const CustomCalender(),
                            ]),
                      ),
                    ],
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomFlatButton(
                  onClick: () => navigateToNextPage(context), text: "Continue"),
            )
          ],
        ),
      ),
    );
  }

  onInit(Artboard art) async {
    var ctrl = StateMachineController.fromArtboard(art, 'Animation_12');
    ctrl?.isActive = false;

    //height of animation
    setState(() {
      animationHeight = art.height;
    });

    if (ctrl != null) {
      art.addController(ctrl);
      setState(() {
        _controller = ctrl;
        art.addController(_controller);
        ctrl.isActive = true;
      });
    }
  }

  void navigateToNextPage(BuildContext context) async {
    await PreferenceService()
        .setBoolPreference(key: 'active_dates_seen', value: true);

    if (context.mounted) {
      track(timer.stop(), "Finished");
      RouteService().navigate(null, context: context, current: 'active_dates');
    }
  }

  track(int spent, String status) async {
    await PendoService.track("Active Dates",
        {"time_on_page": spent, "status": status, "Font Scaler": "$scaler"});
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
        "Blue dots on the calendar indicate that there are submission surveys for the dates.",
        style: CustomTypography()
            .bodyLarge(color: CustomColors.textSecondaryContent),
        // textScaleFactor: 3.0,
      ),
    );
  }
}
