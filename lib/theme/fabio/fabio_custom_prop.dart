import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'fabio_fx.dart';

/// A prop defined by data rather than code, so new ones can be made in
/// Fabio Studio without an app release.
///
/// Scripts declare them in a top-level `props` map and use them by name in
/// `fx` clips, exactly like the built-in [FabioProp]s:
///
/// ```json
/// "props": {
///   "rocket": { "kind": "vector", "viewBox": [0, 0, 24, 24],
///               "paths": [{ "d": "M12 2 ...", "fill": "currentColor" }],
///               "physics": "rise", "color": "#FF5C8A" },
///   "taco":   { "kind": "glyph", "text": "🌮", "physics": "fall" }
/// }
/// ```
///
/// A path `fill` or `stroke` of `currentColor` takes the clip's `color`, or
/// the prop's `color` when the clip has none.
class FabioCustomProp {
  final String name;

  /// Set for glyph props (an emoji or a short piece of text).
  final String? text;
  final Rect viewBox;
  final List<FabioVectorPath> paths;
  final FabioPropPhysics physics;
  final Color color;

  /// Multiplies the default prop size.
  final double size;

  FabioCustomProp({
    required this.name,
    this.text,
    this.viewBox = const Rect.fromLTWH(0, 0, 24, 24),
    this.paths = const [],
    this.physics = FabioPropPhysics.float,
    this.color = const Color(0xFF4396FE),
    this.size = 1,
  });

  bool get isGlyph => text != null;

  /// Returns null when [json] defines nothing drawable.
  static FabioCustomProp? fromJson(String name, Object? json) {
    if (json is! Map) return null;
    final text = json['text'];
    final color = parseSvgColor(json['color']) ?? const Color(0xFF4396FE);
    final base = FabioPropPhysics.preset(json['physics']);
    double? n(String k) => json[k] is num ? (json[k] as num).toDouble() : null;
    final physics = FabioPropPhysics(
      n('gravity') ?? base.gravity,
      n('drag') ?? base.drag,
      spin: n('spin') ?? base.spin,
      sway: n('sway') ?? base.sway,
      life: (n('life') ?? base.life).clamp(0.2, 5).toDouble(),
      flip: json['flip'] is bool ? json['flip'] as bool : base.flip,
      pulse: json['pulse'] is bool ? json['pulse'] as bool : base.pulse,
    );
    final size = (n('size') ?? 1).clamp(0.2, 5).toDouble();

    if (json['kind'] == 'glyph' || (json['kind'] == null && text is String)) {
      if (text is! String || text.isEmpty) return null;
      return FabioCustomProp(
          name: name, text: text, physics: physics, color: color, size: size);
    }

    final vb = json['viewBox'];
    var viewBox = const Rect.fromLTWH(0, 0, 24, 24);
    if (vb is List && vb.length == 4 && vb.every((v) => v is num)) {
      final v = vb.map((e) => (e as num).toDouble()).toList();
      if (v[2] > 0 && v[3] > 0) viewBox = Rect.fromLTWH(v[0], v[1], v[2], v[3]);
    }
    final paths = <FabioVectorPath>[];
    for (final p in (json['paths'] as List? ?? const [])) {
      if (p is! Map || p['d'] is! String) continue;
      final path = parseSvgPath(p['d'] as String);
      final stroke = p['stroke'];
      final fill = p.containsKey('fill') ? p['fill'] : (stroke == null ? 'currentColor' : 'none');
      paths.add(FabioVectorPath(
        path: path,
        fill: parseSvgColor(fill),
        fillIsCurrent: fill == 'currentColor',
        stroke: parseSvgColor(stroke),
        strokeIsCurrent: stroke == 'currentColor',
        strokeWidth: p['strokeWidth'] is num ? (p['strokeWidth'] as num).toDouble() : 1,
        opacity: p['opacity'] is num ? (p['opacity'] as num).toDouble().clamp(0, 1) : 1,
      ));
    }
    if (paths.isEmpty) return null;
    return FabioCustomProp(
      name: name,
      viewBox: viewBox,
      paths: paths,
      physics: physics,
      color: color,
      size: size,
    );
  }

