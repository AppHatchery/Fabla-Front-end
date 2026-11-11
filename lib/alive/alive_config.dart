// Fabla Alive: the one switch for the animated Fabio moments.
//
// Compile time: `--dart-define=FABLA_ALIVE=true`. Without it [AliveConfig.compiled] is a false constant, every
// `if (AliveConfig.on)` hook is dead code and the tree shaker drops the Alive widgets from the app.
// Run time: [AliveConfig.setForSession] turns the moments off in a build that has them (a control run, the tests).
import 'package:flutter/foundation.dart';

class AliveConfig {
  AliveConfig._();

  /// True only in builds made with `--dart-define=FABLA_ALIVE=true`.
  static const bool compiled = bool.fromEnvironment('FABLA_ALIVE');

  static bool _enabled = compiled;

  /// Whether the Alive moments run right now. Always false when not [compiled].
  static bool get on => compiled && _enabled;

  /// For this run only (not kept). No effect when not [compiled].
  static void setForSession(bool value) {
    if (compiled) _enabled = value;
  }

  /// Tests: set the switch whether or not the define is there.
  @visibleForTesting
  static void debugSet(bool value) => _enabled = value;
}
