import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/prompt/prompt_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/question_widgets.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:audio_diaries_flutter/theme/dialogs/bottom_modals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditDiaryPage extends StatefulWidget {
  final DiaryModel diary;
  final PromptModel prompt;
  final int index;
  const EditDiaryPage(
      {super.key,
      required this.diary,
      required this.prompt,
      required this.index});

  @override
  State<EditDiaryPage> createState() => _EditDiaryPageState();
}

class _EditDiaryPageState extends State<EditDiaryPage> {
  late PromptCubit promptCubit;

  bool proceed = true;

  // Functions to run before moving to the next page
  List<Function> preFunctions = [];

  @override
  void initState() {
    promptCubit = BlocProvider.of<PromptCubit>(context);
    loadPrompt();
    super.initState();
  }

  void loadPrompt() {
    promptCubit.loadPrompt(widget.diary, widget.prompt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.fillNormal,
      appBar: AppBar(
        backgroundColor: CustomColors.fillNormal,
        leading: IconButton(
            onPressed: () =>
                proceed ? Navigator.pop(context) : showSnackError(),
            icon: Icon(Icons.close_rounded)),
        centerTitle: true,
        title: Text('Edit Response',
            style: CustomTypography()
                .headlineMedium(color: CustomColors.textNormalContent)),
      ),
      body: BlocConsumer<PromptCubit, PromptState>(
          buildWhen: (previous, current) =>
              current is PromptLoaded || current is PromptInitial,
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
            if (state is PromptLoaded) {
              canUserProceed(state.prompt);
            }
          }),
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

  void canUserProceed(PromptModel prompt) {
    bool isValidResponse = false;
    final answer = prompt.answer;

    if (!prompt.required) {
      setState(() => proceed = true);
      return;
    }

    switch (prompt.responseType) {
      case ResponseType.instruction:
        isValidResponse = true;
        break;
      case ResponseType.audio:
      case ResponseType.textAudio:
      case ResponseType.image:
      case ResponseType.video:
      case ResponseType.imageVideo:
        if (prompt.responseType == ResponseType.textAudio) {
          isValidResponse = (answer?.recordings.isNotEmpty ?? false) ||
              (answer?.response != null && answer!.response!.isNotEmpty);
        } else {
          isValidResponse = answer?.recordings.isNotEmpty ?? false;
        }
        break;
      default:
        isValidResponse = answer?.response?.isNotEmpty ?? false;
    }

    setState(() => proceed = isValidResponse);
  }

  Widget buildPrompt(PromptModel prompt) {
    return Column(
      children: [
        Expanded(
            child: Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                            "Question ${widget.index}/${widget.diary.prompts.length}",
                            style: CustomTypography().custom(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          )),
                    ],
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          prompt.question,
                          style: CustomTypography().titleLarge(),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          prompt.subtitle ?? "",
                          style: const TextStyle(
                              color: CustomColors.textTertiaryContent),
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 36.0),
                    child: getResponseWidget(prompt),
                  )

                  // const CustomTextButton(
                  //     onClick: null, text: "I DON'T WANT TO ANSWER THIS QUESTION"),
                ],
              ),
            ),
          ),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          child: CustomFlatButton(
            isDisabled: !proceed,
            onClick: () => back(),
            text: "Back To Summary",
          ),
        )
      ],
    );
  }

  Widget getResponseWidget(PromptModel prompt) {
    switch (prompt.responseType) {
      case ResponseType.image:
      case ResponseType.video:
      case ResponseType.imageVideo:
        return VisualResponseWidget(
            diary: widget.diary,
            prompt: prompt,
            respond: (answer, [type]) =>
                save(prompt, answer, type ?? 'image', null));
      case ResponseType.multiple:
        final selected = prompt.answer?.response != null
            ? prompt.answer?.response!.first.split("/ ")
            : <String>[];

        return MultipleQuestion(
          options: prompt.option!.choices!,
          selected: selected,
          onChanged: (value) {
            final response = value.join("/ ");
            save(prompt, response, 'other', 0);
          },
          disabled: false,
        );
      case ResponseType.radio:
        final selected = prompt.answer?.response?.first;
        return RadioQuestion(
          value: selected,
          options: prompt.option!.choices!,
          onChanged: (value) {
            save(prompt, value, 'other', 0);
          },
          disabled: false,
        );
      case ResponseType.text:
        return FreeTextQuestionCard(
          diary: widget.diary,
          respond: (String type, index) =>
              recordResponse(prompt, type, index: index),
          prompt: prompt,
        );
      case ResponseType.textAudio:
      case ResponseType.audio:
        return AudioTextCard(
          diary: widget.diary,
          respond: (String type, index) =>
              recordResponse(prompt, type, index: index),
          prompt: prompt,
        );
      case ResponseType.slider:
        return SliderQuestionCard(
          value: prompt.answer?.response != null
              ? double.parse(prompt.answer!.response!.first)
              : prompt.option!.defaultValue!.toDouble(),
          scaleMin: prompt.option!.minValue!,
          scaleMax: prompt.option!.maxValue!,
          scaleMinText: prompt.option!.minLabel,
          scaleMaxText: prompt.option!.maxLabel,
          onSliderValueChanged: (value) => save(prompt, value, 'other', 0),
          isSliderEnabled: true,
        );
      case ResponseType.webview:
        return WebViewResponseCard(
            prompt: prompt,
            diary: widget.diary,
            respond: (answer) => save(prompt, answer, 'other', 0));
      case ResponseType.timer:
        return TimerWidget(
          time: prompt.option?.timerLength ?? Duration(seconds: 30),
          userInteraction: prompt.option?.userInteraction ?? false,
          playbackControls: prompt.option?.playbackControl ?? false,
          respond: (answer) => save(prompt, answer, 'other', 0),
          addToPreFunction: (p0) => preFunctions.add(p0),
        );
      case ResponseType.timePicker:
        return TimePickerWidget(
            prompt: prompt,
            respond: (answer) => save(prompt, answer, "other", 0));
      default:
        return const SizedBox.shrink();
    }
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
  }

  void recordResponse(PromptModel prompt, String type, {int? index}) {
    if (type == "audio") {
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

  void back() {
    for (var function in preFunctions) {
      function();
    }

    Navigator.pop(context, true);
  }

  void showSnackError() {
    final snackBar = SnackBar(
      content: Row(
        spacing: 4,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: CustomColors.warningActive,
          ),
          Text(
            "Answer missing. Please answer the question",
            style: CustomTypography().bodyMedium(
                color: CustomColors.warningActive, weight: FontWeight.w600),
          ),
        ],
      ),
      backgroundColor: CustomColors.warningFill,
      duration: const Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
