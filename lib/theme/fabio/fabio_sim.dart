import 'dart:math' as math;
import 'dart:ui';

import 'fabio_expression.dart';
import 'fabio_math.dart';
import 'fabio_rig.dart';

/// Fabio's "brain": turns high level intent (expression, velocity, gestures,
/// where to look) into a fully animated [FabioPose] every tick.
///
/// Everything that makes him feel alive without being told to — hovering,
/// breathing, blinking, glancing around, his tuft and hem trailing behind
/// movement, jelly wobble after sudden stops — lives here.
class FabioSim {
  final FabioPose pose = FabioPose();
  final FabioRandom _rng;

  double time = 0;

  /// Resting expression. Use [flashExpression] for a temporary one.
  FabioExpression expression;

  /// Velocity in Fabio-widths per second. Owners that move Fabio (the stage)
  /// set this every frame so the body leans and trails.
  Offset velocity = Offset.zero;

  /// Explicit gaze direction, each axis -1..1. `null` lets Fabio look around
  /// on his own (or where he is flying).
  Offset? lookTarget;

  /// 0 disables the idle hover bob, 1 is the default.
  double hover = 1;
  bool autoBlink = true;

  FabioExpression? _flash;
  double _flashUntil = 0;

  Offset _vel = Offset.zero;
  Offset _drag = Offset.zero;
  Offset _look = Offset.zero;
  Offset _saccade = Offset.zero;
  double _nextSaccade = 1;
  Offset _tuft = Offset.zero;
  Offset _tuftVel = Offset.zero;
  double _wobbleEnergy = 0;
  double _facingTarget = 1;
  double _nextBlink = 1.5;
  double _blinkStart = -10;
  bool _doubleBlink = false;
  double _eyeOpenLeft = 1;
  double _eyeOpenRight = 1;
  double _tilt = 0;
  final List<_ActiveGesture> _gestures = [];

  FabioSim({this.expression = FabioExpression.neutral, int seed = 7})
      : _rng = FabioRandom(seed);

  FabioExpression get currentExpression => _flash ?? expression;

  bool get isGesturing => _gestures.isNotEmpty;

  /// Shows [e] for [seconds], then returns to [expression].
  void flashExpression(FabioExpression e, double seconds) {
    _flash = e;
    _flashUntil = time + seconds;
  }

  void clearFlash() => _flash = null;

  void play(FabioGesture gesture, {double? duration}) {
    _gestures.add(_ActiveGesture(
      gesture,
      time,
      duration ?? gesture.duration,
      pose.facing >= 0 ? 1 : -1,
    ));
  }

  void blink() {
    _blinkStart = time;
    _doubleBlink = false;
  }

  /// Turns Fabio to face left (-1) or right (1).
  void face(double direction) => _facingTarget = direction.sign == 0 ? 1 : direction.sign;

