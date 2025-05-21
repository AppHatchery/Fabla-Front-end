import 'dart:async';

import 'package:audio_diaries_flutter/core/usecases/homepage.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/recording.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/review_diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:audio_diaries_flutter/theme/dialogs/pop_ups.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/utils/formatter.dart';
import '../../core/utils/statuses.dart';
import '../../screens/diary/data/diary.dart';
import '../custom_icons.dart';
import '../resources/strings.dart';

/// Diary Card
///
/// This is the card that is displayed on the homescreen.
class DiaryCard extends StatefulWidget {
  final DiaryModel? diary;
  final ValueChanged<bool> refresh;
  final String Function() getPageName;
  final int studyIndex;

  const DiaryCard({
    super.key,
    required this.diary,
    required this.refresh,
    required this.getPageName,
    this.studyIndex = 1,
  });

  @override
  State<DiaryCard> createState() => _DiaryCardState();
}

class _DiaryCardState extends State<DiaryCard> {
  DateTime now = DateTime.now();
  late bool closed;
  String? study;
  Color color = CustomColors.productNormal;

  @override
  void initState() {
    getStudyName();
    super.initState();
  }

  void getStudyName() async {
    final repository = DiaryRepository();
    final _study = await repository.getStudy(widget.diary!.studyID);
    if (mounted) {
      setState(() {
        study = _study?.name ?? '';
        color = _study!.color!;
      });
    }
  }

  bool isClosed() {
    now = DateTime.now();
    // remainingTime = widget.diary!.due.difference(now);
    final diary = widget.diary!;

    if (diary.status == DiaryStatus.submitted) return false;

    return (diary.due.isBefore(now) && diary.status != DiaryStatus.complete) ||
        diary.start.isAfter(now);
  }

  bool isDiaryCompleteAndOverdue() {
    return widget.diary!.status == DiaryStatus.complete &&
        widget.diary!.due.isBefore(now);
  }

