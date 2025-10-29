import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/volume_settings.dart';
import 'package:audio_diaries_flutter/core/usecases/video_image_thumbnail.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/recording.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/prompt/prompt_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/time_picker.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/dialogs/bottom_modals.dart';
import 'package:audio_diaries_flutter/theme/dialogs/pop_ups.dart';
import 'package:audio_diaries_flutter/theme/overlays/keyboard_overlay.dart';
import 'package:audio_diaries_flutter/theme/resources/strings.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import '../../../../theme/components/time_picker.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import 'my_responses.dart';

///These widgets are being used in the QuestionPage class
///They are used to display tbe answer options for each question
///whether slider option, multiple questions or radio questions

class SliderQuestionCard extends StatefulWidget {
  final double? value;
  final String? scaleMinText;
  final String? scaleMaxText;
  final int scaleMin;
  final int scaleMax;
  final bool isSliderEnabled;
  final ValueChanged<double>? onSliderValueChanged;
  const SliderQuestionCard(
      {super.key,
      required this.value,
      required this.scaleMinText,
      required this.scaleMaxText,
      this.onSliderValueChanged,
      required this.scaleMin,
      required this.scaleMax,
      required this.isSliderEnabled});

  @override
  State<SliderQuestionCard> createState() => _SliderQuestionCardState();
}

class _SliderQuestionCardState extends State<SliderQuestionCard> {
  double _value = 0;

  @override
  void initState() {
    _value = widget.value ?? 0;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant SliderQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _value) {
      setState(() {
        _value = widget.value ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(5.0, 60.0, 5.0, 16.0),
      decoration: BoxDecoration(
          color: CustomColors.productLightPrimaryNormalWhite,
          borderRadius: BorderRadius.circular(14.0)),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.scaleMin.toString(),
              style: CustomTypography().button(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: SliderTheme(
                  data: SliderThemeData(
                      thumbColor: widget.value != null
                          ? CustomColors.productNormal
                          : CustomColors.fillDisabled,
                      activeTrackColor: widget.value != null
                          ? CustomColors.productNormal
                          : CustomColors.fillDisabled,
                      inactiveTrackColor: CustomColors.fillDisabled,
                      activeTickMarkColor: CustomColors.productNormal,
                      inactiveTickMarkColor:
                          CustomColors.textNormalContent.withOpacity(0.35),
                      overlayShape: SliderComponentShape.noOverlay,
                      valueIndicatorColor: CustomColors.productNormal,
                      trackHeight: 4,
                      valueIndicatorTextStyle: CustomTypography()
                          .bodyLarge(color: CustomColors.textWhite)),
                  child: Slider(
                    value: _value,
                    min: widget.scaleMin.toDouble(),
                    max: widget.scaleMax.toDouble(),
                    divisions: widget.scaleMax - widget.scaleMin,
                    label: _value.round().toString(),
                    onChangeEnd: widget.isSliderEnabled
                        ? (double value) {
                            if (widget.onSliderValueChanged != null) {
                              widget.onSliderValueChanged!(value);
                            }
                          }
                        : null,
                    onChanged: widget.isSliderEnabled
                        ? (val) {
                            setState(() {
                              _value = val;
                            });
                          }
                        : null,
                    //overlayColor:CustomColors.newBlue,
                  ),
                ),
              ),
            ),
            Text(
              widget.scaleMax.toString(),
              style: CustomTypography().button(),
            ),
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 87,
              child: Text(
                widget.scaleMinText!,
                textAlign: TextAlign.start,
                style: CustomTypography().bodyLarge(),
              ),
            ),
            SizedBox(
              width: 87,
              child: Text(
                widget.scaleMaxText!,
                textAlign: TextAlign.end,
                style: CustomTypography().bodyLarge(),
              ),
            ),
          ],
        )
      ]),
    );
  }
}

class MultipleQuestion extends StatefulWidget {
  final List<String> options;
  final List<String>? selected;
  final ValueChanged<List<String>>? onChanged;
  final bool disabled;

  const MultipleQuestion(
      {super.key,
      required this.options,
      required this.selected,
      required this.onChanged,
      this.disabled = false});

  @override
  State<MultipleQuestion> createState() => _MultipleQuestionState();
}

class _MultipleQuestionState extends State<MultipleQuestion> {
  late List<String> selectedOptions;

