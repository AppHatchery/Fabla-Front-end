import 'dart:math' as math;
import 'dart:ui';

import 'fabio_expression.dart';
import 'fabio_math.dart';

/// Every animatable property of Fabio for a single frame.
///
/// Units are "rig units": the coordinate space of the original 144x138 SVG.
/// [FabioSim] writes this every tick and [FabioRig.paint] reads it.
class FabioPose {
  // Body transform.
  double offsetX = 0;
  double offsetY = 0;
  double rotation = 0;
  double scale = 1;

  /// Vertical squash (<1) and stretch (>1); width compensates to keep volume.
  double stretch = 1;
  double breath = 0;

  // Secondary motion.
  double dragX = 0;
  double dragY = 0;
  double flare = 0;
  double hemPhase = 0;
  double hemAmp = 1.6;
  double wobble = 0;
  double wobblePhase = 0;
  double tuftX = 0;
  double tuftY = 0;

  // Face.
  /// 1 = face on the right (original art), -1 = mirrored to the left.
  double facing = 1;
  double lookX = 0;
  double lookY = 0;
  double eyeOpenLeft = 1;
  double eyeOpenRight = 1;
  double eyeHappy = 0;
  double eyeScale = 1;
  FabioEyeShape eyeShape = FabioEyeShape.none;
  double eyeShapeAmount = 0;
  double eyeSpin = 0;
  double mouthOpen = 0.62;
  double mouthSmile = 0.2;
  double mouthWidth = 1;
  double mouthRound = 0;
  double blush = 0;

  // Arms only appear during gestures. Angle 0 points straight out,
  // negative raises the arm.
  double armLeft = 0;
  double armRight = 0;
  double armLeftAngle = 0;
  double armRightAngle = 0;

  // Look.
  double opacity = 1;
  double shine = 0.2;
  Color color = FabioRig.bodyColor;
}

/// Draws Fabio procedurally from the original SVG outline.
abstract final class FabioRig {
  static const double width = 144;
  static const double height = 138;
  static const Offset pivot = Offset(72, 69);
  static const Color bodyColor = Color(0xFFA8D0FB);
  static const Color _ink = Color(0xFF000000);

  /// The body outline from `fabio.svg`, as absolute cubic segments.
  static const List<List<double>> _bodyCubics = [
    [63.0013, 0.240728, 55.1218, 1.29124, 30.0286, 9.3728, 17.6638, 14.8682],
    [17.6638, 14.8682, 13.85, 16.5632, 9.33981, 27.8797, 21.4217, 32.5668],
    [21.4217, 32.5668, 21.4217, 62.2652, 5.69657, 118.136, 0.695832, 130.861],
    [0.695832, 130.861, 0.319211, 131.819, 0.669977, 132.91, 1.59468, 133.363],
    [1.59468, 133.363, 9.59124, 137.28, 24.1941, 139.066, 34, 135.5],
    [34, 135.5, 61, 125.68, 59, 143.892, 85.5, 135.5],
    [85.5, 135.5, 111.306, 127.328, 123.835, 141.236, 142.02, 133.197],
    [142.02, 133.197, 142.888, 132.814, 143.335, 131.885, 143.077, 130.972],
    [143.077, 130.972, 139.462, 118.175, 119.647, 52.2539, 107.773, 30.5062],
    [107.773, 30.5062, 92.1758, 1.93786, 72.6142, -1.04087, 63.0013, 0.240728],
  ];

  static final List<Offset> _outline = _sampleOutline();

  static List<Offset> _sampleOutline() {
    final points = <Offset>[];
    for (final c in _bodyCubics) {
      final polyLen = _dist(c[0], c[1], c[2], c[3]) +
          _dist(c[2], c[3], c[4], c[5]) +
          _dist(c[4], c[5], c[6], c[7]);
      final n = math.max(4, (polyLen / 2.2).ceil());
      for (var i = 0; i < n; i++) {
        final t = i / n;
        final mt = 1 - t;
        final a = mt * mt * mt, b = 3 * mt * mt * t, cc = 3 * mt * t * t;
        final d = t * t * t;
        points.add(Offset(
          a * c[0] + b * c[2] + cc * c[4] + d * c[6],
          a * c[1] + b * c[3] + cc * c[5] + d * c[7],
        ));
      }
    }
    return points;
  }