  bool isDiaryOpen() {
    return (widget.diary!.status == DiaryStatus.ongoing ||
            widget.diary!.status == DiaryStatus.complete ||
            widget.diary!.status == DiaryStatus.submitted ||
            widget.diary!.status == DiaryStatus.missed ||
            (widget.diary!.status == DiaryStatus.idle &&
                widget.diary!.start.isBefore(now))) &&
        widget.getPageName() == "history_list";
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    closed = isClosed();
    return GestureDetector(
      onTap: () => closed ? null : navigateToDiary(context),
      child: Container(
        decoration: BoxDecoration(
          color: CustomColors.fillWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border(
              left: BorderSide(
            color: closed ? CustomColors.ashGrey : color,
            width: 4,
          )),
          boxShadow: const [
            BoxShadow(
              color: CustomColors.productBorderNormal,
              blurRadius: 4,
              spreadRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
          shape: BoxShape.rectangle,
        ),
        margin: EdgeInsets.only(
          left: 3,
          right: 3,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icon(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: body(),
                ),
              ),
              !closed
                  ? Icon(widget.diary!.status == DiaryStatus.submitted
                      ? Icons.remove_red_eye_outlined
                      : Icons.keyboard_arrow_right_rounded)
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  void navigateToDiary(BuildContext context) async {
    if (widget.diary!.status == DiaryStatus.complete) {
      Navigator.pushNamed(context, '/DiarySummaryPage',
          arguments: widget.diary);
    } else if (widget.diary!.status == DiaryStatus.submitted ||
        widget.diary!.status == DiaryStatus.missed ||
        widget.diary!.start.isAfter(DateTime.now())) {
      PendoService.track("ViewOldDiary", {
        "study_day": "${widget.diary!.id}",
        "diary_day_viewed": "${DateTime.now()}"
      });
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          routeSettings: RouteSettings(name: "/ReviewDiaryModal"),
          builder: (context) => Wrap(
                children: [ReviewDiary(diary: widget.diary!)],
              ));
    } else {
      final repository = DiaryRepository();
      final index =
          await repository.getIndexOfLastAnsweredPrompt(widget.diary!);
      final results = await Navigator.of(context).pushNamed("/NewDiaryPage",
          arguments: {'diary': widget.diary, 'index': index});

      if (results == true) {
        widget.refresh(true);
      }
    }
  }

  Widget icon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: ShapeDecoration(
        color: closed ? CustomColors.fillDisabled : color.withAlpha(90),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Image.asset(
        determineDiaryIcon(widget.diary!),
        height: 24,
        width: 24,
        color: closed ? CustomColors.midGrey : color,
      ),
    );
  }

  Widget body() {
    final colors = formatDiaryCardDueColors(
        widget.diary!.due, widget.diary!.start, widget.diary!.status);

    final wording = formatDiaryCardDue(
        widget.diary!.due, widget.diary!.start, widget.diary!.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          "${study ?? ''} #${widget.studyIndex}",
          style: CustomTypography().titleSmall(),
        ),
        isDiaryOpen()
            ? DiaryCardTag(status: widget.diary!.status)
            : Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: ShapeDecoration(
                  color: colors[0],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(
                  wording,
                  style: CustomTypography().titleRegular(color: colors[1]),
                ),
              )
      ],
    );
  }
}

class DiaryCardTag extends StatelessWidget {
  final DiaryStatus status;
  const DiaryCardTag({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    String text = "";
    IconData? icon;
    Color color = CustomColors.productNormal;

    switch (status) {
      case DiaryStatus.complete:
        text = "Awaiting Submission";
        icon = CupertinoIcons.cloud_upload;
        color = CustomColors.orangeDark;
        break;
      case DiaryStatus.submitted:
        text = "Submitted";
        icon = Icons.done_rounded;
        color = CustomColors.darkGreen;
        break;
      case DiaryStatus.missed:
        text = "Missed";
        icon = Icons.block_rounded;
        color = CustomColors.warningActive;
        break;
      case DiaryStatus.ongoing:
        text = "Ongoing";
        icon = Icons.rotate_right_outlined;
        color = CustomColors.productNormal;
        break;
      default:
        text = "Ready to Start";
        icon = CupertinoIcons.chevron_right_circle;
        color = CustomColors.yellowDark;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(
          width: 5,
        ),
        Flexible(
          child: Text(text,
              style: CustomTypography().bodyMedium(
                  color: CustomColors.textNormalContent,
                  weight: FontWeight.w400)),
        ),
      ],
    );
  }
}

class DiaryCardSmall extends StatefulWidget {
  final DiaryModel diary;
  final StudyModel study;
  const DiaryCardSmall({super.key, required this.diary, required this.study});

  @override
  State<DiaryCardSmall> createState() => _DiaryCardSmallState();
}

class _DiaryCardSmallState extends State<DiaryCardSmall> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: ShapeDecoration(
          color: CustomColors.fillWhite,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                  color: CustomColors.productBorderNormal, width: 1))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  Text(
                    widget.diary.name,
                    style: CustomTypography().titleSmall(),
                  ),
                ],
              ),
            ),
          ),
          widget.diary.status == DiaryStatus.submitted
              ? Icon(Icons.check_circle_rounded, color: CustomColors.darkGreen)
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget icon() {
    return Image.asset(
      determineDiaryIcon(widget.diary),
      height: 24,
      width: 24,
      color: widget.study.color,
    );
  }
}

/// Audio Diary Card
///
/// Requires a [file] to be passed in.
///
/// This is the card that is displayed when the user has recorded an audio diary.
///
/// It contains the following:
/// - A title
/// - A transcript
/// - A slider
/// - Controls
///
/// The card is collapsible, and the controls are only visible when the card is expanded.
///
/// The card is also clickable, and when clicked, it expands or collapses.
class AudioDiaryCard extends StatefulWidget {
  final Recording recording;
  final VoidCallback? delete;
  final bool viewOnly;
  final bool isExpanded;
  final VoidCallback? onTap;
  final int promptId;

