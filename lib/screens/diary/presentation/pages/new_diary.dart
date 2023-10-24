import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/screens/diary/data/option.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/question_widgets.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/theme/dialogs/pop_ups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/statuses.dart';
import '../../../../core/utils/types.dart';
import '../../../../main.dart';
import '../../../../theme/components/buttons.dart';
import '../../../../theme/components/indicators.dart';
import '../../../../theme/components/notes.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_icons.dart';
import '../../../../theme/custom_typography.dart';
import '../../../../theme/dialogs/bottom_modals.dart';
import '../../data/diary.dart';
import '../../data/prompt.dart';
import '../../domain/repository/diary_repository.dart';
import '../cubit/prompt/prompt_cubit.dart';
import '../widgets/my_responses.dart';
import 'diarysummary.dart';

/// This class holds and manages all the pages in the page view
/// It has all the UI elements of the New Daily Diary flow
/// The pages have been hardcoded into the PageView(later to be replaced by the number of questions in the diary)
/// The page view has a controller which is used to navigate between pages
class NewDiaryPage extends StatefulWidget {
  final Diary diary;
  const NewDiaryPage({super.key, required this.diary});

  @override
  State<NewDiaryPage> createState() => _NewDiaryPageState();
}

class _NewDiaryPageState extends State<NewDiaryPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
  late PageController controller;
  late int currentPage;

  bool ableToContinue = false;
  bool showCloseIcon = true;

  @override
  void initState() {
    controller = PageController();
    controllerInit();
    if (widget.diary.status == DiaryStatus.submitted ||
        widget.diary.status == DiaryStatus.missed) {
      setState(() {
        ableToContinue = true;
      });
    }
    showTip();
    if (widget.diary.status == DiaryStatus.idle) {
      participantsDiaryStartDate(widget.diary);
    }
    super.initState();
  }

  void nextPage() {
    if (currentPage < widget.diary.prompts.length - 1) {
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
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  icon: const Icon(CustomIcons.close),
                  iconSize: 15.0,
                ),
                // if (currentPage == 0)

                // else
                //   IconButton(
                //     onPressed: previousPage,
                //     icon: const Icon(Icons.arrow_back),
                //     iconSize: 25.0,
                //   ),
                // IconButton(
                //   onPressed: () {
                //     Navigator.pop(context, true);
                //   },
                //   icon:
                //   const Icon(CustomIcons.close),
                //   iconSize: 15.0,
                // ),
                Expanded(
                  child: CustomBarIndicator(
                      pageCount: widget.diary.prompts.length,
                      currentPage: currentPage),
                ),
                const SizedBox(
                  width: 17,
                ),
                //functionality of the skip button to be added later on
                // TextButton(
                //   onPressed: () {
                //     print("Skip clicked!");
                //   },
                //   child: Text(
                //     "Skip",
                //     style: CustomTypography()
                //         .titleSmall(color: CustomColors.textNormalContent),
                //   ),
                // ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: controller,
                children: pages(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 34),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Visibility(
                      visible: currentPage != 0,
                      child: CustomElevatedIconButton(
                        onClick: () {
                          previousPage();
                        },
                        icon: Icons.arrow_back,
                        //iconSize: 25.0,
                        iconColor: CustomColors.productNormal,
                        color: CustomColors.fillNormal,
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
                      text: "CONTINUE",
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

  List<QuestionPage> pages() {
    return widget.diary.prompts
        .map((e) => QuestionPage(
              currentPage: currentPage,
              diary: widget.diary,
              prompt: e,
              scaffoldKey: key,
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
            ))
        .toList();
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
      Future.delayed(
          const Duration(milliseconds: 500),
          () => showModalBottomSheet(
              backgroundColor: Colors.white,
              context: context,
              isScrollControlled: true,
              builder: (context) => Wrap(
                    children: [
                      BottomTipPopUp(
                        title: 'Tips for You',
                        message:
                            "You can find a quiet place before we start. We can't wait to hear your valuable insights!",
                        image: 'assets/images/living_room.png',
                        dontShowAgain: !show,
                      ),
                    ],
                  )));
    }
  }
}

/// This class is the page that is being duplicated in the PageView
/// It has two parameters:
/// onNextPage: a function that is called when the user clicks on the continue button
/// question: the question that is being asked in the diary
class QuestionPage extends StatefulWidget {
  final Diary diary;
  final Prompt prompt;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ValueChanged<bool> answerAdded;
  final int currentPage;
  final VoidCallback nextPage;
  final VoidCallback previousPage;
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
    this.isLastPage,
  });

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  late PromptCubit promptCubit;
  late Prompt prompt;

  bool isChecked = false;
  bool disabled = false;

  void updateSliderValue(double value) {
    save(prompt, value.toString());
    widget.answerAdded(true);
  }

  bool isClicked = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    prompt = widget.prompt;
    disabled = widget.diary.status == DiaryStatus.submitted ||
        widget.diary.status == DiaryStatus.missed;
    promptCubit = BlocProvider.of<PromptCubit>(context);
    loadPrompt(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child:
            BlocConsumer<PromptCubit, PromptState>(builder: (context, state) {
          if (state is PromptInitial) {
            return buildInitial();
          } else if (state is PromptLoading) {
            return buildLoading();
          } else if (state is PromptLoaded) {
            return buildPrompt(state.prompt);
          } else {
            return buildInitial();
          }
        }, listener: (context, state) {
          if (state is PromptRespondState) {
            recordResponse(context);
          } else if (state is PromptResponseSuccess) {
            showSuccessModal();
          } else if (state is PromptResponseError) {
            showErrorModal();
          } else if (state is PromptLoaded) {
            if (state.prompt.answer?.recordings != null ||
                state.prompt.answer?.response != null) {
              widget.answerAdded(true);
            } else {
              if (widget.diary.status != DiaryStatus.submitted &&
                  widget.diary.status != DiaryStatus.missed) {
                widget.answerAdded(false);
              } else {
                widget.answerAdded(true);
              }
            }
          }
        }));
  }

  Widget buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: CustomColors.productNormalActive,
      ),
    );
  }

  Widget buildInitial() {
    return Container();
  }

  bool isSnackBarVisible = false;

  Widget buildPrompt(Prompt prompt) {
    Widget responseWidget;

    if (prompt.responseType == ResponseType.slider) {
      List<Option> choices = prompt.option!.choices!;
      int scaleMinValue = int.parse(choices[0].option!);
      int scaleMaxValue = int.parse(choices[1].option!);

      responseWidget = SliderQuestionCard(
        value: prompt.answer?.response != null
            ? double.parse(prompt.answer!.response!)
            : null,
        scaleMin: scaleMinValue,
        scaleMax: scaleMaxValue,
        scaleMinText: prompt.option!.startText,
        scaleMaxText: prompt.option!.endText,
        onSliderValueChanged: updateSliderValue,
        isSliderEnabled: !disabled,
      );
    } else if (prompt.responseType == ResponseType.multiple) {
      final selected = prompt.answer?.response != null
          ? prompt.answer?.response!.split("/ ")
          : <String>[];

      responseWidget = MultipleQuestion(
        options:
            prompt.option!.choices!.map((choice) => choice.option!).toList(),
        selected: selected,
        onChanged: (value) {
          final response = value.join("/ ");
          save(prompt, response);

          if (value.isNotEmpty) {
            widget.answerAdded(true);
          } else {
            widget.answerAdded(false);
          }
        },
        disabled: disabled,
      );
    } else if (prompt.responseType == ResponseType.radio) {
      final selected = prompt.answer?.response;
      responseWidget = RadioQuestion(
        value: selected,
        options:
            prompt.option!.choices!.map((choice) => choice.option!).toList(),
        onChanged: (value) {
          save(prompt, value);
          if (value != null) {
            widget.answerAdded(true);
          } else {
            widget.answerAdded(false);
          }
        },
        disabled: disabled,
      );
    } else {
      responseWidget = widget.diary.status == DiaryStatus.submitted ||
              widget.diary.status == DiaryStatus.missed
          ? const SizedBox.shrink()
          : CustomRecordButton(
              onClick: () => recordResponse(context),
              text: prompt.answer != null
                  ? "ADD NEW RESPONSE"
                  : "RECORD MY RESPONSE",
            );
    }

    return SingleChildScrollView(
      controller: _scrollController,
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
              GestureDetector(
                onTap: () => {
                  if (prompt.note != null)
                    {
                      setState(() {
                        isClicked = !isClicked;
                      })
                    }
                  else
                    {
                      if (!isSnackBarVisible)
                        {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("No tips available for this question."),
                              duration: Duration(seconds: 3),
                              backgroundColor: CustomColors.productNormalActive,
                            ),
                          ),
                          if (mounted)
                            {
                              setState(() {
                                isSnackBarVisible = true;
                              }),
                            }
                        },
                      Future.delayed(
                        const Duration(seconds: 4),
                        () => {
                          if (mounted)
                            {
                              setState(() {
                                isSnackBarVisible = false;
                              })
                            }
                        },
                      )
                    }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: CustomColors.productBorderNormal,
                      width: 2,
                    ),
                    color: CustomColors.fillNormal,
                  ),
                  child: Row(children: [
                    Icon(
                      Icons.description_outlined,
                      color: !isClicked && prompt.note != null
                          ? CustomColors.productNormalActive
                          : Colors.black,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Tips",
                      style: CustomTypography().bodyLarge(
                          color: !isClicked && prompt.note != null
                              ? CustomColors.productNormalActive
                              : Colors.black),
                    )
                  ]),
                ),
              )
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
          if (!isClicked)
            prompt.note != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: ResearchersNote(
                      note: prompt.note,
                      onDismissed: (value) => setState(() {
                        isClicked = value;
                      }),
                    ),
                  )
                : const SizedBox.shrink(),
          const SizedBox(height: 112),
          prompt.answer?.recordings.isNotEmpty ?? false
              ? MyResponse(
                  prompt: prompt,
                  status: widget.diary.status,
                  recordings: prompt.answer!.recordings)
              : const SizedBox.shrink(),
          responseWidget,
          if (widget.diary.status != DiaryStatus.submitted &&
              widget.diary.status != DiaryStatus.missed &&
              prompt.responseType == ResponseType.recording)
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          // const CustomTextButton(
          //     onClick: null, text: "I DON'T WANT TO ANSWER THIS QUESTION"),
        ],
      ),
    );
  }

  void loadPrompt(BuildContext context) {
    promptCubit.loadPrompt(prompt);
  }

  void recordResponse(BuildContext context) {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: true,
        elevation: 0,
        builder: (context) => BottomRecordingModal(
              promptId: prompt.id,
              onSave: (value) {
                save(prompt, value.toString());
              },
            ));
  }

  void save(Prompt prompt, dynamic response) {
    // Change diary status
    if (widget.diary.status == DiaryStatus.idle) {
      widget.diary.status = DiaryStatus.ongoing;
      DiaryRepository repository = DiaryRepository();
      repository.updateDiary(widget.diary);
    }
    promptCubit.saveResponse(prompt, response);

    if (!isClicked) {
      setState(() {
        isClicked = true;
      });
    }
  }

  void showSuccessModal() {
    bool isLast = widget.isLastPage ?? true;

    widget.scaffoldKey.currentState!.showBottomSheet((context) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      return BottomSuccessModal(
        previousPage: () => widget.previousPage(),
        onNextQuestionClicked: widget.nextPage,
        text: isLast ? "REVIEW SUMMARY" : "NEXT QUESTION",
      );
    });
  }

  void showErrorModal() {
    widget.scaffoldKey.currentState!
        .showBottomSheet((context) => const BottomErrorModal());
  }
}
