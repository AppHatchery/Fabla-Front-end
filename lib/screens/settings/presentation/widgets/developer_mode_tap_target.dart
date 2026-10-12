import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../services/developer_mode_service.dart';

/// Wraps [child] with a hidden gesture that enables developer mode after
/// [DeveloperModeService.requiredTaps] consecutive taps, similar to Android's
/// "tap build number" developer options.
///
/// Taps must be no more than [tapTimeout] apart, otherwise the count resets.
/// A countdown snackbar is shown for the last [countdownFrom] taps.
class DeveloperModeTapTarget extends StatefulWidget {
  final Widget child;
  final Duration tapTimeout;
  final int countdownFrom;

  const DeveloperModeTapTarget({
    super.key,
    required this.child,
    this.tapTimeout = const Duration(seconds: 2),
    this.countdownFrom = 4,
  });

  @override
  State<DeveloperModeTapTarget> createState() => _DeveloperModeTapTargetState();
}

class _DeveloperModeTapTargetState extends State<DeveloperModeTapTarget> {
  final DeveloperModeService _developerMode = DeveloperModeService();
  int _tapCount = 0;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_developerMode.isEnabled) {
      _showMessage("Developer mode is already on");
      return;
    }

    _resetTimer?.cancel();
    _resetTimer = Timer(widget.tapTimeout, () => _tapCount = 0);
    _tapCount++;

    final remaining = DeveloperModeService.requiredTaps - _tapCount;
    if (remaining <= 0) {
      _resetTimer?.cancel();
      _tapCount = 0;
      await _developerMode.enable();
      _showMessage("Developer mode is now on");
    } else if (remaining <= widget.countdownFrom) {
      _showMessage(
          "You are $remaining ${remaining == 1 ? 'tap' : 'taps'} away from developer mode");
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key("developer_mode_tap_target"),
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: widget.child,
    );
  }
}
