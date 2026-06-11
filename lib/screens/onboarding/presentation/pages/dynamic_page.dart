import 'dart:convert';
import 'dart:math';
import 'package:audio_diaries_flutter/core/usecases/font_scaler_detector.dart';
import 'package:audio_diaries_flutter/core/usecases/page_timer.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/dynamic/dynamic_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/active_dates.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/avatar_background.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/dynamic_widget.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/time_picker.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/components/calendar.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rive/rive.dart';
import 'dart:io' show Platform;

import '../../../../core/utils/participant_experiment_details.dart';

class DynamicOnBoardingHub extends StatefulWidget {
  const DynamicOnBoardingHub({super.key});

  @override
  State<DynamicOnBoardingHub> createState() => _DynamicOnBoardingHubState();
}

class _DynamicOnBoardingHubState extends State<DynamicOnBoardingHub>
    with WidgetsBindingObserver {
  final PageController controller = PageController();
  final PageTimer timer = PageTimer();
  TextScaler? scaler; // Get the size of the text scaler

  late DynamicCubit _cubit;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    timer.start();
    _cubit = BlocProvider.of<DynamicCubit>(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      scaler = await fontScaler(context);
    });
    _cubit.load();
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
  dispose() {
    timer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: CustomColors.backgroundSecondary,
      body: SafeArea(
        top: false,
        bottom: false,
        child: BlocConsumer<DynamicCubit, DynamicState>(
          listener: (context, state) {
            if (state is DynamicNone) {
              track(timer.stop(), "Finished");
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ActiveDatesPage(),
                      settings: RouteSettings(name: "/ActiveDatesPage")));
            } else if (state is DynamicUploaded) {
              track(timer.stop(), "Finished");
              moveOn(context, state.questionsLength);
            }
          },
          builder: (context, state) {
            if (state is DynamicInitial || state is DynamicLoading) {
              return loading();
            } else if (state is DynamicUploading) {
              return uploading(height, width);
            } else if (state is DynamicError) {
              return DynamicErrorPage(
                message: state.message,
                onRetry: () => _cubit.upload(state.questionsLength),
                onBack: () => _cubit.load(),
              );
            } else if (state is DynamicLoaded) {
              return PageView.builder(
                physics: const NeverScrollableScrollPhysics(),
                controller: controller,
                itemCount: state.questions.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return welcome();
                  }
                  return DynamicOnBoardingPage(
                    index: index + 1,
                    question: state.questions[index - 1],
                    onPrevious: () => previousPage(),
                    onContinue: (answer) {
                      if (answer != null) {
                        _cubit.save(state.questions[index - 1], answer);
                        nextPage(state.questions.length);
                      }
                    },
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  track(int spent, String status) async {
    await PendoService.track("Dynamic Onboarding",
        {"time_on_page": spent, "status": status, "Font Scaler": "$scaler"});
  }

  void nextPage(int length) {
    if (controller.page == length) {
      // Navigator.push(context,
      //     MaterialPageRoute(builder: (context) => const ActiveDatesPage()));
      _cubit.upload(length);
    } else {
      controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void previousPage() {
    if (controller.page == 0) {
      track(timer.stop(), "Back");
      RouteService()
          .navigateBack(context: context, current: 'dynamic_onboarding');
    } else {
      controller.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Widget loading() {
    return const Center(
      child: CircularProgressIndicator(
        color: CustomColors.fillWhite,
        strokeCap: StrokeCap.round,
        strokeWidth: 8,
      ),
    );
  }

  Widget uploading(double height, double width) {
    return SizedBox(
      height: height,
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
              strokeCap: StrokeCap.round,
              strokeWidth: 8,
              backgroundColor: CustomColors.backgroundSecondary,
              color: CustomColors.fillWhite),
          const SizedBox(
            height: 24,
          ),
          Text(
            "Setting up...",
            style: CustomTypography()
                .headlineMedium(color: CustomColors.textWhite),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            "Hang tight while we set things up for you - \nalmost there!",
            textAlign: TextAlign.center,
            style: CustomTypography().bodyLarge(color: CustomColors.textWhite),
          ),
        ],
      ),
    );
  }

  Widget welcome() {
    return DynamicWelcome(
      onContinue: () => {
        controller.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut)
      },
    );
  }

  void moveOn(BuildContext context, int length) async {
    await PreferenceService()
        .setBoolPreference(key: 'onboarding_complete', value: true);
    if (context.mounted) {
      final cameBack = await RouteService()
          .navigate(null, context: context, current: 'dynamic_onboarding');

      if (cameBack == true) {
        if (length > 0) {
          _cubit.load();
        } else if (context.mounted) {
          if (Navigator.canPop(context)) Navigator.pop(context);
        }
      }
    }
  }

  // List<Widget> pages(List<Questions> questions) {
  //   return questions
  //       .map((question) => DynamicOnBoardingPage(
  //             question: question,
  //             onPrevious: () => previousPage(),
  //             onContinue: (answer) {
  //               if (answer != null) {
  //                 print("Answer: $answer");
  //                 _cubit.save(question, answer);
  //                 nextPage(questions.length);
  //               }
  //             },
  //           ))
  //       .toList();
  // }
}

class DynamicOnBoardingPage extends StatefulWidget {
  final int index;
  final Questions question;
  final Function onPrevious;
  final Function(String? answer) onContinue;
  const DynamicOnBoardingPage(
      {super.key,
      required this.index,
      required this.question,
      required this.onPrevious,
      required this.onContinue});

  @override
  State<DynamicOnBoardingPage> createState() => _DynamicOnBoardingPageState();
}

class _DynamicOnBoardingPageState extends State<DynamicOnBoardingPage> {
  late TextEditingController textEditingController;
  String? answer;

  TriggerInput? _questionTrigger;
  double foregroundHeight = 0.75;
  String animationURL = "";
  String stateMachineName = "";
  bool loop = true;

  @override
  void initState() {
    setState(() {
      answer = widget.question.answer;
      textEditingController = TextEditingController(
          text: widget.question.type == 'text' ? answer : null);
      animationURL = getAnimationAssets();
    });
    super.initState();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    _questionTrigger?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context);
    // final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final isIos = Platform.isIOS;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: CustomColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: CustomColors.backgroundSecondary,
        scrolledUnderElevation: 0.0,
        leading: IconButton(
            onPressed: () => widget.onPrevious(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: CustomColors.fillWhite,
              size: 32,
            )),
      ),
      body: SafeArea(
          bottom: false,
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              child: Container(
                color: CustomColors.fillWhite,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => FocusScope.of(context).unfocus(),
                        child: LayoutBuilder(builder: (context, constraint) {
                          return Container(
                            color: CustomColors.backgroundSecondary,
                            height: constraint.maxHeight,
                            width: width,
                            child: AvatarBackground(
                                height: constraint.maxHeight,
                                width: width,
                                foregroundHeight: foregroundHeight,
                                image: "",
                                avatarType: "animation",
                                animation: animationURL,
                                stateMachineName: stateMachineName,
                                onContinue: () {},
                                onControllerReady: (ctrl) {
                                  if (stateMachineName == "Animation_5") {
                                    setState(() {
                                      _questionTrigger =
                                          ctrl.stateMachine.trigger("Question");
                                    });
                                    Future.delayed(const Duration(seconds: 2),
                                        () {
                                      if (mounted) _questionTrigger?.fire();
                                    });
                                  }
                                },
                                children: [
                                  getWidget(widget.question,
                                      index: widget.index)
                                ]),
                          );
                        }),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: bottomPadding > 0
                            ? bottomPadding + 16
                            : (isIos ? 34 + 16 : 16),
                      ),
                      child: CustomFlatButton(
                          onClick: () => {
                                FocusScope.of(context).unfocus(),
                                widget.onContinue(
                                    textEditingController.text != ''
                                        ? textEditingController.text
                                        : answer)
                              },
                          // isDisabled: answer != null || textEditingController.text.isNotEmpty,
                          text: "Continue"),
                    ),
                  ],
                ),
              ),
            );
          })),
    );
  }

  getAnimationAssets() {
    if (widget.question.type == 'time') {
      setState(() {
        stateMachineName = "Animation_7";
      });
      return "assets/animations/onboarding/time.riv";
    } else if (widget.question.type == 'date') {
      setState(() {
        stateMachineName = "Animation_8";
        foregroundHeight = 0.39;
        loop = true;
      });
      return 'assets/animations/onboarding/hide_peek.riv';
    } else if (widget.question.type == 'text') {
      setState(() {
        stateMachineName = "Animation_8";
        foregroundHeight = 0.39;
        loop = true;
      });
      return 'assets/animations/onboarding/hide_peek.riv';
    } else {
      //Select animation randomly
      final animations = [
        {
          'stateMachineName': 'Animation_6',
          'animationURL': 'assets/animations/onboarding/left_right.riv',
          'foregroundHeight': 0.75,
          'loop': true
        },
        {
          'stateMachineName': 'Animation_8',
          'animationURL': 'assets/animations/onboarding/hide_peek.riv',
          'foregroundHeight': 0.39,
          'loop': true,
        },
        {
          'stateMachineName': 'Animation_12',
          'animationURL': 'assets/animations/onboarding/floats_in.riv',
          'foregroundHeight': 0.75,
          'loop': true
        },
        {
          'stateMachineName': 'Animation_9',
          'animationURL': 'assets/animations/onboarding/flying_left_right.riv',
          'foregroundHeight': 0.75,
          'loop': false
        },
        {
          'stateMachineName': 'Animation_5',
          'animationURL': 'assets/animations/onboarding/questions.riv',
          'foregroundHeight': 0.79,
          'loop': true
        },
        {
          'stateMachineName': 'Animation_10',
          'animationURL': 'assets/animations/onboarding/rolling.riv',
          'foregroundHeight': 0.75,
          'loop': false
        },
      ];

      final randomizer = Random().nextInt(animations.length);
      final random = animations[randomizer];
      if (mounted) {
        setState(() {
          stateMachineName = random['stateMachineName'] as String;
          foregroundHeight = random['foregroundHeight'] as double;
          loop = random['loop'] as bool;
        });
      }
      return random['animationURL'];
    }
  }

  Widget getWidget(Questions question, {int? index}) {
    final children = <Widget>[];

    children.add(
      Text(
        question.title,
        style: CustomTypography().titleLarge(),
      ),
    );

    if (question.type == 'time') {
      children.add(OnboardingTimePicker(
        time: question.answer,
        title: question.title,
        subtitle: question.subtitle,
        onChanged: (String time) {
          setState(() {
            answer = '$time:00'; // TODO Find better way of adding seconds
          });
        },
      ));
    } else if (question.type == 'text') {
      children.add(OnBoardingTextField(
          subtitle: null, controller: textEditingController));
    } else if (question.type == 'radio') {
      children.add(OnBoardingRadioOptions(
        subtitle: null,
        options: question.options!,
        value: answer,
        onChanged: (String? value) {
          setState(() {
            answer = value;
          });
        },
      ));
    } else if (question.type == 'multiple') {
      final selected = question.answer != null
          ? json
              .decode(question.answer!)
              .cast()
              .toList()
              .map<String>((element) => element.toString())
              .toList()
          : <String>[];
      children.add(OnBoardingMultipleOption(
        subtitle: null,
        options: question.options!,
        selected: selected,
        onChanged: (value) {
          setState(() {
            answer = value;
          });
        },
      ));
    } else if (question.type == 'slider') {
      final value =
          question.answer != null ? double.parse(question.answer!) : null;
      children.add(OnBoardingSlider(
          scaleMinText: question.minLabel ?? "",
          scaleMaxText: question.maxLabel ?? "",
          scaleMin: question.min!,
          scaleMax: question.max!,
          value: value,
          defaultValue: question.defaultValue!,
          onChanged: (value) {
            setState(() {
              answer = value.toString();
            });
          }));
    } else if (question.type == 'date') {
      final _date = answer != null ? stringDateOnlyToDateTime(answer!) : null;
      children.add(CustomDatePicker(
          date: _date,
          onSelect: (date) => setState(() {
                answer = formatDateOnly(date);
              })));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      spacing: 12,
      children: children,
    );
  }

  void saveAnswer() {}

  // @override
  // bool get wantKeepAlive => false;
}

