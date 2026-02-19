import 'dart:async';
import 'dart:io';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:audio_diaries_flutter/core/usecases/video_image_thumbnail.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/recording.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/question_widgets.dart';
import 'package:audio_diaries_flutter/theme/components/waveform.dart';
import 'package:audio_diaries_flutter/theme/components/webview.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/overlays/keyboard_overlay.dart';
import 'package:audio_session/audio_session.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:rive/rive.dart' as r;
import 'package:video_player/video_player.dart';
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
  final Duration? suggested;
  final Duration? limit;
  final ValueChanged<String?>? onSave;
  final String? subtitle;

  const BottomRecordingModal(
      {super.key,
      required this.promptId,
      required this.onSave,
      required this.question,
      this.suggested,
      this.limit,
      this.hint,
      required this.subtitle});

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
  String? tempUrl;

  ScrollController scrollController = ScrollController();

  //Animation
  late r.StateMachineController _controller;
  double animationHeight = 0;

  void _onInit(r.Artboard art) {
    var ctrl = r.StateMachineController.fromArtboard(art, "Animation_12");
    if (ctrl != null) {
      art.addController(ctrl);
      _controller = ctrl;
    }
    setState(() {
      animationHeight = art.height;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setState(() {
        if (recorder.isRecording) {
          recorderState = RecorderState.isPaused;
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
    final textScaleFactor = MediaQuery.of(context).textScaler.scale(1.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: width,
        height: textScaleFactor >= 1.8
            ? MediaQuery.of(context).size.height * 1
            : textScaleFactor >= 1.2
                ? MediaQuery.of(context).size.height * .85
                : MediaQuery.of(context).size.height * .75,
        decoration: const BoxDecoration(
          color: Color(0xFFF3F3F3),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Close Modal Button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => {
                      Navigator.pop(context),
                    },
                    child: Icon(
                      CupertinoIcons.clear_circled_solid,
                      size: 32,
                      color: CustomColors.textSecondaryContent,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: questionAndHints()),
          ],
        ),
      ),
    );
  }

  Widget questionAndHints() {
    final width = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.of(context).textScaler.scale(1.0);
    final isCompleted =
        recorderState == RecorderState.isStopped && elapsed.inSeconds > 0;

    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.question,
                    style: CustomTypography()
                        .titleLarge(color: const Color(0xFF000000)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.subtitle ?? "",
                    style: CustomTypography().bodyLarge(
                      color: CustomColors.textNormalContent,
                      weight: FontWeight.w400,
                    ),
                  ),
                  _riveAnimation(),
                ],
              ),
            ),
          ),

          // Fixed bottom recording controls
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            color: CustomColors.productNormal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      recorderState == RecorderState.isPaused
                          ? "Resume Recording"
                          : recorderState == RecorderState.isRecording
                              ? "Recording"
                              : isCompleted
                                  ? "Save Recording"
                                  : "Start Recording",
                      style: CustomTypography().custom(
                        color: CustomColors.fillWhite,
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                SizedBox(height: 42, width: width, child: waveForm()),
                const SizedBox(height: 5),
                progressBar(),
                const SizedBox(height: 15),
                recordingControls(),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _riveAnimation() {
    final textScaleFactor = MediaQuery.of(context).textScaler.scale(1.0);
    return SizedBox(
      height: 150,
      child: IgnorePointer(
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            Color(0xFFACD3FC),
            BlendMode.modulate,
          ),
          child: Transform(
            transform: Matrix4.translationValues(
                -140, textScaleFactor >= 1.6 ? 0 : 20, 0)
              ..scale(-1.0, 1.0),
            alignment: Alignment.center,
            child: r.RiveAnimation.asset(
              'assets/animations/onboarding/floats_in.riv',
              fit: BoxFit.scaleDown,
              onInit: _onInit,
            ),
          ),
        ),
      ),
    );
  }

  Widget recordingTimer() {
    final text =
        widget.suggested != null && widget.suggested!.inMilliseconds > 0
            ? widget.suggested!
            : widget.limit != null && widget.limit!.inMilliseconds > 0
                ? widget.limit!
                : const Duration(minutes: 5);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          "$timer / ${formatDurationtoHHMMSS(text)}",
          style: CustomTypography().titleSmall(color: CustomColors.textWhite),
        )
      ],
    );
  }

  Widget progressBar() {
    // Calculate the total duration for the progress bar
    final totalDuration =
        widget.suggested != null && widget.suggested!.inMilliseconds > 0
            ? widget.suggested!
            : widget.limit != null && widget.limit!.inMilliseconds > 0
                ? widget.limit!
                : const Duration(minutes: 5);

    // Calculate progress as a percentage (0.0 to 1.0)
    final progress = totalDuration.inMilliseconds > 0
        ? (elapsed.inMilliseconds / totalDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            recordingTimer(),
          ],
        ),
        const SizedBox(height: 5),
        // Progress bar using LinearProgressIndicator
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(1.0),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: CustomColors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF56BB70)),
              minHeight: 17,
              borderRadius: BorderRadius.circular(6.5),
            ),
          ),
        ),
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

  Widget recordingControls() {
    final isCompleted = recorderState == RecorderState.isStopped &&
        elapsed.inSeconds > 0; // Completed by stop or timeout

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isCompleted) ...[
                // When stopped initially: Show mic
                if (recorderState == RecorderState.isStopped)
                  Container(
                    height: 68,
                    width: 68,
                    decoration: BoxDecoration(
                      color: CustomColors.fillWhite,
                      borderRadius: BorderRadius.circular(42),
                    ),
                    child: _buildControlButton(
                      icon: Icons.mic,
                      size: 34,
                      onPressed: () => record(),
                      color: CustomColors.warningActive,
                    ),
                  )
                else
                  // When recording or paused
                  ...[
                  SizedBox(
                      width: recorderState == RecorderState.isRecording
                          ? 90
                          : 130),
                  // Stop button
                  Container(
                    height: recorderState == RecorderState.isPaused ? 40 : 68,
                    width: recorderState == RecorderState.isPaused ? 40 : 68,
                    decoration: BoxDecoration(
                      color: CustomColors.fillWhite,
                      borderRadius: BorderRadius.circular(42),
                    ),
                    child: _buildControlButton(
                      icon: CupertinoIcons.stop_fill,
                      size: recorderState == RecorderState.isPaused ? 24 : 34,
                      onPressed: () => stop(),
                      color: CustomColors.warningActive,
                    ),
                  ),
                  const SizedBox(width: 50),
                  // Pause/Resume (right - swaps size)
                  Container(
                    height: recorderState == RecorderState.isPaused ? 68 : 40,
                    width: recorderState == RecorderState.isPaused ? 68 : 40,
                    decoration: BoxDecoration(
                      color: recorderState == RecorderState.isRecording
                          ? CustomColors.fillWhite
                          : CustomColors.warningActive,
                      borderRadius: BorderRadius.circular(42),
                    ),
                    child: _buildControlButton(
                      icon: recorderState == RecorderState.isPaused
                          ? Icons.mic
                          : CupertinoIcons.pause_fill,
                      color: recorderState == RecorderState.isPaused
                          ? CustomColors.fillWhite
                          : CustomColors.productNormal,
                      size: recorderState == RecorderState.isPaused ? 34 : 24,
                      onPressed: () => record(),
                    ),
                  ),
                ],
              ] else ...[
                // Checkmark button (left)
                SizedBox(width: 90),
                Container(
                  height: 68,
                  width: 68,
                  decoration: BoxDecoration(
                    color: CustomColors.fillWhite,
                    borderRadius: BorderRadius.circular(42),
                  ),
                  child: _buildControlButton(
                    icon: CupertinoIcons.checkmark_alt,
                    size: 34,
                    onPressed: () => save(),
                    color: CustomColors.productNormal,
                  ),
                ),
                const SizedBox(width: 50),
                // Redo button (right)
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: CustomColors.fillWhite,
                    borderRadius: BorderRadius.circular(42),
                  ),
                  child: Transform.rotate(
                    angle: -40 * pi / 180,
                    child: _buildControlButton(
                      icon: CupertinoIcons.refresh_bold,
                      size: 24,
                      onPressed: () => redo(),
                      color: CustomColors.productNormal,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required int size,
    required color,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: size.toDouble(),
        color: color,
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

    await recorder.setSubscriptionDuration(const Duration(milliseconds: 150));
  }

  void startTimer() {
    final limit = (widget.limit != null && widget.limit!.inSeconds > 0)
        ? widget.limit
        : null;
    _timer = Timer.periodic(const Duration(seconds: 1), (time) async {
      if (limit != null && elapsed >= limit) {
        await stop();
        save();
        return;
      }

      if (!mounted) return;

      setState(() {
        elapsed += const Duration(seconds: 1);
        timer = formatDurationtoHHMMSS(elapsed);
      });
    });
  }

  Future<void> stop() async {
    tempUrl = await recorder.stopRecorder();
    _timer?.cancel();
    setState(() {
      recorderState = RecorderState.isStopped;
    });
  }

  Future<void> redo() async {
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

        if (tempUrl != null) {
          final file = File(tempUrl!);
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
          recorderState = RecorderState.isStopped;
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
      _timer?.cancel();
      if (mounted) setState(() => recorderState = RecorderState.isStopped);

      if (tempUrl != null) {
        final file = File(tempUrl!);
        final name = basePath(file.path);
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
    final dir = await Directory(p.join(directory.path, 'audios'))
        .create(recursive: true);
    final now = DateTime.now();
    final fileName =
        'audio_prompt_${widget.promptId + 1}_${formatDate(now)}.aac';
    final filePath = p.join(dir.path, fileName);
    return filePath;
  }
}

String basePath(String path) {
  final parts = p.split(path);
  return parts.sublist(parts.length - 2).join(p.separator);
}

class BottomTextModal extends StatefulWidget {
  final PromptModel prompt;
  final String question;
  final String? hint;
  final int? index;
  final ValueChanged<String?>? onSave;
  final ScrollController scrollController;

  const BottomTextModal(
      {super.key,
      required this.prompt,
      required this.question,
      this.hint,
      required this.index,
      required this.onSave,
      required this.scrollController});

  @override
  State<BottomTextModal> createState() => _BottomTextModalState();
}

class _BottomTextModalState extends State<BottomTextModal>
    with WidgetsBindingObserver {
  late TextEditingController textController;
  late GlobalKey fieldKey;
  late FocusNode textFocusNode;

  late OverlayEntry? _overlayEntry;
  double keyboardHeight = 0;

  bool disabled = true;

  //Animation
  late r.StateMachineController _controller;

  void _onInit(r.Artboard art) {
    var ctrl = r.StateMachineController.fromArtboard(art, "Ghosts");

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
    textFocusNode = FocusNode();
    if (widget.index != null) {
      textController = TextEditingController(
          text: widget.prompt.answer?.response?.elementAtOrNull(widget.index!));
    } else {
      textController = TextEditingController();
    }
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
      final wasKeyboardVisible = keyboardHeight > 0;
      final isKeyboardVisible = size > 0;

      if (size > 0 && checkDevice()) {
        showOverlay(context);
      } else {
        hideOverlay();
      }

      setState(() {
        keyboardHeight = size;
      });

      if (!wasKeyboardVisible && isKeyboardVisible && textFocusNode.hasFocus) {
        _scrollToTextField();
      }
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

  void _scrollToTextField() {
    if (fieldKey.currentContext != null && mounted) {
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.scrollController.animateTo(
            widget.scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

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
        child: Column(
          children: [
            Expanded(
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
                        height: keyboardHeight > 0 ? keyboardHeight + 50 : 50),
                  ],
                ),
              ),
            ),
          ],
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
            child: r.RiveAnimation.asset(
              'assets/animations/ghosts.riv',
              onInit: _onInit,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          widget.hint != null && widget.hint!.isNotEmpty
              ? Text(
                  widget.hint!,
                  style: CustomTypography().body(),
                )
              : SizedBox.shrink(),
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
            focusNode: textFocusNode,
            controller: textController,
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
  const BottomWebViewModal(
      {super.key, required this.url, required this.respond});

  @override
  State<BottomWebViewModal> createState() => _BottomWebViewModalState();
}

class _BottomWebViewModalState extends State<BottomWebViewModal> {
  late DateTime start;
  late DateTime end;
  bool? completed = false;
  late String errorText;

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
              child: CustomWebViewWidget(
                url: widget.url,
                errorText: (value) => setState(() => errorText = value),
                onComplete: (value) {
                  setState(() {
                    completed = value;

                    if (completed == null) {
                      save();
                    }
                  });
                },
              ),
            ),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: CustomFlatButton(
              isDisabled: (completed == false),
              onClick: () => popUp(),
              text: "Continue",
            ),
          )
        ],
      ),
    );
  }

  popUp() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => CompletedPopUp(
        title: "Have you completed the survey?",
        onYes: (ctx) {
          save();
          Navigator.pop(ctx, true);
        },
        onSkip: (ctx) {
          errorText = "survey skipped";
          completed = null;
          save();
          Navigator.pop(ctx, true);
        },
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
    if (completed == null) {
      widget.respond("Item was skipped due to: $errorText");
      dev.log('${widget.respond} Item was skipped due to: $errorText');
    } else {
      widget.respond("Start: $start | End: $end");
      dev.log('${widget.respond} "Start: $start | End: $end" ');
    }
    Navigator.pop(context);
  }
}

