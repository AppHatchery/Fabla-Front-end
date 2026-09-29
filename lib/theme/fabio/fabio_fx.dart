import 'dart:math' as math;
import 'dart:ui';

import 'fabio_custom_prop.dart';
import 'fabio_expression.dart';
import 'fabio_math.dart';
import 'fabio_rig.dart';

/// How a batch of props is emitted.
enum FabioFxMode {
  /// Explodes outward in every direction.
  burst,

  /// Shoots upward and falls back down.
  fountain,

  /// Evenly spaced ring expanding outward.
  ring,

  /// A single prop that pops in and drifts up. Great for "!" or "?".
  float,

  /// Falls from the top edge across the whole stage.
  rain,

  /// Circles around Fabio.
  orbit,

  /// Left behind Fabio while he moves (emitted continuously by the stage).
  trail;

  static FabioFxMode? tryParse(Object? name) {
    for (final m in values) {
      if (m.name == name) return m;
    }
    return null;
  }
}

class FabioParticle {
  /// Exactly one of [prop] and [custom] is set.
  final FabioProp? prop;
  final FabioCustomProp? custom;
  double x, y, vx, vy;
  final double gravity;
  final double drag;
  double rot;
  final double spin;
  final double size;
  final double life;
  double age = 0;
  final Color color;
  final double swayPhase;
  final double swayAmp;
  final bool front;

  // Orbit particles follow Fabio instead of integrating velocity.
  double? orbitAngle;
  double orbitRadius = 0;
  double orbitSpeed = 0;

  FabioParticle({
    this.prop,
    this.custom,
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    this.gravity = 0,
    this.drag = 1,
    this.rot = 0,
    this.spin = 0,
    required this.size,
    required this.life,
    required this.color,
    this.swayPhase = 0,
    this.swayAmp = 0,
    this.front = true,
  });

  double get t => age / life;
}

/// How a prop moves once emitted: gravity (px/s², negative floats up),
/// velocity drag, random spin (rad/s) and side-to-side sway (px/s).
class FabioPropPhysics {
  final double gravity;
  final double drag;
  final double spin;
  final double sway;
  const FabioPropPhysics(this.gravity, this.drag, {this.spin = 0, this.sway = 0});

  // Named presets for custom props, borrowed from the built-ins that move
  // that way. Fabio Studio mirrors this list.
  static const float = FabioPropPhysics(-60, 1.5, sway: 10);
  static const rise = FabioPropPhysics(-90, 1.2, sway: 12);
  static const fall = FabioPropPhysics(260, 1.0, spin: 4);
  static const flutter = FabioPropPhysics(380, 1.3, spin: 8, sway: 18);
  static const drift = FabioPropPhysics(0, 2.5);
  static const still = FabioPropPhysics(0, 3);
  static const drop = FabioPropPhysics(500, 0.5);

  static const presets = {
    'float': float,
    'rise': rise,
    'fall': fall,
    'flutter': flutter,
    'drift': drift,
    'still': still,
    'drop': drop,
  };

  static FabioPropPhysics preset(Object? name) => presets[name] ?? float;
}

/// A lightweight particle system for the props Fabio conjures.
class FabioFx {
  static const confettiColors = [
    Color(0xFF4396FE),
    Color(0xFFFEB954),
    Color(0xFFFF6F91),
    Color(0xFF7ED7A8),
    Color(0xFFA8D0FB),
    Color(0xFFF59241),
  ];

  static const Map<FabioProp, Color> defaultColors = {
    FabioProp.sparkle: Color(0xFFFFD84D),
    FabioProp.star: Color(0xFFFFC23D),
    FabioProp.heart: Color(0xFFFF5C8A),
    FabioProp.note: Color(0xFF4396FE),
    FabioProp.confetti: Color(0xFF4396FE),
    FabioProp.bubble: Color(0xFF69ABFE),
    FabioProp.zzz: Color(0xFF5B89FF),
    FabioProp.exclaim: Color(0xFFF59241),
    FabioProp.question: Color(0xFF4396FE),
    FabioProp.check: Color(0xFF34C38F),
    FabioProp.flower: Color(0xFFFF8FAB),
    FabioProp.puff: Color(0xFFFFFFFF),
    FabioProp.drop: Color(0xFF69ABFE),
    FabioProp.mic: Color(0xFF4396FE),
  };

