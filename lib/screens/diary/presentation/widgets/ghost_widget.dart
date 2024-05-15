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

      Future.delayed(const Duration(milliseconds: 10), () {
        // final arrival = _controller.findSMI('First arrival');
        // if (arrival != null) {
        //   arrival.value = true;
        // }
        determineAnimation();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      left: 0,
      child: RiveAnimation.asset(
        'assets/animations/ghosts.riv',
        onInit: _onInit,
      ),
    );
  }

  determineAnimation() {
    //Show Celebration if the daily goal is reached
    if (widget.currentEntry == widget.dailyGoal) {
      final celebration = _controller.findSMI('Celebration');
      if (celebration != null) {
        celebration.value = true;
      }
      return;
    }

    //Show Cheering if the daily goal is exceeded
    if (widget.currentEntry < widget.dailyGoal) {
      final cheering = _controller.findSMI('Cheering');
      if (cheering != null) {
        cheering.value = true;
      }
      return;
    }

    //Show Surprise + Approve if Current Entry is greater than Daily Goal
    if (widget.currentEntry > widget.dailyGoal) {
      final surprise = _controller.findSMI('Surprise + Approve');
      if (surprise != null) {
        surprise.value = true;
      }
      return;
    }
  }
}
