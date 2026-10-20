/// The app's notion of "now". Use [AppClock.now] instead of `DateTime.now()`
/// anywhere the current date decides what the participant sees or what is
/// saved (diary windows, statuses, goals, incentives, timestamps), so
/// developer mode's time travel can shift it.
///
/// Diagnostics (traces, logs, the network sweep) keep using `DateTime.now()`
/// so their timestamps stay real while travelling.
///
/// Usage example:
/// ```dart
/// final today = AppClock.now();
/// AppClock.offset = const Duration(days: 1); // developer mode only
/// ```
class AppClock {
  AppClock._();

  /// How far [now] is shifted from the device clock. Set only by
  /// `DeveloperModeService`; zero otherwise.
  static Duration offset = Duration.zero;

  static bool get isShifted => offset != Duration.zero;

  static DateTime now() {
    final real = DateTime.now();
    return isShifted ? real.add(offset) : real;
  }
}
