import 'dart:async';
import 'dart:io';

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/theme/components/waveform.dart';
import 'package:audio_diaries_flutter/theme/components/webview.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/overlays/keyboard_overlay.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:rive/rive.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/utils/formatter.dart';
import '../components/buttons.dart';
import '../custom_icons.dart';
import '../custom_typography.dart';
import 'pop_ups.dart';

/// Bottom Modal for when the user needs to record.
class BottomRecordingModal extends StatefulWidget {
  final int promptId;
  final String question;
  final String? hint;
  final ValueChanged<String?>? onSave;

  const BottomRecordingModal(
      {super.key,
      required this.promptId,
      required this.onSave,
      required this.question,
      this.hint});

  @override
  State<BottomRecordingModal> createState() => _BottomRecordingModalState();
}

class _BottomRecordingModalState extends State<BottomRecordingModal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  //Recording
  final FlutterSoundRecorder recorder = FlutterSoundRecorder();
  String timer = "00:00";
  Timer? _timer;
  Duration elapsed = const Duration();
  RecorderState recorderState = RecorderState.isStopped;
  final ValueNotifier<bool> _erase = ValueNotifier<bool>(false);

  ScrollController scrollController = ScrollController();

  //Animation
  late StateMachineController _controller;

  void _onInit(Artboard art) {
    var ctrl = StateMachineController.fromArtboard(art, "Ghosts");

    ctrl?.isActive = false;
    if (ctrl != null) {
      art.addController(ctrl);
      setState(() {
        _controller = ctrl;
      });

      Future.delayed(const Duration(milliseconds: 10), () {
        final searchingThree = _controller.findSMI('Searching_3');
        if (searchingThree != null && mounted) {
          searchingThree.value = true;
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setState(() {
        recorderState = RecorderState.isPaused;
        if (recorder.isRecording) {
          WakelockPlus.disable();
          recorder.pauseRecorder();
          _timer?.cancel();
        }
      });
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void initState() {
    recorderInit();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    _controller.dispose();
    scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F3F3),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14), topRight: Radius.circular(14)),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 32,
          ),
          // Close Modal Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    CupertinoIcons.clear_circled_solid,
                    size: 26,
                    color: CustomColors.textSecondaryContent,
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: questionAndHints(),
          ),
        ],
      ),
    );
  }

  Widget questionAndHints() {
    final width = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        controller: scrollController,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.question,
                      style: CustomTypography().titleLarge(),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: RiveAnimation.asset(
                        'assets/animations/ghosts.riv',
                        onInit: _onInit,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Text(
                      widget.hint ??
                          "Please chat about only one encounter. Got more to say? We'd love for you to take another entry.",
                      style: CustomTypography().body(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight > 750 ? 70 : 32),
              // Recording Controls
              Container(
                width: width,
                padding: const EdgeInsets.all(32),
                color: CustomColors.productNormal,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    recordingTimer(),
                    SizedBox(
                      height: screenHeight > 850 ? 36 : 24,
                    ),
                    SizedBox(
                      height: 42,
                      width: width,
                      child: waveForm(),
                    ),
                    SizedBox(
                      height: screenHeight > 850 ? 36 : 24,
                    ),
                    recordingControls(screenHeight),
                    SizedBox(
                      height: screenHeight > 850 ? 36 : 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget recordingTimer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          "$timer / 5:00",
          style: CustomTypography().titleMedium(color: CustomColors.textWhite),
        )
      ],
    );
  }

  Widget waveForm() {
    final width = MediaQuery.of(context).size.width;

    return CustomWaveform(
      recorder: recorder,
      maxVisibleValues: width ~/ 2,
      maxValue: 40,
      color: CustomColors.fillWhite,
      onErase: _erase,
    );
  }

  Widget recordingControls(double height) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => record(),
              child: Container(
                  height: 68,
                  width: 68,
                  decoration: BoxDecoration(
                      color: CustomColors.fillWhite,
                      borderRadius: BorderRadius.circular(68)),
                  padding: const EdgeInsets.all(4),
                  child: recorderState == RecorderState.isStopped
                      ? Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                              color: CustomColors.warningActive,
                              borderRadius: BorderRadius.circular(60)),
                        )
                      : Center(
                          child: Icon(
                            recorderState == RecorderState.isRecording
                                ? CupertinoIcons.pause_fill
                                : CupertinoIcons.play_fill,
                            color: CustomColors.warningActive,
                            size: 24,
                          ),
                        )),
            )
          ],
        ),
        SizedBox(
          height: height > 850 ? 36 : 24,
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _timer != null ? 1 : 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => redo(),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                      color: CustomColors.fillWhite,
                      borderRadius: BorderRadius.circular(42)),
                  child: const Center(
                      child: Icon(
                    CupertinoIcons.arrow_uturn_left,
                    color: CustomColors.productNormal,
                  )),
                ),
              ),
              const SizedBox(
                width: 68,
              ),
              GestureDetector(
                onTap: () => save(),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                      color: CustomColors.fillWhite,
                      borderRadius: BorderRadius.circular(42)),
                  child: const Center(
                      child: Icon(
                    CupertinoIcons.checkmark_alt,
                    color: CustomColors.productNormal,
                  )),
                ),
              ),
            ],
          ),
        )
      ],
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

    await recorder.setSubscriptionDuration(const Duration(milliseconds: 150));
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (time) {
      if (mounted) {
        setState(() {
          elapsed = const Duration(seconds: 1) + elapsed;
          timer = formatDurationtoHHMMSS(elapsed);
        });
      }
    });
  }

  Future<void> redo() async {
    await recorder.pauseRecorder();
    _timer?.cancel();

    if (mounted) {
      final showDialogResult = await showDialog<bool>(
        context: context,
        builder: (context) => const RedoPopUp(),
      );

      if (showDialogResult == true) {
        if (mounted) {
          setState(() {
            elapsed = const Duration();
            timer = "00:00";
            _erase.value = !_erase.value;
          });
        }
        final stoppedRecorderValue = await recorder.stopRecorder();

        if (stoppedRecorderValue != null) {
          final file = File(stoppedRecorderValue);
          await file.delete();
        }

        await Future.delayed(const Duration(milliseconds: 150));
        record();

        if (mounted) {
          setState(() {
            _erase.value = !_erase.value;
          });
        }
      } else {
        setState(() {
          recorderState = RecorderState.isPaused;
        });
      }
    }
  }

  Future<void> record() async {
    final hasPermission = await checkAndRequestPermission();
    //Check if scroll controller is already at the bottom
    if (mounted) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeIn,
      );
    }

    if (hasPermission) {
      WakelockPlus.enable();
      if (recorder.isRecording) {
        WakelockPlus.disable();
        await recorder.pauseRecorder();
        _timer?.cancel();
      } else if (recorder.isPaused) {
        WakelockPlus.enable();
        await recorder.resumeRecorder();
        startTimer();
      } else {
        final path = await getFilePath();
        await recorder.startRecorder(toFile: path);
        startTimer();
      }

      if (mounted) {
        setState(() {
          recorderState = recorder.isRecording
              ? RecorderState.isRecording
              : RecorderState.isPaused;
        });
      }
    } else {
      /* TODO: Show Permission Error */ null;
    }
  }

  void save() async {
    WakelockPlus.disable();
    try {
      final url = await recorder.stopRecorder();
      _timer?.cancel();
      if (mounted) setState(() => recorderState = RecorderState.isStopped);

      if (url != null) {
        final file = await changeFileName(url);
        final name = p.basename(file.path);
        widget.onSave?.call(name);
        if (mounted) Navigator.pop(context);
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
    final dir = await Directory(p.join(directory.path, 'recordings'))
        .create(recursive: true);
    final now = DateTime.now();
    final fileName =
        'audio_prompt_${widget.promptId + 1}_${formatDate(now)}.aac';
    final filePath = p.join(dir.path, fileName);
    return filePath;
  }

  Future<File> changeFileName(String path) {
    final File file = File(path);

    String directory = p.dirname(file.path);
    String oldName = p.basenameWithoutExtension(file.path);

    String newName = '$oldName.aac';
    String newPath = p.join(directory, newName);
    return file.rename(newPath);
  }
}

class BottomTextModal extends StatefulWidget {
  final PromptModel prompt;
  final String question;
  final String? hint;
  final ValueChanged<String?>? onSave;
  final ScrollController scrollController;

  const BottomTextModal(
      {super.key,
      required this.prompt,
      required this.question,
      this.hint,
      required this.onSave,
      required this.scrollController});

  @override
  State<BottomTextModal> createState() => _BottomTextModalState();
}

class _BottomTextModalState extends State<BottomTextModal>
    with WidgetsBindingObserver {
  late TextEditingController textController;
  late GlobalKey fieldKey;

  late OverlayEntry? _overlayEntry;
  double keyboardHeight = 0;

  bool disabled = true;

  //Animation
  late StateMachineController _controller;

  void _onInit(Artboard art) {
    var ctrl = StateMachineController.fromArtboard(art, "Ghosts");

    ctrl?.isActive = false;
    if (ctrl != null) {
      art.addController(ctrl);
      setState(() {
        _controller = ctrl;
      });

      Future.delayed(const Duration(milliseconds: 10), () {
        final searchingOne = _controller.findSMI('Searching_1');
        if (searchingOne != null && mounted) {
          searchingOne.value = true;
        }
      });
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    textController =
        TextEditingController(text: widget.prompt.answer?.response);
    textController.addListener(() {
      if (mounted) {
        setState(() {
          disabled = textController.text.isEmpty;
        });
      }
    });
    if (mounted) {
      setState(() {
        disabled = textController.text.isEmpty;
      });
    }
    fieldKey = GlobalKey();
    _overlayEntry = null;
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    textController.dispose();
    _controller.dispose();
    hideOverlay();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) {
      final size = View.of(context).viewInsets.bottom;
      if (size > 0 && checkDevice()) {
        showOverlay(context);
      } else {
        hideOverlay();
      }

      setState(() {
        keyboardHeight = size;
      });
    }
    super.didChangeMetrics();
  }

  bool checkDevice() {
    if (Platform.isIOS) {
      return true;
    }
    return false;
  }

  showOverlay(BuildContext context) {
    if (_overlayEntry != null) return;
    OverlayState overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 0,
            right: 0,
            child: const CustomKeyboardOverlay()));
    overlayState.insert(_overlayEntry!);
  }

  hideOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: screenHeight * 0.95,
        width: width,
        decoration: const BoxDecoration(
          color: Color(0xFFF3F3F3),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14), topRight: Radius.circular(14)),
        ),
        child: SingleChildScrollView(
          controller: widget.scrollController,
          child: Column(
            children: [
              questionAndHints(),

              const SizedBox(
                height: 16,
              ),
              // Text controls
              responseField(),

              SizedBox(
                height: keyboardHeight * 0.65,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget questionAndHints() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 26,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  CupertinoIcons.clear_circled_solid,
                  size: 26,
                  color: CustomColors.textSecondaryContent,
                ),
              )
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            widget.question,
            style: CustomTypography().titleLarge(),
          ),
          const SizedBox(
            height: 32,
          ),
          SizedBox(
            height: 100,
            width: 100,
            child: RiveAnimation.asset(
              'assets/animations/ghosts.riv',
              onInit: _onInit,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            widget.hint ??
                "Please chat about only one encounter. Got more to say? We'd love for you to take another entry.",
            style: CustomTypography().body(),
          ),
          const SizedBox(
            height: 16,
          ),
          // CustomOutlineButton(
          //   onClick: () => {},
          //   color: CustomColors.productNormal,
          //   backgroundColor: CustomColors.fillWhite,
          //   children: Wrap(
          //     crossAxisAlignment: WrapCrossAlignment.center,
          //     children: [
          //       Text(
          //         "Try A Hint",
          //         style: CustomTypography()
          //             .button(color: CustomColors.productNormal),
          //       ),
          //       const SizedBox(width: 8),
          //       Image.asset(
          //         "assets/images/star.png",
          //         height: 16,
          //         width: 16,
          //       )
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget responseField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: fieldKey,
            controller: textController,
            onTap: () {
              Scrollable.ensureVisible(fieldKey.currentContext!);
            },
            maxLines: 5,
            cursorColor: CustomColors.productNormal,
            style: CustomTypography().bodyLarge(),
            decoration: InputDecoration(
              hintText: "Type your response here",
              hintStyle: CustomTypography()
                  .bodyLarge(color: CustomColors.textSecondaryContent),
              enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                      width: 1, color: CustomColors.productBorderNormal),
                  borderRadius: BorderRadius.circular(11)),
              border: OutlineInputBorder(
                  borderSide: const BorderSide(
                      width: 1, color: CustomColors.productBorderNormal),
                  borderRadius: BorderRadius.circular(11)),
              contentPadding: const EdgeInsets.all(16),
              fillColor: CustomColors.fillWhite,
              filled: true,
              focusColor: CustomColors.productBorderActive,
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                    width: 1, color: CustomColors.productBorderActive),
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          CustomOutlineButton(
              onClick: () => {
                    if (!disabled)
                      {
                        widget.onSave?.call(textController.text),
                        Navigator.pop(context)
                      }
                  },
              color: !disabled
                  ? CustomColors.textWhite
                  : CustomColors.fillDisabled,
              backgroundColor: !disabled
                  ? CustomColors.productNormal
                  : CustomColors.fillDisabled,
              children: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    "OK",
                    style: CustomTypography().button(
                        color: !disabled
                            ? CustomColors.textWhite
                            : CustomColors.greyDark),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Icon(
                    CupertinoIcons.checkmark_alt,
                    color: !disabled
                        ? CustomColors.textWhite
                        : CustomColors.greyDark,
                    size: 20,
                  )
                ],
              ))
        ],
      ),
    );
  }
}

