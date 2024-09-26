import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/notification_access.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/mic_tester.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rive/rive.dart';

import '../../../../services/preference_service.dart';
import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_icons.dart';
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
  bool canGoBack = false;

  @override
  void initState() {
    if (Navigator.of(context).canPop()) {
      canGoBack = true;
    }
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
          scrolledUnderElevation: 0.0,
          leading: canGoBack
              ? IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: CustomColors.fillWhite,
                    size: 32,
                  ))
              : null,
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          return Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 34.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraint) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraint.maxHeight),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    permission
                                        ? "Let's test your microphone, \"say something\""
                                        : "Great, next enable microphone access",
                                    style: CustomTypography().headlineLarge(
                                        color: CustomColors.textWhite),
                                  ),
                                  const SizedBox(height: 40.0),
                                  MicTester(
                                    permission: permission,
                                    width: width,
                                    recorder: recorder,
                                    request: () => _requestPermission(),
                                  ),
                                  const SizedBox(height: 24),
                                  requested == true && permission == false
                                      ? Container(
                                          width: width,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: CustomColors.warningFill,
                                            border: Border.all(
                                              color: CustomColors.warningActive,
                                              width: 2,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(11),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(CustomIcons.cancel,
                                                      size: 20,
                                                      color: CustomColors
                                                          .warningActive),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                      "Oops! You need to enable microphone access to use the recording diary.",
                                                      style: CustomTypography()
                                                          .bodyLarge(
                                                              color: CustomColors
                                                                  .warningActive),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(
                                                      height: 20, width: 20),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  TextButton(
                                                      style:
                                                          TextButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 4),
                                                        alignment:
                                                            Alignment.center,
                                                        backgroundColor:
                                                            CustomColors
                                                                .warningActive,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(11),
                                                        ),
                                                      ),
                                                      onPressed:
                                                          openPermissionSettings,
                                                      child: Text(
                                                          "Open Settings",
                                                          style: CustomTypography()
                                                              .bodyLarge(
                                                                  color: CustomColors
                                                                      .textWhite)))
                                                ],
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ],
                              ),
                              Visibility(
                                visible: permission,
                                replacement: SizedBox(
                                  height: 300,
                                  width: width,
                                  child: requested == true &&
                                          permission == false
                                      ? const RiveAnimation.asset(
                                          'assets/animations/onboarding/micaccess_denial.riv',
                                          fit: BoxFit.fitWidth)
                                      : const RiveAnimation.asset(
                                          'assets/animations/onboarding/micaccess.riv',
                                          fit: BoxFit.fitWidth),
                                ),
                                child: SizedBox(
                                  height: 300,
                                  width: width,
                                  child: const RiveAnimation.asset(
                                      'assets/animations/onboarding/micaccess_ongoing.riv',
                                      fit: BoxFit.fitWidth),
                                ),
                              ),
                            ]),
                      ),
                    ),
                  ),
                ),
                CustomFlatButton(
                  onClick: () => navigateToNextPage(),
                  text: permission ? "Continue" : "Continue",
                  color: CustomColors.fillWhite,
                  isDisabled: requested == true && permission == false,
                  textColor: CustomColors.productNormalActive,
                )
              ],
            ),
          );
        }));
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
    await PendoService.track("OnBoardingMicAccess", {"button": "continue"});
    setState(() {
      permission = results.isGranted;
    });
    await PendoService.track("OnBoardingMicAccess", {"state": results.name});
    if (permission) {
      if (requested) {
        await PreferenceService()
            .setBoolPreference(key: 'mic_requested', value: requested);
        if (context.mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const NotificationAccessPage()));
        }
      } else {
        startRecorder();
      }
    }

    if (mounted) requested = true;
  }

  void _requestPermission() async {
    await PendoService.track("OnBoardingMicAccess", {"button": "icon"});
    final results = await Permission.microphone.request();
    setState(() {
      permission = results.isGranted;
    });

    if (permission) startRecorder();

    if (mounted) requested = true;
  }

  void openPermissionSettings() async {
    bool opened = await openAppSettings();

    if (opened) {
      final results = await Permission.microphone.request();
      setState(() {
        permission = results.isGranted;
      });

      if (permission) startRecorder();
    }
  }
}