  void update(double dt) {
    dt = clampD(dt, 0, 1 / 20);
    if (dt == 0) return;
    time += dt;
    final p = pose;

    if (_flash != null && time >= _flashUntil) _flash = null;
    final face = currentExpression.face;

    final fx = _GestureFx();
    _gestures.removeWhere((g) => (time - g.start) >= g.duration);
    for (final g in _gestures) {
      _applyGesture(g, (time - g.start) / g.duration, time - g.start, fx);
    }

    // Motion response.
    final prevVel = _vel;
    _vel = _approachOffset(_vel, velocity, 10, dt);
    final accel = (_vel - prevVel).distance / dt;
    _wobbleEnergy = math.min(_wobbleEnergy + accel * 0.0025 * dt * 60, 0.9);
    _wobbleEnergy *= math.exp(-3.5 * dt);
    final speed = _vel.distance;
    _drag = _approachOffset(_drag, _clampOffset(_vel * 0.22, 1.2), 5, dt);

    final look = lookTarget;
    if (look != null && look.dx.abs() > 0.35) {
      _facingTarget = look.dx.sign;
    } else if (_vel.dx.abs() > 0.35) {
      _facingTarget = _vel.dx.sign;
    }
    p.facing = approach(p.facing, _facingTarget, 8, dt);

    Offset desired;
    if (look != null) {
      desired = look;
    } else if (speed > 0.4) {
      desired = _vel / speed * math.min(speed / 2.5, 1);
    } else {
      if (time >= _nextSaccade) {
        final wide = _rng.next() < 0.35;
        _saccade = Offset(
          _rng.range(-1, 1) * (wide ? 0.75 : 0.3),
          _rng.range(-1, 1) * (wide ? 0.5 : 0.2),
        );
        _nextSaccade = time + _rng.range(0.7, 2.8);
      }
      desired = _saccade;
    }
    desired += Offset(face.lookBiasX + fx.lookX, face.lookBiasY + fx.lookY);
    _look = _approachOffset(_look, _clampOffset(desired, 1), 14, dt);
    p.lookX = clampD(_look.dx, -1, 1);
    p.lookY = clampD(_look.dy, -1, 1);

    // Blinking.
    if (autoBlink && time >= _nextBlink) {
      _blinkStart = time;
      _doubleBlink = _rng.next() < 0.18;
      _nextBlink = time + _rng.range(2.0, 5.5) + (_doubleBlink ? 0.4 : 0);
    }
    var blink = _blinkCurve(time - _blinkStart);
    if (_doubleBlink) blink = math.max(blink, _blinkCurve(time - _blinkStart - 0.24));

    // Face.
    const rate = 11.0;
    _eyeOpenLeft = approach(_eyeOpenLeft, face.eyeOpenLeft * fx.eyeOpenMul, rate, dt);
    _eyeOpenRight = approach(_eyeOpenRight, face.eyeOpenRight * fx.eyeOpenMul, rate, dt);
    p.eyeOpenLeft = _eyeOpenLeft * (1 - blink);
    p.eyeOpenRight = _eyeOpenRight * (1 - blink);
    p.eyeHappy = approach(p.eyeHappy, clampD(face.eyeHappy + fx.eyeHappy, 0, 1), rate, dt);
    p.eyeScale = approach(p.eyeScale, math.max(0.5, face.eyeScale + fx.eyeScale), 14, dt);

    final shape = fx.eyeShape ?? face.eyeShape;
    if (p.eyeShape != shape) {
      p.eyeShapeAmount -= dt * 9;
      if (p.eyeShapeAmount <= 0) {
        p.eyeShapeAmount = 0;
        p.eyeShape = shape;
      }
    } else if (shape != FabioEyeShape.none) {
      p.eyeShapeAmount = math.min(1, p.eyeShapeAmount + dt * 5);
    }
    p.eyeSpin += dt * 7;

    p.mouthOpen = approach(p.mouthOpen, clampD(face.mouthOpen + fx.mouthOpen, 0, 1.2), rate, dt);
    p.mouthSmile = approach(p.mouthSmile, clampD(face.mouthSmile + fx.mouthSmile, -1, 1), rate, dt);
    p.mouthWidth = approach(p.mouthWidth, face.mouthWidth, rate, dt);
    p.mouthRound = approach(p.mouthRound, clampD(face.mouthRound + fx.mouthRound, 0, 1), rate, dt);
    p.blush = approach(p.blush, clampD(face.blush + fx.blush, 0, 1), 5, dt);
    _tilt = approach(_tilt, face.tilt + fx.tilt, 8, dt);

    // Body.
    final bob = math.sin(time * 2.1) * 2.6 * hover;
    final lean = clampD(_vel.dx * 0.07, -0.4, 0.4);
    p.rotation = lean + _tilt + math.sin(time * 1.05 + 0.4) * 0.025 * hover + fx.rot;
    p.offsetX = fx.dx;
    p.offsetY = bob + fx.dy;
    p.stretch = (1 + clampD(_vel.dy.abs() * 0.035 - _vel.dx.abs() * 0.012, -0.08, 0.14)) *
        fx.stretch;
    p.scale = fx.scale;
    p.breath = math.sin(time * 1.6);
    p.dragX = _drag.dx;
    p.dragY = _drag.dy;
    p.flare = clampD(-_vel.dy * 0.03, -0.06, 0.12) + fx.flare;
    p.hemAmp = 1.4 + math.min(speed * 0.5, 3.2);
    p.hemPhase += dt * (3.2 + math.min(speed, 6) * 1.1);
    p.wobble = _wobbleEnergy + fx.wobble;
    p.wobblePhase += dt * 16;

    // The tuft is a damped spring so it overshoots and settles.
    final tuftTarget = Offset(
      clampD(-_vel.dx * 2.2 + math.sin(time * 1.7) * 0.6, -7, 7),
      clampD(-_vel.dy * 1.5 + math.cos(time * 1.3) * 0.4, -7, 7),
    );
    final force = (tuftTarget - _tuft) * 90 - _tuftVel * 9;
    _tuftVel += force * dt;
    _tuft += _tuftVel * dt;
    p.tuftX = _tuft.dx;
    p.tuftY = _tuft.dy;

    p.armLeft = fx.armLeft;
    p.armRight = fx.armRight;
    if (fx.armLeft > 0) p.armLeftAngle = fx.armLeftAngle;
    if (fx.armRight > 0) p.armRightAngle = fx.armRightAngle;
  }

