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
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: CustomColors.fillWhite,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              "Your microphone access is fully set up. You can test the microphone before you start recording.",
              style: CustomTypography()
                  .bodyMedium(color: CustomColors.textTertiaryContent),
            ),
            const SizedBox(
              height: 12,
            ),
            SizedBox(
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      if (isRecording) {
                        stopRecorder();
                      } else {
                        startRecorder();
                      }
                    },
                    style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: CustomColors.productNormal),
                    child: Text(
                      isRecording ? "Stop Test" : "Test Microphone",
                      style: CustomTypography()
                          .title(color: CustomColors.textWhite),
                      textAlign: TextAlign.center
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Visibility(
                      visible: isRecording,
                      child: SettingsMIcTest(recorder: recorder),
                    ),
                  )
                ],
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