  const AudioDiaryCard({
    super.key,
    required this.recording,
    this.delete,
    this.viewOnly = false,
    this.isExpanded = false,
    this.onTap,
    required this.promptId,
  });

  @override
  State<AudioDiaryCard> createState() => _AudioDiaryCardState();
}

class _AudioDiaryCardState extends State<AudioDiaryCard> {
  //Audio Player
  late AudioPlayer audioPlayer;
  bool isPlaying = false;
  double currentSliderPosition = 0;
  double maxSliderPosition = 0;
  Duration maxDuration = Duration.zero;

  @override
  void initState() {
    playerInit();
    super.initState();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (widget.isExpanded) {
      PendoService.track("AudioOpen", {
        "study_date": "${DateTime.now()}",
      });
    }
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: CustomColors.fillWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CustomColors.productBorderNormal,
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: CustomColors.productBorderNormal,
                blurRadius: 0,
                offset: Offset(0, 2.5),
              ),
            ],
            shape: BoxShape.rectangle,
          ),
          child: SizedBox(
            child: Column(
              children: [
                title(),
                Visibility(
                    visible: widget.isExpanded,
                    child: Column(
                      children: [
                        // transcript(),
                        /// Remove sized if transcript is available
                        const SizedBox(
                          height: 18,
                        ),
                        slider(width),
                      ],
                    )),
                Visibility(
                  visible: !widget.isExpanded,
                  replacement: const SizedBox(
                    height: 24,
                  ),
                  child: const SizedBox(
                    height: 12,
                  ),
                ),
                controls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget title() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          child: Row(
            children: [
              const Icon(CustomIcons.keyboardVoice),
              const SizedBox(
                width: 5,
              ),
              Text("New Diary", style: CustomTypography().title())
            ],
          ),
        ),
        Visibility(
          visible: widget.isExpanded,
          child: SizedBox(
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded),
                const SizedBox(
                  width: 5,
                ),
                Text(formatDateShort(widget.recording.date),
                    style: CustomTypography().titleRegular())
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget transcript() {
    return Row(
      children: [
        Expanded(
            child: Text(Strings.lorem,
                overflow: TextOverflow.ellipsis,
                style: CustomTypography()
                    .caption(color: CustomColors.textSecondaryContent))),
        Expanded(
            child: SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const IconButton(
                onPressed: null,
                icon: Icon(Icons.edit_note_rounded),
                color: CustomColors.textSecondaryContent,
              ),
              Text("view full transcript",
                  style: CustomTypography()
                      .caption(color: CustomColors.textSecondaryContent))
            ],
          ),
        )),
      ],
    );
  }

  Widget slider(double width) {
    return Column(
      children: [
        SizedBox(
            width: width,
            child: SliderTheme(
              data: SliderThemeData(
                  trackHeight: 3,
                  activeTrackColor: CustomColors.productNormal,
                  thumbColor: CustomColors.productNormal,
                  inactiveTrackColor: CustomColors.productBorderNormal,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: SliderComponentShape.noOverlay),
              child: Slider(
                value: currentSliderPosition,
                max: maxSliderPosition,
                onChanged: (val) => seek(val),
              ),
            )),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatDuration(currentSliderPosition.toInt())),
            Text(formatDuration(maxDuration.inMilliseconds.toInt()))
          ],
        )
      ],
    );
  }

  Widget controls() {
    return Visibility(
      visible: widget.isExpanded,
      replacement: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(formatDateShort(widget.recording.date),
              style: CustomTypography().bodyMedium()),
          Text(formatDuration(maxDuration.inMilliseconds.toInt()),
              style: CustomTypography().bodyMedium())
        ],
      ),
      child: Row(
        children: [
          const Expanded(child: SizedBox()),
          Expanded(
              flex: 2,
              child: SizedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        rewind();
                        PendoService.track("AudioControl", {
                          "action": "backward",
                          "study_date": "${DateTime.now()}",
                          "prompt_number": "${widget.promptId + 1}"
                        });
                      },
                      icon: const Icon(CupertinoIcons.gobackward_15),
                      color: Colors.black,
                      iconSize: 24,
                    ),
                    IconButton(
                      onPressed: () {
                        PendoService.track("AudioControl", {
                          "action": "play",
                          "study_date": "${DateTime.now()}",
                          "prompt_number": "${widget.promptId + 1}"
                        });
                        play();
                      },
                      icon: Icon(isPlaying
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_arrow_solid),
                      color: Colors.black,
                      iconSize: 24,
                    ),
                    IconButton(
                      onPressed: () {
                        PendoService.track("AudioControl", {
                          "action": "forward",
                          "study_date": "${DateTime.now()}",
                          "prompt_number": "${widget.promptId + 1}"
                        });
                        forward();
                      },
                      icon: const Icon(CupertinoIcons.goforward_15),
                      color: Colors.black,
                      iconSize: 24,
                    ),
                  ],
                ),
              )),
          Expanded(
              child: widget.viewOnly
                  ? const SizedBox()
                  : Container(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () {
                          PendoService.track("AudioControl", {
                            "action": "delete",
                            "study_date": "${DateTime.now()}",
                            "prompt_number": "${widget.promptId + 1}"
                          });
                          delete();
                        },
                        icon: const Icon(CupertinoIcons.delete),
                        color: CustomColors.warningActive,
                        iconSize: 24,
                      ),
                    )),
        ],
      ),
    );
  }

  Future<void> play() async =>
      isPlaying ? await audioPlayer.pause() : await audioPlayer.resume();

  Future<void> seek(double value) async {
    currentSliderPosition = value;
    await audioPlayer.seek(Duration(milliseconds: value.toInt()));
    if (!isPlaying) {
      await audioPlayer.resume();
    }
  }

  Future<void> rewind() async {
    final int currentPositionMillis = currentSliderPosition.toInt();
    int reduce = 15000;

    if (currentPositionMillis - reduce < 0) {
      reduce = currentPositionMillis;
    }

    int position = currentPositionMillis - reduce;
    await audioPlayer.seek(Duration(milliseconds: position));
  }

  Future<void> forward() async {
    final int currentPositionMillis = currentSliderPosition.toInt();
    int increase = 15000;

    if (currentPositionMillis + increase > maxSliderPosition.toInt()) {
      increase = maxSliderPosition.toInt() - currentPositionMillis;
    }

    int position = currentPositionMillis + increase;
    await audioPlayer.seek(Duration(milliseconds: position));
  }

  Future<void> delete() async {
    final results = await showDialog<bool>(
        context: context, builder: (context) => const DeletePopUp());

    if (results == true) {
      widget.delete!();
    }
  }

  void playerInit() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, widget.recording.path);
    audioPlayer = AudioPlayer()
      ..setSourceDeviceFile(path)
      ..setReleaseMode(ReleaseMode.stop)
      ..setPlayerMode(PlayerMode.mediaPlayer);

    audioPlayer.onPositionChanged.listen((event) {
      if (mounted) {
        setState(() {
          currentSliderPosition = event.inMilliseconds.toDouble();
        });
      }
    });
    audioPlayer.onPlayerStateChanged.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = event == PlayerState.playing;
        });
      }
    });
    audioPlayer.onDurationChanged.listen((event) {
      if (mounted) {
        setState(() {
          maxDuration = event;
          maxSliderPosition = event.inMilliseconds.toDouble();
        });
      }
    });
  }
}

