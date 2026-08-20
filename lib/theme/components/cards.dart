import 'dart:async';
import 'dart:io';

import 'package:audio_diaries_flutter/core/usecases/diary.dart';
import 'package:audio_diaries_flutter/core/usecases/homepage.dart';
import 'package:audio_diaries_flutter/screens/diary/data/bulk_submission.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/recording.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/pages/bulk_submission.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/review_diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:audio_diaries_flutter/theme/dialogs/pop_ups.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/utils/formatter.dart';
import '../../core/utils/participant_experiment_details.dart';
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
  final String pageName;

  const DiaryCard(
      {super.key,
      required this.diary,
      required this.refresh,
      required this.pageName});

  @override
  State<DiaryCard> createState() => _DiaryCardState();
}

class _DiaryCardState extends State<DiaryCard> {
  DateTime now = DateTime.now();
  late bool closed;
  StudyModel? study;
  Color color = CustomColors.productNormal;

  Timer? _refreshTimer;

  @override
  void initState() {
    getStudyName();
    _refreshDiary();
    super.initState();
  }

  void getStudyName() async {
    final repository = DiaryRepository();
    final _study = await repository.getStudy(widget.diary!.studyID);
    if (mounted) {
      setState(() {
        study = _study;
        color = _study!.color!;
      });
    }
  }

  bool isClosed() {
    now = DateTime.now();
    // remainingTime = widget.diary!.due.difference(now);
    final diary = widget.diary!;

    if (diary.status == DiaryStatus.submitted) return false;

    // If a weekly diary and today is not part of the active days of the diary
    if (diary.activeDays != null && !diary.activeDays!.contains(now.weekday)) {
      if (mounted) {
        setState(() {
          diary.status = DiaryStatus.missed;
        });
      }
      return true;
    }

    return (diary.due.isBefore(now) && diary.status != DiaryStatus.complete) ||
        diary.start.isAfter(now);
  }

  bool isDiaryCompleteAndOverdue() {
    return widget.diary!.status == DiaryStatus.complete &&
        widget.diary!.due.isBefore(now);
  }

