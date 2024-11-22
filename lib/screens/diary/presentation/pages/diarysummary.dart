import 'dart:io';

import 'package:audio_diaries_flutter/core/usecases/notifications.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/recording.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/summary_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/pages/new_diary.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/circle_transition_clipper.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/question_widgets.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/submit_error.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/submit_loading.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/theme/custom_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
// import 'package:just_audio/just_audio.dart';

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
  final DiaryModel diary;

  const DiarySummaryPage({
    super.key,
    required this.diary,
  });

  @override
  State<DiarySummaryPage> createState() => _DiarySummaryPageState();
}

class _DiarySummaryPageState extends State<DiarySummaryPage>
    with WidgetsBindingObserver {
  late SummaryCubit summaryCubit;
  int? expandedCardId;
  bool isSliderEnabled = false;
  Map<int, bool> sliderEnabledStates = {};

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    summaryCubit = BlocProvider.of<SummaryCubit>(context);
    loadDiary(context);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        scheduleSubmitDiaryNotification(widget.diary.id);
        break;
      default:
    }
    super.didChangeAppLifecycleState(state);
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
                  scrolledUnderElevation: 0.0,
                  leadingWidth: 100,
                  leading: isEditable()
                      ? GestureDetector(
                          onTap: () {
                            returnToDiary();
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.edit_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Edit",
                                  style: CustomTypography().bodyLarge(
                                      color: CustomColors.textNormalContent),
                                ),
                              ],
                            ),
                          ),
                        )
                      : null,
                  actions: [
                    IconButton(
                      onPressed: () {
                        scheduleSubmitDiaryNotification(widget.diary.id);
                        Navigator.pushAndRemoveUntil(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const Hub(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              const begin = Offset(-1.0,
                                  0.0); // Left to right for backward navigation
                              const end = Offset.zero;
                              const curve = Curves.easeInOut;

                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));
                              var offsetAnimation = animation.drive(tween);

                              return SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              );
                            },
                            transitionDuration: const Duration(
                                milliseconds: 200), // Adjust as needed
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(CustomIcons.close),
                      iconSize: 15.0,
                    )
                  ],
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
                          : state is SummarySubmitted
                              ? submitLoading()
                              : state is SubmitError
                                  ? submitError()
                                  : initial(),
        );
      },
      listener: (context, state) async {
        if (state is SummarySubmitted) {
          pendoEvent();
          Navigator.of(context).pushReplacement(_completionRoute()).then((_) {
            summaryCubit.loadSummary(widget.diary);
          });
        }
      },
    );
  }

  Widget submitLoading() {
    return const SubmitLoadingPage();
  }

  Widget submitError() {
    return const SubmitErrorPage();
  }

  Route _completionRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          DiaryCompletionPage(diary: widget.diary),
      transitionDuration: const Duration(milliseconds: 1200),
      reverseTransitionDuration: const Duration(milliseconds: 1200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var screenSize = MediaQuery.of(context).size;
        var centerCircleClipper =
            Offset(screenSize.width / 2, screenSize.height / 2);

        double beginRadius = 0.0;
        double endRadius = screenSize.height * 1.2;

        var radiusTween = Tween(begin: beginRadius, end: endRadius);
        var radiusTweenAnimation = animation.drive(radiusTween);

        return ClipPath(
          clipper: CircleTransitionClipper(
              center: centerCircleClipper, radius: radiusTweenAnimation.value),
          child: child,
        );
      },
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

  Widget content(DiaryModel diary, BuildContext context) {
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
            child: CustomFlatButton(
              onClick: () => submitDiary(),
              text: "Submit My Response",
              color: CustomColors.productNormal,
              textColor: CustomColors.textWhite,
            ),
          ),
        ),
      ],
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
              getResponseWidget(prompt),
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
          value: double.tryParse(prompt.answer!.response!) ?? 0.0,
        );
      case ResponseType.multiple:
        return MultipleQuestionSummary(
          answers: extractAnswers(prompt.answer!.response!),
        );
      case ResponseType.radio:
        return RadioQuestionSummary(
          selectedOption: prompt.answer!.response!,
        );
      case ResponseType.recording:
        return prompt.answer!.recordings.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: TextAnswerCard(
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
                      recording: prompt.answer!.recordings[index],
                      delete: () => deleteResponse(
                          prompt, prompt.answer!.recordings[index].path),
                      viewOnly: true,
                      promptId: prompt.id,
                    ),
                  );
                });
      case ResponseType.text:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: TextAnswerCard(
            answer: prompt.answer!.response!,
            delete: () => deleteResponse(prompt, ''),
          ),
        );
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

  void loadDiary(BuildContext context) {
    summaryCubit.loadSummary(widget.diary);
  }

  void recordResponse(BuildContext context, PromptModel prompt) {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        useSafeArea: true,
        builder: (context) => DraggableScrollableSheet(
            initialChildSize: 1,
            minChildSize: 1,
            snap: true,
            builder: (context, scrollController) {
              return BottomRecordingModal(
                promptId: prompt.id,
                question: prompt.question,
                onSave: (value) {
                  summaryCubit.saveResponse(
                      widget.diary, prompt, value.toString());
                },
              );
            }));
  }

  void deleteResponse(PromptModel prompt, String path) {
    summaryCubit.removeResponse(widget.diary, prompt, path);
  }

  void submitDiary() {
    summaryCubit.submitDiary(widget.diary);
  }

  void pendoEvent() async {
    for (final prompt in widget.diary.prompts) {
      int audioPromptCount = 0;
      int totalRecordingCount = 0;
      List<int> individualRecordingSizes = [];
      int totalRecordingDurationInSeconds = 0;
      if (prompt.responseType == ResponseType.recording) {
        audioPromptCount = widget.diary.prompts.indexOf(prompt) + 1;
        if (prompt.answer?.recordings != null) {
          totalRecordingCount += prompt.answer!.recordings.length;

          for (Recording recording in prompt.answer!.recordings) {
            final dir = await getApplicationDocumentsDirectory();
            final path = p.join(dir.path, 'recordings', recording.path);
            File recordingFile = File(path);

            if (recordingFile.existsSync()) {
              AudioPlayer audioPlayer = AudioPlayer()
                ..setSourceDeviceFile(path);

              final duration = await audioPlayer.onDurationChanged.first;

              individualRecordingSizes.add(duration.inSeconds);
              totalRecordingDurationInSeconds += duration.inSeconds;
            }
          }

          PendoService.track("ResponseTime", {
            "prompt_number": "$audioPromptCount",
            "number_of_audio_recordings": "$totalRecordingCount",
            "individual_recording_length(s)": "$individualRecordingSizes",
            "total_recording_length": "$totalRecordingDurationInSeconds",
            "study_day": "day ${widget.diary.id}"
          });
        }
      }
    }
  }

  void returnToDiary() async {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => NewDiaryPage(
          diary: widget.diary,
          index: null,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0); // Start from left
          const end = Offset.zero; // End at the center
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration:
            const Duration(milliseconds: 300), // Faster transition
      ),
    );
  }

  bool isEditable() {
    final due = widget.diary.due;
    final now = DateTime.now();

    //Is it past the due
    return now.isBefore(due);
  }
}