  @override
  void initState() {
    selectedOptions = widget.selected ?? [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.options.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
              decoration: BoxDecoration(
                  color: selectedOptions.contains(widget.options[index]) &&
                          !widget.disabled
                      ? CustomColors.productLightBackground
                      : CustomColors.productLightPrimaryNormalWhite,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                      color: selectedOptions.contains(widget.options[index]) &&
                              !widget.disabled
                          ? CustomColors.productBorderActive
                          : CustomColors.productBorderNormal,
                      width: 2)),
              child: CheckboxListTile(
                title: Text(
                  widget.options[index],
                  style: CustomTypography().button(
                      color: selectedOptions.contains(widget.options[index]) &&
                              !widget.disabled
                          ? CustomColors.productNormalActive
                          : Colors.black),
                ),
                checkColor: CustomColors.productLightPrimaryNormalWhite,
                fillColor: selectedOptions.contains(widget.options[index]) &&
                        !widget.disabled
                    ? WidgetStateProperty.all(CustomColors.productNormalActive)
                    : selectedOptions.contains(widget.options[index])
                        ? WidgetStateProperty.all(
                            CustomColors.textTertiaryContent)
                        : null,
                controlAffinity: ListTileControlAffinity.leading,
                value: selectedOptions.contains(widget.options[index]),
                onChanged: (value) {
                  if (!widget.disabled) {
                    if (value!) {
                      selectedOptions.add(widget.options[index]);
                    } else {
                      selectedOptions.remove(widget.options[index]);
                    }

                    setState(() {
                      widget.onChanged!(selectedOptions);
                    });
                  }
                },
              )),
          const SizedBox(
            height: 12,
          ),
        ]);
      },
    );
  }
}

class RadioQuestion extends StatefulWidget {
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool disabled;

  const RadioQuestion(
      {super.key,
      required this.value,
      required this.options,
      required this.onChanged,
      this.disabled = false});

  @override
  State<RadioQuestion> createState() => _RadioQuestionState();
}

class _RadioQuestionState extends State<RadioQuestion> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.options.length,
      itemBuilder: (context, index) {
        return Column(children: [
          Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 3.0),
              decoration: BoxDecoration(
                  color:
                      widget.options[index] == widget.value && !widget.disabled
                          ? CustomColors.productLightBackground
                          : CustomColors.productLightPrimaryNormalWhite,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                      color: widget.options[index] == widget.value &&
                              !widget.disabled
                          ? CustomColors.productNormalActive
                          : CustomColors.productBorderNormal,
                      width: 2)),
              child: RadioListTile<String>(
                title: Text(
                  widget.options[index],
                  style: CustomTypography().button(
                      color: !widget.disabled
                          ? widget.options[index] == widget.value
                              ? CustomColors.productNormalActive
                              : Colors.black
                          : CustomColors.textTertiaryContent),
                ),
                fillColor: WidgetStateProperty.all(!widget.disabled
                    ? widget.options[index] == widget.value
                        ? CustomColors.productNormalActive
                        : Colors.black
                    : CustomColors.textTertiaryContent),
                controlAffinity: ListTileControlAffinity.leading,
                value: widget.options[index],
                groupValue: widget.value,
                onChanged: (String? value) {
                  if (!widget.disabled) {
                    widget.onChanged(value);
                  }
                },
              )),
          const SizedBox(
            height: 12,
          ),
        ]);
      },
    );
  }
}

class AudioTextCard extends StatefulWidget {
  final void Function(String, int?) respond;
  final DiaryModel diary;
  final PromptModel prompt;
  const AudioTextCard({
    super.key,
    required this.respond,
    required this.diary,
    required this.prompt,
  });

  @override
  State<AudioTextCard> createState() => _AudioTextCardState();
}

class _AudioTextCardState extends State<AudioTextCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              controls(),
              const SizedBox(height: 12),
              (widget.prompt.answer != null &&
                      (widget.prompt.answer!.recordings.isNotEmpty ||
                          (widget.prompt.answer!.response != null &&
                              widget.prompt.answer!.response!.isNotEmpty)))
                  ? MyResponse(
                      diary: widget.diary,
                      edit: widget.respond,
                      prompt: widget.prompt,
                      recordings: widget.prompt.answer?.recordings ?? [])
                  : const SizedBox.shrink()
            ],
          ),
        ));
  }

  Widget controls() {
    final multipleAnswers = widget.prompt.option?.multipleAnswers ?? false;
    final length = widget.prompt.answer?.recordings.length ?? 0;
    final textPresent = widget.prompt.answer?.response != null &&
        widget.prompt.answer!.response!.isNotEmpty;
    return !multipleAnswers && (length > 0 || textPresent)
        ? const SizedBox.shrink()
        : Column(
            spacing: 24,
            children: [
              CustomRecordButton(
                onClick: () => widget.respond("audio", null),
                text:
                    length > 0 ? "Record Another Answer" : "Record My Response",
              ),
              widget.prompt.responseType == ResponseType.textAudio
                  ? Column(
                      spacing: 24,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                  width: 65,
                                  child: Divider(
                                    color: Color(0xFFB0B0B0),
                                    thickness: 1,
                                  )),
                              SizedBox(width: 24),
                              Text(
                                "OR",
                                style: CustomTypography().bodyLarge(
                                    weight: FontWeight.w500,
                                    color: Color(0xFFB0B0B0)),
                              ),
                              SizedBox(
                                width: 24,
                              ),
                              SizedBox(
                                  width: 65,
                                  child: Divider(
                                    color: Color(0xFFB0B0B0),
                                    thickness: 1,
                                  )),
                            ]),
                        CustomTextAnswerButton(
                          onClick: () => widget.respond("text", null),
                          text: textPresent
                              ? "Type Another Answer"
                              : "Text My Response",
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ],
          );
  }
}

