import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio_player_provider.dart';

//  This class handles stopping audio playback when navigating between screens
class AudioNavigationObserver extends NavigatorObserver {

  // Called when a new route is pushed onto the navigator
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _handleNavigation();
  }

// Called when a route is popped from the navigator
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _handleNavigation();
  }

// Called when a route is replaced in the navigator
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _handleNavigation();
  }

// Stops audio playback when navigation occurs
  void _handleNavigation() {
    final context = navigator?.context;
    if (context != null) {
      final audioProvider =
          Provider.of<AudioPlayerProvider>(context, listen: false);
      audioProvider.stop();
    }
  }
}