class NewAudioCard extends StatefulWidget {
  final Recording recording;
  final VoidCallback? delete;
  final bool viewOnly;
  final int promptId;
  final String? callerWidget;
  final bool? isVisible;

  const NewAudioCard(
      {super.key,
      required this.recording,
      this.delete,
      this.isVisible,
      required this.viewOnly,
      this.callerWidget,
      required this.promptId});

  @override
  State<NewAudioCard> createState() => _NewAudioCardState();
}

class _NewAudioCardState extends State<NewAudioCard> {
  late AudioPlayer audioPlayer;
  bool isPlaying = false;
  double currentSliderPosition = 0;
  double maxSliderPosition = 0;
  Duration maxDuration = Duration.zero;

  @override
  void initState() {
    playerInit();
    super.initState();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color:
            widget.isVisible == true ? CustomColors.grey : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        shape: BoxShape.rectangle,
      ),
      child: Row(
        children: [
          Container(
              alignment: Alignment.center,
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CustomColors.productNormalActive,
              ),
              child: IconButton(
                onPressed: () => play(),
                icon: Icon(isPlaying
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_arrow_solid),
                color: CustomColors.fillWhite,
                iconSize: 10,
              )),
          const SizedBox(width: 3),
          Expanded(
            child: slider(),
          ),
          Row(
            children: [
              Text(formatDuration(currentSliderPosition.toInt())),
              const Text(" / "),
              Text(formatDuration(maxDuration.inMilliseconds.toInt()))
            ],
          ),
          widget.isVisible ?? false
              ? IconButton(
                  onPressed: () {
                    PendoService.track("AudioControl", {
                      "action": "delete",
                      "study_date": "${DateTime.now()}",
                      "prompt_number": "${widget.promptId + 1}"
                    });
                    delete();
                  },
                  icon: const Icon(CupertinoIcons.delete),
                  color: CustomColors.warningActive,
                  iconSize: 20,
                )
              : Container()
        ],
      ),
    );
  }

  Future<void> play() async =>
      isPlaying ? await audioPlayer.pause() : await audioPlayer.resume();

  Future<void> seek(double value) async {
    currentSliderPosition = value;
    await audioPlayer.seek(Duration(milliseconds: value.toInt()));
    if (!isPlaying) {
      await audioPlayer.resume();
    }
  }

  Future<void> delete() async {
    String? title, subheader;
    if (widget.callerWidget != null) {
      title = Strings.deletePopUpTitle;
      subheader = Strings.deletePopUpSubheader;
    }
    final results = await showDialog<bool>(
        context: context,
        builder: (context) => DeletePopUp(
              title: title,
              subheader: subheader,
            ));

    if (results == true) {
      widget.delete!();
    }
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
            value: currentSliderPosition,
            max: maxSliderPosition,
            onChanged: (val) => seek(val),
          ),
        )),
      ],
    );
  }

  void playerInit() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, widget.recording.path);
    audioPlayer = AudioPlayer()
      ..setSourceDeviceFile(path)
      ..setReleaseMode(ReleaseMode.stop)
      ..setPlayerMode(PlayerMode.mediaPlayer);

    audioPlayer.onPositionChanged.listen((event) {
      if (mounted) {
        setState(() {
          currentSliderPosition = event.inMilliseconds.toDouble();
        });
      }
    });
    audioPlayer.onPlayerStateChanged.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = event == PlayerState.playing;
        });
      }
    });
    audioPlayer.onDurationChanged.listen((event) {
      if (mounted) {
        setState(() {
          maxDuration = event;
          maxSliderPosition = event.inMilliseconds.toDouble();
        });
      }
    });
  }
}

