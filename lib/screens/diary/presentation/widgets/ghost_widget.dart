import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:rive/rive.dart';

class GhostCompletionWidget extends StatefulWidget {
  const GhostCompletionWidget({
    super.key,
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
    return RiveAnimation.asset(
      'assets/animations/ghosts.riv',
      onInit: _onInit,
      fit: BoxFit.cover,
    );
  }

  determineAnimation() {
    final achieving = _controller.findSMI('Achieving the goal ');

    if (achieving != null && mounted) {
      achieving.value = true;
    }
  }

  track(int total, int current) async {
    final now = DateTime.now();
    await PendoService.track("Goal Progress",
        {"total": total, "current": current, "date": now.toIso8601String()});
  }
}
