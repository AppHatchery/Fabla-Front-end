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
  File? _riveFile;
  RiveWidgetController? _riveController;

  @override
  void initState() {
    super.initState();
    _loadRive();
  }

  Future<void> _loadRive() async {
    final file = await File.asset(
      'assets/animations/ghosts.riv',
      riveFactory: Factory.rive,
    );
    if (file != null && mounted) {
      final controller = RiveWidgetController(
        file,
        stateMachineSelector: StateMachineSelector.byName('Ghosts'),
      );
      setState(() {
        _riveFile = file;
        _riveController = controller;
      });
      Future.delayed(
          const Duration(milliseconds: 10), () => determineAnimation());
    }
  }

  @override
  void dispose() {
    _riveController?.dispose();
    _riveFile?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_riveController == null) return const SizedBox.shrink();
    return RiveWidget(
      controller: _riveController!,
      fit: Fit.cover,
    );
  }

  void determineAnimation() {
    final achieving =
        _riveController?.stateMachine.trigger('Achieving the goal ');
    if (achieving != null && mounted) {
      achieving.fire();
    }
  }

  Future<void> track(int total, int current) async {
    final now = DateTime.now();
    await PendoService.track("Goal Progress",
        {"total": total, "current": current, "date": now.toIso8601String()});
  }
}
