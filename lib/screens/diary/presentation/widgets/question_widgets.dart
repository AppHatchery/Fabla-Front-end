import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:alarm/alarm.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/prompt/prompt_cubit.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/dialogs/bottom_modals.dart';
import 'package:audio_diaries_flutter/theme/dialogs/pop_ups.dart';
import 'package:audio_diaries_flutter/theme/resources/strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

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
                    ? MaterialStateProperty.all(
                        CustomColors.productNormalActive)
                    : selectedOptions.contains(widget.options[index])
                        ? MaterialStateProperty.all(
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
                fillColor: MaterialStateProperty.all(!widget.disabled
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
  final void Function(String) respond;
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            (widget.prompt.answer?.recordings.isEmpty ?? true) &&
                    (widget.prompt.answer?.response?.isEmpty ?? true)
                ? Column(
                    children: [
                      CustomRecordButton(
                        onClick: () => widget.respond("audio"),
                        text: "Record My Response",
                      ),
                      CustomTextAnswerButton(
                        onClick: () => widget.respond("text"),
                        text: "Type My Response",
                      ),
                    ],
                  )
                : MyResponse(
                    diary: widget.diary,
                    edit: widget.respond,
                    prompt: widget.prompt,
                    recordings: widget.prompt.answer?.recordings ?? [])
          ],
        ));
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
      fillColor: MaterialStateProperty.all(CustomColors.textSecondaryContent),
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
          fillColor:
              MaterialStateProperty.all(CustomColors.textSecondaryContent),
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
  final void Function(String) respond;
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
            (widget.prompt.answer?.response?.isEmpty ?? true)
                ? Column(
                    children: [
                      CustomTextAnswerButton(
                        onClick: () => widget.respond("text"),
                        text: "Type My Response",
                      ),
                    ],
                  )
                : MyResponse(
                    diary: widget.diary,
                    edit: widget.respond,
                    prompt: widget.prompt,
                    recordings: [])
          ],
        ));
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
            Column(
                children: widget.prompt.answer?.response?.isEmpty ?? true
                    ? [
                        CustomFlatButton(
                          onClick: () => showModal(),
                          text: "Enter Survey",
                        )
                      ]
                    : [
                        CustomFlatButton(
                          onClick: () => showModal(),
                          color: CustomColors.fillWhite,
                          textColor: CustomColors.productNormal,
                          text: "Retake Survey",
                        ),
                        Text(
                          "✅ Your previous survey responses have been collected. If you retake the survey it will count as a new response. ",
                          style: CustomTypography().bodyLarge(
                              color: CustomColors.textTertiaryContent),
                        ),
                      ])
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
        builder: (context) => DraggableScrollableSheet(
              initialChildSize: 1,
              minChildSize: 1,
              snap: true,
              builder: (context, scrollController) {
                return BottomWebViewModal(
                  url: widget.prompt.subtitle!,
                  respond: widget.respond,
                );
              },
            ));
  }
}

