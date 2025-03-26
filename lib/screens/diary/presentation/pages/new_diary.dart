import 'package:audio_diaries_flutter/core/usecases/notifications.dart';
import 'package:audio_diaries_flutter/core/usecases/page_timer.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/audio_quiestions_widget.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/question_widgets.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
// import 'package:audio_diaries_flutter/theme/dialogs/pop_ups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/types.dart';
import '../../../../main.dart';
import '../../../../theme/components/buttons.dart';
import '../../../../theme/components/indicators.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_icons.dart';
import '../../../../theme/custom_typography.dart';
import '../../../../theme/dialogs/bottom_modals.dart';
import '../../data/diary.dart';
import '../../data/prompt.dart';
import '../../domain/repository/diary_repository.dart';
import '../cubit/prompt/prompt_cubit.dart';
import 'diarysummary.dart';

/// This class holds and manages all the pages in the page view
/// It has all the UI elements of the New Daily Diary flow
/// The pages have been hardcoded into the PageView(later to be replaced by the number of questions in the diary)
/// The page view has a controller which is used to navigate between pages
class NewDiaryPage extends StatefulWidget {
  final DiaryModel diary;
  final int? index;

  const NewDiaryPage({super.key, required this.diary, this.index});

  @override
  State<NewDiaryPage> createState() => _NewDiaryPageState();
}