  // Function to refresh the diary card
  void _refreshDiary() {
    final now = DateTime.now();
    final start = widget.diary!.start;
    final due = widget.diary!.due;

    DateTime? time;

    if (start.isAfter(now)) {
      // Schedule refresh at start time
      time = start;
    } else if (due.isAfter(now)) {
      // Schedule refresh at due time
      time = due;
    }

    if (time != null) {
      final duration = time.difference(now);

      _refreshTimer = Timer(duration, () {
        if (mounted) {
          // This will trigger a rebuild
          setState(() {
            closed = isClosed();
          });
          // Schedule next refresh if needed
          _refreshDiary();
        }
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
    final optional = study?.goals.daily == 0 && study?.goals.weekly == 0;
    final colors = formatDiaryCardDueColors(
        widget.diary!.due, widget.diary!.start, widget.diary!.status, optional);

    final wording = formatDiaryCardDue(
        widget.diary!.due, widget.diary!.start, widget.diary!.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          widget.diary?.name ?? "",
          style: CustomTypography().titleSmall(),
        ),
        widget.pageName != "home"
            ? DiaryCardTag(status: widget.diary!.status)
            : widget.diary!.currentEntry > 0
                ? DiaryCardTag(
                    status: DiaryStatus.submitted,
                  )
                : bodyTag(
                    text: wording, color: colors[1], background: colors[0]),
        if (widget.diary!.entries > 1)
          bodyTag(
              text: "Multiple submissions allowed",
              color: CustomColors.midGrey,
              background: CustomColors.productBorderNormal)
      ],
    );
  }

  Widget bodyTag(
      {required String text, required Color color, required Color background}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: ShapeDecoration(
        color: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(
        text,
        style: CustomTypography().titleRegular(color: color),
      ),
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
                  Flexible(
                    child: Text(
                      widget.diary.name,
                      style: CustomTypography().titleSmall(),
                    ),
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
/// Shared audio playback lifecycle for the recording cards.
///
/// The recording is verified on disk and decoded before [audioPlayer] is
/// exposed, so a missing, empty or undecodable file settles on an
/// [AudioStatus] the card can render instead of throwing an uncaught
/// `PlatformException` out of the platform audio stack.
mixin AudioPlaybackMixin<T extends StatefulWidget> on State<T> {
  AudioPlayer? audioPlayer;
  AudioStatus audioStatus = AudioStatus.loading;
  bool isPlaying = false;
  double currentSliderPosition = 0;
  double maxSliderPosition = 0;
  Duration maxDuration = Duration.zero;

  /// Retained so failure reports identify which recording broke.
  String _recordingPath = '';

  bool get canPlay => audioStatus == AudioStatus.available;

  /// Loads [relativePath], resolved against the documents directory.
  Future<void> initAudio(String relativePath) async {
    _recordingPath = relativePath;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, relativePath);
    final file = File(path);

    if (!await file.exists()) {
      _fail(
        AudioStatus.fileNotFound,
        FileSystemException('Recording file not found', path),
      );
      onAudioStatusResolved(AudioStatus.fileNotFound, duringLoad: true);
      return;
    }

    if (await file.length() == 0) {
      _fail(
        AudioStatus.noAudioLength,
        FileSystemException('Recording file is empty', path),
      );
      onAudioStatusResolved(AudioStatus.noAudioLength, duringLoad: true);
      return;
    }

    final player = AudioPlayer();
    try {
      await player.setSourceDeviceFile(path);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setPlayerMode(PlayerMode.mediaPlayer);

      final duration = await player.getDuration();
      if (duration == null || duration <= Duration.zero) {
        await player.dispose();
        _fail(
          AudioStatus.noAudioLength,
          FileSystemException('Recording has no playable duration', path),
        );
        onAudioStatusResolved(AudioStatus.noAudioLength, duringLoad: true);
        return;
      }

      // The card may have been popped while the source was loading.
      if (!mounted) {
        await player.dispose();
        return;
      }

      player.onPositionChanged.listen((position) {
        if (mounted) {
          setState(
              () => currentSliderPosition = position.inMilliseconds.toDouble());
        }
      });
      player.onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => isPlaying = state == PlayerState.playing);
      });

      setState(() {
        audioPlayer = player;
        maxDuration = duration;
        maxSliderPosition = duration.inMilliseconds.toDouble();
        audioStatus = AudioStatus.available;
      });

      onAudioStatusResolved(AudioStatus.available, duringLoad: true);
    } catch (e, s) {
      await player.dispose();
      _fail(AudioStatus.canNotPlay, e, s);
    }
  }

  /// Called once the card settles on a terminal status, so a parent can react
  /// to a recording that turned out to be unplayable.
  ///
  /// [duringLoad] separates "this file could not be loaded" from "playback of
  /// an already-loaded file failed". The second can be transient — an
  /// interrupted session, a route change — so a caller that discards broken
  /// recordings must not act on it.
  void onAudioStatusResolved(AudioStatus status, {required bool duringLoad}) {}

  void disposeAudio() => audioPlayer?.dispose();

  Future<void> play() =>
      _run((player) => isPlaying ? player.pause() : player.resume());

  Future<void> seek(double value) => _run((player) async {
        await player.seek(Duration(milliseconds: value.toInt()));
        if (!isPlaying) await player.resume();
      });

  /// Seeks [milliseconds] relative to the current position, clamped to the
  /// recording's bounds. Negative values rewind.
  Future<void> skip(int milliseconds) => _run((player) => player.seek(Duration(
        milliseconds: (currentSliderPosition.toInt() + milliseconds)
            .clamp(0, maxSliderPosition.toInt()),
      )));

  /// Runs [action] against the active player, retiring the player and falling
  /// back to an error state if the platform rejects it.
  Future<void> _run(Future<void> Function(AudioPlayer player) action) async {
    final player = audioPlayer;
    if (player == null || !canPlay) return;

    try {
      await action(player);
    } catch (e, s) {
      audioPlayer = null;
      await player.dispose();
      _fail(AudioStatus.canNotPlay, e, s);
      onAudioStatusResolved(AudioStatus.canNotPlay, duringLoad: false);
    }
  }

  /// Moves the card into a failure [status] and reports [error] as a non-fatal.
  ///
  /// Every failure path routes through here, so each one is reported exactly
  /// once with the recording that caused it.
  void _fail(AudioStatus status, Object error, [StackTrace? stackTrace]) {
    CrashlyticsService().recordError(
      error,
      stackTrace ?? StackTrace.current,
      reason: 'Recording unplayable: ${status.name}',
      context: {
        'recording_path': _recordingPath,
        'audio_status': status.name,
      },
    );

    if (!mounted) return;
    setState(() {
      audioStatus = status;
      isPlaying = false;
      currentSliderPosition = 0;
      maxSliderPosition = 0;
      maxDuration = Duration.zero;
    });
  }
}

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

class _AudioDiaryCardState extends State<AudioDiaryCard>
    with AudioPlaybackMixin<AudioDiaryCard> {
  @override
  void initState() {
    super.initState();
    initAudio(widget.recording.path);
  }

  @override
  void dispose() {
    disposeAudio();
    super.dispose();
  }

  void trackControl(String action) {
    PendoService.track("AudioControl", {
      "action": action,
      "study_date": "${DateTime.now()}",
      "prompt_number": "${widget.promptId + 1}"
    });
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
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
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
          child: Column(
            children: [
              title(),
              Visibility(
                visible: widget.isExpanded && canPlay,
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    slider(width),
                  ],
                ),
              ),
              Visibility(
                visible: !widget.isExpanded,
                replacement: const SizedBox(height: 24),
                child: const SizedBox(height: 12),
              ),
              controls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget title() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(CustomIcons.keyboardVoice),
            const SizedBox(width: 5),
            Text(
              "New Diary",
              style: CustomTypography().title(),
            ),
          ],
        ),
        Visibility(
          visible: widget.isExpanded,
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded),
              const SizedBox(width: 5),
              Text(
                formatDateShort(widget.recording.date),
                style: CustomTypography().titleRegular(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget transcript() {
    return Row(
      children: [
        Expanded(
          child: Text(
            Strings.lorem,
            overflow: TextOverflow.ellipsis,
            style: CustomTypography().caption(
              color: CustomColors.textSecondaryContent,
            ),
          ),
        ),
        Expanded(
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
        ),
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
                onChanged: canPlay ? seek : null,
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
    if (audioStatus == AudioStatus.loading) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (!canPlay) {
      return RecordingIssueCard(status: audioStatus);
    }

    return Visibility(
      visible: widget.isExpanded,
      replacement: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            formatDateShort(widget.recording.date),
            style: CustomTypography().bodyMedium(),
          ),
          Text(
            formatDuration(
              maxDuration.inMilliseconds,
            ),
            style: CustomTypography().bodyMedium(),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: SizedBox(),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    trackControl("backward");
                    rewind();
                  },
                  icon: const Icon(
                    CupertinoIcons.gobackward_15,
                  ),
                  color: Colors.black,
                  iconSize: 24,
                ),
                IconButton(
                  onPressed: () {
                    trackControl("play");
                    play();
                  },
                  icon: Icon(
                    isPlaying
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_arrow_solid,
                  ),
                  color: Colors.black,
                  iconSize: 24,
                ),
                IconButton(
                  onPressed: () {
                    trackControl("forward");
                    forward();
                  },
                  icon: const Icon(
                    CupertinoIcons.goforward_15,
                  ),
                  color: Colors.black,
                  iconSize: 24,
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.viewOnly
                ? const SizedBox()
                : Container(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {
                        trackControl("delete");
                        delete();
                      },
                      icon: const Icon(
                        CupertinoIcons.delete,
                      ),
                      color: CustomColors.warningActive,
                      iconSize: 24,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> rewind() => skip(-15000);

  Future<void> forward() => skip(15000);

  Future<void> delete() async {
    final results = await showDialog<bool>(
      context: context,
      builder: (context) => const DeletePopUp(),
    );

    if (results == true) {
      widget.delete?.call();
    }
  }
}

class NewAudioCard extends StatefulWidget {
  final Recording recording;
  final VoidCallback? delete;
  final bool viewOnly;
  final int promptId;
  final String? callerWidget;
  final bool? isVisible;

  /// Reports the terminal [AudioStatus] for this recording once the card
  /// resolves, so the prompt can react to one that turned out unplayable.
  final void Function(String path, AudioStatus status)? onPlaybackResolved;

  const NewAudioCard(
      {super.key,
      required this.recording,
      this.delete,
      this.isVisible,
      required this.viewOnly,
      this.callerWidget,
      this.onPlaybackResolved,
      required this.promptId});

  @override
  State<NewAudioCard> createState() => _NewAudioCardState();
}

class _NewAudioCardState extends State<NewAudioCard>
    with AudioPlaybackMixin<NewAudioCard> {
  @override
  void initState() {
    super.initState();
    initAudio(widget.recording.path);
  }

  @override
  void dispose() {
    disposeAudio();
    super.dispose();
  }

  /// Reports upward so the prompt can offer a way to record a replacement.
  /// Deferred a frame so a parent rebuild triggered by this cannot land while
  /// the surrounding list is still building.
  @override
  void onAudioStatusResolved(AudioStatus status, {required bool duringLoad}) {
    // A failure part-way through playback can be transient, and the page
    // discards whatever it is told is broken. Only load-time outcomes, where
    // the file itself was proven bad, are reported upward.
    if (!duringLoad) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onPlaybackResolved?.call(widget.recording.path, status);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (audioStatus == AudioStatus.loading) {
      return const SizedBox(
        height: 34,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!canPlay) {
      return RecordingIssueCard(status: audioStatus);
    }

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
              child: Transform.translate(
                offset: isPlaying ? const Offset(0, -1) : const Offset(1, -1),
                child: IconButton(
                  onPressed: () => play(),
                  icon: Icon(isPlaying
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
      widget.delete?.call();
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
            onChanged: canPlay ? seek : null,
          ),
        )),
      ],
    );
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
              style: CustomTypography()
                  .bodyLarge(color: CustomColors.textSecondaryContent),
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

class PendingSubmissionCard extends StatelessWidget {
  final List<DiarySubmission> submissions;
  final bool retry; // Should show the retry card
  const PendingSubmissionCard(
      {super.key, required this.submissions, this.retry = false});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final text = Intl.plural(
      submissions.length,
      other:
          "You have ${submissions.length} pending diary submissions. Would you like to upload them now?",
      one:
          "You have 1 pending diary submission. Would you like to upload it now?",
    );

    final retryText = Intl.plural(
      submissions.length,
      other:
          "${submissions.length} diary submissions could not be uploaded and are still pending",
      one: "1 diary submission could not be uploaded and is still pending",
    );
    final buttonText = Intl.plural(
      submissions.length,
      other: "Upload All Now",
      one: "Upload Now",
    );
    final retryButtonText = 'Retry Upload';

    final color =
        retry ? CustomColors.warningNormal : CustomColors.productNormalActive;
    final backgroundColor =
        retry ? CustomColors.warningFill : Color(0xFFD0DEF4);

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 2, color: color),
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                retry ? CupertinoIcons.clear_circled : CupertinoIcons.wifi,
                size: 24,
                color: color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(
                        retry ? 'Upload Failed' : "You're Back Online",
                        style:
                            CustomTypography().titleSmallCustom(color: color),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        child: Text(
                          retry ? retryText : text,
                          style: CustomTypography().bodyLarge(color: color),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0, top: 12),
            child: CustomOutlineButton(
              onClick: () => _navigateToBulkSubmission(context),
              backgroundColor: color,
              color: color,
              borderRadius: 12,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              children: Wrap(children: [
                Text(
                  retry ? retryButtonText : buttonText,
                  style:
                      CustomTypography().button(color: CustomColors.textWhite),
                )
              ]),
            ),
          )
        ],
      ),
    );
  }

  _navigateToBulkSubmission(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                BulkSubmissionPage(submissions: submissions)));
  }
}

