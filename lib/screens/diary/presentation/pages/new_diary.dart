import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/statuses.dart';
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
import '../widgets/custom_app_bar.dart';
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

  @override
  void initState() {
    controller = PageController();
    controllerInit();
    super.initState();
  }

  void nextPage() {
    if (currentPage < widget.diary.prompts.length - 1) {
      controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // Change dairy status to complete
      if (widget.diary.status == DiaryStatus.submitted) {
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
        appBar: const CustomAppBar(),
        body: Column(
          children: [
            CustomBarIndicator(
              pageCount: 2,
              currentPage: currentPage,
            ),
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: controller,
                children: pages(),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 34),
              alignment: Alignment.bottomCenter,
              child: CustomFlatButton(
                isDisabled: !ableToContinue,
                onClick: () => nextPage(),
                text: "CONTINUE",
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
  const QuestionPage(
      {super.key,
      required this.diary,
      required this.prompt,
      required this.scaffoldKey,
      required this.answerAdded});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  late PromptCubit promptCubit;
  late Prompt prompt;

  bool isClicked = false;

  @override
  void initState() {
    prompt = widget.prompt;
    promptCubit = BlocProvider.of<PromptCubit>(context);
    loadPrompt(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
            if (state.prompt.answer?.recordings.isNotEmpty ?? false) {
              widget.answerAdded(true);
            } else {
              if (widget.diary.status != DiaryStatus.submitted) {
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

  Widget buildPrompt(Prompt prompt) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: prompt.question,
                    style: CustomTypography()
                        .titleLarge(color: CustomColors.textNormalContent),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              isClicked = !isClicked;
                            });
                          },
                          icon: Icon(isClicked
                              ? CustomIcons.note
                              : CustomIcons.note_1),
                          color: CustomColors.productNormal,
                          iconSize: 22.0,
                          padding: const EdgeInsets.all(0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!isClicked)
            ResearchersNote(
              onDismissed: (value) => setState(() {
                isClicked = value;
              }),
            ),
          const SizedBox(height: 24),
          prompt.answer?.recordings.isNotEmpty ?? false
              ? MyResponse(
                  prompt: prompt,
                  status: widget.diary.status,
                  recordings: prompt.answer!.recordings)
              : const SizedBox.shrink(),
          widget.diary.status == DiaryStatus.submitted
              ? const SizedBox.shrink()
              : CustomRecordButton(
                  onClick: () => recordResponse(context),
                  text: prompt.answer != null
                      ? "ADD NEW RESPONSE"
                      : "RECORD RESPONSE"),
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
        // isDismissible: false,
        // enableDrag: false,
        builder: (context) => BottomRecordingModal(
              promptId: prompt.id,
              onSave: (value) {
                // Change diary status
                widget.diary.status = DiaryStatus.ongoing;
                DiaryRepository repository = DiaryRepository();
                repository.updateDiary(widget.diary);

                promptCubit.saveResponse(prompt, value.toString());
              },
            ));
  }

  void showSuccessModal() {
    widget.scaffoldKey.currentState!
        .showBottomSheet((context) => const BottomSuccessModal());
  }

  void showErrorModal() {
    widget.scaffoldKey.currentState!
        .showBottomSheet((context) => const BottomErrorModal());
  }
}