class DynamicWelcome extends StatefulWidget {
  final Function onContinue;
  const DynamicWelcome({super.key, required this.onContinue});

  @override
  State<DynamicWelcome> createState() => _DynamicWelcomeState();
}

class _DynamicWelcomeState extends State<DynamicWelcome> {
  final SetupRepository _repository = SetupRepository();
  late String name;

  File? _riveFile;
  RiveWidgetController? _riveController;

  @override
  void initState() {
    setState(() {
      name = _repository.getParticipant()!.name;
    });
    _loadRive();
    super.initState();
  }

  Future<void> _loadRive() async {
    final file = await File.asset(
      'assets/animations/onboarding/clipboard.riv',
      riveFactory: Factory.rive,
    );
    if (file != null && mounted) {
      setState(() {
        _riveFile = file;
        _riveController = RiveWidgetController(
          file,
          stateMachineSelector: StateMachineSelector.byName('Animation_4'),
        );
      });
    }
  }

  @override
  void dispose() {
    _riveController?.dispose();
    _riveFile?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isIos = Platform.isIOS;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: CustomColors.backgroundSecondary,
        scrolledUnderElevation: 0.0,
        leading: IconButton(
            onPressed: () => {
                  RouteService().navigateBack(
                      context: context, current: 'dynamic_onboarding')
                },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: CustomColors.fillWhite,
              size: 32,
            )),
      ),
      backgroundColor: CustomColors.backgroundSecondary,
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(builder: (context, constraints) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraint) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraint.maxHeight),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16.0, right: 16.0),
                                  child: Text(
                                    "You’re almost done! Just a few more questions to personalize your study",
                                    style: CustomTypography().headlineLarge(
                                        color: CustomColors.textWhite),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 300,
                              width: width,
                              child: _riveController != null
                                  ? RiveWidget(
                                      controller: _riveController!,
                                      fit: Fit.fitWidth,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ]),
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
                  onClick: () => widget.onContinue(),
                  text: "Continue",
                  color: CustomColors.fillWhite,
                  isDisabled: false,
                  textColor: CustomColors.productNormalActive,
                ),
              )
            ],
          );
        }),
      ),
    );
  }
}

