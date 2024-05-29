import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

class AudioQuestionsWidget extends StatelessWidget {
  final DiaryModel diary;
  final PromptModel prompt;
  final int currentPage;
  final Widget responseWidget;
  final PersistentBottomSheetController? bottomSheetController;

  const AudioQuestionsWidget({
    super.key,
    required this.diary,
    required this.prompt,
    required this.currentPage,
    required this.responseWidget,
    this.bottomSheetController,
  });

  @override
  Widget build(BuildContext context) {
    String questionTip = "You only need to take one response.";
    double height = MediaQuery.of(context).size.height;
    double textScale = MediaQuery.of(context).textScaler.scale(1);

    //Conditions for making the page scrollable or not
    bool isSmallScreen = height < 700 || textScale > 1.2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      width: MediaQuery.of(context).size.width,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        color: CustomColors.fillWhite,
      ),
      child: isSmallScreen
          ? SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                          alignment: Alignment.topLeft,
                          child: Text(
                            "Question ${currentPage + 1}/${diary.prompts.length}",
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
                          prompt.question.toString(),
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
                              color: CustomColors.textTertiaryContent),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 50),
                  Center(child: responseWidget),
                  bottomSheetController == null
                      ? Container()
                      : const SizedBox(height: 240),
                ],
              ),
            )
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "Question ${currentPage + 1}/${diary.prompts.length}",
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
                        prompt.question.toString(),
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
                            color: CustomColors.textTertiaryContent),
                      ),
                    )
                  ],
                ),
                Expanded(child: Center(child: responseWidget)),
                if (diary.status != DiaryStatus.submitted &&
                    diary.status != DiaryStatus.missed &&
                    prompt.responseType == ResponseType.recording)
                  SizedBox(height: MediaQuery.of(context).size.height * 0),
                // const CustomTextButton(
                //     onClick: null, text: "I DON'T WANT TO ANSWER THIS QUESTION"),
              ],
            ),
    );
  }
}
