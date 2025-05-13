import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio_player_provider.dart';

class AudioNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _handleNavigation();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _handleNavigation();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _handleNavigation();
  }

  void _handleNavigation() {
    final context = navigator?.context;
    if (context != null) {
      final audioProvider =
          Provider.of<AudioPlayerProvider>(context, listen: false);
      audioProvider.stop();
    }
  }
}
