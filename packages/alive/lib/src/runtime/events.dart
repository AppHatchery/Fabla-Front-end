// What the controller reports to the app. Flows pace themselves off these (a cue, a clip end), so they fire at the
// same times with reduced motion on.
import '../schema/errors.dart';

/// Something that happened in a scene. [time] is the stage clock in seconds since the scene started.
sealed class AliveEvent {
  const AliveEvent(this.time);

  /// Stage clock, seconds.
  final double time;
}

/// The scene's data is loaded and the first frame can be drawn.
class AliveLoaded extends AliveEvent {
  /// Loaded at [time].
  const AliveLoaded(super.time, this.scene);

  /// Scene id.
  final String scene;
}

/// A clip started.
class AliveClipStarted extends AliveEvent {
  /// A clip start.
  const AliveClipStarted(super.time, this.clip, {this.pool, this.look});

  /// The clip id.
  final String clip;

  /// The pool it was picked from, if any.
  final String? pool;

  /// The look it wears, if any.
  final String? look;
}

/// A clip reached its end (fires every pass of a looping clip).
class AliveClipEnded extends AliveEvent {
  /// A clip end.
  const AliveClipEnded(super.time, this.clip);

  /// The clip id.
  final String clip;
}

/// A clip passed a named mark.
class AliveCue extends AliveEvent {
  /// A cue.
  const AliveCue(super.time, this.name, this.clip);

  /// The cue name.
  final String name;

  /// The clip it belongs to.
  final String clip;
}

/// The speech bubble's text changed (null: no bubble). The app draws the bubble, so the copy stays localizable;
/// read `controller.bubble` each frame for its opacity.
class AliveBubble extends AliveEvent {
  /// A bubble change.
  const AliveBubble(super.time, this.text, this.clip);

  /// The text, or null.
  final String? text;

  /// The clip it comes from.
  final String clip;
}

/// The app state changed.
class AliveStateChanged extends AliveEvent {
  /// A state change.
  const AliveStateChanged(super.time, this.from, this.to);

  /// Previous state.
  final String? from;

  /// New state.
  final String to;
}

/// Something failed. A failed load shows the stage's fallback; a usage problem is reported and ignored.
class AliveFailed extends AliveEvent {
  /// A failure.
  const AliveFailed(super.time, this.error);

  /// What failed.
  final AliveError error;
}