  static const Map<FabioProp, FabioPropPhysics> _physics = {
    FabioProp.sparkle: FabioPropPhysics(0, 2.5),
    FabioProp.star: FabioPropPhysics(260, 1.0, spin: 4),
    FabioProp.heart: FabioPropPhysics(-60, 1.5, sway: 10),
    FabioProp.note: FabioPropPhysics(-80, 1.5, sway: 14),
    FabioProp.confetti: FabioPropPhysics(380, 1.3, spin: 8, sway: 18),
    FabioProp.bubble: FabioPropPhysics(-90, 1.2, sway: 12),
    FabioProp.zzz: FabioPropPhysics(-50, 1.0, sway: 12),
    FabioProp.exclaim: FabioPropPhysics(0, 3),
    FabioProp.question: FabioPropPhysics(0, 3),
    FabioProp.check: FabioPropPhysics(0, 3),
    FabioProp.flower: FabioPropPhysics(150, 1.5, spin: 3, sway: 10),
    FabioProp.puff: FabioPropPhysics(-20, 3),
    FabioProp.drop: FabioPropPhysics(500, 0.5),
    FabioProp.mic: FabioPropPhysics(0, 3, spin: 0.5),
  };

  final List<FabioParticle> particles = [];
  final FabioRandom _rng;

  /// Scale factor for sizes and speeds (1 = Fabio drawn 110px wide).
  double unit = 1;

  /// Stage size, used by [FabioFxMode.rain].
  Size bounds = Size.zero;

  /// Where Fabio currently is, used by orbiting props.
  Offset anchor = Offset.zero;

  FabioFx({int seed = 11}) : _rng = FabioRandom(seed);

  static const int maxParticles = 400;

  void emit(
    FabioProp prop,
    FabioFxMode mode,
    Offset at, {
    int count = 12,
    Color? color,
    double spread = 1,
    double sizeScale = 1,
    double? life,
  }) =>
      _emit(mode, at, _physics[prop]!, color ?? defaultColors[prop]!,
          prop: prop,
          randomConfetti: prop == FabioProp.confetti && color == null,
          count: count,
          spread: spread,
          sizeScale: sizeScale,
          life: life);

  /// Emits a data-defined prop (see [FabioCustomProp]).
  void emitCustom(
    FabioCustomProp custom,
    FabioFxMode mode,
    Offset at, {
    int count = 12,
    Color? color,
    double spread = 1,
    double sizeScale = 1,
    double? life,
  }) =>
      _emit(mode, at, custom.physics, color ?? custom.color,
          custom: custom,
          count: count,
          spread: spread,
          sizeScale: sizeScale * custom.size,
          life: life);

  void _emit(
    FabioFxMode mode,
    Offset at,
    FabioPropPhysics phys,
    Color baseColor, {
    FabioProp? prop,
    FabioCustomProp? custom,
    bool randomConfetti = false,
    required int count,
    required double spread,
    required double sizeScale,
    required double? life,
  }) {
    final u = unit;
    for (var i = 0; i < count; i++) {
      if (particles.length >= maxParticles) particles.removeAt(0);
      double angle, speed, gravity = phys.gravity * u, drag = phys.drag;
      double px = at.dx, py = at.dy;
      var plife = life ?? _rng.range(0.9, 1.6);
      var size = 15 * u * sizeScale * _rng.range(0.75, 1.25);
      var front = true;
      switch (mode) {
        case FabioFxMode.burst:
          angle = _rng.range(0, 2 * math.pi);
          speed = _rng.range(140, 330) * u * spread;
        case FabioFxMode.fountain:
          angle = -math.pi / 2 + _rng.range(-0.55, 0.55) * spread;
          speed = _rng.range(260, 440) * u;
          gravity = math.max(gravity, 0) + 520 * u;
          plife = life ?? _rng.range(1.2, 1.9);
        case FabioFxMode.ring:
          angle = i / count * 2 * math.pi;
          speed = 230 * u * spread;
          drag = 3;
          gravity = 0;
          plife = life ?? 0.9;
        case FabioFxMode.float:
          angle = -math.pi / 2 + _rng.range(-0.3, 0.3);
          speed = _rng.range(30, 50) * u;
          gravity = 0;
          drag = 0.5;
          plife = life ?? 1.8;
          size *= 1.35;
          px += _rng.range(-8, 8) * u * (count > 1 ? spread * 3 : 0);
        case FabioFxMode.rain:
          px = _rng.range(0, math.max(bounds.width, 1));
          py = -20 * u - _rng.range(0, bounds.height * 0.3);
          angle = math.pi / 2;
          speed = _rng.range(120, 260) * u;
          gravity = gravity.abs() * 0.3 + 40 * u;
          drag = 0.2;
          plife = life ?? (bounds.height / (speed + 1) + 1.2);
        case FabioFxMode.orbit:
          angle = 0;
          speed = 0;
          plife = life ?? 2;
        case FabioFxMode.trail:
          angle = _rng.range(0, 2 * math.pi);
          speed = _rng.range(8, 36) * u;
          gravity *= 0.25;
          plife = life ?? _rng.range(0.5, 0.9);
          size *= 0.7;
          front = false;
      }
      final pColor = randomConfetti ? _rng.pick(confettiColors) : baseColor;
      final p = FabioParticle(
        prop: prop,
        custom: custom,
        x: px,
        y: py,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        gravity: gravity,
        drag: drag,
        rot: phys.spin == 0 ? 0 : _rng.range(-math.pi, math.pi),
        spin: phys.spin * _rng.range(-1, 1),
        size: size,
        life: plife,
        color: pColor,
        swayPhase: _rng.range(0, 2 * math.pi),
        swayAmp: phys.sway * u,
        front: front,
      );
      if (mode == FabioFxMode.orbit) {
        p.orbitAngle = i / count * 2 * math.pi;
        p.orbitRadius = 88 * u * spread;
        p.orbitSpeed = 3.2;
      }
      particles.add(p);
    }
  }