// The Text Diary card is being used to create the Text diary Response
// It takes in the answer and the delete and edit function
class TextAnswerCard extends StatefulWidget {
  final String answer;
  final VoidCallback? delete;
  final String? callerWidget;
  final bool? isVisible;
  final void Function(String, int)? edit;
  final int index;

  const TextAnswerCard(
      {super.key,
      required this.answer,
      this.delete,
      this.callerWidget,
      this.edit,
      required this.index,
      this.isVisible});

  @override
  State<TextAnswerCard> createState() => _TextAnswerCardState();
}

class _TextAnswerCardState extends State<TextAnswerCard> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: BoxDecoration(
        color:
            widget.isVisible == true ? CustomColors.grey : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        shape: BoxShape.rectangle,
      ),
      child: Row(children: [
        Expanded(
          child: Text(widget.answer,
              style: CustomTypography().bodyMedium(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        widget.isVisible ?? false
            ? IconButton(
                onPressed: () {
                  if (widget.edit != null) {
                    widget.edit!("text", widget.index);
                  }
                },
                icon: const Icon(Icons.edit),
                color: CustomColors.productNormal,
                iconSize: 20,
              )
            : Container(),
        widget.isVisible ?? false
            ? IconButton(
                onPressed: () {
                  delete();
                },
                icon: const Icon(CupertinoIcons.delete),
                color: CustomColors.warningActive,
                iconSize: 20,
              )
            : Container()
      ]),
    );
  }

  Future<void> delete() async {
    String? title, subheader;
    if (widget.callerWidget != null) {
      title = Strings.deletePopUpTitle;
      subheader = Strings.deletePopUpSubheader;
    } else {
      subheader = Strings.deleteTextResponse;
    }
    final results = await showDialog<bool>(
        context: context,
        builder: (context) => DeletePopUp(
              title: title,
              subheader: subheader,
            ));

    if (results == true) {
      widget.delete!();
    }
  }
}