// radio question summary
class RadioQuestionSummary extends StatefulWidget {
  final String? selectedOption;
  const RadioQuestionSummary({super.key, required this.selectedOption});

  @override
  State<RadioQuestionSummary> createState() => _RadioQuestionSummaryState();
}

class _RadioQuestionSummaryState extends State<RadioQuestionSummary> {
  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      title: Text(
        widget.selectedOption ?? "",
        style: CustomTypography()
            .bodyLarge(color: CustomColors.textSecondaryContent),
      ),
      fillColor: WidgetStateProperty.all(CustomColors.textSecondaryContent),
      controlAffinity: ListTileControlAffinity.leading,
      value: widget.selectedOption ?? "",
      groupValue: widget.selectedOption,
      onChanged: (String? value) {},
    );
    // },
    // );
  }
}

// multiple question summary
class MultipleQuestionSummary extends StatefulWidget {
  final List<String> answers;
  const MultipleQuestionSummary({super.key, required this.answers});

  @override
  State<MultipleQuestionSummary> createState() =>
      _MultipleQuestionSummaryState();
}

class _MultipleQuestionSummaryState extends State<MultipleQuestionSummary> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.answers.length,
      itemBuilder: (context, index) {
        return CheckboxListTile(
          title: Text(
            widget.answers[index],
            style: CustomTypography()
                .bodyLarge(color: CustomColors.textSecondaryContent),
          ),
          fillColor: WidgetStateProperty.all(CustomColors.textSecondaryContent),
          checkColor: CustomColors.productLightPrimaryNormalWhite,
          controlAffinity: ListTileControlAffinity.leading,
          value: true,
          onChanged: (bool? value) {},
        );
      },
    );
  }
}

class TextQuestionCard extends StatefulWidget {
  const TextQuestionCard({super.key});

  @override
  State<TextQuestionCard> createState() => _TextQuestionCardState();
}

//Free response text question card
class _TextQuestionCardState extends State<TextQuestionCard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0)),
        TextField(
          decoration: InputDecoration(
            hintText: 'Type your message',
            hintStyle: CustomTypography()
                .button(color: CustomColors.textTertiaryContent),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: CustomColors.productBorderNormal),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: CustomColors.productBorderNormal),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: CustomColors.productBorderActive),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
          maxLines: null,
        )
      ],
    );
  }
}

class FreeTextQuestionCard extends StatefulWidget {
  final void Function(String, int?) respond;
  final DiaryModel diary;
  final PromptModel prompt;
  const FreeTextQuestionCard(
      {super.key,
      required this.respond,
      required this.diary,
      required this.prompt});

  @override
  State<FreeTextQuestionCard> createState() => _FreeTextQuestionCardState();
}

class _FreeTextQuestionCardState extends State<FreeTextQuestionCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            controls(),
            (widget.prompt.answer?.response?.isNotEmpty ?? false)
                ? MyResponse(
                    diary: widget.diary,
                    edit: widget.respond,
                    prompt: widget.prompt,
                    recordings: [])
                : const SizedBox.shrink()
          ],
        ));
  }

  Widget controls() {
    final multipleAnswers = widget.prompt.option?.multipleAnswers ?? false;
    final textPresent = widget.prompt.answer?.response != null &&
        widget.prompt.answer!.response!.isNotEmpty;
    return !multipleAnswers && textPresent
        ? const SizedBox.shrink()
        : CustomTextAnswerButton(
            onClick: () => widget.respond("text", null),
            text: textPresent ? "Type Another Answer" : "Type My Answer",
          );
  }
}

//Free response text question summary

class FreeTextQuestionSummary extends StatefulWidget {
  final String answer;
  const FreeTextQuestionSummary({super.key, required this.answer});

  @override
  State<FreeTextQuestionSummary> createState() =>
      _FreeTextQuestionSummaryState();
}

class _FreeTextQuestionSummaryState extends State<FreeTextQuestionSummary> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(color: CustomColors.greyDark),
            borderRadius: BorderRadius.circular(16.0),
            color: CustomColors.productLightPrimaryNormalWhite,
            boxShadow: const [
              BoxShadow(
                  color: CustomColors.greyDark,
                  blurRadius: .5,
                  spreadRadius: .5,
                  offset: Offset(0, 1))
            ]),
        child: ListTile(
          title: Text(
            widget.answer,
            style: CustomTypography()
                .bodyLarge(color: CustomColors.textSecondaryContent),
          ),
        ),
      ),
    );
  }
}

class WebViewResponseCard extends StatefulWidget {
  final DiaryModel diary;
  final PromptModel prompt;
  final void Function(String) respond;
  const WebViewResponseCard(
      {super.key,
      required this.diary,
      required this.prompt,
      required this.respond});

