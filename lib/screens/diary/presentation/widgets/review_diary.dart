import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/types.dart';
import '../../../../theme/components/cards.dart';
import '../../../../theme/custom_colors.dart';
import '../../data/diary.dart';
import '../../data/prompt.dart';
import '../cubit/diary/summary_cubit.dart';
import 'question_widgets.dart';

class ReviewDiary extends StatefulWidget {
  final DiaryModel diary;
  const ReviewDiary({super.key, required this.diary});

  @override
  State<ReviewDiary> createState() => _ReviewDiaryState();
}

class _ReviewDiaryState extends State<ReviewDiary> {
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

  Widget content(DiaryModel diary, BuildContext context) {
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
                    diary.status == DiaryStatus.missed ||
                            diary.start.isBefore(DateTime.now())
                        ? "Response of ${_formatDate(diary.start)}"
                        : "Upcoming Diary for ${_formatDate(diary.start)}",
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
              diary.status == DiaryStatus.missed ||
                      diary.start.isBefore(DateTime.now())
                  ? "Response Summary"
                  : "Prompts Preview",
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

  Widget buildPrompt(PromptModel prompt, int index) {
    if (!sliderEnabledStates.containsKey(index)) {
      sliderEnabledStates[index] = false;
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
          child: Column(children: [
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
            getPromptWidget(prompt)
          ]),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  List<String> extractAnswers(String? response) {
    if (response == null) return [];

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

  /// Returns an empty container or calls `getResponseWidget` based on availability of a response
  Widget getPromptWidget(PromptModel prompt) {
    if (prompt.responseType == ResponseType.recording) {
      if ((prompt.answer?.recordings.isEmpty ?? true) &&
          (prompt.answer?.response?.isEmpty ?? true)) {
        return Container();
      }
    }
    return getResponseWidget(prompt);
  }

  /// Returns the appropriate widget based on the response type of the prompt.
  Widget getResponseWidget(PromptModel prompt) {
    switch (prompt.responseType) {
      case ResponseType.slider:
        return SliderQuestionCard(
          scaleMin: prompt.option!.minValue!,
          scaleMax: prompt.option!.maxValue!,
          scaleMinText: prompt.option?.minLabel,
          scaleMaxText: prompt.option?.maxLabel,
          isSliderEnabled: false,
          value: double.tryParse(prompt.answer?.response ?? '') ?? 0.0,
        );
      case ResponseType.multiple:
        return MultipleQuestionSummary(
          answers: extractAnswers(prompt.answer?.response),
        );
      case ResponseType.radio:
        return RadioQuestionSummary(
          selectedOption: prompt.answer?.response,
        );
      case ResponseType.recording:
        return prompt.answer!.recordings.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: TextAnswerCard(
                  isVisible: true,
                  answer: prompt.answer!.response!,
                  delete: () => deleteResponse(prompt, ''),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: prompt.answer!.recordings.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: NewAudioCard(
                      isVisible: true,
                      recording: prompt.answer!.recordings[index],
                      delete: () => deleteResponse(
                          prompt, prompt.answer!.recordings[index].path),
                      viewOnly: true,
                      promptId: prompt.id,
                    ),
                  );
                });
      case ResponseType.webview:
        final width = MediaQuery.of(context).size.width;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            decoration: BoxDecoration(
              color: CustomColors.grey,
              borderRadius: BorderRadius.circular(12),
              shape: BoxShape.rectangle,
            ),
            child: Row(children: [
              Expanded(
                child: Text("Response submitted through webview",
                    style: CustomTypography().bodyMedium(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        );
      //TODO: Add support for other response types
      default:
        return const SizedBox.shrink();
    }
  }

  void deleteResponse(PromptModel prompt, String path) {
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