class BottomCameraModal extends StatefulWidget {
  final void Function(String p, [String? type]) respond;
  final PromptModel prompt;
  final bool isImage;
  const BottomCameraModal(
      {super.key,
      required this.respond,
      required this.prompt,
      this.isImage = true});

  @override
  State<BottomCameraModal> createState() => _BottomCameraModalState();
}

class _BottomCameraModalState extends State<BottomCameraModal> {
  late CameraController controller;
  IconData flashIcon = CupertinoIcons.bolt_badge_a_fill;

  XFile? file;

  // Video Recording
  Timer? _timer;
  Duration elapsed = const Duration();
  // "" Playback
  VideoPlayerController? videoController;
  bool videoPlaying = false;

  double feedHeight = 0;
  double feedWidth = 0;

  double zoomScale = 1.0;
  double minZoom = 1.0;
  double maxZoom = 1.0;
  double baseScale = 1.0;

  int pointers = 0;

  bool isFullscreen = false;

  @override
  void initState() {
    controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
    );
    cameraInit();
    super.initState();
  }

  @override
  dispose() {
    controller.dispose();
    super.dispose();
  }

  //Animation
  late r.StateMachineController _controller;

  void _onInit(r.Artboard art) {
    var ctrl = r.StateMachineController.fromArtboard(art, "Ghosts");

    ctrl?.isActive = false;
    if (ctrl != null) {
      art.addController(ctrl);
      setState(() {
        _controller = ctrl;
      });

      Future.delayed(const Duration(milliseconds: 10), () {
        final searchingThree = _controller.findSMI('Searching_1');
        if (searchingThree != null && mounted) {
          searchingThree.value = true;
        }
      });
    }
  }

  cameraInit() async {
    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) {
        setState(() {
          if (controller.value.previewSize != null) {
            // Reversed for portrait
            feedWidth = controller.value.previewSize!.height / 3;
            feedHeight = controller.value.previewSize!.width / 3;
          }
        });
      }
      if (controller.value.hasError) {
        dev.log('Camera error ${controller.value.errorDescription}');
      }
    });
    try {
      await controller.initialize();
      await Future.wait([
        controller.getMinZoomLevel().then((value) => minZoom = value),
        controller.getMaxZoomLevel().then((value) => maxZoom = value)
      ]);
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          dev.log('You have denied camera access.');
        case 'CameraAccessDeniedWithoutPrompt':
          // iOS only
          dev.log('Please go to Settings app to enable camera access.');
        case 'CameraAccessRestricted':
          // iOS only
          dev.log('Camera access is restricted.');
        case 'AudioAccessDenied':
          dev.log('You have denied audio access.');
        case 'AudioAccessDeniedWithoutPrompt':
          // iOS only
          dev.log('Please go to Settings app to enable audio access.');
        case 'AudioAccessRestricted':
          // iOS only
          dev.log('Audio access is restricted.');
        default:
          dev.log(e.toString());
          break;
      }
    }
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
          if (!isFullscreen)
            const SizedBox(
              height: 32,
            ),
          // Close Modal Button
          if (!isFullscreen)
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
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isFullscreen)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.prompt.question,
                        style: CustomTypography().titleLarge(),
                      ),
                      const SizedBox(
                        height: 32,
                      ),
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: r.RiveAnimation.asset(
                          'assets/animations/ghosts.riv',
                          onInit: _onInit,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Text(
                        widget.prompt.subtitle ??
                            "Please chat about only one encounter. Got more to say? We'd love for you to take another entry.",
                        style: CustomTypography().body(),
                      ),
                    ],
                  ),
                ),
              if (!isFullscreen) SizedBox(height: 32),
              // Recording Controls
              Stack(
                children: [
                  Container(
                    width: width,
                    padding: const EdgeInsets.all(0),
                    color: CustomColors.productNormal,
                    child: Column(
                      children: [
                        if (!isFullscreen) const SizedBox(height: 16),
                        file != null ? preview() : cameraFeed(),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36.0),
                          child: file != null
                              ? playbackControls()
                              : widget.isImage
                                  ? pictureControls()
                                  : recordingControls(),
                        ),
                        if (!isFullscreen)
                          SizedBox(
                            height: screenHeight > 850 ? 36 : 24,
                          ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GestureDetector(
                        onTap: () {
                          // change the field view to full screen
                          if (mounted) {
                            if (isFullscreen) {
                              setState(() {
                                feedHeight =
                                    controller.value.previewSize!.width / 3;
                                feedWidth =
                                    controller.value.previewSize!.height / 3;
                                isFullscreen = false;
                              });
                            } else {
                              setState(() {
                                feedHeight = constraints.maxHeight - 30;
                                feedWidth = constraints.maxWidth;
                                isFullscreen = true;
                              });
                            }
                          }
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isFullscreen
                                ? CustomColors.fillWhite.withValues(alpha: 0.5)
                                : CustomColors.fillWhite,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFullscreen
                                ? Icons.close_fullscreen_rounded
                                : Icons.fullscreen_rounded,
                            size: 24,
                            color: CustomColors.productNormalActive,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget preview() {
    if (file != null) {
      final _file = File(file!.path);
      return Container(
        height: feedHeight,
        width: feedWidth,
        decoration: BoxDecoration(
          color: CustomColors.grey,
          border: GradientBoxBorder(
            gradient:
                LinearGradient(colors: [Color(0xFFABD0FE), Color(0xFF595EF2)]),
            width: 4,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: switch (widget.isImage) {
          true => Image.file(_file),
          false => videoController != null
              ? VideoPreview(controller: videoController!)
              : const SizedBox.shrink(),
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget cameraFeed() {
    return Container(
      width: feedWidth,
      height: feedHeight,
      decoration: BoxDecoration(
        color: CustomColors.grey,
        border: GradientBoxBorder(
          gradient:
              LinearGradient(colors: [Color(0xFFABD0FE), Color(0xFF595EF2)]),
          width: 4,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: controller.value.isInitialized
            ? Stack(
                children: [
                  Center(
                      child: SizedBox(
                          width: feedWidth,
                          height: feedHeight,
                          child: Listener(
                            onPointerDown: (_) => pointers++,
                            onPointerUp: (_) => pointers--,
                            child: CameraPreview(
                              controller,
                              child: LayoutBuilder(
                                  builder: (context, constraints) {
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onScaleStart: _handleScaleStart,
                                  onScaleUpdate: _handleScaleUpdate,
                                );
                              }),
                            ),
                          ))),

                  // Time
                  elapsed.inMilliseconds > 0
                      ? Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 9.0),
                            child: Container(
                              width: 90,
                              padding: EdgeInsets.symmetric(horizontal: 9),
                              decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                  color: controller.value.isRecordingPaused
                                      ? CustomColors.productNormal
                                      : CustomColors.warningActive),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    formatDurationtoHHMMSS(elapsed),
                                    style: CustomTypography().custom(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: CustomColors.textWhite),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink()
                ],
              )
            : SizedBox(
                height: feedHeight,
                width: feedWidth,
              ),
      ),
    );
  }

  Widget pictureControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 50),
        SizedBox(
          height: 64,
          width: 64,
          child: Material(
            color: Colors.transparent,
            child: Ink(
                decoration: BoxDecoration(
                    border: Border.all(color: CustomColors.fillWhite, width: 5),
                    borderRadius: BorderRadius.circular(68)),
                child: InkWell(
                  key: const Key("capture"),
                  splashColor: CustomColors.fillWhiteShade,
                  borderRadius: BorderRadius.circular(68),
                  onTap: () => capture(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                          color: CustomColors.fillWhite,
                          borderRadius: BorderRadius.circular(60)),
                    ),
                  ),
                )),
          ),
        ),
        GestureDetector(
          onTap: () => flip(),
          child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                  color: CustomColors.fillWhite,
                  borderRadius: BorderRadius.circular(68)),
              padding: const EdgeInsets.all(4),
              child: SizedBox(
                height: 45,
                width: 45,
                child: Center(
                  child: Icon(
                    CupertinoIcons.switch_camera_solid,
                    color: CustomColors.productNormal,
                    size: 25,
                  ),
                ),
              )),
        )
      ],
    );
  }

  Widget recordingControls() {
    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      width: width,
      height: 68,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //Pause
          Visibility(
              visible: controller.value.isRecordingVideo,
              replacement: const SizedBox(width: 50),
              child: GestureDetector(
                  onTap: () => pause(),
                  child: AnimatedContainer(
                      duration: Duration(milliseconds: 100),
                      height: controller.value.isRecordingPaused ? 68 : 50,
                      width: controller.value.isRecordingPaused ? 68 : 50,
                      decoration: BoxDecoration(
                          color: controller.value.isRecordingPaused
                              ? Colors.transparent
                              : CustomColors.fillWhite,
                          border: Border.all(
                              color: CustomColors.fillWhite, width: 4),
                          borderRadius: BorderRadius.circular(68)),
                      padding: const EdgeInsets.all(4),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 100),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                              scale: animation, child: child);
                        },
                        child: controller.value.isRecordingPaused
                            ? Container(
                                key: ValueKey(1),
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                    color: CustomColors.warningActive,
                                    borderRadius: BorderRadius.circular(60)),
                              )
                            : SizedBox(
                                key: ValueKey(2),
                                height: 50,
                                width: 50,
                                child: Icon(
                                  Icons.pause_rounded,
                                  color: CustomColors.warningActive,
                                  size: 30,
                                ),
                              ),
                      )))),

          //Record
          GestureDetector(
            onTap: () => record(),
            child: AnimatedContainer(
                duration: Duration(milliseconds: 100),
                height: controller.value.isRecordingPaused ? 50 : 64,
                width: controller.value.isRecordingPaused ? 50 : 64,
                decoration: BoxDecoration(
                    border: Border.all(color: CustomColors.fillWhite, width: 4),
                    borderRadius: BorderRadius.circular(68)),
                padding: EdgeInsets.all(controller.value.isRecordingPaused
                    ? 10
                    : controller.value.isRecordingVideo
                        ? 15
                        : 4),
                child: Container(
                  // height: controller.value.isRecordingPaused ? 42 : 50,
                  // width: controller.value.isRecordingPaused ? 42 : 50,
                  decoration: BoxDecoration(
                      color: CustomColors.warningActive,
                      shape: controller.value.isRecordingVideo
                          ? BoxShape.rectangle
                          : BoxShape.circle,
                      borderRadius: controller.value.isRecordingVideo
                          ? BorderRadius.circular(4)
                          : null),
                )),
          ),
          GestureDetector(
            onTap: () => flip(),
            child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                    color: CustomColors.fillWhite,
                    borderRadius: BorderRadius.circular(68)),
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  height: 45,
                  width: 45,
                  child: Center(
                    child: Icon(
                      CupertinoIcons.switch_camera_solid,
                      color: CustomColors.productNormal,
                      size: 25,
                    ),
                  ),
                )),
          )
        ],
      ),
    );
  }

  Widget playbackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 24,
      children: [
        GestureDetector(
          onTap: () => redo(),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: CustomColors.fillWhite),
            child: Icon(
              CupertinoIcons.arrow_uturn_left,
              color: CustomColors.productNormalActive,
            ),
          ),
        ),
        widget.isImage
            ? const SizedBox(
                height: 64,
                width: 64,
              )
            : GestureDetector(
                onTap: () => play(),
                child: Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: CustomColors.fillWhite),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: videoPlaying ? 0 : 4.0),
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
              ),
        GestureDetector(
          key: const Key("save"),
          onTap: () => save(),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: CustomColors.fillWhite),
            child: Icon(
              CupertinoIcons.checkmark_alt,
              color: CustomColors.productNormalActive,
            ),
          ),
        ),
      ],
    );
  }

  capture() async {
    if (controller.value.isTakingPicture) return;

    if (mounted) {
      final _file = await controller.takePicture();
      setState(() {
        file = _file;
      });
    }
  }

  _handleScaleStart(ScaleStartDetails details) {
    // Store the initial scale and focal point
    if (mounted) {
      setState(() {
        baseScale = zoomScale;
      });
    }
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (!controller.value.isInitialized || pointers != 2) {
      return;
    }

    // Update the zoom scale based on the pinch gesture
    zoomScale = (baseScale * details.scale).clamp(
      minZoom,
      maxZoom,
    );

    await controller.setZoomLevel(zoomScale);
  }

  Future<String> getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = await Directory(
            p.join(directory.path, widget.isImage ? 'images' : 'videos'))
        .create(recursive: true);
    final now = DateTime.now();
    final fileName =
        '${widget.prompt.id + 1}_${formatDate(now)}${widget.isImage ? ".jpg" : ".mp4"}';
    final filePath = p.join(dir.path, fileName);
    return filePath;
  }

  record() async {
    if (controller.value.isRecordingVideo) {
      stop();
      return;
    }

    await controller.startVideoRecording();
    startTimer();
  }

  // Used to play the video
  play() async {
    if (videoController?.value.isPlaying ?? false) {
      await videoController?.pause();
      if (mounted) {
        setState(() {
          videoPlaying = false;
        });
      }
    } else {
      await videoController?.play();
      if (mounted) {
        setState(() {
          videoPlaying = true;
        });
      }
    }
  }

  save() async {
    try {
      if (file != null) {
        final path = await getFilePath();
        await file!.saveTo(path);
        final name = basePath(path);
        widget.respond(name, widget.isImage ? "image" : "video");
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      dev.log(e.toString(), name: "Camera Modal - Save");
    }
  }

  redo() async {
    setState(() {
      file = null;
      elapsed = const Duration();
    });
  }

  pause() async {
    if (controller.value.isRecordingVideo &&
        !controller.value.isRecordingPaused) {
      await controller.pauseVideoRecording();
      if (mounted) {
        setState(() {
          stopTimer();
        });
      }
      return;
    }

    await controller.resumeVideoRecording();
    setState(() {
      startTimer();
    });
  }

  stop() async {
    stopTimer();
    final _file = await controller.stopVideoRecording();
    if (mounted) {
      setState(() {
        file = _file;
        videoController = VideoPlayerController.file(File(_file.path));
        videoController?.addListener(() {
          if (mounted) {
            setState(() {
              videoPlaying = videoController?.value.isPlaying ?? false;
            });
          }
        });
      });
    }
  }

  flip() async {
    final currentLensDirection = controller.description.lensDirection;
    CameraDescription lens = cameras[0];

    for (final camera in cameras) {
      if (camera.lensDirection != currentLensDirection) {
        lens = camera;
        break;
      }
    }

    controller.setDescription(lens);
  }

  flash() async {
    final flashes = [FlashMode.auto, FlashMode.always, FlashMode.off];
    final current = controller.value.flashMode;

    // Get the index of the current mode
    int currentIndex = flashes.indexOf(current);

    // Calculate the next index (looping back to 0 if at the end)
    int nextIndex = (currentIndex + 1) % flashes.length;

    final mode = flashes[nextIndex];

    // Set new flash
    try {
      await controller.setFlashMode(mode);
    } catch (e) {
      dev.log("Problem setting flash: $e");
    }

    switch (mode) {
      case FlashMode.auto:
        setState(() {
          flashIcon = CupertinoIcons.bolt_badge_a_fill;
        });
        break;
      case FlashMode.always:
        setState(() {
          flashIcon = CupertinoIcons.bolt_fill;
        });
        break;
      case FlashMode.off:
        setState(() {
          flashIcon = CupertinoIcons.bolt_slash_fill;
        });
        break;
      default:
        setState(() {
          flashIcon = CupertinoIcons.bolt;
        });
        break;
    }
  }

  startTimer() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (value) {
      if (mounted) {
        setState(() {
          elapsed = const Duration(seconds: 1) + elapsed;
        });
      }
    });
  }

  stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  pauseTimer() {
    _timer?.cancel();
  }
}