  @override
  State<WebViewResponseCard> createState() => _WebViewResponseCardState();
}

class _WebViewResponseCardState extends State<WebViewResponseCard> {

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              widget.prompt.answer?.response?.isEmpty ?? true
                  ? CustomFlatButton(
                onClick: () => showModal(),
                text: "Tap here to respond",
              )
                  : Text(
                "✅ Thank you, please click 'Continue' to proceed.",
                style: CustomTypography()
                    .bodyLarge(color: CustomColors.textTertiaryContent),
              ),
          ],
        ));
  }

  void showModal() {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        elevation: 0,
        useSafeArea: true,
        routeSettings: RouteSettings(name: "/WebViewModal"),
        builder: (context) => DraggableScrollableSheet(
              initialChildSize: 1,
              minChildSize: 1,
              snap: true,
              builder: (context, scrollController) {
                return BottomWebViewModal(
                  url: widget.prompt.option!.link!,
                  respond: widget.respond,
                );
              },
            ));
  }
}

class TimerWidget extends StatefulWidget {
  final Duration time;
  final bool playbackControls;
  final bool userInteraction;
  final void Function(String) respond;
  final Function(Function) addToPreFunction;

  const TimerWidget({
    super.key,
    required this.time,
    required this.playbackControls,
    required this.userInteraction,
    required this.respond,
    required this.addToPreFunction,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late Duration duration;
  late Duration remaining;
  Timer? _timer;

  bool inProgress = false;
  bool paused = false;
  bool complete = false;
  bool showTimeUpOverlay = false;
  bool showCompletionText = false;

  AudioPlayer? player;
  late AnimationController _shakeController;

  late TextEditingController minuteController;
  late TextEditingController secondsController;
  int pickerMinutes = 1;
  int pickerSeconds = 0;

  bool showPersistentSheet = false;
  void Function()? _updateModalCallback;
  int? currentAlarmId;
  // Track when the current countdown should complete (wall-clock). Used to detect completion when app is backgrounded
  DateTime? _expectedEndTime;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    duration = widget.time;
    remaining = widget.time;
    pickerMinutes = duration.inMinutes;
    pickerSeconds = duration.inSeconds.remainder(60);

    minuteController =
        TextEditingController(text: formatDurationMMOnly(duration));
    secondsController =
        TextEditingController(text: formatDurationSSOnly(duration));

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

// Observe lifecycle to detect if timer elapsed while in background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      if (_expectedEndTime != null &&
          DateTime.now().isAfter(_expectedEndTime!)) {
        setState(() {
          _timer?.cancel();
          inProgress = false;
          paused = false;
          complete = true;
          showTimeUpOverlay = false;
          showCompletionText = true;
          showPersistentSheet = false;
          remaining = Duration.zero;
          _expectedEndTime = null;
        });
        stopAlarm();
        widget.respond("Complete");
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    player?.dispose();
    _shakeController.dispose();
    stopAlarm();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (remaining.inSeconds > 0 && inProgress && !paused) {
          remaining -= const Duration(seconds: 1);
          // Update expected end time on first tick after start/resume
          _expectedEndTime ??= DateTime.now().add(remaining);
          _refreshModal();
        } else if (remaining.inSeconds <= 0) {
          _timer?.cancel();
          _onTimerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() => paused = true);
    stopAlarm();
    _timer?.cancel();
  }

  void _resumeTimer() {
    setState(() => paused = false);
    // Set alarm for remaining time when resuming
    setAlarm(remaining);
    _expectedEndTime = DateTime.now().add(remaining);
    _startTimer();
  }

  void _restartTimer() {
    setState(() {
      remaining = duration;
      inProgress = true;
      paused = false;
      complete = false;
      showTimeUpOverlay = false;
      showCompletionText = false; // Reset completion text visibility
    });

    // Cancel existing timer if any
    _timer?.cancel();

    // Reset and handle audio/alarms
    Future.microtask(() async {
      await stopAlarm();
      _shakeController.reset();
      await _startSound();
      await setAlarm(duration);
      _startTimer();
    });
  }

  void _stopTimer() {
    setState(() {
      inProgress = false;
      paused = false;
      showTimeUpOverlay = false;
    });
    _timer?.cancel();
    stopAlarm();
    _shakeController.reset();
  }

  void _pauseResumeTimer() => paused ? _resumeTimer() : _pauseTimer();

  void _playBlack() => widget.playbackControls ? _pauseResumeTimer() : null;

  void _onTimerComplete() {
    setState(() {
      inProgress = false;
      complete = true;
      showTimeUpOverlay = true;
      showCompletionText = false; // Don't show completion text immediately
    });
    _shakeController.forward().then((_) => _shakeController.repeat());
    widget.respond("timer");
    _refreshModal();

    // Delay showing the completion text until after modal animations are done
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && complete) {
        setState(() {
          showCompletionText = true;
        });
      }
    });
  }

  void _onTimerClose() {
    setState(() {
      inProgress = false;
      paused = false;
      complete = false;
      showTimeUpOverlay = false;
      showPersistentSheet = false;
      showCompletionText = false;
      _expectedEndTime = null;
    });
    _shakeController.reset();
    stopAlarm();
  }

  Future<void> _startAndShowModal({bool startPaused = false}) async {
    if (!await _seekPermission()) return;

    setState(() {
      inProgress = true;
      paused = startPaused;
      complete = false;
      remaining = duration;
      showTimeUpOverlay = false;
      showPersistentSheet = true;
      showCompletionText = false; // Reset completion text visibility
    });

    if (!startPaused) {
      await _startSound();
      await setAlarm(duration);
    }

    _startSound();
    _startTimer();
    _expectedEndTime = DateTime.now().add(remaining);

    if (!mounted) return;
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      elevation: 0,
      useSafeArea: true,
      routeSettings: RouteSettings(name: "/TimerModal"),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 1,
        minChildSize: 1,
        snap: true,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              // Capture a callback to refresh the modal with latest parent state
              _updateModalCallback = () {
                if (mounted) setModalState(() {});
              };
              return BottomTimerModal(
                  remaining: remaining,
                  isRunning: inProgress && !paused,
                  isPaused: paused,
                  showTimeUpOverlay: showTimeUpOverlay,
                  playbackControls: widget.playbackControls,
                  onClose: () {
                    Navigator.of(context).pop();
                    _onTimerClose();
                  },
                  onRestart: () {
                    if (widget.playbackControls) _restartTimer();
                    _refreshModal();
                  },
                  onPauseResume: () {
                    _playBlack();
                    _refreshModal();
                  },
                  onStop: () {
                    _stopTimer();
                    stopAlarm();
                    Navigator.of(context).pop();
                    if (mounted) {
                      setState(() {
                        inProgress = false;
                        paused = false;
                        complete = true;
                        showTimeUpOverlay = false;
                        showCompletionText = true;
                        showPersistentSheet = false;
                        _expectedEndTime = null;
                      });
                    }
                    widget.respond("Complete");
                  });
            },
          );
        },
      ),
    );
  }

  void _refreshModal() {
    if (showPersistentSheet && _updateModalCallback != null) {
      _updateModalCallback?.call();
    }
  }

  void _showMinuteSecondPicker() async {
    final result = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => CustomMinuteSecondPicker(duration: duration),
    );

    if (result != null && mounted) {
      _updateDuration(result);

      // If timer is running, update it with new duration
      if (inProgress && mounted) {
        remaining = result;
        stopAlarm(); // Stop current alarm

        if (!paused) {
          // If running, set new alarm immediately
          stopAlarm();
          setAlarm(remaining);
        }
        // If paused, alarm will be set when resumed
      } else {
        remaining = result;
      }
    }
  }

  void _updateDuration(Duration newDuration) {
    if (!mounted) return;

    setState(() {
      duration = newDuration;
      pickerMinutes = newDuration.inMinutes;
      pickerSeconds = newDuration.inSeconds.remainder(60);
    });
    // Only refresh modal if it's still active
    if (showPersistentSheet && _updateModalCallback != null) {
      _refreshModal();
    }
  }

  Future<void> stopAlarm() async {
    await Alarm.stopAll();
    if (player != null) {
      await player?.stop();
      final tempPlayer = player;
      player = null; // Set to null first to prevent double disposal
      await tempPlayer?.dispose();
    }
  }

  Future<void> setAlarm(Duration time) async {
    // Stop current alarm first
    await stopAlarm();

    currentAlarmId = Random().nextInt(1000);
    final alarmTime = DateTime.now().add(time);
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: currentAlarmId!,
        dateTime: alarmTime,
        assetAudioPath: 'assets/audio/bowl.wav',
        loopAudio: false,
        vibrate: false,
        volumeSettings: VolumeSettings.staircaseFade(
          fadeSteps: List.generate(
              10, (i) => VolumeFadeStep(Duration(seconds: 3), 0.1 + (i * 0.1))),
          volume: 1.0,
        ),
        warningNotificationOnKill: Platform.isIOS,
        androidFullScreenIntent: false,
        notificationSettings: const NotificationSettings(
          title: "Time's Up!",
          body: "Please come back to Fabla to finish your entry",
          stopButton: "Stop",
        ),
      ),
    );
  }

  Future<void> _startSound() async {
    player?.dispose();
    player = AudioPlayer();
    await player!.play(AssetSource('audio/bowl.wav'), volume: 1.0);
  }

  Future<bool> _seekPermission() async {
    if (Platform.isIOS) return true;
    final status = await Permission.scheduleExactAlarm.status;
    return status.isGranted ||
        (await Permission.scheduleExactAlarm.request()).isGranted;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 36.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    "Time Length",
                    style: CustomTypography().custom(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF383838)),
                    textAlign: TextAlign.start,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildEditableControls(),
                const SizedBox(height: 36),
                if (!complete) ...[_buildStartButton()],
                if (complete && showCompletionText) ...[_buildCompletionView()],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionView() {
    return CustomOutlineButton(
      onClick: () {
        _startAndShowModal();
      },
      backgroundColor: Colors.transparent,
      color: CustomColors.productNormal,
      children: Wrap(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Text(
                "Restart Timer",
                style: CustomTypography()
                    .button(color: CustomColors.productNormal),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: CustomColors.fillWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CustomColors.productBorderNormal, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              "$pickerMinutes min ${pickerSeconds.toString().padLeft(2, '0')} sec",
              style: CustomTypography().titleMedium(
                  color: CustomColors.textNormalContent.withOpacity(0.64)),
            ),
          ),
          IconButton(
            onPressed: widget.userInteraction ? _showMinuteSecondPicker : null,
            icon: widget.userInteraction
                ? const Icon(
                    Icons.edit_outlined,
                    color: CustomColors.productNormal,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton({bool isCompletion = false}) {
    final isDisabled = inProgress || paused;
    return Stack(children: [
      //completetion check here then display either the start timer now button another button
      CustomElevatedButton(
        color: (isDisabled
            ? CustomColors.fillDisabled
            : CustomColors.productNormal),
        onClick: isDisabled
            ? null
            : () {
                if (isCompletion) {
                  _shakeController.reset();
                  stopAlarm();
                  setState(() {
                    inProgress = true;
                    complete = false;
                    remaining = duration;
                  });
                }
                _startAndShowModal();
              },
        text: 'Start Timer',
      ),
    ]);
  }
}

class VisualResponseWidget extends StatefulWidget {
  final void Function(String answer, [String? type]) respond;
  final DiaryModel diary;
  final PromptModel prompt;
  const VisualResponseWidget(
      {super.key,
      required this.diary,
      required this.prompt,
      required this.respond});

  @override
  State<VisualResponseWidget> createState() => _VisualResponseWidgetState();
}

class _VisualResponseWidgetState extends State<VisualResponseWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                widget.prompt.responseType == ResponseType.image ||
                        widget.prompt.responseType == ResponseType.imageVideo
                    ? CustomButton(
                        onClick: () => showModal(isImage: true),
                        children: [
                          Icon(
                            CupertinoIcons.camera_fill,
                            color: CustomColors.fillWhite,
                            size: 24,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            widget.prompt.answer?.recordings.isNotEmpty ?? false
                                ? 'Add Another Picture'
                                : 'Take a Picture',
                            style: CustomTypography()
                                .button(color: CustomColors.textWhite),
                          )
                        ],
                      )
                    : const SizedBox.shrink(),
                widget.prompt.responseType == ResponseType.video ||
                        widget.prompt.responseType == ResponseType.imageVideo
                    ? CustomButton(
                        onClick: () => showModal(isImage: false),
                        children: [
                          Icon(
                            CupertinoIcons.camera_fill,
                            color: CustomColors.fillWhite,
                            size: 24,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            widget.prompt.answer?.recordings.isNotEmpty ?? false
                                ? 'Add Another Video'
                                : 'Take a Video',
                            style: CustomTypography()
                                .button(color: CustomColors.textWhite),
                          )
                        ],
                      )
                    : const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 32),
            widget.prompt.answer?.recordings.isNotEmpty ?? false
                ? SizedBox(
                    child: MediaPreview(
                      recordings: widget.prompt.answer!.recordings,
                      delete: (path) => delete(path),
                    ),
                  )
                : const SizedBox.shrink()
          ],
        ));
  }

  delete(String path) async {
    final result = await showDialog<bool>(
        context: context,
        builder: (context) => DeletePopUp(
              title: Strings.deletePopUpTitle,
              subheader: Strings.deletePopUpSubheader,
            ));

    if (result == true && mounted) {
      final promptCubit = context.read<PromptCubit>();
      promptCubit.removeResponse(
          diary: widget.diary, path: path, prompt: widget.prompt);
    }
  }

  void showModal({required bool isImage}) {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        elevation: 0,
        useSafeArea: true,
        routeSettings: RouteSettings(name: "/CameraModal"),
        builder: (context) => DraggableScrollableSheet(
              initialChildSize: 1,
              minChildSize: 1,
              snap: true,
              builder: (context, scrollController) {
                return BottomCameraModal(
                  respond: widget.respond,
                  prompt: widget.prompt,
                  isImage: isImage,
                );
              },
            ));
  }
}