class FailedSubmissionCard extends StatelessWidget {
  const FailedSubmissionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Color(0xFFD0DEF4),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 2, color: CustomColors.productNormalActive),
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/icons/arrow_upload_progress.png',
                height: 24,
                width: 24,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(
                        'Diary Saved for Submission',
                        style: CustomTypography().titleSmallCustom(
                            color: CustomColors.productNormalActive),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        child: Text(
                          'Your entry is saved on your phone. You can submit it once you get back online.',
                          style: CustomTypography().bodyLarge(
                              color: CustomColors.productNormalActive),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PendingSubmissionSmallCard extends StatefulWidget {
  final DiaryModel diary;
  final StudyModel study;
  final SubmissionStatus status;
  const PendingSubmissionSmallCard(
      {super.key,
      required this.diary,
      required this.study,
      required this.status});

  @override
  State<PendingSubmissionSmallCard> createState() =>
      _PendingSubmissionSmallCardState();
}

class _PendingSubmissionSmallCardState
    extends State<PendingSubmissionSmallCard> {
  Color color = CustomColors.productNormal;
  late DateTime completedAt;

  @override
  void initState() {
    completedAt = widget.diary.due;
    color = widget.study.color ?? CustomColors.productNormal;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            switch (widget.status) {
              SubmissionStatus.pending => SizedBox(
                  height: 24,
                  width: 24,
                  child: Center(
                      child: const CircularProgressIndicator(
                    color: CustomColors.productNormalActive,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                  ))),
              SubmissionStatus.successful => Icon(
                  Icons.check_rounded,
                  color: CustomColors.darkGreen,
                  size: 24,
                ),
              SubmissionStatus.failed => Image.asset(
                  'assets/images/icons/arrow_upload_ready.png',
                  height: 24,
                  width: 24,
                )
            }
          ],
        ),
      ),
    );
  }

  Widget icon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: ShapeDecoration(
        color: widget.study.color?.withAlpha(90),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Image.asset(
        determineDiaryIcon(widget.diary),
        height: 24,
        width: 24,
        color: widget.study.color,
      ),
    );
  }

  Widget body() {
    final wording = formatDiaryDueSubmission(completedAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          widget.diary.name,
          style: CustomTypography().titleSmall(),
        ),
        Text(
          wording,
          style: CustomTypography()
              .titleRegular(color: CustomColors.textSecondaryContent),
        )
      ],
    );
  }

  void updateCompletedAt(DateTime date) async {
    final _completedAt = await getCompletionDate(widget.diary.id.toString(),
        fallback: widget.diary.due);

    if (mounted) {
      setState(() {
        completedAt = _completedAt;
      });
    }
  }
}

