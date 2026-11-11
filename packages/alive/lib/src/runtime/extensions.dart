// Extensions an app gives a controller: painters for plugin nodes (art the engine does not draw itself: a live
// waveform, particles), reading the frame they are drawn in.
import 'dart:ui' as ui;

import '../schema/art_def.dart' show PluginNode;
import '../schema/track.dart';

/// What a plugin painter can read of the frame it draws in.
abstract class AliveFrame {
  /// The stage clock, seconds.
  double get time;

  /// The clip playing (or holding), if any, and seconds into it.
  String? get clip;

  /// Seconds into [clip].
  double get clipTime;

  /// An input's smoothed value (the mic level, anything the app sets with `setInput`).
  double input(String name);

  /// A step channel of the clip at the shown time (`lamp`, `face`, any the clip carries).
  Object? channel(String name);

  /// A layer's value in this frame.
  double? value(String layer, LayerProp prop);

  /// Are still poses shown (reduced motion)?
  bool get reducedMotion;
}

/// Draws a plugin node: [canvas] is at the node's place, its box is (0, 0, node.w, node.h).
typedef AliveNodePainter = void Function(ui.Canvas canvas, PluginNode node, AliveFrame frame);

/// A plugin node kind.
class AlivePlugin {
  /// A painter; [animates] when it changes on its own from frame to frame (particles, a live meter), so the clock
  /// keeps running while a scene with it shows.
  const AlivePlugin(this.paint, {this.animates = false});

  /// The painter.
  final AliveNodePainter paint;

  /// It changes from frame to frame by itself.
  final bool animates;
}

/// What an app adds to a controller's scenes without changing the engine.
class AliveExtensions {
  /// Extensions: painters for plugin nodes by kind (`{"plugin": "<kind>"}` in the art).
  const AliveExtensions({this.nodes = const {}});

  /// Plugin painters by kind.
  final Map<String, AlivePlugin> nodes;

  /// None.
  static const AliveExtensions none = AliveExtensions();
}

/// The frame's plugin host: what the renderer asks to draw a plugin node (the player is one).
abstract class AlivePluginHost {
  /// Draw [node] (its painter, or nothing when none is registered).
  void paintPlugin(ui.Canvas canvas, PluginNode node);
}