  TextPainter? _glyph;
  static const double _glyphFontSize = 64;

  /// Draws the prop centred on the origin, about `2 * r` across.
  void paint(Canvas canvas, double r, Color tint, double alpha) {
    if (isGlyph) {
      final g = _glyph ??= TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(fontSize: _glyphFontSize, color: tint, height: 1)),
        textDirection: TextDirection.ltr,
      )..layout();
      final k = 2 * r / math.max(g.width, g.height);
      canvas.save();
      canvas.scale(k);
      canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
      g.paint(canvas, Offset(-g.width / 2, -g.height / 2));
      canvas.restore();
      canvas.restore();
      return;
    }
    final vb = viewBox;
    final k = 2 * r / math.max(vb.width, vb.height);
    canvas.save();
    canvas.scale(k);
    canvas.translate(-vb.center.dx, -vb.center.dy);
    for (final p in paths) {
      final a = alpha * p.opacity;
      final fill = p.fillIsCurrent ? tint : p.fill;
      if (fill != null) {
        canvas.drawPath(p.path, Paint()..color = fill.withValues(alpha: fill.a * a));
      }
      final stroke = p.strokeIsCurrent ? tint : p.stroke;
      if (stroke != null && p.strokeWidth > 0) {
        canvas.drawPath(
            p.path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = p.strokeWidth
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..color = stroke.withValues(alpha: stroke.a * a));
      }
    }
    canvas.restore();
  }
}

class FabioVectorPath {
  final Path path;
  final Color? fill;
  final bool fillIsCurrent;
  final Color? stroke;
  final bool strokeIsCurrent;
  final double strokeWidth;
  final double opacity;

  const FabioVectorPath({
    required this.path,
    this.fill,
    this.fillIsCurrent = false,
    this.stroke,
    this.strokeIsCurrent = false,
    this.strokeWidth = 1,
    this.opacity = 1,
  });
}

/// `#RGB`, `#RRGGBB`, `#RRGGBBAA`, `black` or `white`. `none`,
/// `currentColor` and anything else return null.
Color? parseSvgColor(Object? v) {
  if (v is! String) return null;
  final s = v.trim().toLowerCase();
  if (s == 'black') return const Color(0xFF000000);
  if (s == 'white') return const Color(0xFFFFFFFF);
  if (!s.startsWith('#')) return null;
  var hex = s.substring(1);
  if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
  if (hex.length == 6) hex = '${hex}ff';
  if (hex.length != 8) return null;
  final rgba = int.tryParse(hex, radix: 16);
  if (rgba == null) return null;
  return Color(((rgba & 0xFF) << 24) | (rgba >> 8));
}

