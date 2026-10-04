import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class VideoLoadingIndicator extends StatefulWidget {
  const VideoLoadingIndicator({super.key});

  @override
  State<VideoLoadingIndicator> createState() => _VideoLoadingIndicatorState();
}

class _VideoLoadingIndicatorState extends State<VideoLoadingIndicator> {
  File? _riveFile;
  RiveWidgetController? _riveController;

  Future<void> _initAnimation() async {
    final riveFile = await File.asset(
        "assets/animations/fabla_video_loader.riv",
        riveFactory: Factory.rive);
    if (riveFile == null || !mounted) return;

    setState(() {
      _riveFile = riveFile;
      _riveController = RiveWidgetController(
        riveFile,
        // stateMachineSelector: StateMachineSelector.byName('State Machine 1'));
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  @override
  void dispose() {
    _riveFile?.dispose();
    _riveController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.widthOf(context);
    return Center(
        child: Column(
      spacing: 24,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_riveController != null)
          SizedBox(
            height: 210,
            width: width,
            child: RiveWidget(
              controller: _riveController!,
              fit: Fit.fitWidth,
            ),
          ),
        Column(
          spacing: 12,
          children: [
            Text(
              'Getting your video ready',
              style: CustomTypography().headlineMedium(),
            ),
            Text('Fabio’s lining up the shot.',
                style: CustomTypography().bodyLarge())
          ],
        )
      ],
    ));
  }
}
