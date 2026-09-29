import 'dart:math' as math;

/// Small math helpers shared by the Fabio rig, sim and choreography player.
///
/// Fabio Studio (the web dashboard) ports these one-to-one, so keep the
/// formulas in sync when changing them.

double clampD(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

double lerpD(double a, double b, double t) => a + (b - a) * t;

double smoothstep(double edge0, double edge1, double x) {
  final t = clampD((x - edge0) / (edge1 - edge0), 0, 1);
  return t * t * (3 - 2 * t);
}

/// Frame-rate independent exponential approach of [current] to [target].
double approach(double current, double target, double rate, double dt) =>
    current + (target - current) * (1 - math.exp(-rate * dt));

/// Rises in over [attack] and falls out over [release] (both fractions of 0..1).
double envelope(double u, {double attack = 0.15, double release = 0.2}) {
  if (u <= 0 || u >= 1) return 0;
  if (u < attack) return smoothstep(0, attack, u);
  if (u > 1 - release) return 1 - smoothstep(1 - release, 1, u);
  return 1;
}

/// Named easing curves usable from choreography JSON.
double ease(String? name, double t) {
  t = clampD(t, 0, 1);
  switch (name) {
    case 'linear':
      return t;
    case 'inQuad':
      return t * t;
    case 'outQuad':
      return 1 - (1 - t) * (1 - t);
    case 'inOutQuad':
      return t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2;
    case 'inCubic':
      return t * t * t;
    case 'outCubic':
      return 1 - math.pow(1 - t, 3).toDouble();
    case 'inOutSine':
      return -(math.cos(math.pi * t) - 1) / 2;
    case 'outExpo':
      return t == 1 ? 1 : 1 - math.pow(2, -10 * t).toDouble();
    case 'inBack':
      const c1 = 1.70158;
      return (c1 + 1) * t * t * t - c1 * t * t;
    case 'outBack':
      const c1 = 1.70158;
      const c3 = c1 + 1;
      return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);
    case 'outElastic':
      if (t == 0 || t == 1) return t;
      return math.pow(2, -10 * t) *
              math.sin((t * 10 - 0.75) * (2 * math.pi) / 3) +
          1;
    case 'outBounce':
      return _outBounce(t);
    case 'inOutCubic':
    default:
      return t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
  }
}

double _outBounce(double t) {
  const n1 = 7.5625;
  const d1 = 2.75;
  if (t < 1 / d1) return n1 * t * t;
  if (t < 2 / d1) {
    t -= 1.5 / d1;
    return n1 * t * t + 0.75;
  }
  if (t < 2.5 / d1) {
    t -= 2.25 / d1;
    return n1 * t * t + 0.9375;
  }
  t -= 2.625 / d1;
  return n1 * t * t + 0.984375;
}

/// Deterministic PRNG (mulberry32) so a script with a seed replays the same
/// particles and idle behaviour in the app and in Fabio Studio.
class FabioRandom {
  int _state;
  FabioRandom([int seed = 1]) : _state = seed & 0xFFFFFFFF;

  static int _imul(int a, int b) => (a * b) & 0xFFFFFFFF;

  /// Uniform in [0, 1).
  double next() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = _imul(t ^ (t >> 15), t | 1);
    t ^= (t + _imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF;
    return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0;
  }

  double range(double lo, double hi) => lo + (hi - lo) * next();

  T pick<T>(List<T> items) => items[(next() * items.length).floor() % items.length];
}