/// Parses SVG path data (`M L H V C S Q T A Z`, absolute and relative).
/// Malformed input stops parsing and returns what was read so far, which
/// matches how browsers treat broken path data.
Path parseSvgPath(String d) {
  final path = Path();
  final s = _Scanner(d);
  var cx = 0.0, cy = 0.0, startX = 0.0, startY = 0.0;
  // Last control point, for the reflected S and T commands.
  double? ctrlX, ctrlY;
  var cmd = '';
  var prev = '';
  try {
    while (true) {
      s.skipSeparators();
      if (s.done) break;
      if (_isCommand(s.peek)) {
        cmd = s.take();
      } else if (cmd.isEmpty || cmd == 'Z' || cmd == 'z') {
        break;
      }
      final rel = cmd == cmd.toLowerCase();
      final ox = rel ? cx : 0.0, oy = rel ? cy : 0.0;
      final upper = cmd.toUpperCase();
      switch (upper) {
        case 'M':
          cx = s.number() + ox;
          cy = s.number() + oy;
          path.moveTo(cx, cy);
          startX = cx;
          startY = cy;
          cmd = rel ? 'l' : 'L';
        case 'L':
          cx = s.number() + ox;
          cy = s.number() + oy;
          path.lineTo(cx, cy);
        case 'H':
          cx = s.number() + ox;
          path.lineTo(cx, cy);
        case 'V':
          cy = s.number() + oy;
          path.lineTo(cx, cy);
        case 'C':
          final x1 = s.number() + ox, y1 = s.number() + oy;
          final x2 = s.number() + ox, y2 = s.number() + oy;
          cx = s.number() + ox;
          cy = s.number() + oy;
          path.cubicTo(x1, y1, x2, y2, cx, cy);
          ctrlX = x2;
          ctrlY = y2;
        case 'S':
          final reflect = prev == 'C' || prev == 'S';
          final x1 = reflect ? 2 * cx - ctrlX! : cx;
          final y1 = reflect ? 2 * cy - ctrlY! : cy;
          final x2 = s.number() + ox, y2 = s.number() + oy;
          cx = s.number() + ox;
          cy = s.number() + oy;
          path.cubicTo(x1, y1, x2, y2, cx, cy);
          ctrlX = x2;
          ctrlY = y2;
        case 'Q':
          final x1 = s.number() + ox, y1 = s.number() + oy;
          cx = s.number() + ox;
          cy = s.number() + oy;
          path.quadraticBezierTo(x1, y1, cx, cy);
          ctrlX = x1;
          ctrlY = y1;
        case 'T':
          final reflect = prev == 'Q' || prev == 'T';
          final x1 = reflect ? 2 * cx - ctrlX! : cx;
          final y1 = reflect ? 2 * cy - ctrlY! : cy;
          cx = s.number() + ox;
          cy = s.number() + oy;
          path.quadraticBezierTo(x1, y1, cx, cy);
          ctrlX = x1;
          ctrlY = y1;
        case 'A':
          final rx = s.number().abs(), ry = s.number().abs();
          final rotation = s.number();
          final large = s.flag(), sweep = s.flag();
          cx = s.number() + ox;
          cy = s.number() + oy;
          if (rx == 0 || ry == 0) {
            path.lineTo(cx, cy);
          } else {
            path.arcToPoint(Offset(cx, cy),
                radius: Radius.elliptical(rx, ry),
                rotation: rotation,
                largeArc: large,
                clockwise: sweep);
          }
        case 'Z':
          path.close();
          cx = startX;
          cy = startY;
        default:
          return path;
      }
      prev = upper;
    }
  } on FormatException {
    // Keep what parsed cleanly.
  }
  return path;
}

bool _isCommand(String c) => 'MmLlHhVvCcSsQqTtAaZz'.contains(c) && c.isNotEmpty;

class _Scanner {
  final String src;
  int i = 0;
  _Scanner(this.src);

  bool get done => i >= src.length;
  String get peek => done ? '' : src[i];
  String take() => src[i++];

  void skipSeparators() {
    while (!done && ' \t\n\r,'.contains(src[i])) {
      i++;
    }
  }

  double number() {
    skipSeparators();
    final start = i;
    if (!done && (src[i] == '+' || src[i] == '-')) i++;
    var digits = false;
    while (!done && _digit(src[i])) {
      i++;
      digits = true;
    }
    if (!done && src[i] == '.') {
      i++;
      while (!done && _digit(src[i])) {
        i++;
        digits = true;
      }
    }
    if (!digits) {
      i = start;
      throw const FormatException('expected a number');
    }
    if (!done && (src[i] == 'e' || src[i] == 'E')) {
      final mark = i;
      i++;
      if (!done && (src[i] == '+' || src[i] == '-')) i++;
      if (!done && _digit(src[i])) {
        while (!done && _digit(src[i])) {
          i++;
        }
      } else {
        i = mark;
      }
    }
    return double.parse(src.substring(start, i));
  }

  bool flag() {
    skipSeparators();
    if (done || (src[i] != '0' && src[i] != '1')) {
      throw const FormatException('expected an arc flag');
    }
    return src[i++] == '1';
  }

  static bool _digit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
}