class DynamicErrorPage extends StatefulWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const DynamicErrorPage(
      {super.key,
      required this.message,
      required this.onRetry,
      required this.onBack});

  @override
  State<DynamicErrorPage> createState() => _DynamicErrorPageState();
}

class _DynamicErrorPageState extends State<DynamicErrorPage> {
  File? _riveFile;
  RiveWidgetController? _riveController;
  BooleanInput? _searchingTwo;

  @override
  void initState() {
    super.initState();
    _loadRive();
  }

  Future<void> _loadRive() async {
    final file = await File.asset(
      'assets/animations/ghosts.riv',
      riveFactory: Factory.rive,
    );
    if (file != null && mounted) {
      final controller = RiveWidgetController(
        file,
        stateMachineSelector: StateMachineSelector.byName('Ghosts'),
      );
      setState(() {
        _riveFile = file;
        _riveController = controller;
        _searchingTwo = controller.stateMachine.boolean('Searching_2');
      });
      Future.delayed(const Duration(milliseconds: 10), () {
        if (mounted) _searchingTwo?.value = true;
      });
    }
  }

  @override
  void dispose() {
    _searchingTwo?.dispose();
    _riveController?.dispose();
    _riveFile?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: CustomColors.fillWhite,
        scrolledUnderElevation: 0.0,
        leading: IconButton(
            onPressed: () => widget.onBack(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: CustomColors.textNormalContent,
              size: 32,
            )),
      ),
      backgroundColor: CustomColors.fillWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 25,
                children: [
                  SizedBox(
                    height: width * 0.75,
                    width: width * 0.75,
                    child: _riveController != null
                        ? RiveWidget(
                            controller: _riveController!,
                            fit: Fit.cover,
                          )
                        : const SizedBox.shrink(),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(widget.message,
                        textAlign: TextAlign.center,
                        style: CustomTypography().headlineMedium(
                            color: CustomColors.textNormalContent)),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 32.0, right: 32.0, top: 40),
                    child: CustomFlatButton(
                      onClick: widget.onRetry,
                      text: 'Try Again',
                      color: CustomColors.fillWhite,
                      textColor: CustomColors.warningActive,
                      borderColor: CustomColors.warningActive,
                    ),
                  ),

                  // or
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 24,
                    children: [
                      SizedBox(
                        width: 65,
                        child: Divider(
                          color: const Color(0xFFB0B0B0),
                          thickness: 1,
                        ),
                      ),
                      Text(
                        'OR',
                        style: CustomTypography().bodyLarge(
                            color: const Color(0xFFB0B0B0),
                            weight: FontWeight.w500),
                      ),
                      SizedBox(
                        width: 65,
                        child: Divider(
                          color: const Color(0xFFB0B0B0),
                          thickness: 1,
                        ),
                      )
                    ],
                  ),

                  CustomTextButton(
                    onClick: () => launchEmail(),
                    text: 'Contact Researcher',
                    textColor: CustomColors.warningActive,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> launchEmail() async {
    await ParticipantAndExperimentDetails().loginSupportEmail(
        'Issue with Uploading Onboarding Questions',
        'Hi,\n\nI\'m experiencing the following issue while trying to onboard:\n\n[Please describe the issue you\'re facing]\n\nThank you!',
        'I am failing to Submit my onboarding questions');
  }

}
