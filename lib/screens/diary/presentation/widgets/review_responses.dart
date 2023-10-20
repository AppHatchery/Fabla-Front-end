import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/types.dart';
import '../../../../theme/components/cards.dart';
import '../../../../theme/custom_colors.dart';
import '../../data/diary.dart';
import '../../data/option.dart';
import '../../data/prompt.dart';
import '../cubit/diary/summary_cubit.dart';
import 'question_widgets.dart';

class ReviewResponses extends StatefulWidget {
  final Diary diary;
  const ReviewResponses({super.key, required this.diary});

  @override
  State<ReviewResponses> createState() => _ReviewResponsesState();
}

class _ReviewResponsesState extends State<ReviewResponses> {
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
    return BlocBuilder<SummaryCubit, SummaryState>(
      builder: (context, state) {
        if (state is SummaryInitial) {
          return initial();
        } else if (state is SummaryLoading) {
          return loading();
        } else if (state is SummaryLoaded) {
          return content(state.diary, context);
        } else {
          return Container();
        }
      },
    );
  }

  Widget initial() {
    return Container();
  }

  Widget loading() {
    return const Center(
        child: CircularProgressIndicator(
      color: CustomColors.productNormalActive,
    ));
  }

  Widget content(Diary diary, BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Container(
      decoration: const BoxDecoration(
          color: Color(0xFFF4F4F4),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      constraints: BoxConstraints(maxHeight: height * 0.75, maxWidth: width),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                const Expanded(flex: 1, child: SizedBox()),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Response of ${_formatDate(diary.start)}",
                    style: CustomTypography().bodyLarge(),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                )
              ],
            ),
          ),
          const Divider(
            thickness: 1,
            height: 0,
          ),
          const SizedBox(height: 24),
          Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Response Summary",
              style: CustomTypography()
                  .headlineMedium(color: CustomColors.textNormalContent),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
              child: Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                    shrinkWrap: true,
                    
                    itemCount: diary.prompts.length,
                    itemBuilder: (context, index) =>
                        buildPrompt(diary.prompts[index], index)),
              )),
        ],
      ),
    );
  }

  Widget buildPrompt(Prompt prompt, int index) {
    if (!sliderEnabledStates.containsKey(index)) {
      sliderEnabledStates[index] = false;
    }
    List<Option>? choices = prompt.option?.choices;
    int scaleMinValue = 0;
    int scaleMaxValue = 100;

    if (prompt.responseType == ResponseType.slider && choices != null && choices.length >= 2) {
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
        const SizedBox(height: 12),
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

  void deleteResponse(Prompt prompt, String path) {
    summaryCubit.removeResponse(widget.diary, prompt, path);
  }

  void loadDiary(BuildContext context) {
    summaryCubit.loadSummary(widget.diary);
  }
}

String _formatDate(DateTime date) {
  final DateFormat formatter = DateFormat("MMMM d'");
  return formatter.format(date);
}