class NoInternetCard extends StatelessWidget {
  const NoInternetCard({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Color(0xFFFFF8DE),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 2, color: Color(0xFFD26B00)),
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.wifi_slash,
            size: 24,
            color: Color(0xFFD26B00),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    "No Internet Connection",
                    style: CustomTypography()
                        .titleSmallCustom(color: Color(0xFFD26B00)),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      "You can continue logging your diary. Your data will be saved securely on this device, and you’ll need to upload it once you’re back online.",
                      style: CustomTypography()
                          .bodyLarge(color: Color(0xFFD26B00)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WebViewErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final double spacing;
  final String buttonText;
  final VoidCallback onRetry;
  final bool showContactResearch;
  final String icon;
  final VoidCallback skip;
  final bool connection;
  final VoidCallback screenChange;

  const WebViewErrorCard({
    super.key,
    required this.title,
    required this.message,
    this.spacing = 24,
    required this.buttonText,
    required this.onRetry,
    required this.showContactResearch,
    required this.icon,
    required this.skip,
    required this.connection,
    required this.screenChange,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: spacing,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            icon,
            width: 80,
            height: 80,
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: CustomTypography().headlineMedium(
              color: Color(0xFFFF3B30),
            ),
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: CustomTypography().bodyLarge(),
          ),
          if (!connection)
            Text(
              "Are you currently offline?",
              style: CustomTypography().bodyLarge(),
            ),
          Row(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (buttonText == "Try Again")
                Expanded(
                  child: CustomOutlineButton(
                    onClick: onRetry,
                    color: Color(0xFFFF3B30),
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 14.0),
                    children: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: [
                        Text(
                          buttonText,
                          style: CustomTypography()
                              .button(color: Color(0xFFFF3B30)),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: CustomFlatButton(
                    color: Color(0xFFFF3B30),
                    borderColor: Color(0xFFFF3B30),
                    onClick: !connection ? screenChange : skip,
                    text: !connection ? "Yes, I'm Offline" : "Skip"),
              )
            ],
          ),
          if (showContactResearch)
            Padding(
              padding: const EdgeInsets.only(top: 142.0),
              child: GestureDetector(
                onTap: _launchEmail,
                child: Text(
                  "Contact Researcher",
                  textAlign: TextAlign.center,
                  style: CustomTypography().button(color: Color(0xFFFF3B30)),
                ),
              ),
            )
        ],
      ),
    );
  }

