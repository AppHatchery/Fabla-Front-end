import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/recording.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../core/utils/formatter.dart';
import '../../core/utils/statuses.dart';
import '../../screens/diary/data/diary.dart';
import '../../screens/diary/data/tag.dart';
import '../custom_icons.dart';
import '../resources/strings.dart';
import 'buttons.dart';

/// Diary Card
///
/// This is the card that is displayed on the homescreen.
class DiaryCard extends StatelessWidget {
  final Diary? diary;
  const DiaryCard({super.key, required this.diary});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: diary?.status == DiaryStatus.submitted
            ? CustomColors.fillNormal
            : CustomColors.fillWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CustomColors.productBorderNormal,
          width: 2,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                direction: Axis.horizontal,
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [for (var tag in diary!.tags) TagPill(tag: tag)],
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text(
                      "Tell me about your day.",
                      style: CustomTypography().bodyMedium(),
                    )),
                Expanded(
                  flex: 1,
                  child: CustomElevatedButton(
                    onClick: () => navigateToDiary(context),
                    text: switch (diary!.status) {
                      DiaryStatus.complete => "Submit",
                      DiaryStatus.idle => "Start",
                      DiaryStatus.ongoing => "Continue",
                      DiaryStatus.submitted => "View",
                    },
                    color: diary?.status == DiaryStatus.submitted
                        ? CustomColors.fillNormal
                        : CustomColors.productNormal,
                    border: diary?.status == DiaryStatus.submitted
                        ? Border.all(
                            color: CustomColors.productNormal, width: 2)
                        : const Border(),
                    textColor: diary?.status == DiaryStatus.submitted
                        ? CustomColors.productNormal
                        : CustomColors.textWhite,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void navigateToDiary(BuildContext context) {
    if (diary!.status == DiaryStatus.complete) {
      Navigator.pushNamed(context, '/DiarySummaryPage', arguments: diary);
    } else {
      Navigator.of(context).pushNamed("/NewDiaryPage", arguments: diary);
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
    Tuple2<Color, Color> colors = getColorFromString(tag.text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(5),
          color: colors.item1),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            switch (tag.type) {
              TagType.time => Icons.access_time_rounded,
              TagType.remainder => Icons.contrast_rounded,
              TagType.questions => Icons.quiz_outlined,
            },
            color: colors.item2,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(tag.text,
              style: CustomTypography().caption(color: colors.item2)),
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
  const AudioDiaryCard(
      {super.key, required this.recording, this.delete, this.viewOnly = false});

  @override
  State<AudioDiaryCard> createState() => _AudioDiaryCardState();
}

class _AudioDiaryCardState extends State<AudioDiaryCard> {
  bool isExpanded = false;

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
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () => {setState(() => isExpanded = !isExpanded)},
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
                    visible: isExpanded,
                    child: Column(
                      children: [
                        // transcript(),
                        /// Remove sized if transcript is available
                        const SizedBox(
                          height: 10,
                        ),
                        slider(width),
                      ],
                    )),
                Visibility(
                    visible: !isExpanded,
                    child: const SizedBox(
                      height: 12,
                    )),
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
          visible: isExpanded,
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
              data: const SliderThemeData(
                trackHeight: 3,
                activeTrackColor: CustomColors.productNormal,
                thumbColor: CustomColors.productNormal,
                inactiveTrackColor: CustomColors.productBorderNormal,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
              ),
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
      visible: isExpanded,
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
                      onPressed: () => rewind(),
                      icon: const Icon(CustomIcons.backupLeft_15s),
                      color: Colors.black,
                    ),
                    IconButton(
                      onPressed: () => play(),
                      icon: Icon(isPlaying
                          ? CustomIcons.pause
                          : CustomIcons.playArrow),
                      color: Colors.black,
                    ),
                    IconButton(
                      onPressed: () => forward(),
                      icon: const Icon(CustomIcons.forwardRight_15s),
                      color: Colors.black,
                    ),
                  ],
                ),
              )),
          Expanded(
              child: widget.viewOnly
                  ? const SizedBox()
                  : GestureDetector(
                      onTap: () => delete(),
                      child: const SizedBox(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            CustomIcons.delete,
                            color: CustomColors.warningActive,
                          ),
                        ),
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
    widget.delete!();
  }

  void playerInit() async {
    audioPlayer = AudioPlayer()
      ..setSourceDeviceFile(widget.recording.path)
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

class CalendaerCard extends StatelessWidget {
  const CalendaerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      decoration: BoxDecoration(
          color: CustomColors.fillNormal,
          border: Border.all(
            color: CustomColors.productBorderNormal,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: CustomColors.yellowDark,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                      child: Container(
                    alignment: Alignment.centerLeft,
                    child: const Icon(Icons.book_rounded,
                        size: 32, color: CustomColors.fillWhite),
                  )),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "1 diaries left this week",
                          style: CustomTypography()
                              .bodyLarge(color: CustomColors.fillWhite),
                        ),
                        Text(
                          "Great job!",
                          style: CustomTypography()
                              .bodyMedium(color: CustomColors.fillWhite),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                      child: Container(
                          alignment: Alignment.bottomRight,
                          child: const Icon(Icons.more_horiz_rounded,
                              color: CustomColors.fillWhite))),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                dayOfTheWeek("M", true),
                dayOfTheWeek("T", false),
                dayOfTheWeek("W", false),
                dayOfTheWeek("T", false),
                dayOfTheWeek("F", false),
                dayOfTheWeek("S", false),
                dayOfTheWeek("S", false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget dayOfTheWeek(String day, bool isToday) {
  return Column(
    children: [
      Text(
        day,
        style: CustomTypography().titleSmall(
          color: isToday
              ? CustomColors.yellowDark
              : CustomColors.textTertiaryContent,
        ),
      ),
      Container(
        height: 35,
        width: 35,
        padding: const EdgeInsets.only(right: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          //borderRadius: BorderRadius.circular(100),
          shape: BoxShape.circle,
          color: isToday
              ? CustomColors.yellowDark
              : CustomColors.productBorderNormal,
        ),
        child: isToday
            ? const Icon(
                CustomIcons.check,
                color: CustomColors.fillWhite,
                size: 13,
              )
            : const SizedBox.shrink(),
      ),
    ],
  );
}