class MediaPreview extends StatefulWidget {
  final List<Recording> recordings;
  final Function(String path) delete;
  final bool interactions;
  const MediaPreview(
      {super.key,
      required this.recordings,
      required this.delete,
      this.interactions = true});

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  final children = <Widget>[];

  @override
  void initState() {
    getData();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MediaPreview oldWidget) {
    if (oldWidget.recordings != widget.recordings) {
      children.clear();
      getData();
    }
    super.didUpdateWidget(oldWidget);
  }

  getData() async {
    for (int i = 0; i < widget.recordings.length; i++) {
      final recording = widget.recordings[i];
      final path = recording.path;
      final type = recording.type;

      if (children.length >= 3) {
        final remaining = widget.recordings.length - 4;
        final child = remaining > 0
            ? type == 'video'
                ? lastVideoPreviewTile(path, remaining)
                : lastPreviewTile(path, remaining)
            : type == 'video'
                ? videoPreviewTile(path)
                : previewTile(path);
        children.add(child);

        break;
      }

      final child =
          type == 'video' ? videoPreviewTile(path) : previewTile(path);
      children.add(child);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      color: CustomColors.productNormalActive,
      strokeWidth: 4,
      radius: Radius.circular(4),
      padding: const EdgeInsets.all(16),
      dashPattern: [8, 8],
      borderType: BorderType.RRect,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: children,
      ),
    );
  }

  Widget previewTile(
    String path,
  ) {
    return FutureBuilder(
        future: getImageFile(path: path),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return GestureDetector(
              onTap: () => showModal(snapshot.data!.path, 'image'),
              child: SizedBox(
                height: 140,
                width: 140,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        height: 140,
                        width: 140,
                      ),
                    ),
                    widget.interactions
                        ? Positioned(
                            top: 0,
                            right: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: GestureDetector(
                                onTap: () => widget.delete(path),
                                child: Container(
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF616161)),
                                  child: Icon(
                                    Icons.remove,
                                    size: 28,
                                    color: CustomColors.fillWhite,
                                  ),
                                ),
                              ),
                            ))
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            );
          }

          return Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              color: CustomColors.greyDark,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        });
  }

  Widget lastPreviewTile(String path, int remaining) {
    return FutureBuilder(
        future: getImageFile(path: path),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return GestureDetector(
              onTap: () => showAllModal(),
              child: SizedBox(
                height: 140,
                width: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        foregroundDecoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4)),
                        child: Image.file(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          height: 140,
                          width: 140,
                        ),
                      ),
                      Center(
                        child: Text(
                          '+$remaining',
                          style: CustomTypography().custom(
                              color: CustomColors.textWhite,
                              fontWeight: FontWeight.w500,
                              fontSize: 24),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          }

          return Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              color: CustomColors.greyDark,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        });
  }

  Widget videoPreviewTile(String path) {
    return FutureBuilder(
        future: getVideoFileInfo(path: path),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return GestureDetector(
              onTap: () => showModal(snapshot.data!.absolutePath, 'video'),
              child: SizedBox(
                height: 140,
                width: 140,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        snapshot.data!.thumbnail,
                        fit: BoxFit.cover,
                        height: 140,
                        width: 140,
                      ),
                    ),
                    widget.interactions
                        ? Positioned(
                            top: 0,
                            right: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: GestureDetector(
                                onTap: () => widget.delete(path),
                                child: Container(
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF616161)),
                                  child: Icon(
                                    Icons.remove,
                                    size: 28,
                                    color: CustomColors.fillWhite,
                                  ),
                                ),
                              ),
                            ))
                        : const SizedBox.shrink(),
                    Positioned(
                        bottom: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            formatDurationtoHHMMSS(snapshot.data!.length),
                            style: CustomTypography().custom(
                                color: CustomColors.textWhite,
                                fontWeight: FontWeight.w500),
                          ),
                        ))
                  ],
                ),
              ),
            );
          }

          return Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              color: CustomColors.greyDark,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        });
  }

  Widget lastVideoPreviewTile(String path, int remaining) {
    return FutureBuilder(
        future: getVideoFileInfo(path: path),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return GestureDetector(
              onTap: () => showAllModal(),
              child: SizedBox(
                height: 140,
                width: 140,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        foregroundDecoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4)),
                        child: Stack(
                          children: [
                            Image.file(
                              snapshot.data!.thumbnail,
                              fit: BoxFit.cover,
                              height: 140,
                              width: 140,
                            ),
                            Positioned(
                                bottom: 0,
                                right: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Text(
                                    formatDurationtoHHMMSS(
                                        snapshot.data!.length),
                                    style: CustomTypography().custom(
                                        color: CustomColors.textWhite,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ))
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '+$remaining',
                        style: CustomTypography().custom(
                            color: CustomColors.textWhite,
                            fontWeight: FontWeight.w500,
                            fontSize: 24),
                      ),
                    )
                  ],
                ),
              ),
            );
          }

          return Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              color: CustomColors.greyDark,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        });
  }

  void showModal(String path, String type) {
    final File _file = File(path);
    final width = MediaQuery.of(context).size.width;
    showModalBottomSheet(
        backgroundColor: CustomColors.fillNormal,
        barrierColor: CustomColors.fillNormal,
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
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(
                                CupertinoIcons.clear,
                                size: 24,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    type == 'video'
                        ? Expanded(
                            child:
                                LayoutBuilder(builder: (context, constraints) {
                              return VideoViewer(
                                file: _file,
                                height: constraints.maxHeight,
                                width: constraints.maxWidth,
                              );
                            }),
                          )
                        : Expanded(
                            child: Container(
                              width: width,
                              decoration: const BoxDecoration(
                                color: CustomColors.greyLight,
                              ),
                              child: Image.file(_file),
                            ),
                          ),
                  ],
                );
              },
            ));
  }

  showAllModal() {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        elevation: 0,
        useSafeArea: true,
        routeSettings: RouteSettings(name: "/CameraModal"),
        builder: (context) => DraggableScrollableSheet(
              initialChildSize: 1,
              minChildSize: 1,
              snap: true,
              builder: (context, scrollController) {
                return ViewAllMediaModal(
                    recordings: widget.recordings, delete: widget.delete);
              },
            ));
  }
}