class VideoPreview extends StatefulWidget {
  final VideoPlayerController controller;
  const VideoPreview({super.key, required this.controller});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  // Slider
  double max = 0.0;
  double current = 0.0;
  Duration maxDuration = const Duration();
  Duration remaining = const Duration();
  Duration elapsed = const Duration();

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: widget.controller.value.aspectRatio,
            child: VideoPlayer(widget.controller),
          ),
        ),
        Positioned(
          bottom: 15,
          left: 8,
          right: 8,
          child: SizedBox(
              child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //Elapsed
                  Text(
                    formatDurationtoHHMMSS(elapsed),
                    style: CustomTypography()
                        .bodyMedium(color: CustomColors.textWhite),
                  ),
                  //Remaining
                  Text(
                    formatDurationtoHHMMSS(remaining),
                    style: CustomTypography()
                        .bodyMedium(color: CustomColors.textWhite),
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
    );
  }

  init() async {
    widget.controller.addListener(() {
      if (mounted) {
        setState(() {
          current = widget.controller.value.position.inMilliseconds.toDouble();
          elapsed = widget.controller.value.position;
          remaining = maxDuration - elapsed;
        });
      }
    });
    widget.controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          max = widget.controller.value.duration.inMilliseconds.toDouble();
          maxDuration = widget.controller.value.duration;
          remaining = maxDuration;
        });
      }
    });
  }

  seek(double value) async {
    await widget.controller.seekTo(Duration(milliseconds: value.toInt()));
  }
}

