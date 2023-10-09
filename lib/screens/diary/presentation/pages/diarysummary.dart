import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/summary_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/question_widgets.dart';
import 'package:audio_diaries_flutter/theme/custom_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../theme/components/buttons.dart';
import '../../../../theme/components/cards.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import '../../../../theme/dialogs/bottom_modals.dart';
import '../../data/option.dart';
import 'diarycompletion.dart';

///This page holds all the questions that have been answered by the user
///Currently only takes a string as a parameter, later to be replaced by a list of questions and answers
///No functionality for the Add a new response button
class DiarySummaryPage extends StatefulWidget {
  final Diary diary;

  const DiarySummaryPage({
    super.key,
    required this.diary,
  });

  @override
  State<DiarySummaryPage> createState() => _DiarySummaryPageState();
}

class _DiarySummaryPageState extends State<DiarySummaryPage> {
  late SummaryCubit summaryCubit;
  int? expandedCardId;
  bool isSliderEnabled = false;
  Map<int, bool> sliderEnabledStates = {};

  @override
  void initState() {
    summaryCubit = BlocProvider.of<SummaryCubit>(context);
    loadDiary(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SummaryCubit, SummaryState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: CustomColors.fillNormal,
          appBar: (state is SubmitLoading || state is SubmitError)
              ? null
              : AppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: CustomColors.fillNormal,
                  leading: IconButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const Hub()),
                          (route) => false);
                    },
                    icon: const Icon(CustomIcons.close),
                    iconSize: 15.0,
                  ),
                  title: Text(
                    "My Responses",
                    style: CustomTypography().titleMedium(
                      color: CustomColors.textNormalContent,
                    ),
                  ),
                  centerTitle: true,
                ),
          body: state is SummaryInitial
              ? initial()
              : state is SummaryLoading
                  ? loading()
                  : state is SummaryLoaded
                      ? content(state.diary, context)
                      : state is SubmitLoading
                          ? submitLoading()
                          : state is SubmitError
                              ? submitError()
                              : initial(),
        );
      },
      listener: (context, state) {
        if (state is SummarySubmitted) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const DiaryCompletionPage()),
              (route) => false);
        }
      },
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: CustomColors.fillNormal,
  //     appBar:
  //      AppBar(
  //       automaticallyImplyLeading: false,
  //       backgroundColor: CustomColors.fillNormal,
  //       leading: IconButton(
  //         onPressed: () {
  //           Navigator.pushAndRemoveUntil(
  //               context,
  //               MaterialPageRoute(builder: (context) => const Hub()),
  //               (route) => false);
  //         },
  //         icon: const Icon(CustomIcons.close),
  //         iconSize: 15.0,
  //       ),
  //       title: Text(
  //         "My Responses",
  //         style: CustomTypography().titleMedium(
  //           color: CustomColors.textNormalContent,
  //         ),
  //       ),
  //       centerTitle: true,
  //     ),
  //     body: BlocConsumer<SummaryCubit, SummaryState>(builder: (context, state) {
  //       if (state is SummaryInitial) {
  //         return initial();
  //       } else if (state is SummaryLoading) {
  //         return loading();
  //       } else if (state is SummaryLoaded) {
  //         return content(state.diary, context);
  //       } else if (state is SubmitLoading) {
  //         return submitLoading();
  //       } else if (state is SubmitError) {
  //         return submitError();
  //       } else {
  //         return initial();
  //       }
  //     }, listener: (context, state) {
  //       if (state is SummarySubmitted) {
  //         Navigator.pushAndRemoveUntil(
  //             context,
  //             MaterialPageRoute(
  //                 builder: (context) => const DiaryCompletionPage()),
  //             (route) => false);
  //       }
  //     }),
  //   );
  // }

  Widget submitLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: CustomColors.productNormalActive,
          ),
          Text(
            "Submitting...",
            style: CustomTypography()
                .headlineLarge(color: CustomColors.greyDarker),
          ),
          Text(
            "Hang tight while we process your responses - almost there!",
            style: CustomTypography().bodyMedium(
              color: CustomColors.textSecondaryContent,
            ),
          ),
        ],
      ),
    );
  }

  Widget submitError() {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ImageIcon(AssetImage("assets/images/icon_error.png")),
        Text(
          "Oops! Something went wrong.",
          style:
              CustomTypography().headlineLarge(color: CustomColors.greyDarker),
        ),
        Text(
          "Don't worry! We're here to help. Please reach out to us at [our@email.com] for assistance.",
          style: CustomTypography().bodyMedium(
            color: CustomColors.textSecondaryContent,
          ),
        ),
      ],
    ));
  }

  Widget loading() {
    return const Center(
      child: CircularProgressIndicator(
        color: CustomColors.productNormalActive,
      ),
    );
  }

  Widget initial() {
    return Container();
  }

  Widget content(Diary diary, BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 100.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  "Response Summary",
                  style: CustomTypography()
                      .headlineMedium(color: CustomColors.textNormalContent),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                  child: SingleChildScrollView(
                child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: diary.prompts.length,
                    itemBuilder: (context, index) =>
                        buildPrompt(diary.prompts[index], index)),
              )),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: CustomColors.fillWhite,
            padding:
                const EdgeInsets.only(bottom: 34, top: 24, left: 16, right: 16),
            alignment: Alignment.bottomCenter,
            child: CustomElevatedButton(
              onClick: () => submitDiary(),
              text: "SUBMIT MY RESPONSE",
              color: CustomColors.productNormal,
              textColor: CustomColors.textWhite,
              shadowColor: CustomColors.productNormalActive,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildPrompt(Prompt prompt, int index) {
    if (!sliderEnabledStates.containsKey(index)) {
      sliderEnabledStates[index] = false;
    }
    List<Option>? choices = prompt.option?.choices;
    int scaleMinValue = 0;
    int scaleMaxValue = 100;

    if (choices != null && choices.length >= 2) {
      try {
        scaleMinValue = int.parse(choices[0].option!);
        scaleMaxValue = int.parse(choices[1].option!);
      } catch (e) {
        print("Parsing error: $e");
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            color: CustomColors.productLightPrimaryNormalWhite,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Q ${index + 1}. ${prompt.question}",
                    ),
                  ),
                  // IconButton(
                  //     onPressed: () {
                  //       setState(() {
                  //         sliderEnabledStates[index] =
                  //             !sliderEnabledStates[index]!;
                  //       });
                  //     },
                  //     icon: Icon(CustomIcons.editNote))
                  // const SizedBox(height: 12),
                ],
              ),
              Column(
                children: [
                  Visibility(
                    visible: prompt.responseType == ResponseType.slider,
                    child: prompt.answer?.response != null
                        ? SliderQuestionCard(
                            scaleMin: scaleMinValue,
                            scaleMax: scaleMaxValue,
                            scaleMinText: prompt.option?.startText,
                            scaleMaxText: prompt.option?.endText,
                            isSliderEnabled: false,
                            value: double.tryParse(prompt.answer!.response!) ??
                                0.0,
                          )
                        : const SizedBox.shrink(),
                  ),
                  Visibility(
                    visible: prompt.responseType == ResponseType.multiple,
                    child: prompt.answer?.response != null
                        ? MultipleQuestionSummary(
                            answers: extractAnswers(prompt.answer!.response!),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Visibility(
                    visible: prompt.responseType == ResponseType.radio,
                    child: prompt.answer?.response != null
                        ? RadioQuestionSummary(
                            selectedOption: prompt.answer!.response!,
                          )
                        : const SizedBox.shrink(),
                  ),
                  Visibility(
                    visible: prompt.responseType == ResponseType.recording,
                    child: prompt.answer?.recordings != null
                        ? ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: prompt.answer!.recordings.length,
                            itemBuilder: (context, index) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6.0),
                                  child: AudioDiaryCard(
                                      recording:
                                          prompt.answer!.recordings[index],
                                      delete: () => deleteResponse(
                                          prompt,
                                          prompt
                                              .answer!.recordings[index].path),
                                      isExpanded: expandedCardId ==
                                          prompt.answer!.recordings[index].id,
                                      onTap: () {
                                        setState(() {
                                          expandedCardId = expandedCardId ==
                                                  prompt.answer!
                                                      .recordings[index].id
                                              ? null
                                              : prompt
                                                  .answer!.recordings[index].id;
                                        });
                                      }),
                                ))
                        : const SizedBox.shrink(),
                  )
                ],
              )
            ],
          ),
        ),

        // const AudioDiaryCard(
        //   path: "",
        // ),
        const SizedBox(height: 12),
        // Visibility(
        //   visible: prompt.responseType == ResponseType.recording,
        //   child: CustomRecordButton(
        //     onClick: () => recordResponse(context, prompt),
        //     text: "ADD A NEW RESPONSE",
        //   ),
        // ),
        // const SizedBox(height: 24),
      ],
    );
  }

  List<String> extractAnswers(String response) {
    final answerList = <String>[];
    final lines = response.split(RegExp(r'\d+\.'));

    for (var line in lines) {
      line = line.trim();
      if (line.isNotEmpty) {
        answerList.addAll(line.split('/').map((item) => item.trim()));
      }
    }

    return answerList;
  }

  void loadDiary(BuildContext context) {
    summaryCubit.loadSummary(widget.diary);
  }

  void recordResponse(BuildContext context, Prompt prompt) {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        isScrollControlled: true,
        // isDismissible: false,
        // enableDrag: false,
        builder: (context) => BottomRecordingModal(
              promptId: prompt.id,
              onSave: (value) {
                summaryCubit.saveResponse(
                    widget.diary, prompt, value.toString());
              },
            ));
  }

  void deleteResponse(Prompt prompt, String path) {
    summaryCubit.removeResponse(widget.diary, prompt, path);
  }

  void submitDiary() {
    summaryCubit.submitDiary(widget.diary);
  }
}