class TimerWidget extends StatefulWidget {
  final String time;
  final void Function(String) respond;
  const TimerWidget({super.key, required this.time, required this.respond});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget>
    with TickerProviderStateMixin {
  late Duration duration;
  late Duration remaining;
  Timer? timer;
  bool inProgress = false;

  double progress = 0.0;

  //Animations
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _gradientController;
  late Animation<List<Color>> _gradientAnimation;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    duration = formatStringToDuration(widget.time);
    remaining = formatStringToDuration(widget.time);

    // Initialize AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _gradientAnimation = _gradientController.drive(
      ColorListTween(
        [
          [CustomColors.productLightBackground, const Color(0xFF4396FE)],
          [CustomColors.productNormal, CustomColors.productLightPrimaryActive],
          [CustomColors.productLightBackground, CustomColors.productNormal],
        ],
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: duration,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _animationController.dispose();
    _gradientController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
      child: inProgress
          ? Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return SizedBox(
                            width: 250,
                            height: 250,
                            child: CircularProgressIndicator(
                              value: _progressAnimation.value,
                              strokeWidth: 8,
                              color: CustomColors.productNormalActive,
                              backgroundColor:
                                  CustomColors.productLightBackground,
                              strokeCap: StrokeCap.round,
                            ),
                          );
                        }),
                    AnimatedBuilder(
                      animation: Listenable.merge(
                        [_scaleAnimation, _gradientAnimation],
                      ),
                      builder: (context, child) {
                        final colors = _gradientAnimation.value;
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                  colors: colors, stops: [0.5, 1.0]),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          formatDurationtoHHMMSS(remaining),
                          style: CustomTypography()
                              .titleLarge(color: CustomColors.textWhite),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomFlatButton(
                        onClick: () => restart(),
                        text: "Restart",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomFlatButton(
                        onClick: () => pause(),
                        text: "Pause",
                      ),
                    )
                  ],
                )
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomFlatButton(
                  onClick: () => start(),
                  text: "Start",
                )
              ],
            ),
    );
  }

  void start() async {
    final permission = await seekPermission();

    if (!permission) {
      return;
    }

    setState(() {
      inProgress = true;
    });
    timer?.cancel();
    _progressController.forward();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (remaining.inSeconds > 0) {
          remaining -= const Duration(seconds: 1);
        } else {
          timer?.cancel();
          _animationController.stop();
          widget.respond("Done");
        }
      });
    });

    setAlarm(remaining);
  }

  void pause() {
    if (timer?.isActive ?? false) {
      _progressController.stop();
      _animationController.stop();
      _gradientController.stop();
      timer?.cancel();
      timer = null;
    } else {
      _progressController.forward();
      _animationController.repeat(reverse: true);
      _gradientController.repeat(reverse: true);

      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          if (remaining.inSeconds > 0) {
            remaining -= const Duration(seconds: 1);
          } else {
            timer?.cancel();
            _animationController.stop();
            widget.respond("Done");
          }
        });
      });
    }
  }

  void stop() {
    timer?.cancel();
    timer = null;
    _progressController.reset();
    setState(() {
      duration = formatStringToDuration(widget.time);
      remaining = formatStringToDuration(widget.time);
      progress = 0.0;
    });
  }

  void restart() {
    stop();
    start();
  }

  void stopAlarm() async {
    await Alarm.stopAll();
  }

  void setAlarm(Duration time) async {
    // Ensure the alarm is cancelled after firing
    stopAlarm();

    final alarmID = Random().nextInt(1000);
    final _time = DateTime.now().add(time);
    await Alarm.set(
        alarmSettings: AlarmSettings(
            id: alarmID,
            dateTime: _time,
            assetAudioPath: 'assets/audio/chime.mp3',
            loopAudio: false,
            vibrate: true,
            volume: 1.0,
            fadeDuration: 0.0,
            warningNotificationOnKill: Platform.isIOS,
            androidFullScreenIntent: false,
            notificationSettings: const NotificationSettings(
                title: "Time's Up!",
                body: "Please come back to Fabla to finish your entry")));
  }

  /// Get special permission for the alarm
  /// Only applies to Android
  Future<bool> seekPermission() async {
    if (Platform.isIOS) return true;

    final status = await Permission.scheduleExactAlarm.status;
    if (status.isDenied) {
      final result = await Permission.scheduleExactAlarm.request();
      return result.isGranted;
    }
    return status.isGranted;
  }
}

class ColorListTween extends Tween<List<Color>> {
  final List<List<Color>> colors;

  ColorListTween(this.colors) : super(begin: colors.first, end: colors.last);

  @override
  List<Color> lerp(double t) {
    final index = (t * (colors.length - 1)).floor();
    final nextIndex = min(index + 1, colors.length - 1);
    final localT = (t * (colors.length - 1)) - index;

    return List<Color>.generate(
      begin!.length,
      (i) => Color.lerp(colors[index][i], colors[nextIndex][i], localT)!,
    );
  }
}

class ImageWidget extends StatefulWidget {
  final void Function(String) respond;
  final DiaryModel diary;
  final PromptModel prompt;
  const ImageWidget(
      {super.key,
      required this.diary,
      required this.prompt,
      required this.respond});

  @override
  State<ImageWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.prompt.answer?.response == null
                ? CustomFlatButton(
                    onClick: () => showModal(),
                    text: "Take a Picture",
                  )
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {
                              delete();
                            },
                            icon: const Icon(CupertinoIcons.delete),
                            color: CustomColors.warningActive,
                            iconSize: 20,
                          )
                        ],
                      ),
                      SizedBox(
                          width: width,
                          child: ImageViewer(
                              name: widget.prompt.answer!.response!)),
                    ],
                  )
          ],
        ));
  }

  delete() async {
    final result = await showDialog<bool>(
        context: context,
        builder: (context) => DeletePopUp(
              title: Strings.deletePopUpTitle,
              subheader: Strings.deletePopUpSubheader,
            ));

    if (result == true && mounted) {
      final promptCubit = context.read<PromptCubit>();
      promptCubit.removeResponse(
          diary: widget.diary, path: "", prompt: widget.prompt);
    }
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
        builder: (context) => DraggableScrollableSheet(
              initialChildSize: 1,
              minChildSize: 1,
              snap: true,
              builder: (context, scrollController) {
                return BottomCameraModal(
                  respond: widget.respond,
                  prompt: widget.prompt,
                );
              },
            ));
  }
}