  static double _dist(double x1, double y1, double x2, double y2) =>
      math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));

  /// Paints Fabio with his visual centre at [center], [size] logical pixels
  /// wide (before [FabioPose.scale]).
  static void paint(Canvas canvas, FabioPose pose, Offset center, double size) {
    if (pose.opacity <= 0.001 || pose.scale <= 0.001) return;
    final k = size / width * pose.scale;
    canvas.save();
    canvas.translate(center.dx + pose.offsetX * k, center.dy + pose.offsetY * k);
    canvas.rotate(pose.rotation);
    canvas.scale(k);
    canvas.translate(-pivot.dx, -pivot.dy);

    final faded = pose.opacity < 0.999;
    if (faded) {
      canvas.saveLayer(const Rect.fromLTWH(-90, -90, 324, 318),
          Paint()..color = _ink.withValues(alpha: pose.opacity));
    }

    final d = _Deformer(pose);
    final bodyPaint = Paint()
      ..isAntiAlias = true
      ..shader = Gradient.linear(
        const Offset(40, 0),
        const Offset(100, 140),
        [
          Color.lerp(pose.color, const Color(0xFFFFFFFF), 0.16)!,
          pose.color,
          Color.lerp(pose.color, const Color(0xFF5B89FF), 0.16)!,
        ],
        const [0, 0.5, 1],
      );

    _paintArms(canvas, pose, d, bodyPaint);
    final body = _bodyPath(d);
    canvas.drawPath(body, bodyPaint);
    if (pose.shine > 0.01) _paintShine(canvas, pose, d, body);
    _paintFace(canvas, pose, d);

    if (faded) canvas.restore();
    canvas.restore();
  }

  static Path _bodyPath(_Deformer d) {
    final pts = _outline.map((p) => d.apply(p.dx, p.dy)).toList();
    final n = pts.length;
    final path = Path();
    final start = Offset.lerp(pts[n - 1], pts[0], 0.5)!;
    path.moveTo(start.dx, start.dy);
    for (var i = 0; i < n; i++) {
      final p = pts[i];
      final mid = Offset.lerp(p, pts[(i + 1) % n], 0.5)!;
      path.quadraticBezierTo(p.dx, p.dy, mid.dx, mid.dy);
    }
    path.close();
    return path;
  }

  static void _paintArms(
      Canvas canvas, FabioPose pose, _Deformer d, Paint bodyPaint) {
    final stroke = Paint()
      ..shader = bodyPaint.shader
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 11;
    void arm(double ext, Offset root, double angle) {
      if (ext <= 0.01) return;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final len = 4 + 17 * clampD(ext, 0, 1.3);
      canvas.drawLine(root - dir * 4, root + dir * len, stroke);
    }

    arm(pose.armRight, d.apply(122, 72), pose.armRightAngle);
    arm(pose.armLeft, d.apply(18, 72), math.pi - pose.armLeftAngle);
  }

  static void _paintShine(
      Canvas canvas, FabioPose pose, _Deformer d, Path body) {
    canvas.save();
    canvas.clipPath(body);
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: clampD(pose.shine, 0, 1));
    final c = d.apply(46, 22);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.5);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 17, height: 7), paint);
    canvas.restore();
    final dot = d.apply(34, 33);
    canvas.drawCircle(dot, 2.2, paint);
    canvas.restore();
  }

  static void _paintFace(Canvas canvas, FabioPose pose, _Deformer d) {
    final fx = 72 + 13 * pose.facing + pose.lookX * 4.5;
    final fy = 41 + pose.lookY * 3.5;
    final spread = 6.55 * (0.9 + 0.1 * pose.facing.abs());
    final eyeL = d.apply(fx - spread, fy - 4.2);
    final eyeR = d.apply(fx + spread, fy - 4.2);
    final mouth = d.apply(fx + pose.lookX * 1.2, fy + 4 + pose.lookY * 1.2);

    if (pose.blush > 0.01) {
      final a = clampD(pose.blush, 0, 1);
      final soft = Paint()..color = const Color(0xFFFF8FAB).withValues(alpha: 0.3 * a);
      final core = Paint()..color = const Color(0xFFFF8FAB).withValues(alpha: 0.5 * a);
      for (final e in [eyeL + const Offset(-2, 6.4), eyeR + const Offset(2, 6.4)]) {
        canvas.drawOval(Rect.fromCenter(center: e, width: 9.5, height: 5), soft);
        canvas.drawOval(Rect.fromCenter(center: e, width: 6.5, height: 3.2), core);
      }
    }

    _paintEye(canvas, pose, d, eyeL, pose.eyeOpenLeft);
    _paintEye(canvas, pose, d, eyeR, pose.eyeOpenRight);
    _paintMouth(canvas, pose, d, mouth);
  }

  static void _paintEye(
      Canvas canvas, FabioPose pose, _Deformer d, Offset c, double open) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(d.sx, d.sy);
    final s = pose.eyeScale;
    final shapeA =
        pose.eyeShape == FabioEyeShape.none ? 0.0 : clampD(pose.eyeShapeAmount, 0, 1);
    final happy = clampD(pose.eyeHappy, 0, 1);
    final baseA = (1 - happy) * (1 - shapeA);
    final happyA = happy * (1 - shapeA);
    open = clampD(open, 0, 1.2);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8;

    if (baseA > 0.01) {
      final capA = smoothstep(0.1, 0.3, open) * baseA;
      if (capA > 0.01) {
        final w = 4 * s;
        final h = math.max(7 * s * open, 1.6);
        final r = math.min(w, h) / 2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: w, height: h),
              Radius.circular(r)),
          Paint()..color = _ink.withValues(alpha: capA),
        );
        final glint = smoothstep(1.04, 1.3, s) * capA * smoothstep(0.5, 0.9, open);
        if (glint > 0.01) {
          canvas.drawCircle(Offset(-0.5 * s, -h / 2 + 1.5 * s), 0.85 * s,
              Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: glint));
        }
      }
      final lineA = (1 - smoothstep(0.1, 0.3, open)) * baseA;
      if (lineA > 0.01) {
        final p = Path()
          ..moveTo(-2.4 * s, -0.3)
          ..quadraticBezierTo(0, 1.4 * s, 2.4 * s, -0.3);
        canvas.drawPath(p, line..color = _ink.withValues(alpha: lineA));
      }
    }
    if (happyA > 0.01) {
      final p = Path()
        ..moveTo(-2.8 * s, 1.4 * s)
        ..quadraticBezierTo(0, -2.9 * s, 2.8 * s, 1.4 * s);
      canvas.drawPath(p, line..color = _ink.withValues(alpha: happyA));
    }
    if (shapeA > 0.01) {
      final pop = s * (0.35 + 0.65 * ease('outBack', shapeA));
      canvas.scale(pop);
      _paintEyeShape(canvas, pose, shapeA);
    }
    canvas.restore();
  }

  static void _paintEyeShape(Canvas canvas, FabioPose pose, double alpha) {
    final ink = _ink.withValues(alpha: alpha);
    switch (pose.eyeShape) {
      case FabioEyeShape.heart:
        canvas.drawPath(unitHeart(4.4),
            Paint()..color = const Color(0xFFFF4F7B).withValues(alpha: alpha));
      case FabioEyeShape.star:
        final star = starPath(5.2, 2.3);
        canvas.drawPath(
            star, Paint()..color = const Color(0xFFFFC23D).withValues(alpha: alpha));
        canvas.drawPath(
            star,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = 0.9
              ..color = ink);
      case FabioEyeShape.spiral:
        final p = Path();
        const turns = 2.6;
        for (var i = 0; i <= 40; i++) {
          final t = i / 40;
          final a = t * turns * 2 * math.pi + pose.eyeSpin;
          final r = 0.3 + t * 3.3;
          final pt = Offset(math.cos(a) * r, math.sin(a) * r);
          i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(
            p,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = 1.1
              ..color = ink);
      case FabioEyeShape.cross:
        final paint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.8
          ..color = ink;
        canvas.drawLine(const Offset(-2.4, -2.4), const Offset(2.4, 2.4), paint);
        canvas.drawLine(const Offset(2.4, -2.4), const Offset(-2.4, 2.4), paint);
      case FabioEyeShape.none:
        break;
    }
  }

  static void _paintMouth(Canvas canvas, FabioPose pose, _Deformer d, Offset c) {
    final w = 4.2 * pose.mouthWidth;
    final s = clampD(pose.mouthSmile, -1, 1);
    final o = clampD(pose.mouthOpen, 0, 1.2);
    final r = clampD(pose.mouthRound, 0, 1);

    // "D" mouth: two cubic edges between the corners.
    final cy = -s * 1.8;
    final topC = cy + s * 2.2 * (1 - clampD(o, 0, 1));
    final bot = topC + o * 8.5;
    final dm = <double>[
      w, cy, w * 0.5, topC, -w * 0.5, topC, -w, cy, //
      -w * 0.95, bot, w * 0.95, bot,
    ];

    // "O" mouth: an ellipse from the same topology.
    final a = 2.4 * pose.mouthWidth;
    final b = 1.0 + o * 2.6;
    final ey = b * 0.9 - 0.5;
    final k = b * 4 / 3;
    final om = <double>[
      a, ey, a, ey - k, -a, ey - k, -a, ey, //
      -a, ey + k, a, ey + k,
    ];
    final m = List<double>.generate(12, (i) => lerpD(dm[i], om[i], r));

    final path = Path()
      ..moveTo(m[0], m[1])
      ..cubicTo(m[2], m[3], m[4], m[5], m[6], m[7])
      ..cubicTo(m[8], m[9], m[10], m[11], m[0], m[1])
      ..close();

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(d.sx, d.sy);
    canvas.drawPath(path, Paint()..color = _ink);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.1
          ..color = _ink);
    final tongue = smoothstep(0.45, 0.9, o) * (1 - r);
    if (tongue > 0.01) {
      canvas.clipPath(path);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(0, lerpD(cy, bot, 0.72)), width: w * 1.05, height: 4.4),
          Paint()..color = const Color(0xFFFF7E9D).withValues(alpha: tongue));
    }
    canvas.restore();
  }

  /// A heart in a box roughly `2r` wide, centred on the origin.
  static Path unitHeart(double r) => Path()
    ..moveTo(0, 0.9 * r)
    ..cubicTo(-0.9 * r, 0.25 * r, -1.05 * r, -0.55 * r, -0.5 * r, -0.75 * r)
    ..cubicTo(-0.2 * r, -0.85 * r, 0, -0.6 * r, 0, -0.45 * r)
    ..cubicTo(0, -0.6 * r, 0.2 * r, -0.85 * r, 0.5 * r, -0.75 * r)
    ..cubicTo(1.05 * r, -0.55 * r, 0.9 * r, 0.25 * r, 0, 0.9 * r)
    ..close();

  static Path starPath(double outer, double inner, [int points = 5]) {
    final p = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / points;
      final pt = Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }
}