/// Text Diary Card
///
/// This is the card that is displayed when the user has written a text diary.
///
/// The card is collapsible, and the controls are only visible when the card is expanded.
///
/// The card is also clickable, and when clicked, it expands or collapses.
class TextDiaryCard extends StatefulWidget {
  const TextDiaryCard({super.key});

  @override
  State<TextDiaryCard> createState() => _TextDiaryCardState();
}

class _TextDiaryCardState extends State<TextDiaryCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () => {setState(() => isExpanded = !isExpanded)},
      child: SizedBox(
        width: width,
        child: Container(
          decoration: BoxDecoration(
            color: CustomColors.fillWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CustomColors.productBorderNormal,
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: CustomColors.productBorderNormal,
                blurRadius: 0,
                offset: Offset(0, 2.5),
              ),
            ],
            shape: BoxShape.rectangle,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      child: Row(
                        children: [
                          const Icon(CustomIcons.editDocument),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "New Diary",
                            style: CustomTypography().title(),
                          )
                        ],
                      ),
                    ),
                    Visibility(
                      visible: isExpanded,
                      child: SizedBox(
                        child: Row(
                          children: [
                            const Icon(Icons.timer),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              "3:15 PM",
                              style: CustomTypography().title(),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Visibility(
                  maintainState: true,
                  maintainAnimation: true,
                  visible: isExpanded,
                  child: SizedBox(
                      child: Text(
                    Strings.loremHalf,
                    style: CustomTypography()
                        .caption(color: CustomColors.textSecondaryContent),
                  )),
                ),
                Visibility(
                  visible: isExpanded,
                  child: const SizedBox(
                    height: 12,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Visibility(
                      visible: isExpanded,
                      replacement: Text(
                        "3:16 PM",
                        style: CustomTypography().bodyMedium(),
                      ),
                      child: Text(
                        "${Strings.loremHalf.length} words",
                        style: CustomTypography().bodyMedium(),
                      ),
                    ),
                    Visibility(
                      visible: isExpanded,
                      replacement: Text(
                        "${Strings.loremHalf.length} words",
                        style: CustomTypography().bodyMedium(),
                      ),
                      child: SizedBox(
                        child: GestureDetector(
                          onTap: () {},
                          child: const Icon(
                            CustomIcons.delete,
                            size: 24,
                            color: CustomColors.warningActive,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