class _NewDiaryPageState extends State<NewDiaryPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
  late PageController controller;
  late int currentPage;

  final PageTimer timer = PageTimer();

  bool ableToContinue = false;
  bool showCloseIcon = true;

  // Functions to run before moving to the next page
  List<Function> preFunctions = [];

  //get page => currentPage = widget.diary.prompts.length;

  @override
  void initState() {
    controller = PageController();
    controllerInit();
    showTip();
    timer.start();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.diary.status == DiaryStatus.complete || widget.index != null) {
        currentPage = widget.index != null
            ? widget.index!
            : widget.diary.prompts.length - 1;
        if (controller.hasClients) {
          controller.jumpToPage(currentPage);
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      trackExit("Paused");
      track(timer.stop(), "Paused");
    } else if (state == AppLifecycleState.resumed) {
      timer.start();
    }
  }

  void nextPage() {
    for (var function in preFunctions) {
      function();
    }

    if (currentPage < widget.diary.prompts.length - 1) {
      track(timer.reset(), "Next");
      controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // Change dairy status to complete
      if (widget.diary.status == DiaryStatus.submitted ||
          widget.diary.status == DiaryStatus.missed) {
        Navigator.pop(context);
      } else {
        DiaryRepository repository = DiaryRepository();
        widget.diary.status = DiaryStatus.complete;
        repository.updateDiary(widget.diary);
        track(timer.stop(), "Finished");
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DiarySummaryPage(diary: widget.diary)));
      }
    }
  }

  bool get isCurrentPageLast => currentPage == widget.diary.prompts.length - 1;

  void previousPage() {
    if (currentPage > 0) {
      controller.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Hub()),
          (route) => false);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    timer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        previousPage();
        return false;
      },
      child: Scaffold(
        key: key,
        backgroundColor: CustomColors.fillNormal,
        appBar: AppBar(
          backgroundColor: CustomColors.fillNormal,
          scrolledUnderElevation: 0.0,
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(
                  width: 7,
                ),
                IconButton(
                  onPressed: () {
                    if (widget.diary.status == DiaryStatus.ongoing) {
                      scheduleContinueDiaryNotifications(widget.diary.id);
                    }
                    trackExit("Closed");
                    track(timer.stop(), "Close");
                    Navigator.pushAndRemoveUntil(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const Hub(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(-1.0,
                              0.0); // Left to right for back-to-home effect
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
                            milliseconds: 300), // Matches iOS animation speed
                      ),
                      (route) => false, // Clears the entire stack
                    );
                  },
                  icon: const Icon(CustomIcons.close),
                  iconSize: 15.0,
                ),
                Expanded(
                  child: CustomBarIndicator(
                      pageCount: widget.diary.prompts.length,
                      currentPage: currentPage),
                ),
                const SizedBox(
                  width: 15,
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: controller,
                  children: pages(),
                  onPageChanged: (pageIdx) => controller.animateToPage(pageIdx,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.fastEaseInToSlowEaseOut),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 30,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Visibility(
                      visible: currentPage != 0,
                      child: CustomElevatedIconButton(
                        onClick: () {
                          track(timer.reset(), "Previous");
                          previousPage();
                        },
                        icon: Icons.arrow_back,
                        //iconSize: 25.0,
                        iconColor: CustomColors.productNormal,
                        color: CustomColors.fillWhite,
                        shadowColor: Colors.transparent,
                        border: Border.all(
                          color: CustomColors.productBorderNormal,
                          width: 2,
                        ),
                      )),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    flex: 3,
                    child: CustomFlatButton(
                      isDisabled: !ableToContinue,
                      onClick: () => nextPage(),
                      text: "Continue",
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> pages() {
    return widget.diary.prompts.map((e) {
      final _key = GlobalKey<ScaffoldState>();
      return QuestionPage(
        currentPage: currentPage,
        diary: widget.diary,
        prompt: e,
        scaffoldKey: _key,
        answerAdded: (value) {
          if (mounted) {
            setState(() {
              ableToContinue = value;
            });
          }
        },
        previousPage: previousPage,
        nextPage: nextPage,
        isLastPage: isCurrentPageLast,
        addToPreFunction: (p0) {
          preFunctions.add(p0);
        },
      );
    }).toList();
  }

  void controllerInit() {
    currentPage = controller.initialPage;
    controller.addListener(() {
      if (controller.page != currentPage) {
        if (mounted) {
          setState(() {
            currentPage = controller.page!.round();
          });
        }
      }
    });
  }

  void showTip() async {
    bool show =
        await PreferenceService().getBoolPreference(key: "show_diary_tip") ??
            true;

    if (show && mounted) {
      Future.delayed(const Duration(milliseconds: 500),
          () async => await PendoService.track("DiaryPopUp", null));
      // () => showModalBottomSheet(
      //     backgroundColor: Colors.white,
      //     context: context,
      //     isScrollControlled: true,
      //     builder: (context) => const Wrap(
      //           children: [CustomBottomTipPopUp()],
      //         )));
    }
  }

  track(int spent, String status) async {
    await PendoService.track("Diary Entry", {
      "time_on_page": spent,
      "status": status,
      "diary": widget.diary.name,
      "prompt": currentPage + 1
    });
  }

  trackExit(String state) async {
    final now = DateTime.now();

    PendoService.track("Exit Survey", {
      "question_at_exit": "${currentPage + 1}",
      "diary_id": widget.diary.id,
      "diary_name": widget.diary.name,
      "time": now.toIso8601String(),
      "state": state
    });
  }
}

/// This class is the page that is being duplicated in the PageView
/// It has two parameters:
/// onNextPage: a function that is called when the user clicks on the continue button
/// question: the question that is being asked in the diary
class QuestionPage extends StatefulWidget {
  final DiaryModel diary;
  final PromptModel prompt;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ValueChanged<bool> answerAdded;
  final int currentPage;
  final VoidCallback nextPage;
  final VoidCallback previousPage;
  final ValueChanged<Function> addToPreFunction;
  final bool? isLastPage;

  const QuestionPage({
    super.key,
    required this.diary,
    required this.prompt,
    required this.scaffoldKey,
    required this.currentPage,
    required this.answerAdded,
    required this.previousPage,
    required this.nextPage,
    required this.addToPreFunction,
    this.isLastPage,
  });

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage>
    with WidgetsBindingObserver {
  late PromptCubit promptCubit;
  late PromptModel promptModel;

  bool isChecked = false;
  bool disabled = false;
  PersistentBottomSheetController? _bottomSheetController;

  void updateSliderValue(PromptModel prompt, double value) {
    save(prompt, value.toString(), 'other', 0);
    widget.answerAdded(true);
  }

  bool isClicked = false;
  // final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    promptModel = widget.prompt;
    promptCubit = BlocProvider.of<PromptCubit>(context);
    loadPrompt();
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
        if (widget.diary.status == DiaryStatus.ongoing) {
          scheduleContinueDiaryNotifications(widget.diary.id);
          //partialDataUpload(widget.diary);
        }
        break;
      default:
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: BlocConsumer<PromptCubit, PromptState>(
        builder: (context, state) {
          if (state is PromptInitial) {
            return buildInitial();
          } else if (state is PromptLoading) {
            return buildLoading();
          } else if (state is PromptLoaded) {
            return buildPrompt(state.prompt);
          } else {
            return buildInitial();
          }
        },
        listener: (context, state) {
          if (state is PromptRespondState) {
            recordResponse(promptModel, "");
          } else if (state is PromptResponseSuccess) {
            showSuccessModal();
          } else if (state is PromptResponseError) {
            showErrorModal();
          } else if (state is PromptLoaded) {
            checkForResponse(state.prompt);
          } else if (state is PromptResponseDeleted) {
            dismissSuccessModal();
          }
        },
      ),
    );
  }

  Widget buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: CustomColors.productNormalActive,
      ),
    );
  }

  Widget buildInitial() {
    return SizedBox(
      height: 900,
      width: double.infinity,
    );
  }

  bool isSnackBarVisible = false;

  Widget buildPrompt(PromptModel prompt) {
    Widget responseWidget;

    if (prompt.responseType == ResponseType.slider) {
      responseWidget = SliderQuestionCard(
        value: prompt.answer?.response != null
            ? double.parse(prompt.answer!.response!.first)
            : prompt.option!.defaultValue!.toDouble(),
        scaleMin: prompt.option!.minValue!,
        scaleMax: prompt.option!.maxValue!,
        scaleMinText: prompt.option!.minLabel,
        scaleMaxText: prompt.option!.maxLabel,
        onSliderValueChanged: (value) => updateSliderValue(prompt, value),
        isSliderEnabled: !disabled,
      );
    } else if (prompt.responseType == ResponseType.multiple) {
      final selected = prompt.answer?.response != null
          ? prompt.answer?.response!.first.split("/ ")
          : <String>[];

      responseWidget = MultipleQuestion(
        options: prompt.option!.choices!,
        selected: selected,
        onChanged: (value) {
          final response = value.join("/ ");
          save(prompt, response, 'other', 0);
          if (value.isNotEmpty) {
            widget.answerAdded(true);
          } else {
            widget.answerAdded(false);
          }
        },
        disabled: disabled,
      );
    } else if (prompt.responseType == ResponseType.radio) {
      final selected = prompt.answer?.response?.first;
      responseWidget = RadioQuestion(
        value: selected,
        options: prompt.option!.choices!,
        onChanged: (value) {
          save(prompt, value, 'other', 0);
          if (value != null) {
            widget.answerAdded(true);
          } else {
            widget.answerAdded(false);
          }
        },
        disabled: disabled,
      );
    } else if (prompt.responseType == ResponseType.text) {
      responseWidget = FreeTextQuestionCard(
        diary: widget.diary,
        respond: (String type, int index) =>
            recordResponse(prompt, type, index: index),
        prompt: prompt,
      );
    } else if (prompt.responseType == ResponseType.audio ||
        prompt.responseType == ResponseType.textAudio) {
      responseWidget = AudioTextCard(
        diary: widget.diary,
        respond: (String type, int? index) =>
            recordResponse(prompt, type, index: index),
        prompt: prompt,
      );
    } else if (prompt.responseType == ResponseType.webview) {
      responseWidget = WebViewResponseCard(
          prompt: prompt,
          diary: widget.diary,
          respond: (answer) => save(prompt, answer, 'other', 0));
    } else if (prompt.responseType == ResponseType.timer) {
      responseWidget = TimerWidget(
        time: prompt.option?.timerLength ?? Duration(seconds: 30),
        userInteraction: prompt.option?.userInteraction ?? false,
        playbackControls: prompt.option?.playbackControl ?? false,
        respond: (answer) => save(prompt, answer, 'other', 0),
        addToPreFunction: (p0) => {widget.addToPreFunction(p0)},
      );
    } else if (prompt.responseType == ResponseType.image) {
      responseWidget = VisualResponseWidget(
          diary: widget.diary,
          prompt: prompt,
          respond: (answer, [type]) => save(prompt, answer, 'image', null));
    } else if (prompt.responseType == ResponseType.video) {
      responseWidget = VisualResponseWidget(
          diary: widget.diary,
          prompt: prompt,
          respond: (answer, [type]) => save(prompt, answer, 'video', null));
    } else if (prompt.responseType == ResponseType.imageVideo) {
      responseWidget = VisualResponseWidget(
          diary: widget.diary,
          prompt: prompt,
          respond: (answer, [type]) =>
              save(prompt, answer, type ?? 'video', null));
    } else if (prompt.responseType == ResponseType.timePicker) {
      responseWidget = TimePickerWidget(
          prompt: prompt,
          respond: (answer) => save(prompt, answer, "other", 0));
    } else {
      responseWidget = const SizedBox.shrink();
    }

    String questionTip = "";

    if (prompt.responseType == ResponseType.slider) {
      questionTip = prompt.subtitle ?? "Please use the slider to rate:";
    } else if (prompt.responseType == ResponseType.multiple) {
      questionTip = prompt.subtitle ?? "Please check all that apply:";
    } else if (prompt.responseType == ResponseType.radio) {
      questionTip = prompt.subtitle ?? "Please check 1 option:";
    } else if (prompt.responseType == ResponseType.text) {
      questionTip = prompt.subtitle ?? "Please type your answer:";
    } else if (prompt.responseType == ResponseType.webview) {
      questionTip =
          "Close the pop-up window when you are done filling the survey.";
    } else if (prompt.responseType == ResponseType.timer) {
      questionTip =
          'Hit the “Start” button to begin meditation countdown.\nDuring the countdown, if you leave the page, the timer will continue on the background.';
    } else if (prompt.responseType == ResponseType.timePicker) {
      questionTip = prompt.subtitle ?? "";
    }

    return (prompt.responseType == ResponseType.audio ||
            prompt.responseType == ResponseType.textAudio)
        ? AudioQuestionsWidget(
            diary: widget.diary,
            prompt: prompt,
            currentPage: widget.currentPage,
            responseWidget: responseWidget,
            bottomSheetController: _bottomSheetController,
          )
        : prompt.responseType == ResponseType.instruction
            ? SizedBox(
                child: CustomFormatterText(text: prompt.question),
              )
            : Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: CustomColors.fillWhite,
                ),
                child: SingleChildScrollView(
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
                      SizedBox(
                          height: prompt.responseType == ResponseType.text
                              ? 24
                              : 112),
                      responseWidget,
                      if (widget.diary.status != DiaryStatus.submitted &&
                          widget.diary.status != DiaryStatus.missed &&
                          prompt.responseType == ResponseType.audio)
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3),

                      // const CustomTextButton(
                      //     onClick: null, text: "I DON'T WANT TO ANSWER THIS QUESTION"),
                    ],
                  ),
                ),
              );
  }

  void loadPrompt() {
    promptCubit.loadPrompt(widget.diary, promptModel);
  }

  ///Checks whether the provided prompt has a response
  ///Returns a bool for [`able to continue`] that allows the user to either proceed or not
  ///depending on the availability of the response/recording
  void checkForResponse(PromptModel prompt1) {
    bool isValidResponse = false;
    final answer = prompt1.answer;

    switch (prompt1.responseType) {
      case ResponseType.instruction:
        isValidResponse = true;
        break;
      case ResponseType.audio:
      case ResponseType.image:
      case ResponseType.video:
      case ResponseType.imageVideo:
        isValidResponse = answer?.recordings.isNotEmpty ?? false;
        break;
      default:
        isValidResponse = answer?.response?.isNotEmpty ?? false;
    }

    widget.answerAdded(isValidResponse);
  }

  void recordResponse(PromptModel prompt, String type, {int? index}) {
    if (type == "audio") {
      track("Audio");
      showModalBottomSheet(
          backgroundColor: Colors.transparent,
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          elevation: 0,
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
                    hint: hint,
                    limit: prompt.option?.maxLength,
                    suggested: prompt.option?.suggestedLength,
                    onSave: (value) {
                      save(prompt, value.toString(), "audio", null);
                    },
                  );
                },
              ));
    } else {
      track("Text");
      showModalBottomSheet(
          backgroundColor: Colors.transparent,
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          elevation: 0,
          useSafeArea: true,
          builder: (context) => DraggableScrollableSheet(
                initialChildSize: 1,
                minChildSize: 1,
                snap: true,
                builder: (context, scrollController) {
                  final hint = prompt.subtitle?.replaceAll(r'\\n', '\n');

                  return BottomTextModal(
                    prompt: prompt,
                    question: prompt.question,
                    hint: hint,
                    onSave: (value) {
                      save(prompt, value.toString(), 'other', index);
                    },
                    index: index,
                    scrollController: scrollController,
                  );
                },
              ));
    }
  }

  track(String option) async {
    await PendoService.track("Diary Entry Question Type", {
      "option_selected": option,
      "diary": widget.diary.name,
    });
  }

  void save(PromptModel prompt, dynamic response, String type, int? index) {
    // Change diary status
    if (widget.diary.status == DiaryStatus.idle) {
      widget.diary.status = DiaryStatus.ongoing;
      DiaryRepository repository = DiaryRepository();
      repository.updateDiary(widget.diary);
    }
    promptCubit.saveResponse(
        diary: widget.diary,
        prompt: prompt,
        response: response,
        type: type,
        index: index);
    cancelContinueNotifications(widget.diary.id);
    if (!isClicked && mounted) {
      setState(() {
        isClicked = true;
      });
    }
  }

  void showSuccessModal() {
    bool isLast = widget.isLastPage ?? true;

    _bottomSheetController =
        widget.scaffoldKey.currentState?.showBottomSheet((context) {
      // _scrollController.animateTo(
      //   _scrollController.position.maxScrollExtent,
      //   duration: const Duration(milliseconds: 300),
      //   curve: Curves.easeInOut,
      // );

      return BottomSuccessModal(
        previousPage: () => widget.previousPage(),
        onNextQuestionClicked: widget.nextPage,
        text: isLast ? "Review Summary" : "Next Question",
      );
    });
  }

  void dismissSuccessModal() {
    if (_bottomSheetController != null) {
      _bottomSheetController!.close();
      _bottomSheetController = null;
    }
  }

  void showErrorModal() {
    widget.scaffoldKey.currentState!
        .showBottomSheet((context) => const BottomErrorModal());
  }
}
