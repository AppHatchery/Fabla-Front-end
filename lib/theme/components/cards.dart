import 'dart:async';

import 'package:audio_diaries_flutter/screens/diary/domain/entities/recording.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/review_diary.dart';
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
import '../../screens/diary/data/tag.dart';
import '../custom_icons.dart';
import '../resources/strings.dart';

/// Diary Card
///
/// This is the card that is displayed on the homescreen.
class DiaryCard extends StatefulWidget {
  final DiaryModel? diary;
  final ValueChanged<bool> refresh;
  final String Function() getPageName;

  const DiaryCard(
      {super.key,
      required this.diary,
      required this.refresh,
      required this.getPageName});

  @override
  State<DiaryCard> createState() => _DiaryCardState();
}

class _DiaryCardState extends State<DiaryCard> {
  DateTime now = DateTime.now();
  late Duration remainingTime;
  late bool closed;
  String? study;
  Color color = CustomColors.productNormal;
  Timer? timer;

  @override
  void initState() {
    getStudyName();
    super.initState();
  }

  void getStudyName() async {
    final repository = DiaryRepository();
    final _study = await repository.getStudy(widget.diary!.studyID);
    setState(() {
      study = _study?.name ?? '';
      color = _study!.color!;
    });
  }

  void _startTimer() {
    if (!closed && timer == null) {
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) {
          setState(() {
            remainingTime = widget.diary!.due.difference(DateTime.now());
            if (remainingTime.isNegative) {
              if (widget.diary!.status != DiaryStatus.complete) closed = true;
              t.cancel();
              timer = null;
            }
          });
        }
      });
    }
  }

  bool isClosed() {
    now = DateTime.now();
    remainingTime = widget.diary!.due.difference(now);
    final diary = widget.diary!;
    return (diary.due.isBefore(now) && diary.status != DiaryStatus.complete) ||
        diary.start.isAfter(now) ||
        diary.status == DiaryStatus.submitted;
  }

  bool isDiaryCompleteAndOverdue() {
    return widget.diary!.status == DiaryStatus.complete &&
        widget.diary!.due.isBefore(now);
  }

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    closed = isClosed();
    _startTimer();
    return Stack(
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: CustomColors.amber,
            borderRadius: BorderRadius.circular(10),
            shape: BoxShape.rectangle,
          ),
          margin: const EdgeInsets.only(left: 3, right: 3),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(CupertinoIcons.clock,
                    color: CustomColors.fillWhite, size: 20),
                const SizedBox(width: 4),
                Text(
                  "This task will expire in ${formatDuration(remainingTime.inMilliseconds)}",
                  style: CustomTypography().body(color: Colors.white),
                )
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: CustomColors.fillWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border(
                left: BorderSide(
              color: color,
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
              top: closed || isDiaryCompleteAndOverdue() ? 0 : 30),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.restart_alt_outlined,
                        color: color,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        study ?? "",
                        style: CustomTypography()
                            .bodyMedium(weight: FontWeight.w500),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      widget.diary?.tags != null &&
                              widget.diary!.tags!.isNotEmpty
                          ? Flexible(
                              fit: FlexFit.loose,
                              child: TagPill(tag: widget.diary!.tags!.first))
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.diary!.name,
                        style: CustomTypography().titleSmall(),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "About 5 minutes to complete",
                        style: CustomTypography().bodyMedium(
                            color: CustomColors.textSecondaryContent),
                      )
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    color: CustomColors.productBorderNormal,
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GestureDetector(
                    onTap:
                        closed && widget.diary!.status != DiaryStatus.submitted
                            ? () {}
                            : () => navigateToDiary(context),
                    child: Container(
                      decoration: BoxDecoration(
                          color: widget.diary!.status == DiaryStatus.submitted
                              ? CustomColors.fillWhite
                              : closed
                                  ? CustomColors.fillDisabled
                                  : CustomColors.productNormal,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: closed &&
                                      widget.diary!.status !=
                                          DiaryStatus.submitted
                                  ? CustomColors.fillDisabled
                                  : CustomColors.productNormal,
                              width: 2)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Text(
                          closed &&
                                  widget.diary!.status != DiaryStatus.submitted
                              ? widget.diary!.start.isAfter(now)
                                  ? "Opens at ${formatDurationToHHMM(widget.diary!.start)}"
                                  : "Closed at ${formatDurationToHHMM(widget.diary!.due)}"
                              : switch (widget.diary!.status) {
                                  DiaryStatus.complete => "Continue",
                                  DiaryStatus.idle => "Start",
                                  DiaryStatus.ongoing => "Continue",
                                  DiaryStatus.submitted => "View",
                                  DiaryStatus.missed => "View",
                                },
                          style: CustomTypography().button(
                            color: widget.diary!.status == DiaryStatus.submitted
                                ? CustomColors.productNormal
                                : closed
                                    ? CustomColors.textDisabled
                                    : CustomColors.textWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
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
}

/// Used in [DiaryCard]
class TagPill extends StatelessWidget {
  final Tag tag;

  const TagPill({
    super.key,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    late Color iconColor;
    switch (tag.text) {
      case "Done":
        iconColor = CustomColors.darkGreen;
        break;
      case "Missed":
        iconColor = CustomColors.warningActive;
        break;
      case "Awaiting Submission":
        iconColor = CustomColors.orangeDark;
        break;
      case "Ongoing":
        iconColor = CustomColors.productNormal;
        break;
      case "Ready to Start":
        iconColor = CustomColors.yellowDark;
        break;
      case "13 Questions":
        iconColor = CustomColors.yellowLight;
        break;
      case "12 Minutes":
        iconColor = const Color(0xFFEEEEFC);
        break;
      default:
        iconColor = CustomColors.productNormal;
        break;
    }

    late Color foreground;
    switch (tag.text) {
      case "13 Questions":
        foreground = CustomColors.yellowDark;
        break;
      case "12 Minutes":
        foreground = const Color(0xFF0147A0);
        break;
      default:
        foreground = Colors.black;
        break;
    }

    late IconData icon;
    switch (tag.text) {
      case "13 Questions":
        icon = CupertinoIcons.question_circle;
        break;
      case "12 Minutes":
        icon = Icons.access_time_rounded;
        break;
      case "Done":
        icon = Icons.done_rounded;
        break;
      case "Missed":
        icon = Icons.block_rounded;
        break;
      case "Awaiting Submission":
        icon = CupertinoIcons.cloud_upload;
        break;
      case "Ongoing":
        icon = Icons.rotate_right_outlined;
        break;
      case "Ready to Start":
        icon = CupertinoIcons.chevron_right_circle;
        break;
      default:
        icon = Icons.access_time_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(
            width: 5,
          ),
          Flexible(
            child: Text(tag.text,
                style: CustomTypography()
                    .bodyMedium(color: foreground, weight: FontWeight.w500)),
          ),
        ],
      ),
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
      reduce = currentSliderPosition.toInt();
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

    int position = currentSliderPosition.toInt() + increase;
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
    final path = p.join(dir.path, 'recordings', widget.recording.path);
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
        color: CustomColors.grey,
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
    final path = p.join(dir.path, 'recordings', widget.recording.path);
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
  final void Function(String)? edit;

  const TextAnswerCard(
      {super.key,
      required this.answer,
      this.delete,
      this.callerWidget,
      this.edit,
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
        color: CustomColors.grey,
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
                    widget.edit!("text");
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