class ImageViewer extends StatefulWidget {
  final String name;
  const ImageViewer({super.key, required this.name});

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  File? file;

  @override
  initState() {
    imageInit();
    super.initState();
  }

  imageInit() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'images', widget.name);
    setState(() {
      file = File(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return file != null ? Image.file(file!) : SizedBox.shrink();
  }
}

class VideoWidget extends StatefulWidget {
  final void Function(String) respond;
  final DiaryModel diary;
  final PromptModel prompt;
  const VideoWidget(
      {super.key,
      required this.diary,
      required this.prompt,
      required this.respond});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.prompt.answer?.response == null
                ? CustomFlatButton(
                    onClick: () => showModal(),
                    text: "Take a Video",
                  )
                : SizedBox(
                    width: width,
                    child: VideoViewer(
                        name: widget.prompt.answer!.response!, delete: delete),
                  )
          ],
        ));
  }

  delete() async {
    final result = await showDialog<bool>(
        context: context,
        builder: (context) => DeletePopUp(
              title: Strings.deletePopUpTitle,
              subheader: Strings.deletePopUpSubheader,
            ));

    if (result == true && mounted) {
      final promptCubit = context.read<PromptCubit>();
      promptCubit.removeResponse(
          diary: widget.diary, path: "", prompt: widget.prompt);
    }
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
        builder: (context) => DraggableScrollableSheet(
              initialChildSize: 1,
              minChildSize: 1,
              snap: true,
              builder: (context, scrollController) {
                return BottomCameraModal(
                  respond: widget.respond,
                  prompt: widget.prompt,
                  isImage: false,
                );
              },
            ));
  }
}

class VideoViewer extends StatefulWidget {
  final String name;
  final Function? delete;
  const VideoViewer({super.key, required this.name, required this.delete});

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  VideoPlayerController? controller;

  // Slider
  double max = 0.0;
  double current = 0.0;
  Duration maxDuration = const Duration();

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
        ? Column(children: [
            Row(
              children: [
                Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CustomColors.productNormalActive,
                    ),
                    child: Center(
                      child: IconButton(
                        onPressed: () => play(),
                        icon: Icon(controller!.value.isPlaying
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_arrow_solid),
                        color: CustomColors.fillWhite,
                        iconSize: 10,
                      ),
                    )),
                const SizedBox(width: 3),
                Expanded(
                  child: slider(),
                ),
                Row(
                  children: [
                    Text(formatDuration(current.toInt())),
                    const Text(" / "),
                    Text(formatDuration(maxDuration.inMilliseconds.toInt()))
                  ],
                ),
                widget.delete == null
                    ? SizedBox.shrink()
                    : IconButton(
                        onPressed: () => widget.delete!(),
                        icon: const Icon(CupertinoIcons.delete),
                        color: CustomColors.warningActive,
                        iconSize: 20,
                      )
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Center(
                child: AspectRatio(
                  aspectRatio: controller!.value.aspectRatio,
                  child: VideoPlayer(controller!),
                ),
              ),
            )
          ])
        : Center(
            child: CircularProgressIndicator(),
          );
  }

  Widget slider() {
    return Column(
      children: [
        SizedBox(
            child: SliderTheme(
          data: SliderThemeData(
              trackHeight: 5,
              activeTrackColor: CustomColors.productNormalActive,
              thumbColor: CustomColors.productNormalActive,
              inactiveTrackColor: CustomColors.greyTrack,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noOverlay),
          child: Slider(
            value: current,
            max: max,
            onChanged: (val) => seek(val),
          ),
        )),
      ],
    );
  }

  init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'videos', widget.name);
    final file = File(path);
    controller = VideoPlayerController.file(file);

    controller!.addListener(() {
      if (mounted) {
        setState(() {
          current = controller!.value.position.inMilliseconds.toDouble();
        });
      }
    });
    controller!.initialize().then((_) {
      if (mounted) {
        setState(() {
          max = controller!.value.duration.inMilliseconds.toDouble();
          maxDuration = controller!.value.duration;
        });
      }
    });
  }

  play() async {
    if (controller!.value.isPlaying) {
      await controller!.pause();
    } else {
      await controller!.play();
    }
  }

  seek(double value) async {
    await controller!.seekTo(Duration(milliseconds: value.toInt()));
  }
}
