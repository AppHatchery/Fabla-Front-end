import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/finish.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/mic_tester.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

class MicAccessPage extends StatefulWidget {
  const MicAccessPage({super.key});

  @override
  State<MicAccessPage> createState() => _MicAccessPageState();
}

class _MicAccessPageState extends State<MicAccessPage> {
  late FlutterSoundRecorder recorder;
  bool permission = false;
  bool requested = false;

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
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: CustomColors.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: CustomColors.backgroundSecondary,
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: CustomColors.fillWhite,
                size: 32,
              )),
        ),
        body: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 34.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                child: Column(children: [
                  Text(
                    "Let’s enable the microphone access.",
                    style: CustomTypography()
                        .headlineLarge(color: CustomColors.textWhite),
                  ),
                  const SizedBox(height: 16.0),
                  MicTester(
                    width: width,
                    recorder: recorder,
                  ),
                  const SizedBox(height: 24.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60.0),
                    child: Image.asset(
                      "assets/images/notification_example_ios.png",
                      width: width,
                    ),
                  ),
                ]),
              ),
              CustomElevatedButton(
                onClick: () => navigateToNextPage(),
                text: permission ? "CONTINUE" : "ALLOW",
                color: CustomColors.fillWhite,
                shadowColor: CustomColors.productBorderNormal,
                textColor: CustomColors.productNormalActive,
              )
            ],
          ),
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
  }

  void navigateToNextPage() async {
    final results = await Permission.microphone.request();
    setState(() {
      permission = results.isGranted;
    });
    if (permission) {
      if (requested) {
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const FinishPage()),
              (route) => false);
        }
      } else {
        startRecorder();
      }
    }
    requested = true;
  }
}
