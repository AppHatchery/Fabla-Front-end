// Easing for keyframes: named eases, cubic beziers and springs, typed so that sampling a track allocates nothing.
// The formulas are the old engine's (fabio_plus curves.dart and math.dart), so clips play with the same timing.
import 'dart:math' as math;

/// How a keyframe segment is shaped. The ease on a key shapes the span that ENDS at that key (Figma's convention).
class Ease {
  const Ease._(this.kind, [this.a = 0, this.b = 0, this.c = 0, this.d = 0]);

  /// A cubic bezier (x1, y1, x2, y2), CSS and Figma style.
  factory Ease.bezier(double x1, double y1, double x2, double y2) => Ease._(_bezier, x1, y1, x2, y2);

  /// A spring released from rest toward the target (mass, stiffness, damping); its duration is the segment's.
  factory Ease.spring(double mass, double stiffness, double damping) => Ease._(_spring, mass, stiffness, damping);

  /// One of the named eases ([names]).
  factory Ease.named(String name) {
    final i = names.indexOf(name);
    if (i < 0) throw ArgumentError.value(name, 'name', 'unknown ease');
    if (name == 'linear') return linear;
    if (name == 'hold' || name == 'step') return hold;
    return Ease._(_named, i.toDouble());
  }

  /// Linear (the default).
  static const Ease linear = Ease._(_linear);

  /// Hold the previous value until the key, then jump.
  static const Ease hold = Ease._(_hold);

  /// Parse an alive/1 ease (null, a name, [x1, y1, x2, y2] or {"spring": {...}}); null when it is not one.
  static Ease? parse(Object? spec) {
    if (spec == null) return linear;
    if (spec is String) return names.contains(spec) ? Ease.named(spec) : null;
    if (spec is List && spec.length == 4 && spec.every((v) => v is num)) {
      return Ease.bezier((spec[0] as num).toDouble(), (spec[1] as num).toDouble(), (spec[2] as num).toDouble(), (spec[3] as num).toDouble());
    }
    if (spec is Map && spec['spring'] is Map) {
      final s = spec['spring'] as Map;
      double n(Object? v, double d) => v is num ? v.toDouble() : d;
      return Ease.spring(n(s['mass'], 1), n(s['stiffness'], 100), n(s['damping'], 10));
    }
    return null;
  }

  static const int _linear = 0, _hold = 1, _bezier = 2, _spring = 3, _named = 4;

  /// Every named ease alive/1 accepts.
  static const List<String> names = ['linear', 'hold', 'step', 'inQuad', 'outQuad', 'inOutQuad', 'inCubic', 'outCubic', 'inOutCubic', 'inOutSine', 'outExpo', 'inBack', 'outBack', 'outElastic', 'outBounce'];

  /// The shape, and up to four parameters.
  final int kind;

  /// Parameters (bezier: x1 y1 x2 y2; spring: mass stiffness damping; named: the index in [names]).
  final double a, b, c, d;

  /// Progress at u (0..1) of a segment lasting [span] seconds (springs need the span).
  double at(double u, double span) {
    if (u <= 0) return 0;
    if (u >= 1) return 1;
    switch (kind) {
      case _linear:
        return u;
      case _hold:
        return 0;
      case _bezier:
        return bezier(a, b, c, d, u);
      case _spring:
        return spring(a, b, c, u * span);
      default:
        return named(names[a.toInt()], u);
    }
  }

  @override
  String toString() => switch (kind) { _linear => 'linear', _hold => 'hold', _bezier => '[$a, $b, $c, $d]', _spring => 'spring($a, $b, $c)', _ => names[a.toInt()] };
}

/// Cubic bezier ease: solve x(s) = u for s (Newton steps, then a bisection), return y(s).
double bezier(double x1, double y1, double x2, double y2, double uIn) {
  final u = uIn.clamp(0.0, 1.0);
  if (u == 0 || u == 1) return u;
  final cx = 3 * x1, bx = 3 * (x2 - x1) - cx, ax = 1 - cx - bx;
  final cy = 3 * y1, by = 3 * (y2 - y1) - cy, ay = 1 - cy - by;
  double x(double s) => ((ax * s + bx) * s + cx) * s;
  double dx(double s) => (3 * ax * s + 2 * bx) * s + cx;
  var s = u;
  for (var i = 0; i < 8; i++) {
    final e = x(s) - u, d = dx(s);
    if (e.abs() < 1e-7) break;
    if (d.abs() < 1e-6) break;
    s -= e / d;
  }
  if (!(s >= 0 && s <= 1) || (x(s) - u).abs() > 1e-5) {
    var lo = 0.0, hi = 1.0;
    s = u;
    for (var i = 0; i < 40; i++) {
      if (x(s) < u) {
        lo = s;
      } else {
        hi = s;
      }
      s = (lo + hi) / 2;
    }
  }
  return ((ay * s + by) * s + cy) * s;
}

/// A spring released from rest at 0 toward 1, at time t seconds. Under, critically and over damped.
double spring(double mass, double stiffness, double damping, double t) {
  final m = math.max(1e-3, mass), k = math.max(1e-3, stiffness), c = math.max(0.0, damping);
  final w0 = math.sqrt(k / m), z = c / (2 * math.sqrt(k * m));
  if (t <= 0) return 0;
  if (z < 1) {
    final wd = w0 * math.sqrt(1 - z * z);
    return 1 - math.exp(-z * w0 * t) * (math.cos(wd * t) + (z * w0 / wd) * math.sin(wd * t));
  }
  if (z == 1) return 1 - math.exp(-w0 * t) * (1 + w0 * t);
  final r1 = -w0 * (z - math.sqrt(z * z - 1)), r2 = -w0 * (z + math.sqrt(z * z - 1));
  final ca = r2 / (r2 - r1), cb = -r1 / (r2 - r1);
  return 1 - (ca * math.exp(r1 * t) + cb * math.exp(r2 * t));
}

double _pow(num a, num b) => math.pow(a, b).toDouble();

/// The named eases (the Fabla team's curves).
double named(String name, double t) {
  switch (name) {
    case 'inQuad':
      return t * t;
    case 'outQuad':
      return 1 - (1 - t) * (1 - t);
    case 'inOutQuad':
      return t < 0.5 ? 2 * t * t : 1 - _pow(-2 * t + 2, 2) / 2;
    case 'inCubic':
      return t * t * t;
    case 'outCubic':
      return 1 - _pow(1 - t, 3);
    case 'inOutSine':
      return -(math.cos(math.pi * t) - 1) / 2;
    case 'outExpo':
      return t == 1 ? 1 : 1 - _pow(2, -10 * t);
    case 'inBack':
      const c1 = 1.70158;
      return (c1 + 1) * t * t * t - c1 * t * t;
    case 'outBack':
      const c1 = 1.70158, c3 = c1 + 1;
      return 1 + c3 * _pow(t - 1, 3) + c1 * _pow(t - 1, 2);
    case 'outElastic':
      if (t == 0 || t == 1) return t;
      return _pow(2, -10 * t) * math.sin((t * 10 - 0.75) * (2 * math.pi) / 3) + 1;
    case 'outBounce':
      return _outBounce(t);
    default: // inOutCubic
      return t < 0.5 ? 4 * t * t * t : 1 - _pow(-2 * t + 2, 3) / 2;
  }
}

double _outBounce(double tIn) {
  var t = tIn;
  const n1 = 7.5625, d1 = 2.75;
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