class BottomUpdateModal extends StatefulWidget {
  final ValueNotifier<bool?> completeNotifier;
  const BottomUpdateModal({super.key, required this.completeNotifier});

  @override
  State<BottomUpdateModal> createState() => _BottomUpdateModalState();
}

class _BottomUpdateModalState extends State<BottomUpdateModal> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      height: 300,
      width: width,
      decoration: const BoxDecoration(
        color: CustomColors.fillWhite,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14), topRight: Radius.circular(14)),
      ),
      child: ValueListenableBuilder(
          valueListenable: widget.completeNotifier,
          builder: (context, complete, _) {
            return Column(
              spacing: 24,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Text(
                    complete == null
                        ? "Updating Experiment \nContent"
                        : complete
                            ? "Experiment Content \nUpdated"
                            : "Content Update \nFailed",
                    style: CustomTypography().headlineMedium(),
                    textAlign: TextAlign.center,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Text(
                    complete == null
                        ? "Hang tight! We're updating the experiment content. This won’t take long!"
                        : complete
                            ? "Content Update Complete!"
                            : "Please check your internet connection and try again.",
                    style: CustomTypography().bodyMedium(),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Progress

                SizedBox(
                  height: 30,
                  width: 30,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: complete == null
                        ? CircularProgressIndicator(
                            key: ValueKey(1), // Unique key for transition
                            color: CustomColors.productNormal,
                            strokeCap: StrokeCap.round,
                          )
                        : complete
                            ? Center(
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  key: ValueKey(2), // Unique key for transition
                                  color: CustomColors.darkGreen,
                                  size: 32,
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.cancel_rounded,
                                  key: ValueKey(3), // Unique key for transition
                                  color: CustomColors.warningActive,
                                  size: 32,
                                ),
                              ),
                  ),
                ),
              ],
            );
          }),
    );
  }
}