/// Bottom Modal for when the user has successfull answered a prompt.
class BottomSuccessModal extends StatelessWidget {
  final VoidCallback? onNextQuestionClicked;
  final VoidCallback? previousPage;
  final String text;

  const BottomSuccessModal(
      {super.key,
      this.previousPage,
      this.onNextQuestionClicked,
      required this.text});

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
                        CustomElevatedIconButton(
                          onClick: () {
                            Navigator.pop(context);
                            previousPage?.call();
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
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: CustomFlatButton(
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
                            text: "Try Again",
                            color: CustomColors.warningActive,
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

class BottomWebViewModal extends StatefulWidget {
  final String url;
  final void Function(String) respond;
  const BottomWebViewModal({super.key, required this.url, required this.respond});

  @override
  State<BottomWebViewModal> createState() => _BottomWebViewModalState();
}

class _BottomWebViewModalState extends State<BottomWebViewModal> {
  late DateTime start;
  late DateTime end;

  @override
  void initState() {
    start = DateTime.now();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F3F3),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14), topRight: Radius.circular(14)),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 26,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => exit(),
                  child: const Icon(
                    CupertinoIcons.clear_circled_solid,
                    size: 26,
                    color: CustomColors.textSecondaryContent,
                  ),
                )
              ],
            ),
          ),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              width: width,
              color: CustomColors.greyTrack,
              child: CustomWebViewWidget(url: widget.url),
            ),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: CustomFlatButton(onClick: () => save(), text: "Finish Survey"),
          )
        ],
      ),
    );
  }

  exit() async {
    final results = await showDialog<bool>(
        context: context,
        builder: (context) => ExitPopUp(
              title: "Exit Survey?",
              subheader: "If you exit, your progress will not be saved.",
            ));
    if (results == true && mounted) Navigator.pop(context);
  }

  save() {
    end = DateTime.now();
    widget.respond("Start: $start | End: $end");
    Navigator.pop(context);
  }
}