class VideoViewer extends StatefulWidget {
  final File file;
  final double height;
  final double width;
  const VideoViewer(
      {super.key,
      required this.file,
      required this.height,
      required this.width});

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  VideoPlayerController? controller;
  bool videoPlaying = false;

  // Slider
  double max = 0.0;
  double current = 0.0;
  Duration maxDuration = const Duration();
  Duration remaining = const Duration();
  Duration elapsed = const Duration();

  @override
  initState() {
    super.initState();
    init();
  }

  @override
  dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return controller != null
        ? SizedBox(
            height: widget.height,
            width: widget.width,
            child: Column(children: [
              Expanded(
                child: Container(
                  width: widget.width,
                  decoration: const BoxDecoration(
                    color: CustomColors.greyLight,
                  ),
                  child: Center(
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: controller!.value.aspectRatio,
                          child: VideoPlayer(controller!),
                        ),
                        Positioned(
                          bottom: 15,
                          left: 8,
                          right: 8,
                          child: SizedBox(
                              child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  //Elapsed
                                  Text(
                                    formatDurationtoHHMMSS(elapsed),
                                    style: CustomTypography().bodyMedium(
                                        color: CustomColors.textWhite),
                                  ),
                                  //Remaining
                                  Text(
                                    formatDurationtoHHMMSS(remaining),
                                    style: CustomTypography().bodyMedium(
                                        color: CustomColors.textWhite),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderThemeData(
                                    trackHeight: 8,
                                    activeTrackColor: CustomColors.fillWhite,
                                    thumbColor: CustomColors.fillWhite,
                                    inactiveTrackColor: Color(0xFF545454),
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 2, elevation: 0),
                                    overlayShape: SliderComponentShape.noThumb),
                                child: Slider(
                                  value: current,
                                  max: max,
                                  onChanged: (val) => seek(val),
                                ),
                              ),
                            ],
                          )),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 28.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => play(),
                      child: Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CustomColors.fillWhite),
                        child: Center(
                          child: Padding(
                            padding:
                                EdgeInsets.only(left: videoPlaying ? 0 : 4.0),
                            child: Icon(
                              videoPlaying
                                  ? CupertinoIcons.pause_fill
                                  : CupertinoIcons.play_arrow_solid,
                              color: CustomColors.productNormalActive,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              )
            ]),
          )
        : Center(
            child: CircularProgressIndicator(),
          );
  }

