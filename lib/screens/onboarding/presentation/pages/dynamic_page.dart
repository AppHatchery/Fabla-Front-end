import 'dart:convert';

import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/dynamic/dynamic_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/active_dates.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/avatar_background.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/dynamic_widget.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/time_picker.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DynamicOnBoardingHub extends StatefulWidget {
  const DynamicOnBoardingHub({super.key});

  @override
  State<DynamicOnBoardingHub> createState() => _DynamicOnBoardingHubState();
}

class _DynamicOnBoardingHubState extends State<DynamicOnBoardingHub> {
  final PageController controller = PageController();

  late DynamicCubit _cubit;

  @override
  void initState() {
    _cubit = BlocProvider.of<DynamicCubit>(context);

    _cubit.load();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: CustomColors.backgroundPrimary,
      body: BlocConsumer<DynamicCubit, DynamicState>(
        listener: (context, state) {
          if (state is DynamicNone) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const ActiveDatesPage()));
          } else if (state is DynamicUploaded) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ActiveDatesPage()));
          }
        },
        builder: (context, state) {
          if (state is DynamicInitial || state is DynamicLoading) {
            return loading();
          } else if (state is DynamicUploading || state is DynamicUploaded) {
            return uploading(height, width);
          } else if (state is DynamicLoaded) {
            return PageView.builder(
              physics: const NeverScrollableScrollPhysics(),
              controller: controller,
              itemCount: state.questions.length,
              itemBuilder: (context, index) {
                return DynamicOnBoardingPage(
                  index: index + 1,
                  question: state.questions[index],
                  onPrevious: () => previousPage(),
                  onContinue: (answer) {
                    if (answer != null) {
                      _cubit.save(state.questions[index], answer);
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
    );
  }

  void nextPage(int length) {
    if (controller.page == length - 1) {
      // Navigator.push(context,
      //     MaterialPageRoute(builder: (context) => const ActiveDatesPage()));
      _cubit.upload();
    } else {
      controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void previousPage() {
    if (controller.page == 0) {
      Navigator.pop(context);
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
              backgroundColor: CustomColors.fillWhite,
              color: CustomColors.productBorderActive),
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

class _DynamicOnBoardingPageState extends State<DynamicOnBoardingPage>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController textEditingController;
  String? answer;

  @override
  void initState() {
    setState(() {
      answer = widget.question.answer;
      textEditingController = TextEditingController(
          text: widget.question.type == 'text' ? answer : null);
    });
    super.initState();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
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
                                            widget.question.title,
                                            style: CustomTypography()
                                                .headlineLarge(
                                                    color:
                                                        CustomColors.textWhite),
                                          ),
                                        ),
                                        const Expanded(child: SizedBox()),
                                        SizedBox(
                                            height: constraintHeight * 0.8,
                                            child: AvatarBackground(
                                                height: height,
                                                width: width,
                                                image:
                                                    "assets/images/avatar_onboarding_placeholder.png",
                                                avatarType: "image",
                                                animation: "",
                                                onContinue: () {},
                                                children: [
                                                  getWidget(widget.question,
                                                      index: widget.index)
                                                ]))
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
                        padding: const EdgeInsets.all(16),
                        child: CustomFlatButton(
                            onClick: () => {
                                  FocusScope.of(context).unfocus(),
                                  widget.onContinue(
                                      textEditingController.text != ''
                                          ? textEditingController.text
                                          : answer)
                                },
                            text: "Continue"),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })),
    );
  }

  Widget getWidget(Questions question, {int? index}) {
    if (question.type == 'time') {
      return OnboardingTimePicker(
        time: question.answer,
        subtitle: question.subtitle,
        onChanged: (String time) {
          setState(() {
            answer = '$time:00'; // TODO Find better way of adding seconds
          });
        },
      );
    } else if (question.type == 'text') {
      return OnBoardingTextField(
          subtitle: question.subtitle, controller: textEditingController);
    } else if (question.type == 'radio') {
      // return OnBoardingRadioOptions(
      //   subtitle: question.subtitle,
      //   options: question.options!,
      //   value: answer,
      //   onChanged: (String? value) {
      //     setState(() {
      //       answer = value;
      //     });
      //   },
      // );
      return SizedBox();
    } else if (question.type == 'multiple') {
      final selected = question.answer != null
          ? json
              .decode(question.answer!)
              .cast()
              .toList()
              .map<String>((element) => element.toString())
              .toList()
          : <String>[];
      return OnBoardingMultipleOption(
        subtitle: question.subtitle,
        options: question.options!,
        selected: selected,
        onChanged: (value) {
          setState(() {
            answer = value;
          });
        },
      );
    } else if (question.type == 'slider') {
      final value =
          question.answer != null ? double.parse(question.answer!) : null;
      return OnBoardingSlider(
          scaleMinText: "Min",
          scaleMaxText: "Max",
          scaleMin: question.min!,
          scaleMax: question.max!,
          value: value,
          defaultValue: question.defaultValue!,
          onChanged: (value) {
            setState(() {
              answer = value.toString();
            });
          });
    } else {
      return const SizedBox.shrink();
    }
  }

  void saveAnswer() {}

  @override
  bool get wantKeepAlive => false;
}
