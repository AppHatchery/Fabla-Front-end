import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/summary_cubit.dart';
import 'package:audio_diaries_flutter/theme/custom_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../theme/components/buttons.dart';
import '../../../../theme/components/cards.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import '../../../../theme/dialogs/bottom_modals.dart';
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

  @override
  void initState() {
    summaryCubit = BlocProvider.of<SummaryCubit>(context);
    loadDiary(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.fillNormal,
      appBar: AppBar(
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
      body: BlocConsumer<SummaryCubit, SummaryState>(builder: (context, state) {
        if (state is SummaryInitial) {
          return initial();
        } else if (state is SummaryLoading) {
          return loading();
        } else if (state is SummaryLoaded) {
          return content(state.diary, context);
        } else {
          return initial();
        }
      }, listener: (context, state) {
        if (state is SummarySubmitted) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const DiaryCompletionPage()),
              (route) => false);
        }
      }),
    );
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
                  "Review your responses",
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          prompt.question.toString(),
          style: CustomTypography()
              .titleMedium(color: CustomColors.textNormalContent),
        ),
        const SizedBox(height: 12),

        prompt.answer?.recordings != null
            ? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: prompt.answer!.recordings.length,
                itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: AudioDiaryCard(
                          recording: prompt.answer!.recordings[index],
                          delete: () => deleteResponse(
                              prompt, prompt.answer!.recordings[index].path),
                          isExpanded: expandedCardId ==
                              prompt.answer!.recordings[index].id,
                          onTap: () {
                            setState(() {
                              expandedCardId = expandedCardId ==
                                      prompt.answer!.recordings[index].id
                                  ? null
                                  : prompt.answer!.recordings[index].id;
                            });
                          }),
                    ))
            : const SizedBox.shrink(),
        // const AudioDiaryCard(
        //   path: "",
        // ),
        const SizedBox(height: 12),
        CustomRecordButton(
          onClick: () => recordResponse(context, prompt),
          text: "ADD A NEW RESPONSE",
        ),
        const SizedBox(height: 24),
      ],
    );
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