  Future<void> _launchEmail() async {
    await ParticipantAndExperimentDetails().launchSupportEmail(
        subject: '$title – Assistance Needed',
        body:
            '$title was encountered. Please investigate and advise on next steps.',
        example:
            "e.g The survey page won't load and shows a red error screen. This happens every time I try to open the task, even after restarting the app.");
  }
}

class NoNotificationCard extends StatelessWidget {
  final VoidCallback openSettings;

  const NoNotificationCard({
    required this.openSettings,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFD26B00);
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xFFFFF8DE),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 2, color: accent),
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                CupertinoIcons.bell_fill,
                size: 24,
                color: accent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(
                        "Notification permission required",
                        style:
                            CustomTypography().titleSmallCustom(color: accent),
                      ),
                      Text(
                        "Notifications for Fabla are turned off. Enable them in Settings so you don't miss diary reminders.",
                        style: CustomTypography().bodyLarge(color: accent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 12),
            child: CustomOutlineButton(
              onClick: openSettings,
              backgroundColor: accent,
              color: accent,
              borderRadius: 12,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              children: Wrap(children: [
                Text(
                  "Open Settings",
                  style:
                      CustomTypography().button(color: CustomColors.textWhite),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class WarningCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const WarningCard({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.warning_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: CustomColors.fillVanilla,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 2, color: CustomColors.pumpkinOrange),
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: CustomColors.pumpkinOrange,
            size: 24,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    title,
                    style: CustomTypography().titleSmallCustom(
                      color: CustomColors.pumpkinOrange,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      message,
                      style: CustomTypography().bodyLarge(
                        color: CustomColors.pumpkinOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Explains why a recording cannot be played, in place of the audio controls.
class RecordingIssueCard extends StatelessWidget {
  const RecordingIssueCard({super.key, required this.status});

  final AudioStatus status;

  static const _messages = {
    AudioStatus.fileNotFound:
        "Sorry, we couldn\u2019t find this recording on your device. Please record your answer again using the button above.",
    AudioStatus.noAudioLength:
        "Sorry, no audio was captured in this recording. Please record your answer again using the button above.",
    AudioStatus.canNotPlay:
        "Sorry, something went wrong while saving. Please record your answer again using the button above.",
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: ShapeDecoration(
        color: CustomColors.warningFill,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 2, color: CustomColors.warningNormal),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            CupertinoIcons.xmark_circle_fill,
            size: 24,
            color: Color(0xFFCD091D),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                _messages[status] ?? '',
                style: CustomTypography().bodyLarge(
                  color: const Color(0xFFCD091D),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//disclaimer message for the audio recording
class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: ShapeDecoration(
        color: CustomColors.fillVanilla,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/icons/notice_icon.png',
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Please stay in the app. Leaving while recording can result in data loss.',
              style: CustomTypography().bodyLarge(),
            ),
          ),
        ],
      ),
    );
  }
}