  void update(double dt) {
    for (final p in particles) {
      p.age += dt;
      final orbit = p.orbitAngle;
      if (orbit != null) {
        final a = orbit + p.orbitSpeed * p.age;
        final r = p.orbitRadius * ease('outBack', clampD(p.age / 0.4, 0, 1));
        p.x = anchor.dx + math.cos(a) * r;
        p.y = anchor.dy + math.sin(a) * r * 0.55;
        continue;
      }
      final k = math.exp(-p.drag * dt);
      p.vx *= k;
      p.vy = p.vy * k + p.gravity * dt;
      p.x += p.vx * dt + math.cos(p.age * 3 + p.swayPhase) * p.swayAmp * dt;
      p.y += p.vy * dt;
      p.rot += p.spin * dt;
    }
    particles.removeWhere((p) => p.age >= p.life);
  }

  void clear() => particles.clear();

  void paint(Canvas canvas, {required bool front}) {
    for (final p in particles) {
      if (p.front != front) continue;
      final t = p.t;
      final popIn = ease('outBack', clampD(p.age / 0.18, 0, 1));
      var alpha = 1 - smoothstep(0.7, 1, t);
      var scale = popIn;
      if (p.prop == FabioProp.puff) {
        scale = popIn * (1 + t * 0.9);
        alpha = 1 - t;
      }
      if (p.prop == FabioProp.sparkle) scale *= 0.75 + 0.25 * math.sin(p.age * 18);
      if (alpha <= 0.01 || scale <= 0.01) continue;
      final orbitFront = p.orbitAngle == null ||
          math.sin(p.orbitAngle! + p.orbitSpeed * p.age) >= 0;
      if (!orbitFront) alpha *= 0.55;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rot);
      final custom = p.custom;
      if (custom != null) {
        custom.paint(canvas, p.size / 2 * scale, p.color, alpha);
      } else {
        paintProp(canvas, p.prop!, p.size / 2 * scale, p.color, alpha, p.age);
      }
      canvas.restore();
    }
  }

  /// Draws [prop] centred on the origin with radius [r].
  static void paintProp(
      Canvas canvas, FabioProp prop, double r, Color color, double alpha, double age) {
    Paint fill(Color c, [double a = 1]) => Paint()..color = c.withValues(alpha: alpha * a);
    Paint stroke(Color c, double w) => Paint()
      ..color = c.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w;
    const white = Color(0xFFFFFFFF);
    const ink = Color(0xFF242424);

    switch (prop) {
      case FabioProp.sparkle:
        final c = r * 0.14;
        final path = Path()
          ..moveTo(0, -r)
          ..quadraticBezierTo(c, -c, r, 0)
          ..quadraticBezierTo(c, c, 0, r)
          ..quadraticBezierTo(-c, c, -r, 0)
          ..quadraticBezierTo(-c, -c, 0, -r)
          ..close();
        canvas.drawPath(path, fill(color));
        canvas.drawCircle(Offset.zero, r * 0.18, fill(white, 0.9));
      case FabioProp.star:
        final path = FabioRig.starPath(r, r * 0.48);
        canvas.drawPath(path, fill(color));
        canvas.drawPath(path, stroke(const Color(0xFFE09A00), r * 0.12));
      case FabioProp.heart:
        canvas.drawPath(FabioRig.unitHeart(r), fill(color));
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(-r * 0.42, -r * 0.4), width: r * 0.34, height: r * 0.22),
            fill(white, 0.8));
      case FabioProp.note:
        canvas.save();
        canvas.translate(-r * 0.3, r * 0.55);
        canvas.rotate(-0.4);
        canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: r * 0.95, height: r * 0.68),
            fill(color));
        canvas.restore();
        canvas.drawLine(Offset(r * 0.12, r * 0.5), Offset(r * 0.12, -r * 0.85),
            stroke(color, r * 0.18));
        final flag = Path()
          ..moveTo(r * 0.12, -r * 0.85)
          ..cubicTo(r * 0.3, -r * 0.55, r * 0.8, -r * 0.5, r * 0.6, -r * 0.1);
        canvas.drawPath(flag, stroke(color, r * 0.18));
      case FabioProp.confetti:
        canvas.scale(math.cos(age * 9 + r), 1);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset.zero, width: r * 1.2, height: r * 0.6),
                Radius.circular(r * 0.12)),
            fill(color));
      case FabioProp.bubble:
        canvas.drawCircle(Offset.zero, r, fill(color, 0.16));
        canvas.drawCircle(Offset.zero, r, stroke(color, r * 0.12));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.62), -2.6, 0.9,
            false, stroke(white, r * 0.14));
      case FabioProp.zzz:
        final path = Path()
          ..moveTo(-r * 0.5, -r * 0.5)
          ..lineTo(r * 0.5, -r * 0.5)
          ..lineTo(-r * 0.5, r * 0.5)
          ..lineTo(r * 0.5, r * 0.5);
        canvas.drawPath(path, stroke(color, r * 0.24));
      case FabioProp.exclaim:
        canvas.drawLine(Offset(0, -r), Offset(0, r * 0.3), stroke(color, r * 0.4));
        canvas.drawCircle(Offset(0, r * 0.82), r * 0.22, fill(color));
      case FabioProp.question:
        final path = Path()
          ..moveTo(-r * 0.45, -r * 0.4)
          ..cubicTo(-r * 0.45, -r * 1.05, r * 0.55, -r * 1.05, r * 0.5, -r * 0.4)
          ..cubicTo(r * 0.45, -r * 0.05, 0, -r * 0.05, 0, r * 0.3);
        canvas.drawPath(path, stroke(color, r * 0.3));
        canvas.drawCircle(Offset(0, r * 0.82), r * 0.19, fill(color));
      case FabioProp.check:
        canvas.drawCircle(Offset.zero, r, fill(color));
        final path = Path()
          ..moveTo(-r * 0.45, 0)
          ..lineTo(-r * 0.1, r * 0.35)
          ..lineTo(r * 0.5, -r * 0.35);
        canvas.drawPath(path, stroke(white, r * 0.24));
      case FabioProp.flower:
        for (var i = 0; i < 5; i++) {
          final a = i / 5 * 2 * math.pi;
          canvas.drawCircle(
              Offset(math.cos(a) * r * 0.55, math.sin(a) * r * 0.55), r * 0.45, fill(color));
        }
        canvas.drawCircle(Offset.zero, r * 0.36, fill(const Color(0xFFFFD84D)));
      case FabioProp.puff:
        final p = fill(color, 0.9);
        canvas.drawCircle(Offset(-r * 0.45, r * 0.12), r * 0.5, p);
        canvas.drawCircle(Offset(r * 0.42, r * 0.16), r * 0.5, p);
        canvas.drawCircle(Offset(0, -r * 0.22), r * 0.62, p);
      case FabioProp.drop:
        final path = Path()
          ..moveTo(0, -r)
          ..cubicTo(r * 0.9, 0, r * 0.75, r, 0, r)
          ..cubicTo(-r * 0.75, r, -r * 0.9, 0, 0, -r)
          ..close();
        canvas.drawPath(path, fill(color));
        canvas.drawCircle(Offset(-r * 0.25, r * 0.3), r * 0.16, fill(white, 0.8));
      case FabioProp.mic:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset(0, -r * 0.35), width: r * 0.9, height: r * 1.25),
                Radius.circular(r * 0.45)),
            fill(color));
        for (var i = 0; i < 3; i++) {
          final y = -r * 0.7 + i * r * 0.28;
          canvas.drawLine(Offset(-r * 0.22, y), Offset(r * 0.22, y), stroke(white, r * 0.08));
        }
        canvas.drawArc(
            Rect.fromCenter(center: Offset(0, -r * 0.1), width: r * 1.35, height: r * 1.2),
            0.15,
            math.pi - 0.3,
            false,
            stroke(ink, r * 0.12));
        canvas.drawLine(Offset(0, r * 0.5), Offset(0, r * 0.85), stroke(ink, r * 0.12));
        canvas.drawLine(
            Offset(-r * 0.35, r * 0.88), Offset(r * 0.35, r * 0.88), stroke(ink, r * 0.12));
    }
  }
}