  init() async {
    controller = VideoPlayerController.file(widget.file);

    controller!.addListener(() {
      if (mounted) {
        setState(() {
          current = controller!.value.position.inMilliseconds.toDouble();
          elapsed = controller!.value.position;
          remaining = maxDuration - elapsed;
          if (elapsed == maxDuration) videoPlaying = false;
        });
      }
    });
    controller!.initialize().then((_) {
      if (mounted) {
        setState(() {
          max = controller!.value.duration.inMilliseconds.toDouble();
          maxDuration = controller!.value.duration;
          remaining = maxDuration;
        });
      }
    });
  }

  play() async {
    if (controller!.value.isPlaying) {
      await controller!.pause();
      if (mounted) setState(() => videoPlaying = false);
    } else {
      await controller!.play();
      if (mounted) setState(() => videoPlaying = true);
    }
  }

  seek(double value) async {
    await controller!.seekTo(Duration(milliseconds: value.toInt()));
  }
}

class TimePickerWidget extends StatefulWidget {
  final PromptModel prompt;
  final void Function(String) respond;
  const TimePickerWidget(
      {super.key, required this.prompt, required this.respond});

  @override
  State<TimePickerWidget> createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  @override
  Widget build(BuildContext context) {
    return TimeElapsedPicker(
      time: widget.prompt.answer?.response?.firstOrNull,
      subtitle: widget.prompt.subtitle ?? "",
      onChanged: (value) => widget.respond(value),
    );
  }
}
