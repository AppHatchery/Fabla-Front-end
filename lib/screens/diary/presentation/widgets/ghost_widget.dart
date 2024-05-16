import 'package:flutter/cupertino.dart';
import 'package:rive/rive.dart';

class GhostCompletionWidget extends StatefulWidget {
  final int currentEntry;
  final int dailyGoal;
  final int weeklyGoal;
  const GhostCompletionWidget(
      {super.key,
      required this.currentEntry,
      required this.dailyGoal,
      required this.weeklyGoal});

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
    //Show Celebration if the daily goal is reached
    if (widget.currentEntry == widget.dailyGoal) {
      final celebration = _controller.findSMI('Celebration');
      if (celebration != null && mounted) {
        celebration.value = true;
      }
      return;
    }

    //Show Cheering if the daily goal is exceeded
    if (widget.currentEntry < widget.dailyGoal) {
      final cheering = _controller.findSMI('Cheering');
      if (cheering != null && mounted) {
        cheering.value = true;
      }
      return;
    }

    //Show Surprise + Approve if Current Entry is greater than Daily Goal
    if (widget.currentEntry > widget.dailyGoal) {
      final surprise = _controller.findSMI('Surprise + Approve');
      if (surprise != null && mounted) {
        surprise.value = true;
      }
      return;
    }
  }
}
