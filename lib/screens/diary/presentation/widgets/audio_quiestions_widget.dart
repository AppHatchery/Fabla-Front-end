import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

class AudioQuestionsWidget extends StatefulWidget {
  final DiaryModel diary;
  final PromptModel prompt;
  final int currentPage;
  final Widget responseWidget;
  final PersistentBottomSheetController? bottomSheetController;
  final ScrollController? scrollController;

  const AudioQuestionsWidget({
    super.key,
    required this.diary,
    required this.prompt,
    required this.currentPage,
    required this.responseWidget,
    this.bottomSheetController,
    this.scrollController,
  });

  @override
  State<AudioQuestionsWidget> createState() => _AudioQuestionsWidgetState();
}
  class _AudioQuestionsWidgetState extends State<AudioQuestionsWidget> {
  @override
  Widget build(BuildContext context) {
    String questionTip = widget.prompt.subtitle ?? "";

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: CustomColors.fillWhite,
        ),
        child: SingleChildScrollView(
          controller: widget.scrollController,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "Question ${widget.currentPage + 1}/${widget.diary.prompts.length}",
                        style: CustomTypography().button(),
                      )),
                  const SizedBox(height: 15),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.prompt.question.toString(),
                      style: CustomTypography().titleLarge(),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      questionTip,
                      style: const TextStyle(
                          color: CustomColors.textNormalContent),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 50),
              Center(child: widget.responseWidget),
              widget.bottomSheetController == null
                  ? Container()
                  : const SizedBox(height: 240),
            ],
          ),
        ));
  }
}