class ViewAllMediaModal extends StatefulWidget {
  final List<Recording> recordings;
  final bool interactions;
  final Function(String path) delete;
  const ViewAllMediaModal(
      {super.key,
      required this.recordings,
      this.interactions = true,
      required this.delete});

  @override
  State<ViewAllMediaModal> createState() => _ViewAllMediaModalState();
}

class _ViewAllMediaModalState extends State<ViewAllMediaModal> {
  List<Recording> recordings = [];

  @override
  void initState() {
    recordings = widget.recordings;
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
          Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 8),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (int i = 0; i < widget.recordings.length; i++)
                    widget.recordings[i].type == 'video'
                        ? videoPreviewTile(widget.recordings[i].path)
                        : previewTile(widget.recordings[i].path)
                ],
              ))
        ],
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
                                onTap: () => deleteRecording(path),
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
                                onTap: () => deleteRecording(path),
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

  void deleteRecording(String path) {
    widget.delete(path);
    setState(() {
      recordings.removeWhere((element) => element.path == path);
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
}

class BottomTimerModal extends StatefulWidget {
  final Duration remaining;
  final bool isRunning;
  final bool isPaused;
  final bool showTimeUpOverlay;
  final bool playbackControls;
  final VoidCallback onClose;
  final VoidCallback onRestart;
  final VoidCallback onPauseResume;
  final VoidCallback onStop;

  const BottomTimerModal({
    super.key,
    required this.remaining,
    required this.isRunning,
    required this.isPaused,
    required this.showTimeUpOverlay,
    required this.playbackControls,
    required this.onClose,
    required this.onRestart,
    required this.onPauseResume,
    required this.onStop,
  });

  @override
  State<BottomTimerModal> createState() => _BottomTimerModalState();
}

class _BottomTimerModalState extends State<BottomTimerModal>
    with TickerProviderStateMixin {
  double animationHeight = 0;
  // Icon Shake animation
  late AnimationController _shakeController;
  r.StateMachineController? _controller;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.repeat();
        }
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onRiveInit(r.Artboard art) {
    var ctrl = r.StateMachineController.fromArtboard(art, "Animation_12");
    if (ctrl != null) {
      art.addController(ctrl);
      _controller = ctrl;
    }
    setState(() {
      animationHeight = art.height;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _mainArea();
  }

  Widget _mainArea() {
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff4186F5), Color(0xff626AD9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        image: DecorationImage(
          image: AssetImage('assets/images/Meditation_timer_background.png'),
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildTimerDisplay(),
          SizedBox(height: 81),
          _buildRiveAnimation(),
          _buildTimerControls(),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textScale = MediaQuery.of(context).textScaler.scale(1);

    // Positioning: proportional + text scaling
    final double topPos = (screenHeight * 0.12) * (textScale > 1 ? 0.8 : 1);
    final double sidePadding = screenWidth * 0.07;

    // Icon size: scales but capped
    final double iconSize = 32;

    return Positioned(
      top: topPos,
      left: sidePadding,
      right: sidePadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.showTimeUpOverlay
              ? SizedBox.shrink()
              : Image.asset(
                  'assets/images/icons/pace.png',
                  height: iconSize,
                  width: iconSize,
                ),
          SizedBox(width: 8), // spacing proportional to width
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown, // prevents clipping if space is tight
              child: Text(
                widget.showTimeUpOverlay
                    ? "Time's Up!"
                    : formatMinsAndSecs(widget.remaining),
                textAlign: TextAlign.center,
                style: CustomTypography()
                    .custom(
                      color: CustomColors.textWhite,
                      fontWeight: FontWeight.w400,
                      fontSize: 48,
                    )
                    .copyWith(
                      fontFeatures: widget.showTimeUpOverlay
                          ? []
                          : [const FontFeature.tabularFigures()],
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiveAnimation() {
    return Positioned(
      top: 257,
      bottom: 154.37,
      right: 50,
      child: IgnorePointer(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Transform(
            transform: Matrix4.translationValues(5, -animationHeight / 5, 0)
              ..scale(-1.7,
                  1.7), // Scale up by 1.5x and flip horizontally with negative x
            alignment: Alignment.center,
            child: r.RiveAnimation.asset(
              'assets/animations/onboarding/floats_in.riv',
              fit: BoxFit.contain,
              onInit: _onRiveInit,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: widget.playbackControls || widget.showTimeUpOverlay
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          width: 2,
                          color: CustomColors.fillWhite,
                        ),
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: CustomColors.fillWhite,
                      ),
                    ),
                  ),
                  SizedBox(width: 37),
                  if (widget.playbackControls || widget.showTimeUpOverlay) ...[
                    GestureDetector(
                      onTap: widget.showTimeUpOverlay
                          ? widget.onStop
                          : widget.onPauseResume,
                      child: Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 5),
                        decoration: BoxDecoration(
                            color: CustomColors.fillWhite,
                            border: Border.all(
                              color: CustomColors.productLightBackground,
                            ),
                            shape: BoxShape.circle),
                        child: Center(
                          child: widget.showTimeUpOverlay
                              ? Transform.translate(
                                  offset: Offset(
                                      3, 0), // Shift checkmark slightly right
                                  child: Icon(
                                    CupertinoIcons.checkmark_alt,
                                    size: 40,
                                    color: CustomColors.productNormal,
                                  ),
                                )
                              : (widget.isRunning && !widget.isPaused)
                                  ? Icon(
                                      CupertinoIcons.pause_fill,
                                      size: 40,
                                      color: CustomColors.warningActive,
                                    )
                                  : Transform.translate(
                                      offset: Offset(4,
                                          0), // Shift play icon slightly right
                                      child: Icon(
                                        CupertinoIcons.play_fill,
                                        size: 40,
                                        color: CustomColors.productNormal,
                                      ),
                                    ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(width: 37),
                  widget.playbackControls
                      ? GestureDetector(
                          onTap: widget.onRestart,
                          child: Container(
                            width: 64,
                            height: 64,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 5),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(
                                width: 2,
                                color: CustomColors.productLightBackground,
                              ),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Icon(
                              Icons.refresh_rounded,
                              size: 24,
                              color: CustomColors.fillWhite,
                            ),
                          ),
                        )
                      : SizedBox(width: 64, height: 64),
                ],
              )
            : GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 64,
                  height: 64,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      width: 2,
                      color: CustomColors.fillWhite,
                    ),
                    borderRadius: BorderRadius.circular(100.0),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 24,
                    color: CustomColors.fillWhite,
                  ),
                ),
              ),
      ),
    );
  }
}