  static double _blinkCurve(double e) {
    const d = 0.16;
    if (e < 0 || e > d) return 0;
    return math.sin(math.pi * e / d);
  }

  static Offset _approachOffset(Offset c, Offset t, double rate, double dt) {
    final k = 1 - math.exp(-rate * dt);
    return c + (t - c) * k;
  }

  static Offset _clampOffset(Offset o, double max) {
    final d = o.distance;
    return d > max ? o / d * max : o;
  }

  void _applyGesture(_ActiveGesture g, double u, double e, _GestureFx fx) {
    final env = envelope(u);
    final bell = math.sin(math.pi * u);
    switch (g.gesture) {
      case FabioGesture.bounce:
        fx.jump(u, 24);
      case FabioGesture.hop:
        fx.jump(u, 11, takeoff: 0.12, landing: 0.85);
      case FabioGesture.spin:
        fx.rot += 2 * math.pi * ease('inOutCubic', u) * g.side;
        fx.stretch *= 1 + 0.06 * bell;
        fx.dy -= 6 * bell;
        fx.eyeHappy += 0.6 * env;
      case FabioGesture.flip:
        fx.jump(u, 32, takeoff: 0.15, landing: 0.85);
        final air = clampD((u - 0.15) / 0.7, 0, 1);
        fx.rot -= 2 * math.pi * ease('inOutSine', air) * g.side;
        fx.eyeHappy += env;
        fx.mouthOpen += 0.4 * env;
      case FabioGesture.shake:
        final w = math.sin(u * math.pi * 6) * bell;
        fx.lookX += w * 0.9;
        fx.rot += w * 0.07;
        fx.mouthSmile -= 0.3 * bell;
      case FabioGesture.nod:
        final w = math.sin(u * math.pi * 4) * bell;
        fx.lookY += w * 0.7;
        fx.dy += w * 2.2;
        fx.rot += w * 0.03;
        fx.mouthSmile += 0.2 * bell;
      case FabioGesture.wiggle:
        fx.wobble += 0.9 * bell;
        fx.stretch *= 1 + 0.04 * math.sin(u * math.pi * 8);
        fx.eyeHappy += 0.5 * env;
      case FabioGesture.pop:
        fx.scale *= 1 + 0.55 * math.exp(-5 * u) * math.sin(u * math.pi * 3.2);
        fx.eyeScale += 0.25 * env;
      case FabioGesture.wave:
        final a = envelope(u, attack: 0.12, release: 0.18);
        final angle = -1.0 + 0.5 * math.sin(e * 13);
        fx.arm(g.side, a, angle);
        fx.eyeHappy += 0.9 * a;
        fx.mouthOpen += 0.25 * a;
        fx.mouthSmile += 0.4 * a;
        fx.rot += 0.06 * a * g.side;
      case FabioGesture.cheer:
        final a = envelope(u, attack: 0.1, release: 0.2);
        fx.arm(1, a, -1.15 + 0.3 * math.sin(e * 16));
        fx.arm(-1, a, -1.15 + 0.3 * math.sin(e * 16 + 1.4));
        fx.dy -= 12 * (math.sin(2 * math.pi * u)).abs() * a;
        fx.stretch *= 1 + 0.05 * math.sin(4 * math.pi * u);
        fx.eyeHappy += a;
        fx.mouthOpen += 0.5 * a;
        fx.mouthSmile += 0.5 * a;
      case FabioGesture.shiver:
        fx.dx += math.sin(e * 85) * 1.6 * env;
        fx.stretch *= 1 - 0.03 * env;
        fx.mouthSmile -= 0.5 * env;
        fx.mouthOpen -= 0.4 * env;
        fx.eyeScale -= 0.1 * env;
      case FabioGesture.squish:
        final attack = smoothstep(0, 0.06, u);
        fx.stretch *= 1 - 0.34 * math.exp(-5 * u) * math.cos(u * math.pi * 5) * attack;
        fx.eyeOpenMul *= 1 - 0.75 * math.exp(-6 * u) * attack;
        fx.eyeHappy += 0.6 * env;
        fx.blush += 0.4 * env;
      case FabioGesture.dizzy:
        final a = envelope(u, attack: 0.1, release: 0.25);
        fx.rot += math.sin(e * 9) * 0.16 * a;
        fx.dx += math.cos(e * 9) * 5 * a;
        if (u < 0.85) fx.eyeShape = FabioEyeShape.spiral;
        fx.mouthSmile -= 0.4 * a;
        fx.mouthOpen += 0.2 * a;
      case FabioGesture.laugh:
        fx.dy -= (math.sin(e * 20)).abs() * 3.2 * env;
        fx.eyeHappy += env;
        fx.mouthOpen += 0.6 * env;
        fx.mouthSmile += 0.6 * env;
        fx.stretch *= 1 + 0.035 * math.sin(e * 40) * env;
        fx.rot += math.sin(e * 10) * 0.04 * env;
        fx.blush += 0.3 * env;
      case FabioGesture.yawn:
        final a = envelope(u, attack: 0.3, release: 0.3);
        fx.stretch *= 1 + 0.09 * a;
        fx.eyeOpenMul *= 1 - 0.92 * a;
        fx.mouthRound += a;
        fx.mouthOpen += 0.9 * a;
        fx.arm(1, 0.75 * a, -1.3);
        fx.arm(-1, 0.75 * a, -1.3);
        fx.tilt += 0.08 * a * g.side;
      case FabioGesture.startle:
        final jolt = math.sin(math.pi * clampD(u / 0.5, 0, 1));
        fx.dy -= 14 * jolt;
        fx.stretch *= 1 + 0.16 * math.sin(math.pi * clampD(u / 0.3, 0, 1));
        fx.eyeScale += 0.45 * envelope(u, attack: 0.05, release: 0.4);
        fx.mouthRound += env;
        fx.mouthOpen += 0.5 * env;
        fx.dx += math.sin(e * 70) * env;
        fx.armLeft = math.max(fx.armLeft, 0.6 * jolt);
        fx.armRight = math.max(fx.armRight, 0.6 * jolt);
        fx.armLeftAngle = fx.armRightAngle = -0.9;
      case FabioGesture.tada:
        final a = envelope(u, attack: 0.12, release: 0.2);
        fx.arm(1, a, -0.6);
        fx.arm(-1, a, -0.6);
        fx.scale *= 1 + 0.12 * a;
        fx.dy -= 8 * math.sin(math.pi * clampD(u / 0.3, 0, 1));
        fx.eyeHappy += a;
        fx.mouthOpen += 0.6 * a;
        fx.mouthSmile += 0.6 * a;
      case FabioGesture.think:
        final a = envelope(u, attack: 0.2, release: 0.2);
        fx.lookX += 0.55 * a * g.side;
        fx.lookY -= 0.8 * a;
        fx.tilt += 0.14 * a * g.side;
        fx.mouthSmile -= 0.2 * a;
        fx.mouthOpen -= 0.45 * a;
        fx.arm(g.side, 0.55 * a, -2.2);
    }
  }
}