/// Maps a point of the rest outline to its deformed position for a pose.
class _Deformer {
  final FabioPose p;
  final double sx;
  final double sy;

  _Deformer(this.p)
      : sy = p.stretch * (1 + p.breath * 0.014),
        sx = (1 + (1 / p.stretch - 1) * 0.9) * (1 + p.breath * 0.008);

  Offset apply(double x, double y) {
    var dx = 0.0, dy = 0.0;
    final hem = smoothstep(96, 134, y);
    if (hem > 0) {
      final a = x * 0.085 - p.hemPhase;
      dy += p.hemAmp * hem * math.sin(a);
      dx += p.hemAmp * 0.45 * hem * math.cos(a);
      dx += (x - 72) * hem * p.flare;
    }
    final lag = clampD(y / 138, 0, 1.1);
    final lag2 = lag * lag;
    dx -= p.dragX * lag2 * 16;
    dy -= p.dragY * lag2 * 8;
    final tx = x - 17, ty = y - 23;
    final tuft = math.exp(-(tx * tx + ty * ty) / 242);
    dx += p.tuftX * tuft;
    dy += p.tuftY * tuft;
    if (p.wobble != 0) dx += p.wobble * math.sin(y * 0.07 + p.wobblePhase) * 7;
    return Offset(72 + (x + dx - 72) * sx, 118 + (y + dy - 118) * sy);
  }
}
