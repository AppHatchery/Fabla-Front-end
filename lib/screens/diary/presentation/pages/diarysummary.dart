import 'dart:io';

import 'package:audio_diaries_flutter/core/usecases/notifications.dart';
import 'package:audio_diaries_flutter/core/usecases/page_timer.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/recording.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/summary_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/pages/diary_edit.dart';
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

  final PageTimer timer = PageTimer();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    timer.start();
    summaryCubit = BlocProvider.of<SummaryCubit>(context);
    loadDiary(context);
    super.initState();
  }

  @override
  void dispose() {
    timer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        scheduleSubmitDiaryNotification(widget.diary.id);
        track(timer.stop(), "Paused");
        break;
      case AppLifecycleState.resumed:
        timer.start();
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
                  leading: IconButton(
                    onPressed: () {
                      scheduleSubmitDiaryNotification(widget.diary.id);
                      track(timer.stop(), "Close");
                      Navigator.pushAndRemoveUntil(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const Hub(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
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
                  ),
                  title: Text(
                    "Response Summary",
                    style: CustomTypography()
                        .headlineMedium(color: CustomColors.textNormalContent),
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
          track(timer.stop(), "Submitted");
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

  track(int spent, String status) async {
    await PendoService.track("Diary Summary", {
      "time_on_page": spent,
      "status": status,
      "diary": widget.diary.name,
    });
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
              onClick: () => submitDiary(diary),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              color: CustomColors.fillWhite),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Q${index + 1}. ${prompt.question}",
                      style: CustomTypography()
                          .custom(fontSize: 18, fontWeight: FontWeight.w400),
                    ),
                  ),

                  // Edit Button
                  isEditable()
                      ? GestureDetector(
                          onTap: () => editResponse(prompt, index + 1),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_note_sharp,
                                  color: Color(0xFF4186F5), size: 24),
                              Text(' Edit',
                                  style: CustomTypography()
                                      .button(color: Color(0xFF4186F5)))
                            ],
                          ),
                        )
                      : const SizedBox.shrink()
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
      case ResponseType.audio || ResponseType.textAudio:
        return prompt.answer != null && prompt.answer!.recordings.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: TextAnswerCard(
                  answer: prompt.answer!.response!,
                  delete: () => deleteResponse(prompt, null),
                ),
              )
            : prompt.answer != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: prompt.answer?.recordings.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: NewAudioCard(
                              recording: prompt.answer!.recordings[index],
                              delete: () => deleteResponse(prompt,
                                  prompt.answer!.recordings[index].path),
                              viewOnly: true,
                              promptId: prompt.id,
                            ),
                          );
                        }),
                  )
                : const SizedBox.shrink();
      case ResponseType.text:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: TextAnswerCard(
            answer: prompt.answer!.response!,
            delete: () => deleteResponse(prompt, null),
          ),
        );
      case ResponseType.webview:
        final width = MediaQuery.of(context).size.width;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(children: [
              Expanded(
                child: Text("Response recorded externally",
                    style: CustomTypography().bodyMedium(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        );
      case ResponseType.image:
      case ResponseType.video:
      case ResponseType.imageVideo:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Preview(
            recordings: prompt.answer?.recordings ?? [],
            delete: (String path) {},
            interactions: false,
          ),
        );

      case ResponseType.timer:
        final width = MediaQuery.of(context).size.width;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(children: [
              Expanded(
                child: Text("Completed the timer ✅",
                    style: CustomTypography().bodyMedium(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void loadDiary(BuildContext context) {
    summaryCubit.loadSummary(widget.diary);
  }

  void editResponse(PromptModel _prompt, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDiaryPage(
          diary: widget.diary,
          prompt: _prompt,
          index: index,
        ),
      ),
    );

    if (result == true && mounted) {
      loadDiary(context);
    }
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
              final hint = prompt.subtitle?.replaceAll(r'\\n', '\n');

              return BottomRecordingModal(
                promptId: prompt.id,
                question: prompt.question,
                limit: prompt.option?.maxLength,
                suggested: prompt.option?.suggestedLength,
                hint: hint,
                onSave: (value) {
                  summaryCubit.saveResponse(
                      widget.diary, prompt, value.toString(), 'audio');
                },
              );
            }));
  }

  void deleteResponse(PromptModel prompt, String? path) {
    summaryCubit.removeResponse(widget.diary, prompt, path);
  }

  void submitDiary(DiaryModel diary) {
    summaryCubit.submitDiary(diary);
  }

  void pendoEvent() async {
    final now = DateTime.now();
    for (final prompt in widget.diary.prompts) {
      int audioPromptCount = 0;
      int totalRecordingCount = 0;
      List<int> individualRecordingSizes = [];
      int totalRecordingDurationInSeconds = 0;
      if (prompt.responseType == ResponseType.audio) {
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
            "diary_id": widget.diary.id,
            "diary_name": widget.diary.name,
            "submission_time": now.toIso8601String()
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
          index:
              null, // TODO: Add index of the prompt to edit & have a way to skip the other prompts back to the summary
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