class _ActiveGesture {
  final FabioGesture gesture;
  final double start;
  final double duration;

  /// Which side the gesture favours (1 = right), fixed when it starts.
  final double side;
  _ActiveGesture(this.gesture, this.start, this.duration, this.side);
}

/// Additive contribution of all running gestures for one frame.
class _GestureFx {
  double dx = 0, dy = 0, rot = 0, stretch = 1, scale = 1, wobble = 0, flare = 0;
  double armLeft = 0, armLeftAngle = 0, armRight = 0, armRightAngle = 0;
  double lookX = 0, lookY = 0, tilt = 0;
  double eyeHappy = 0, eyeOpenMul = 1, eyeScale = 0;
  FabioEyeShape? eyeShape;
  double mouthOpen = 0, mouthSmile = 0, mouthRound = 0, blush = 0;

  void arm(double side, double ext, double angle) {
    if (side >= 0) {
      if (ext >= armRight) {
        armRight = ext;
        armRightAngle = angle;
      }
    } else if (ext >= armLeft) {
      armLeft = ext;
      armLeftAngle = angle;
    }
  }

  /// Anticipation squash, airborne arc with stretch, landing squash.
  void jump(double u, double height,
      {double takeoff = 0.18, double landing = 0.82}) {
    if (u < takeoff) {
      stretch *= 1 - 0.18 * math.sin(math.pi * u / takeoff);
    } else if (u < landing) {
      final v = (u - takeoff) / (landing - takeoff);
      dy -= height * 4 * v * (1 - v);
      stretch *= 1 +
          0.14 * (1 - 2 * v).abs() * smoothstep(0, 0.12, v) * (1 - smoothstep(0.88, 1, v));
      flare += 0.05 * (1 - v);
    } else {
      final v = (u - landing) / (1 - landing);
      stretch *= 1 - 0.16 * math.sin(math.pi * v);
    }
  }
}
