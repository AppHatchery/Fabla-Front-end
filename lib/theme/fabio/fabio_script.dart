import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

import 'fabio_custom_prop.dart';
import 'fabio_expression.dart';
import 'fabio_fx.dart';
import 'fabio_math.dart';

/// A choreography for Fabio: a timeline of clips on parallel tracks.
///
/// Scripts are authored in Fabio Studio and saved as JSON under
/// `assets/fabio/scripts/`. Times (`t`, `d`) are milliseconds; positions are
/// normalised to the stage (0,0 top-left, 1,1 bottom-right, values outside
/// 0..1 are off-screen) and radii are fractions of the stage's shorter side.
///
/// Parsing is deliberately lenient: unknown tracks, types and fields are
/// ignored so older app builds keep playing newer scripts.
class FabioScript {
  final String name;
  final int seed;
  final bool loop;
  final FabioStart start;
  final List<FabioMotionClip> motion;
  final List<FabioFaceClip> face;
  final List<FabioActionClip> actions;
  final List<FabioLookClip> looks;
  final List<FabioFxClip> fx;
  final List<FabioSpeechClip> speech;
  final List<FabioEventClip> events;

  /// Props defined by this script's `props` map, by name.
  final Map<String, FabioCustomProp> customProps;
  final double? _duration;

  FabioScript({
    this.name = 'Untitled',
    this.seed = 7,
    this.loop = false,
    this.start = const FabioStart(),
    this.motion = const [],
    this.face = const [],
    this.actions = const [],
    this.looks = const [],
    this.fx = const [],
    this.speech = const [],
    this.events = const [],
    this.customProps = const {},
    double? duration,
  }) : _duration = duration;

  /// Length in seconds.
  double get duration {
    if (_duration != null) return _duration;
    var end = 0.0;
    for (final c in motion) {
      end = math.max(end, c.t + c.d);
    }
    for (final c in face) {
      end = math.max(end, c.t + (c.d ?? 0));
    }
    for (final c in actions) {
      end = math.max(end, c.t + (c.d ?? c.gesture.duration));
    }
    for (final c in looks) {
      end = math.max(end, c.t + c.d);
    }
    for (final c in fx) {
      end = math.max(end, c.t + (c.d ?? 0) + 0.8);
    }
    for (final c in speech) {
      end = math.max(end, c.t + c.d);
    }
    for (final c in events) {
      end = math.max(end, c.t);
    }
    return end + 0.4;
  }

  static Future<FabioScript> load(String asset) async =>
      parse(await rootBundle.loadString(asset));

  static FabioScript parse(String source) =>
      FabioScript.fromJson(jsonDecode(source) as Map<String, dynamic>);

