import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:flutter/cupertino.dart';
import 'package:rive/rive.dart';

class GhostCompletionWidget extends StatefulWidget {
  final List<StudyModel> studies;
  final List<DiaryModel> diaries;
  const GhostCompletionWidget({
    super.key,
    required this.studies,
    required this.diaries,
  });

  @override
  State<GhostCompletionWidget> createState() => _GhostCompletionWidgetState();
}

class _GhostCompletionWidgetState extends State<GhostCompletionWidget> {
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

      Future.delayed(
          const Duration(milliseconds: 10), () => determineAnimation());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: SizedBox(
          height: 120,
          width: 180,
          child: RiveAnimation.asset(
            'assets/animations/ghosts.riv',
            onInit: _onInit,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  determineAnimation() {
    final totalEntries =
        widget.diaries.fold(0, (prev, diary) => prev + diary.currentEntry);
    final totalGoal =
        widget.studies.fold(0, (prev, study) => prev + study.goals.daily);

    //Show Celebration if the daily goal is reached
    if (totalEntries == totalGoal) {
      final celebration = _controller.findSMI('Celebration');
      if (celebration != null && mounted) {
        celebration.value = true;
      }
      return;
    }

    //Show Cheering if the daily goal is exceeded
    if (totalEntries < totalGoal) {
      final cheering = _controller.findSMI('Cheering');
      if (cheering != null && mounted) {
        cheering.value = true;
      }
      return;
    }

    //Show Surprise + Approve if Current Entry is greater than Daily Goal
    if (totalEntries > totalGoal) {
      final surprise = _controller.findSMI('Surprise + Approve');
      if (surprise != null && mounted) {
        surprise.value = true;
      }
      return;
    }
  }
}
