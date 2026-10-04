import 'package:audio_diaries_flutter/core/utils/quickstart_handler.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/widgets/video_loading_indicator.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/widgets/video_progress_bar.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class QuickstartModal extends StatefulWidget {
  const QuickstartModal({super.key});

  @override
  State<QuickstartModal> createState() => _QuickstartModalState();
}

class _QuickstartModalState extends State<QuickstartModal> {
  VideoPlayerController? _controller;
  VideoPlayerController? _controller2;
  bool _showSkipped = false;
  bool _walkthroughEnded = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  Future<void> _initControllers() async {
    final handler = QuickstartHandler();
    await handler.ensureVideosCached();
    if (!mounted) return;

    final cachedUrls = await handler.getCachedVideoUrls();
    final walkThroughUrl = cachedUrls['walkThrough'];
    final skipUrl = cachedUrls['skip'];
    if (walkThroughUrl == null || skipUrl == null) return;

    final controller =
        VideoPlayerController.networkUrl(Uri.parse(walkThroughUrl))
          ..addListener(_onWalkthroughVideoUpdate);
    final controller2 = VideoPlayerController.networkUrl(Uri.parse(skipUrl));

    setState(() {
      _controller = controller;
      _controller2 = controller2;
    });

    controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
        controller.play();
      }
    });
    controller2.initialize();
    controller2.setLooping(true).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_onWalkthroughVideoUpdate);
    _controller?.dispose();
    _controller2?.dispose();
    super.dispose();
  }

  void _onWalkthroughVideoUpdate() {
    if (_walkthroughEnded || _showSkipped) return;
    final value = _controller!.value;
    if (!value.isInitialized ||
        value.isPlaying ||
        value.duration == Duration.zero ||
        value.position < value.duration) {
      return;
    }
    _walkthroughEnded = true;
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_showSkipped) {
        Navigator.pop(context);
      }
    });
  }

  void _skip() {
    setState(() => _showSkipped = true);
    _controller!.pause();
    _controller2!.play();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: screenHeight * (_showSkipped ? 0.65 : 1.0),
        decoration: const BoxDecoration(
          color: CustomColors.fillNormal,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _controller == null || _controller2 == null
              ? VideoLoadingIndicator()
              : (_showSkipped ? _skipped() : _walkThrough()),
        ),
      ),
    );
  }

  Widget _walkThrough() {
    final controller = _controller!;
    return Column(
      key: const ValueKey('walkThrough'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 18.0),
          child: Row(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                  child: VideoProgressBar(
                controller: controller,
                // The progress bar is read-only in the modal, so we provide no-op callbacks.
                onChanged: (value) {},
              )),
              GestureDetector(
                onTap: _skip,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                    color: CustomColors.productNormal,
                  ),
                  child: Text("Skip",
                      style: CustomTypography()
                          .title(color: CustomColors.textWhite),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.clip),
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  )
                : VideoLoadingIndicator(),
          ),
        ),
      ],
    );
  }

  Widget _skipped() {
    final controller2 = _controller2!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 22,
        key: const ValueKey('skipped'),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                "Need Help Later?",
                style: CustomTypography().custom(
                    fontSize: 22.sp,
                    color: CustomColors.textNormalContent,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              Text(
                "Find the guide any time in Settings, under Help.",
                style: CustomTypography().custom(
                    fontSize: 15.sp,
                    color: CustomColors.textSecondaryContent,
                    fontWeight: FontWeight.w400),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          // Video loop
          Expanded(
            child: Center(
              child: controller2.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: controller2.value.aspectRatio,
                      child: VideoPlayer(controller2),
                    )
                  : VideoLoadingIndicator(),
            ),
          ),

          CustomElevatedButton(
            onClick: () => Navigator.pop(context),
            text: 'Dismiss',
          )
        ],
      ),
    );
  }
}
