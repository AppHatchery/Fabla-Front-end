import 'package:audio_diaries_flutter/core/usecases/daily_goal_service.dart';
import 'package:audio_diaries_flutter/core/usecases/home_progress_tracking.dart'
    show modifyHomeProgressTracking;
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/hub/data/submission_progress.dart'
    show SubmissionProgress;
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:flutter/material.dart';

import '../../../../core/usecases/font_scaler_detector_and_adjuster.dart';

class RingProgressIndicator extends StatefulWidget {
  final double progress;
  final double size;
  final Color color;
  final Color backgroundColor;
  final bool activateAnimation;

  /// The value to animate from when [activateAnimation] is true.
  /// Represents progress before the most recent submission.
  final double fromProgress;

  final VoidCallback? onAnimationComplete;

  const RingProgressIndicator(
      {super.key,
      required this.progress,
      required this.size,
      required this.color,
      required this.backgroundColor,
      this.activateAnimation = false,
      this.fromProgress = 0.0,
      this.onAnimationComplete});

  @override
  State<RingProgressIndicator> createState() => _RingProgressIndicatorState();
}

class _RingProgressIndicatorState extends State<RingProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationComplete?.call();
        }
      });
    _buildAnimation(widget.fromProgress);
    if (widget.activateAnimation) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void didUpdateWidget(RingProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress ||
        oldWidget.activateAnimation != widget.activateAnimation) {
      if (widget.activateAnimation) {
        _buildAnimation(widget.fromProgress);
        _controller.reset();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  void _buildAnimation(double begin) {
    _animation = Tween<double>(begin: begin, end: widget.progress)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => CircularProgressIndicator(
          value: widget.activateAnimation ? _animation.value : widget.progress,
          strokeWidth: getAdaptiveTextScaler(context).scale(5),
          strokeCap: StrokeCap.round,
          backgroundColor: widget.backgroundColor,
          color: widget.color,
        ),
      ),
    );
  }
}

class GoalProgressIndicators extends StatelessWidget {
  final Map<StudyModel, DailyGoalData> goalData;
  final Map<int, SubmissionProgress> submissionProgress;

  const GoalProgressIndicators(
      {super.key, required this.goalData, required this.submissionProgress});

  static const double baseSize = 150;
  static const double spacing = 40;

  /// The factor every ring is drawn at: the text scale, shrunk if needed so
  /// the outermost of [ringCount] rings fits in [maxWidth].
  ///
  /// At large font sizes (iOS caps at 2x) the outer ring can be wider than
  /// the screen. The width is bounded but the height isn't, so the ring would
  /// be squashed into an oval. Anything drawn inside the rings (the Rive
  /// mascot) must use this same factor or it will cover the inner rings.
  static double ringScale(
      BuildContext context, int ringCount, double maxWidth) {
    final textScale = getAdaptiveTextScaler(context).scale(1);
    final rings = ringCount < 1 ? 1 : ringCount;
    final outerSize = (baseSize + (rings - 1) * spacing) * textScale;
    if (!maxWidth.isFinite || outerSize <= maxWidth) return textScale;
    return textScale * maxWidth / outerSize;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(builder: (context, constraints) {
        final scale = ringScale(context, goalData.length, constraints.maxWidth);

        return Stack(
          alignment: Alignment.center,
          children: goalData.entries.toList().asMap().entries.map((entry) {
            int index = entry.key;
            final study = entry.value.key;
            final data = entry.value.value;
            final activateAnimation =
                submissionProgress[study.studyId]?.activateAnimation ?? false;

            // Start one submission behind so the animation fills the last step.
            final fromProgress = activateAnimation && data.target > 0
                ? ((data.completed - 1).clamp(0, data.target) / data.target)
                    .toDouble()
                : 0.0;

            double size = baseSize + (index * spacing);

            return RingProgressIndicator(
              progress: data.progress,
              size: size * scale,
              color: study.color ?? CustomColors.productNormal,
              backgroundColor: study.color?.withOpacity(0.2) ??
                  CustomColors.productNormal.withOpacity(0.2),
              activateAnimation: activateAnimation,
              fromProgress: fromProgress,
              onAnimationComplete: activateAnimation
                  ? () => modifyHomeProgressTracking(
                      studyID: study.studyId, activateAnimation: false)
                  : null,
            );
          }).toList(),
        );
      }),
    );
  }
}
