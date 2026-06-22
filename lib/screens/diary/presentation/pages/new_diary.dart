import 'package:audio_diaries_flutter/core/usecases/diary.dart';
import 'package:audio_diaries_flutter/core/usecases/notifications.dart';
import 'package:audio_diaries_flutter/core/usecases/page_timer.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/session/diary_session_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/audio_quiestions_widget.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/question_widgets.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
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
import 'diarysummary.dart';

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
  late DiarySessionCubit sessionCubit;
  int currentPage = 0;

  // Tracks the visible list length across builds so we can detect changes
  int _lastVisibleCount = 0;

  final PageTimer timer = PageTimer();
  bool ableToContinue = false;
  bool showCloseIcon = true;
  // Functions to run before moving to the next page
  List<Function> preFunctions = [];
  final List<GlobalKey<_QuestionPageState>> _questionPageKeys = [];

  //get page => currentPage = widget.diary.prompts.length;

  @override
  void initState() {
    super.initState();
    controller = PageController();
    controller.addListener(() {
      final page = controller.page?.round();
      if (page != null && page != currentPage && mounted) {
        setState(() => currentPage = page);
      }
    });
    sessionCubit = BlocProvider.of<DiarySessionCubit>(context);
    sessionCubit.init(widget.diary);
    timer.start();
    // loop to initialize keys for each prompt
    for (int i = 0; i < widget.diary.prompts.length; i++) {
      _questionPageKeys.add(GlobalKey<_QuestionPageState>());
    }
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    showTip();
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

  @override
  void dispose() {
    controller.dispose();
    timer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void nextPage(List<PromptModel> visiblePrompts) {
    for (var fn in preFunctions) {
      fn();
    }
    if (currentPage < visiblePrompts.length - 1) {
      track(timer.reset(), "Next");
      controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      if (widget.diary.status == DiaryStatus.submitted ||
          widget.diary.status == DiaryStatus.missed) {
        Navigator.pop(context);
      } else {
        DiaryRepository()
            .updateDiary(widget.diary..status = DiaryStatus.complete);
        diaryEnd(diaryID: widget.diary.id.toString());
        track(timer.stop(), "Finished");
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DiarySummaryPage(diary: widget.diary),
                settings: const RouteSettings(name: "/DiarySummaryPage")));
      }
    }
  }

  void previousPage() {
    for (var fn in preFunctions) {
      fn();
    }
    if (currentPage > 0) {
      controller.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const Hub(),
              settings: const RouteSettings(name: "/Hub")),
          (route) => false);
    }
  }

  void _scrollToTopOfCurrentQuestion() {
    if (currentPage < _questionPageKeys.length) {
      final GlobalKey<_QuestionPageState> currentKey =
          _questionPageKeys[currentPage];
      final _QuestionPageState? currentState = currentKey.currentState;
      currentState?.scrollToTop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        previousPage();
        return false;
      },
      child: BlocConsumer<DiarySessionCubit, DiarySessionState>(
        buildWhen: (_, current) =>
            current is DiarySessionReady || current is DiarySessionLoading,
        builder: (context, state) {
          if (state is DiarySessionLoading) return _buildLoading();
          if (state is DiarySessionReady) return _buildDiary(state);
          return _buildLoading();
        },
        listener: (context, state) {
          if (state is DiarySessionReady) {
            // When the visible list changes size, keep the same prompt on screen
            if (state.visiblePrompts.length != _lastVisibleCount &&
                _lastVisibleCount > 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (controller.hasClients) {
                  controller.jumpToPage(
                      currentPage.clamp(0, state.visiblePrompts.length - 1));
                }
              });
            }
            _lastVisibleCount = state.visiblePrompts.length;
          }
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildDiary(DiarySessionReady state) {
    final visiblePrompts = state.visiblePrompts;
    final isLastPage = currentPage == visiblePrompts.length - 1;

    return Scaffold(
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
              const SizedBox(width: 7),
              IconButton(
                onPressed: () {
                  if (widget.diary.status == DiaryStatus.ongoing) {
                    scheduleContinueDiaryNotifications(widget.diary.id);
                  }
                  trackExit("Closed");
                  track(timer.stop(), "Close");
                  for (var fn in preFunctions) {
                    fn();
                  }
                  Navigator.pushAndRemoveUntil(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const Hub(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(-1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        final tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        return SlideTransition(
                            position: animation.drive(tween), child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(CustomIcons.close),
                iconSize: 15.0,
              ),
              Expanded(
                child: CustomBarIndicator(
                    pageCount: widget.diary.prompts.length,
                    currentPage: currentPage < visiblePrompts.length
                        ? widget.diary.prompts.indexWhere(
                            (p) => p.id == visiblePrompts[currentPage].id)
                        : 0),
              ),
              const SizedBox(width: 15),
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
                key: const PageStorageKey('diaryPageView'),
                physics: const NeverScrollableScrollPhysics(),
                controller: controller,
                onPageChanged: (idx) {
                  setState(() {
                    currentPage = idx;
                    ableToContinue = false;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _scrollToTopOfCurrentQuestion();
                    }
                  });
                },
                children: visiblePrompts.asMap().entries.map((entry) {
                  final scaffoldKey = GlobalKey<ScaffoldState>();
                  return QuestionPage(
                    key: ValueKey(entry.value.id),
                    index: entry.key,
                    currentPage: currentPage,
                    diary: widget.diary,
                    prompt: entry.value,
                    scaffoldKey: scaffoldKey,
                    answerAdded: (value) {
                      if (mounted) setState(() => ableToContinue = value);
                    },
                    previousPage: previousPage,
                    nextPage: () => nextPage(visiblePrompts),
                    isLastPage: isLastPage,
                    addToPreFunction: (fn) => preFunctions.add(fn),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 30),
            child: Column(
              children: [
                Row(
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
                        iconColor: CustomColors.productNormal,
                        color: CustomColors.fillWhite,
                        shadowColor: Colors.transparent,
                        border: Border.all(
                          color: CustomColors.productBorderNormal,
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: CustomFlatButton(
                        isDisabled: visiblePrompts[currentPage].responseType ==
                                ResponseType.timer
                            ? false
                            : !ableToContinue,
                        onClick: () => nextPage(visiblePrompts),
                        text: "Next",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showTip() async {
    bool show =
        await PreferenceService().getBoolPreference(key: "show_diary_tip") ??
            true;
    if (show && mounted) {
      Future.delayed(const Duration(milliseconds: 500),
          () async => await PendoService.track("DiaryPopUp", null));
    }
  }

  track(int spent, String status) async {
    await PendoService.track("Diary Entry", {
      "time_on_page": spent,
      "status": status,
      "diary": widget.diary.name,
      "prompt": currentPage + 1,
    });
  }

  trackExit(String state) async {
    final now = DateTime.now();
    PendoService.track("Exit Survey", {
      "question_at_exit": "${currentPage + 1}",
      "diary_id": widget.diary.id,
      "diary_name": widget.diary.name,
      "time": now.toIso8601String(),
      "state": state,
    });
  }
}

class QuestionPage extends StatefulWidget {
  final DiaryModel diary;
  final PromptModel prompt;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ValueChanged<bool> answerAdded;
  final int currentPage;
  final int index;
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
    required this.index,
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
  final ScrollController _scrollController = ScrollController();
  void scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  late PromptModel promptModel;
  late DiarySessionCubit sessionCubit;

  bool disabled = false;
  PersistentBottomSheetController? _bottomSheetController;
  bool isClicked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    promptModel = widget.prompt;
    sessionCubit = BlocProvider.of<DiarySessionCubit>(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      checkForResponse(promptModel);
      if (promptModel.responseType == ResponseType.instruction) {
        save(promptModel, 'read', 'other', 0);
      }
    });
  }

  @override
  void didUpdateWidget(QuestionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prompt != widget.prompt) {
      setState(() => promptModel = widget.prompt);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) checkForResponse(widget.prompt);
      });
    } else if (oldWidget.currentPage != widget.currentPage &&
        widget.currentPage == widget.index) {
      // This page just became active — re-evaluate the Next button
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) checkForResponse(promptModel);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused &&
        widget.diary.status == DiaryStatus.ongoing) {
      scheduleContinueDiaryNotifications(widget.diary.id);
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: BlocListener<DiarySessionCubit, DiarySessionState>(
        listener: (context, state) {
          if (state is DiarySessionResponseSaved &&
              state.promptId == widget.prompt.id) {
            setState(() => promptModel = state.updatedPrompt);
            checkForResponse(state.updatedPrompt);
            _showSuccessModal();
          } else if (state is DiarySessionResponseDeleted &&
              state.promptId == widget.prompt.id) {
            _dismissSuccessModal();
            checkForResponse(promptModel);
          }
        },
        child: buildPrompt(promptModel),
      ),
    );
  }

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
        onSliderValueChanged: (value) {
          save(prompt, value.toString(), 'other', 0);
          widget.answerAdded(true);
        },
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
          save(prompt, response.isEmpty ? null : response, 'other', 0);
          widget.answerAdded(response.isNotEmpty);
        },
        disabled: disabled,
      );
    } else if (prompt.responseType == ResponseType.radio) {
      responseWidget = RadioQuestion(
        value: prompt.answer?.response?.first,
        options: prompt.option!.choices!,
        onChanged: (value) {
          save(prompt, value, 'other', 0);
          widget.answerAdded(value != null);
        },
        disabled: disabled,
      );
    } else if (prompt.responseType == ResponseType.text) {
      responseWidget = FreeTextQuestionCard(
        diary: widget.diary,
        respond: (String type, int? index) =>
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
      final completedTimes = prompt.answer?.response != null
          ? prompt.answer?.response!.first.split("| ")
          : <String>[];
      responseWidget = TimerWidget(
        time: prompt.option?.timerLength ?? const Duration(seconds: 30),
        userInteraction: prompt.option?.userInteraction ?? false,
        playbackControls: prompt.option?.playbackControl ?? false,
        respond: (answer) {
          final completed = completedTimes ?? [];
          completed.add(answer);
          save(prompt, completed.join("| "), 'other', 0);
        },
        addToPreFunction: (fn) => widget.addToPreFunction(fn),
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
          prompt.subtitle ?? "Tap ‘Finish’ when you’ve completed the survey";
    } else if (prompt.responseType == ResponseType.timer) {
      questionTip =
          'Hit the "Start" button to begin meditation countdown.\nDuring the countdown, if you leave the page, the timer will continue on the background.';
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
            scrollController: _scrollController,
          )
        : prompt.responseType == ResponseType.instruction
            ? SingleChildScrollView(
                child: SizedBox(
                  child: CustomFormatterText(text: prompt.question),
                ),
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
                  controller: _scrollController,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              alignment: Alignment.topLeft,
                              child: Text(
                                "Question ${widget.diary.prompts.indexWhere((p) => p.id == widget.prompt.id) + 1}/${widget.diary.prompts.length}",
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
                            child: Text(questionTip,
                                style: CustomTypography().bodyLarge(
                                    color: CustomColors.textNormalContent,
                                    weight: FontWeight.w400)),
                          )
                        ],
                      ),
                      SizedBox(
                          height: (prompt.responseType == ResponseType.text ||
                                  prompt.responseType == ResponseType.radio ||
                                  prompt.responseType == ResponseType.multiple)
                              ? 48
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

  void checkForResponse(PromptModel prompt) {
    if (!prompt.required) {
      widget.answerAdded(true);
      return;
    }

    final answer = prompt.answer;
    bool isValid;

    switch (prompt.responseType) {
      case ResponseType.instruction:
      case ResponseType.timer:
        isValid = true;
        break;
      case ResponseType.textAudio:
        isValid = (answer?.recordings.isNotEmpty ?? false) ||
            (answer?.response?.isNotEmpty ?? false);
        break;
      case ResponseType.audio:
      case ResponseType.image:
      case ResponseType.video:
      case ResponseType.imageVideo:
      case ResponseType.mediaImage:
      case ResponseType.mediaVideo:
        isValid = answer?.recordings.isNotEmpty ?? false;
        break;
      default:
        isValid = answer?.response?.isNotEmpty ?? false;
    }

    widget.answerAdded(isValid);
  }

  void recordResponse(PromptModel prompt, String type, {int? index}) {
    if (type == "audio") {
      _track("Audio");
      showModalBottomSheet(
          backgroundColor: Colors.transparent,
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          elevation: 0,
          useSafeArea: true,
          routeSettings: const RouteSettings(name: "/RecordingModal"),
          builder: (context) => DraggableScrollableSheet(
                initialChildSize: 1,
                minChildSize: 1,
                snap: true,
                builder: (context, scrollController) {
                  final hint = prompt.subtitle?.replaceAll(r'\\n', '\n');
                  return BottomRecordingModal(
                    promptId: prompt.id,
                    question: prompt.question,
                    subtitle: prompt.subtitle,
                    hint: hint,
                    limit: prompt.option?.maxLength,
                    suggested: prompt.option?.suggestedLength,
                    onSave: (value) =>
                        save(prompt, value.toString(), "audio", null),
                  );
                },
              ));
    } else {
      _track("Text");
      showModalBottomSheet(
          backgroundColor: Colors.transparent,
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          elevation: 0,
          useSafeArea: true,
          routeSettings: const RouteSettings(name: "/TextModal"),
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
                    onSave: (value) =>
                        save(prompt, value.toString(), 'other', index),
                    index: index,
                    scrollController: scrollController,
                  );
                },
              ));
    }
  }

  void save(PromptModel prompt, dynamic response, String type, int? index) {
    if (widget.diary.status == DiaryStatus.idle) {
      widget.diary.status = DiaryStatus.ongoing;
      DiaryRepository().updateDiary(widget.diary);
    }
    sessionCubit.saveAnswer(
        prompt: prompt, response: response, type: type, index: index);
    cancelContinueNotifications(widget.diary.id);
    if (!isClicked && mounted) setState(() => isClicked = true);
  }

  void _showSuccessModal() {
    _bottomSheetController =
        widget.scaffoldKey.currentState?.showBottomSheet((context) {
      return BottomSuccessModal(
        previousPage: widget.previousPage,
        onNextQuestionClicked: widget.nextPage,
        text: (widget.isLastPage ?? true) ? "Review Summary" : "Next Question",
      );
    });
  }

  void _dismissSuccessModal() {
    _bottomSheetController?.close();
    _bottomSheetController = null;
  }

  _track(String option) async {
    await PendoService.track("Diary Entry Question Type", {
      "option_selected": option,
      "diary": widget.diary.name,
    });
  }
}
