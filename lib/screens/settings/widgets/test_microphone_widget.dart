import 'package:audio_diaries_flutter/screens/settings/widgets/settings_mic_test.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

import '../../../theme/custom_colors.dart';
import '../../../theme/custom_typography.dart';

class TestMicrophone extends StatefulWidget {
  const TestMicrophone({super.key});

  @override
  State<TestMicrophone> createState() => _TestMicrophoneState();
}

class _TestMicrophoneState extends State<TestMicrophone> {
  late FlutterSoundRecorder recorder;
  bool permission = false;
  bool requested = false;
  bool isRecording = false;

  @override
  void initState() {
    recorder = FlutterSoundRecorder();
    recorderInit();
    super.initState();
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 18.0),
        decoration: BoxDecoration(
          color: CustomColors.fillWhite,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          spacing: 12,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Your microphone access is fully set up. You can test the microphone before you start recording.",
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.64),
                  fontSize: 14,
                  fontFamily: 'Rubik',
                  fontWeight: FontWeight.w400,
                  height: 1.50,
                ),
              ),
            ),
            Divider(
              thickness: 0.5,
              height: 24,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final buttonWidth = isRecording
                      ? (constraints.maxWidth - 10) / 3
                      : constraints.maxWidth;
                  final waveformWidth = (constraints.maxWidth - 10) * 2 / 3;
              
                  return Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.fastOutSlowIn,
                        width: buttonWidth,
                        child: TextButton(
                          onPressed: () {
                            if (isRecording) {
                              stopRecorder();
                            } else {
                              startRecorder();
                            }
                          },
                          style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100)),
                              backgroundColor: CustomColors.productNormal),
                          child: Text(
                              isRecording ? "Stop Test" : "Test Microphone",
                              style: CustomTypography()
                                  .title(color: CustomColors.textWhite),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.clip),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.fastOutSlowIn,
                        clipBehavior: Clip.hardEdge,
                        child: isRecording
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: waveformWidth,
                                    child: SettingsMIcTest(recorder: recorder),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ));
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

  void startRecorder() async {
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/flutter_sound.aac';
    recorder.startRecorder(
        toFile: path, codec: Codec.aacADTS, sampleRate: 44100, bitRate: 48000);
    setState(() {
      isRecording = true;
    });
  }

  void stopRecorder() {
    recorder.stopRecorder();
    setState(() {
      isRecording = false;
    });
  }
}
