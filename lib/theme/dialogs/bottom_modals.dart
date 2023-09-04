import 'dart:io';

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/theme/components/waveform.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/formatter.dart';
import '../components/buttons.dart';
import '../custom_icons.dart';
import '../custom_typography.dart';
import 'pop_ups.dart';

final tabs = [
  Tab(
    child: SizedBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            const Icon(CustomIcons.graphicEq, size: 24),
            const SizedBox(
              width: 5,
            ),
            Text(
              "Audio",
              style: CustomTypography().bodyMedium(),
            )
          ],
        ),
      ),
    ),
  ),
  // Tab(
  //   child: SizedBox(
  //     child: Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 10),
  //       child: Row(
  //         children: [
  //           const Icon(
  //             Icons.sort,
  //             size: 24,
  //           ),
  //           const SizedBox(
  //             width: 5,
  //           ),
  //           Text(
  //             "Transcript",
  //             style: CustomTypography().bodyMedium(),
  //           )
  //         ],
  //       ),
  //     ),
  //   ),
  // ),
];

/// Bottom Modal for when the user needs to record.
class BottomRecordingModal extends StatefulWidget {
  final int promptId;
  final ValueChanged<String?>? onSave;

  const BottomRecordingModal(
      {super.key, required this.promptId, required this.onSave});

  @override
  State<BottomRecordingModal> createState() => _BottomRecordingModalState();
}

class _BottomRecordingModalState extends State<BottomRecordingModal>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  //Recording
  final FlutterSoundRecorder recorder = FlutterSoundRecorder();
  String timer = "00:00:00";
  RecorderState recorderState = RecorderState.isStopped;

  @override
  void initState() {
    recorderInit();
    tabController = TabController(length: tabs.length, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final contentHeight =
        screenHeight >= 850 ? screenHeight * 0.5 : screenHeight * 0.65;
    return Container(
      height: contentHeight,
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 30, bottom: 24),
              height: contentHeight - 100,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  )),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //Tab Indicator
                  tabIndicatos(),

                  const SizedBox(
                    height: 15,
                  ),

                  // Title & Rename Button
                  recordingTitle(),

                  const SizedBox(
                    height: 15,
                  ),

                  // Timer
                  recordingTimer(),

                  const SizedBox(
                    height: 24,
                  ),
                  // Waveform & Transcript
                  waveFormAndTranscript(),

                  const SizedBox(
                    height: 24,
                  ),

                  // Controls
                  recordingControls(),
                ],
              ),
            ),
          ),

          // Avatar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 19.86),
                    height: 150,
                    child: Image.asset("assets/images/avatar_listening.png"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget tabIndicatos() {
    return SizedBox(
      child: TabBar(
          isScrollable: true,
          controller: tabController,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorColor: Colors.transparent,
          labelColor: CustomColors.productNormalActive,
          unselectedLabelColor: CustomColors.textTertiaryContent,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: CustomColors.productLightPrimaryActive,
          ),
          padding: EdgeInsets.zero,
          indicatorPadding: EdgeInsets.zero,
          labelPadding: EdgeInsets.zero,
          tabs: tabs),
    );
  }

  Widget recordingTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "New Diary",
          style: CustomTypography().headlineMedium(),
        ),
        const SizedBox(
          width: 5,
        ),
        const IconButton(
            onPressed: null,
            icon: Icon(
              CustomIcons.editNote,
              size: 24,
            ))
      ],
    );
  }

  Widget recordingTimer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 15,
          width: 15,
          decoration: const BoxDecoration(
              color: CustomColors.warningActive, shape: BoxShape.circle),
        ),
        const SizedBox(
          width: 5,
        ),
        Text(
          timer,
          style: CustomTypography().bodyLarge(),
        )
      ],
    );
  }

  Widget waveFormAndTranscript() {
    final width = MediaQuery.of(context).size.width;
    return Expanded(
        child: TabBarView(
      physics: const NeverScrollableScrollPhysics(),
      controller: tabController,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final parentHeight = constraints.maxHeight;
          return CustomWaveform(
              recorder: recorder,
              maxVisibleValues: width ~/ 2,
              maxValue: parentHeight);
        }),

        /// Transcript
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 15),
        //   child: SingleChildScrollView(
        //       child: Text(
        //     Strings.lorem,
        //     style: CustomTypography().bodyMedium(),
        //   )),
        // ),
      ],
    ));
  }

  Widget recordingControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //Redo
          TextButton(
              onPressed: () async => {
                    await recorder.pauseRecorder(),
                    setState(() {
                      recorderState = RecorderState.isPaused;
                    }),
                    redo()
                  },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 9.5),
                child: Text("Redo",
                    style: CustomTypography()
                        .button(color: CustomColors.textSecondaryContent)),
              )),

          //Play Pause Resume

          switch (recorderState) {
            RecorderState.isStopped => IconButton(
                style: IconButton.styleFrom(
                  splashFactory: NoSplash.splashFactory,
                ),
                onPressed: () => record(),
                icon: Container(
                  height: 60,
                  width: 60,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: CustomColors.textTertiaryContent, width: 2)),
                  child: Container(
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: CustomColors.warningActive),
                  ),
                )),
            _ => Container(
                width: 150,
                child: IconButton(
                style: IconButton.styleFrom(
                  splashFactory: NoSplash.splashFactory,
                ),
                onPressed: () => record(),
                color: CustomColors.warningActive,

                icon: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 14.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: recorderState == RecorderState.isRecording
                          ? Colors.transparent
                          : CustomColors.warningFill,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                          color: recorderState == RecorderState.isRecording
                              ? CustomColors.textTertiaryContent
                              : CustomColors.warningActive,
                          width: 2),
                    ),
                    child: recorderState == RecorderState.isRecording
                        ? const Icon(Icons.pause_rounded, size: 24)
                        : Text(
                            "Resume",
                            style: CustomTypography()
                                .bodyLarge(color: CustomColors.warningActive),
                          )
                ),
              )
            ),
          },

          //Save
          TextButton(
              onPressed: () => {save(), Navigator.pop(context)},
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 9.5),
                child: Text("Save",
                    style: CustomTypography()
                        .button(color: CustomColors.textSecondaryContent)),
              )),
        ],
      ),
    );
  }

  void recorderInit() async {
    await recorder.openRecorder();
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    recorder.onProgress!.listen((event) {
      if (mounted) {
        setState(() {
          timer = formatDurationtoHHMMSS(event.duration);
        });
      }
    });
    await recorder.setSubscriptionDuration(const Duration(milliseconds: 150));
  }

  Future<void> redo() async {
    final showDialogResult = await showDialog<bool>(
      context: context,
      builder: (context) => const RedoPopUp(),
    );

    if (showDialogResult == true) {
      final stoppedRecorderValue = await recorder.stopRecorder();

      if (stoppedRecorderValue != null) {
        final file = File(stoppedRecorderValue);
        await file.delete();
      }

      await Future.delayed(const Duration(milliseconds: 150));
      record();
    }
  }

  Future<void> record() async {
    final hasPermission = await checkAndRequestPermission();
    if (hasPermission) {
      if (recorder.isRecording) {
        await recorder.pauseRecorder();
      } else if (recorder.isPaused) {
        await recorder.resumeRecorder();
      } else {
        final path = await getFilePath();
        await recorder.startRecorder(toFile: path);
      }

      setState(() {
        recorderState = recorder.isRecording
            ? RecorderState.isRecording
            : RecorderState.isPaused;
      });
    } else {
      /* TODO: Show Permission Error */ null;
    }
  }

  void save() async {
    try {
      final url = await recorder.stopRecorder();
      setState(() => recorderState = RecorderState.isStopped);

      if (url != null) {
        final file = await changeFileName(url);
        widget.onSave?.call(file.path);
      }
    } catch (e) {
      // TODO: Show Error
    }
  }

  Future<bool> checkAndRequestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String> getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final dir =
        await Directory(p.join(directory.path, widget.promptId.toString()))
            .create(recursive: true);
    final now = DateTime.now();
    final fileName = 'audio_prompt_${widget.promptId + 1}_${formatDate(now)}.aac';
    final filePath = p.join(dir.path, fileName);
    return filePath;
  }

  Future<File> changeFileName(String path) {
    final File file = File(path);

    String directory = p.dirname(file.path);
    String oldName = p.basenameWithoutExtension(file.path);

    String newName = '$oldName.mp3';
    String newPath = p.join(directory, newName);
    return file.rename(newPath);
  }
}

