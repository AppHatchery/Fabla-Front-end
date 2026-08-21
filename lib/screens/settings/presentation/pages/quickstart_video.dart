import 'package:audio_diaries_flutter/core/utils/quickstart_handler.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/widgets/video_loading_indicator.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/widgets/video_progress_bar.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class QuickstartVideoPage extends StatefulWidget {
  final String videoName;

  const QuickstartVideoPage({super.key, this.videoName = 'walkThrough'});

  @override
  State<QuickstartVideoPage> createState() => _QuickstartVideoPageState();
}

class _QuickstartVideoPageState extends State<QuickstartVideoPage> {
  VideoPlayerController? _controller;
  double? _dragPositionMs;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final handler = QuickstartHandler();
    await handler.ensureVideosCached();
    if (!mounted) return;

    final cachedUrls = await handler.getCachedVideoUrls();
    final networkUrl = cachedUrls[widget.videoName];
    if (networkUrl == null) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(networkUrl));
    setState(() => _controller = controller);
    controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
        controller.play();
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: CustomColors.fillNormal,
      appBar: AppBar(
        backgroundColor: CustomColors.fillNormal,
        automaticallyImplyLeading: false,
        title: Row(
          spacing: 12,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.close_rounded,
                size: 28,
              ),
            ),
            Expanded(
              child: controller == null
                  ? const SizedBox.shrink()
                  : VideoProgressBar(
                      controller: controller,
                      dragPositionMs: _dragPositionMs,
                      onChangeStart: (_) => controller.pause(),
                      onChanged: (newValue) =>
                          setState(() => _dragPositionMs = newValue),
                      onChangeEnd: (newValue) async {
                        await controller
                            .seekTo(Duration(milliseconds: newValue.round()));
                        await controller.play();
                        if (mounted) setState(() => _dragPositionMs = null);
                      },
                    ),
            ),
          ],
        ),
      ),
      body: Center(
        child: controller != null && controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              )
            : VideoLoadingIndicator(),
      ),
    );
  }
}