  factory FabioScript.fromJson(Map<String, dynamic> json) {
    final motion = <FabioMotionClip>[];
    final face = <FabioFaceClip>[];
    final actions = <FabioActionClip>[];
    final looks = <FabioLookClip>[];
    final fx = <FabioFxClip>[];
    final speech = <FabioSpeechClip>[];
    final events = <FabioEventClip>[];
    final customProps = <String, FabioCustomProp>{};
    final rawProps = json['props'];
    if (rawProps is Map) {
      for (final entry in rawProps.entries) {
        final name = entry.key;
        // Built-in names always win so a script cannot restyle them.
        if (name is! String || FabioProp.tryParse(name) != null) continue;
        final prop = FabioCustomProp.fromJson(name, entry.value);
        if (prop != null) customProps[name] = prop;
      }
    }

    for (final raw in (json['clips'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final c = raw.cast<String, dynamic>();
      final t = _ms(c['t']) ?? 0;
      final d = _ms(c['d']);
      switch (c['track']) {
        case 'motion':
          motion.add(FabioMotionClip._fromJson(c, t, d ?? 1));
        case 'face':
          final e = FabioExpression.tryParse(c['expression']);
          if (e != null) face.add(FabioFaceClip(t: t, d: d, expression: e));
        case 'action':
          final g = FabioGesture.tryParse(c['gesture']);
          if (g != null) actions.add(FabioActionClip(t: t, d: d, gesture: g));
        case 'look':
          looks.add(FabioLookClip(
              t: t, d: d ?? 1, at: _point(c['at']), target: c['target'] as String?));
        case 'fx':
          final prop = FabioProp.tryParse(c['prop']);
          final custom = customProps[c['prop']];
          if (prop == null && custom == null) break;
          fx.add(FabioFxClip(
            t: t,
            d: d,
            prop: prop,
            custom: custom,
            mode: FabioFxMode.tryParse(c['mode']) ?? FabioFxMode.burst,
            count: (_num(c['count']) ?? 12).round(),
            at: _point(c['at']),
            spread: _num(c['spread']) ?? 1,
            rate: _num(c['rate']) ?? 18,
            size: _num(c['size']) ?? 1,
            color: _color(c['color']),
          ));
        case 'speech':
          final text = c['text'];
          if (text is String && text.isNotEmpty) {
            speech.add(FabioSpeechClip(t: t, d: d ?? 2, text: text));
          }
        case 'event':
          final name = c['name'];
          if (name is String) events.add(FabioEventClip(t: t, name: name));
      }
    }
    int byT(FabioClip a, FabioClip b) => a.t.compareTo(b.t);
    for (final list in <List<FabioClip>>[motion, face, actions, looks, fx, speech, events]) {
      list.sort(byT);
    }

    return FabioScript(
      name: json['name'] as String? ?? 'Untitled',
      seed: (_num(json['seed']) ?? 7).round(),
      loop: json['loop'] == true,
      start: FabioStart._fromJson(json['start']),
      motion: motion,
      face: face,
      actions: actions,
      looks: looks,
      fx: fx,
      speech: speech,
      events: events,
      customProps: customProps,
      duration: _ms(json['duration']),
    );
  }
}

double? _num(Object? v) => v is num ? v.toDouble() : null;
double? _ms(Object? v) => v is num ? v.toDouble() / 1000 : null;

Offset? _point(Object? v) {
  if (v is List && v.length >= 2 && v[0] is num && v[1] is num) {
    return Offset((v[0] as num).toDouble(), (v[1] as num).toDouble());
  }
  if (v is Map && v['x'] is num && v['y'] is num) {
    return Offset((v['x'] as num).toDouble(), (v['y'] as num).toDouble());
  }
  return null;
}

Color? _color(Object? v) {
  if (v is! String) return null;
  var hex = v.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  final value = int.tryParse(hex, radix: 16);
  return value == null ? null : Color(value);
}

class FabioStart {
  final Offset position;
  final double scale;
  final FabioExpression expression;
  final double facing;

  const FabioStart({
    this.position = const Offset(0.5, 0.5),
    this.scale = 1,
    this.expression = FabioExpression.neutral,
    this.facing = 1,
  });

  factory FabioStart._fromJson(Object? json) {
    if (json is! Map) return const FabioStart();
    return FabioStart(
      position: Offset(_num(json['x']) ?? 0.5, _num(json['y']) ?? 0.5),
      scale: _num(json['scale']) ?? 1,
      expression: FabioExpression.tryParse(json['expression']) ?? FabioExpression.neutral,
      facing: (_num(json['facing']) ?? 1) < 0 ? -1 : 1,
    );
  }
}

abstract class FabioClip {
  /// Start time in seconds.
  final double t;
  const FabioClip(this.t);
}

enum FabioMotionType { fly, dash, hold, orbit, figure8, hop, wander, teleport }

class FabioMotionClip extends FabioClip {
  final double d;
  final FabioMotionType type;
  final List<Offset> path;
  final Offset? to;
  final Offset? center;
  final double? radius;
  final double? radiusTo;
  final double turns;
  final int hops;
  final double height;
  final String? ease;
  final double? scale;

  const FabioMotionClip({
    required double t,
    required this.d,
    required this.type,
    this.path = const [],
    this.to,
    this.center,
    this.radius,
    this.radiusTo,
    this.turns = 1,
    this.hops = 3,
    this.height = 0.08,
    this.ease,
    this.scale,
  }) : super(t);

  factory FabioMotionClip._fromJson(Map<String, dynamic> c, double t, double d) {
    final typeName = c['type'] == 'path' ? 'fly' : c['type'];
    final type = FabioMotionType.values
            .where((m) => m.name == typeName)
            .firstOrNull ??
        FabioMotionType.fly;
    final path = <Offset>[
      for (final p in (c['path'] as List? ?? const []))
        if (_point(p) case final Offset o) o,
    ];
    final to = _point(c['to']);
    return FabioMotionClip(
      t: t,
      d: math.max(d, 0.05),
      type: type,
      path: path.isEmpty && to != null ? [to] : path,
      to: to ?? (path.isNotEmpty ? path.last : null),
      center: _point(c['center']),
      radius: _num(c['radius']),
      radiusTo: _num(c['radiusTo']),
      turns: _num(c['turns']) ?? 1,
      hops: (_num(c['hops']) ?? 3).round().clamp(1, 20),
      height: _num(c['height']) ?? 0.08,
      ease: c['ease'] as String?,
      scale: _num(c['scale']),
    );
  }
}

class FabioFaceClip extends FabioClip {
  /// `null` holds the expression until the next face clip.
  final double? d;
  final FabioExpression expression;
  const FabioFaceClip({required double t, this.d, required this.expression}) : super(t);
}

class FabioActionClip extends FabioClip {
  final double? d;
  final FabioGesture gesture;
  const FabioActionClip({required double t, this.d, required this.gesture}) : super(t);
}

class FabioLookClip extends FabioClip {
  final double d;

  /// Normalised stage point to look at.
  final Offset? at;

  /// `viewer` looks straight out of the screen; `forward` (default when [at]
  /// is null) looks where Fabio is flying.
  final String? target;
  const FabioLookClip({required double t, required this.d, this.at, this.target})
      : super(t);
}

class FabioFxClip extends FabioClip {
  /// Window for continuous modes (`trail`, `rain`) and life for `orbit`.
  final double? d;

  /// Exactly one of [prop] (built-in) and [custom] is set.
  final FabioProp? prop;
  final FabioCustomProp? custom;
  final FabioFxMode mode;
  final int count;

  /// Normalised stage point, or `null` for "wherever Fabio is".
  final Offset? at;
  final double spread;

  /// Particles per second for `trail` and `rain`.
  final double rate;
  final double size;
  final Color? color;

  const FabioFxClip({
    required double t,
    this.d,
    this.prop,
    this.custom,
    this.mode = FabioFxMode.burst,
    this.count = 12,
    this.at,
    this.spread = 1,
    this.rate = 18,
    this.size = 1,
    this.color,
  }) : super(t);

  bool get continuous => mode == FabioFxMode.trail || mode == FabioFxMode.rain;
}

class FabioSpeechClip extends FabioClip {
  final double d;
  final String text;
  const FabioSpeechClip({required double t, required this.d, required this.text}) : super(t);
}

class FabioEventClip extends FabioClip {
  final String name;
  const FabioEventClip({required double t, required this.name}) : super(t);
}

/// Where Fabio is, how big and how visible at a point in time.
class FabioMotionSample {
  final Offset position;
  final double scale;
  final double alpha;
  const FabioMotionSample(this.position, this.scale, this.alpha);
}

/// Resolves a [FabioScript] against a concrete stage size and answers
/// "what should be happening at time t?".
class FabioTimeline {
  final FabioScript script;
  final Size size;
  final List<_Segment> _segments = [];

  /// Puffs of smoke generated for teleports.
  final List<FabioFxClip> derivedFx = [];

  FabioTimeline(this.script, this.size) {
    _resolve();
  }

  double get _minSide => math.max(1, math.min(size.width, size.height));

  Offset _px(Offset n) => Offset(n.dx * size.width, n.dy * size.height);

  void _resolve() {
    var pos = _px(script.start.position);
    var scale = script.start.scale;
    final rng = FabioRandom(script.seed);
    for (final c in script.motion) {
      final seg = _Segment(c, pos, scale, c.scale ?? scale);
      final from = pos;
      switch (c.type) {
        case FabioMotionType.fly:
        case FabioMotionType.dash:
          final spline = _Spline([from, ...c.path.map(_px)]);
          seg.at = spline.at;
          seg.defaultEase = c.type == FabioMotionType.dash ? 'outExpo' : 'inOutCubic';
        case FabioMotionType.hold:
          final to = c.to == null ? from : _px(c.to!);
          seg.at = (u) => Offset.lerp(from, to, u)!;
        case FabioMotionType.orbit:
          final center = c.center == null ? _px(const Offset(0.5, 0.5)) : _px(c.center!);
          final r1 = (c.radius ?? 0.25) * _minSide;
          final r2 = (c.radiusTo ?? c.radius ?? 0.25) * _minSide;
          final r0 = (from - center).distance;
          final a0 = math.atan2(from.dy - center.dy, from.dx - center.dx);
          seg.at = (u) {
            final a = a0 + c.turns * 2 * math.pi * u;
            final r = lerpD(r0, lerpD(r1, r2, u), smoothstep(0, 0.25, u));
            return center + Offset(math.cos(a), math.sin(a)) * r;
          };
          seg.defaultEase = 'inOutSine';
        case FabioMotionType.figure8:
          final s = (c.radius ?? 0.3) * _minSide;
          final center = c.center == null ? from : _px(c.center!);
          seg.at = (u) {
            final th = 2 * math.pi * c.turns * u;
            final p = center + Offset(math.sin(th) * s, math.sin(2 * th) * s * 0.35);
            return Offset.lerp(from, p, smoothstep(0, 0.15, u))!;
          };
          seg.defaultEase = 'inOutSine';
        case FabioMotionType.hop:
          final to = c.to == null ? from : _px(c.to!);
          final h = c.height * _minSide;
          seg.at = (u) =>
              Offset.lerp(from, to, u)! -
              Offset(0, h * (math.sin(math.pi * c.hops * u)).abs());
          seg.defaultEase = 'linear';
        case FabioMotionType.wander:
          final center = c.center == null ? from : _px(c.center!);
          final r = (c.radius ?? 0.15) * _minSide;
          final p1 = rng.range(0, 6.28), p2 = rng.range(0, 6.28);
          final p3 = rng.range(0, 6.28), p4 = rng.range(0, 6.28);
          final secs = c.d;
          seg.at = (u) {
            final s = u * secs;
            final n = Offset(
              math.sin(s * 1.3 + p1) * 0.65 + math.sin(s * 2.9 + p2) * 0.35,
              math.sin(s * 1.7 + p3) * 0.6 + math.sin(s * 3.3 + p4) * 0.4,
            );
            return Offset.lerp(from, center + n * r, smoothstep(0, 0.2, u))!;
          };
          seg.defaultEase = 'linear';
        case FabioMotionType.teleport:
          final to = c.to == null ? from : _px(c.to!);
          seg.at = (u) => u < 0.5 ? from : to;
          seg.alpha = (u) => u < 0.4
              ? 1 - smoothstep(0.1, 0.4, u)
              : (u < 0.6 ? 0 : smoothstep(0.6, 0.85, u));
          seg.scaleMul = (u) => u < 0.4
              ? 1 - ease('inBack', clampD(u / 0.4, 0, 1)) * 0.9
              : (u < 0.6 ? 0.1 : 0.1 + 0.9 * ease('outBack', (u - 0.6) / 0.4));
          seg.defaultEase = 'linear';
          derivedFx.add(FabioFxClip(
              t: c.t + c.d * 0.3,
              prop: FabioProp.puff,
              count: 7,
              at: Offset(from.dx / size.width, from.dy / size.height),
              spread: 0.45));
          derivedFx.add(FabioFxClip(
              t: c.t + c.d * 0.62,
              prop: FabioProp.puff,
              count: 7,
              at: Offset(to.dx / size.width, to.dy / size.height),
              spread: 0.45));
      }
      _segments.add(seg);
      pos = seg.sample(1).position;
      scale = seg.toScale;
    }
    derivedFx.sort((a, b) => a.t.compareTo(b.t));
  }

  FabioMotionSample motionAt(double t) {
    _Segment? last;
    for (final s in _segments) {
      if (t < s.clip.t) break;
      last = s;
    }
    if (last == null) {
      return FabioMotionSample(_px(script.start.position), script.start.scale, 1);
    }
    return last.sample((t - last.clip.t) / last.clip.d);
  }

  FabioExpression expressionAt(double t) {
    var held = script.start.expression;
    var current = held;
    for (final c in script.face) {
      if (c.t > t) break;
      if (c.d == null) {
        held = c.expression;
        current = held;
      } else {
        current = t < c.t + c.d! ? c.expression : held;
      }
    }
    return current;
  }

  FabioLookClip? lookAt(double t) {
    FabioLookClip? active;
    for (final c in script.looks) {
      if (c.t > t) break;
      if (t < c.t + c.d) active = c;
    }
    return active;
  }

  FabioSpeechClip? speechAt(double t) {
    FabioSpeechClip? active;
    for (final c in script.speech) {
      if (c.t > t) break;
      if (t < c.t + c.d) active = c;
    }
    return active;
  }

  Offset stagePoint(Offset normalised) => _px(normalised);
}

class _Segment {
  final FabioMotionClip clip;
  final Offset from;
  final double fromScale;
  final double toScale;
  Offset Function(double u) at = (_) => Offset.zero;
  double Function(double u)? alpha;
  double Function(double u)? scaleMul;
  String defaultEase = 'inOutCubic';

  _Segment(this.clip, this.from, this.fromScale, this.toScale);

  FabioMotionSample sample(double u) {
    u = clampD(u, 0, 1);
    final e = ease(clip.ease ?? defaultEase, u);
    final scale = lerpD(fromScale, toScale, e) * (scaleMul?.call(u) ?? 1);
    return FabioMotionSample(at(e), scale, alpha?.call(u) ?? 1);
  }
}

/// Catmull-Rom spline through points, re-parameterised by arc length so the
/// easing curve alone controls speed.
class _Spline {
  final List<Offset> _lut = [];
  final List<double> _len = [];

  _Spline(List<Offset> pts) {
    if (pts.length == 1) pts = [pts[0], pts[0]];
    const perSeg = 24;
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[math.max(i - 1, 0)];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[math.min(i + 2, pts.length - 1)];
      for (var j = 0; j < perSeg; j++) {
        _lut.add(_cr(p0, p1, p2, p3, j / perSeg));
      }
    }
    _lut.add(pts.last);
    var total = 0.0;
    _len.add(0);
    for (var i = 1; i < _lut.length; i++) {
      total += (_lut[i] - _lut[i - 1]).distance;
      _len.add(total);
    }
  }

  static Offset _cr(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t, t3 = t2 * t;
    return (p1 * 2 +
            (p2 - p0) * t +
            (p0 * 2 - p1 * 5 + p2 * 4 - p3) * t2 +
            (p1 * 3 - p0 - p2 * 3 + p3) * t3) *
        0.5;
  }

  Offset at(double u) {
    final total = _len.last;
    if (total <= 0.0001) return _lut.first;
    final target = clampD(u, 0, 1) * total;
    var lo = 0, hi = _len.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (_len[mid] < target) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final span = _len[hi] - _len[lo];
    final f = span <= 0 ? 0.0 : (target - _len[lo]) / span;
    return Offset.lerp(_lut[lo], _lut[hi], f)!;
  }
}