/// Bottom Modal for when the user has successfull answered a prompt.
class BottomSuccessModal extends StatelessWidget {
  final VoidCallback? onNextQuestionClicked;
  final String text;

  const BottomSuccessModal(
      {super.key, this.onNextQuestionClicked, required this.text});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      child: Container(
          constraints: const BoxConstraints.tightFor(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 34),
          width: width,
          decoration: const BoxDecoration(
            color: CustomColors.productLightBackground,
          ),
          child: Wrap(
            children: [
              Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          CustomIcons.checkCircle,
                          color: CustomColors.productNormalActive,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text("Great!",
                            style: CustomTypography().headlineMedium(
                                color: CustomColors.productNormalActive)),
                      ],
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      "Your response has been automatically saved.",
                      style: CustomTypography()
                          .body(color: CustomColors.productNormalActive),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: CustomElevatedButton(
                              onClick: () {
                                Navigator.pop(context);
                                onNextQuestionClicked?.call();
                              },
                              text: text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),
            ],
          )),
    );
  }
}

/// Bottom modal for error
class BottomErrorModal extends StatelessWidget {
  const BottomErrorModal({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      child: Container(
          constraints: const BoxConstraints.tightFor(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 34),
          width: width,
          decoration: const BoxDecoration(
            color: CustomColors.warningFill,
          ),
          child: Wrap(
            children: [
              Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          CustomIcons.cancel,
                          color: CustomColors.warningActive,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text("Error",
                            style: CustomTypography().headlineMedium(
                                color: CustomColors.warningActive)),
                      ],
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text("We didn’t detect your answer.",
                        style: CustomTypography()
                            .body(color: CustomColors.warningActive)),
                    const SizedBox(
                      height: 24,
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: CustomElevatedButton(
                            onClick: () => Navigator.pop(context),
                            text: "TRY AGAIN",
                            color: CustomColors.warningActive,
                            shadowColor: const Color(0xFFC72C1E),
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: CustomElevatedIconButton(
                            icon: Icons.help_outline_rounded,
                            onClick: null,
                            color: CustomColors.warningFill,
                            shadowColor: const Color(0xFFC72C1E),
                            iconColor: CustomColors.warningActive,
                            border: Border.all(
                                color: CustomColors.warningActive, width: 1),
                            elevation: 2.5,
                          ),
                        )
                      ],
                    ),
                  ]),
            ],
          )),
    );
  }
}
