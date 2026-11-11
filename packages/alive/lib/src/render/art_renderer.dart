// Draws alive/1 art with the values of one frame.
//
// Everything that never changes is recorded once into ui.Pictures when the art is prepared: static shapes, text,
// gradients, shadows and the static parts of animated groups. Per frame the renderer only walks the animated layers
// (a few dozen groups), sets their transforms, opacities and colours, and replays the pictures. The drawing rules are
// the old FigmaArtPainter's, so the pixels are the same (test/render_parity_test.dart measures it).
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show FontWeight, TextAlign, TextBaseline, TextDirection, TextPainter, TextSpan, TextStyle;
import 'package:path_parsing/path_parsing.dart';

import '../runtime/layer_state.dart';
import '../schema/art_def.dart';
import '../schema/path_data.dart' show PathCommands, PathOp;
import '../schema/track.dart' show LayerProp;

export '../runtime/layer_state.dart' show AliveDressing;

/// Font families for the three faces Figma text boxes use. The app registers the fonts; Rubik is Fabla's own.
class AliveFonts {
  /// Font families by the art's font keys.
  const AliveFonts({this.rubik = 'Rubik', this.vt323, this.pixelify, this.system, this.families = const {}});

  /// Family for 'rubik' (and the fallback for the others).
  final String rubik;

  /// Family for 'vt323' (recorder displays), or null to use [rubik].
  final String? vt323;

  /// Family for 'pixelify', or null to use [rubik].
  final String? pixelify;

  /// Family for 'system' (the phone's own font in iOS status bar mockups), or null for the platform default.
  final String? system;

  /// Families for any other font key the art names (`ibm-plex-mono`: the CLI keys a family by its name, lower case,
  /// words joined by -), each registered by the app. A key with no family here draws in [rubik], as before 0.5.0.
  final Map<String, String> families;

  /// The family for an art font key (null: the platform default).
  String? family(String key) => families[key] ?? switch (key) { 'vt323' => vt323 ?? rubik, 'pixelify' => pixelify ?? rubik, 'system' => system, _ => rubik };

  @override
  bool operator ==(Object other) =>
      other is AliveFonts && other.rubik == rubik && other.vt323 == vt323 && other.pixelify == pixelify && other.system == system && _sameMap(other.families, families);

  @override
  int get hashCode => Object.hash(rubik, vt323, pixelify, system, Object.hashAllUnordered(families.entries.map((e) => '${e.key}=${e.value}')));

  static bool _sameMap(Map<String, String> a, Map<String, String> b) => a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
}

class _PathProxy extends PathProxy {
  _PathProxy(this.p);
  final ui.Path p;
  @override
  void moveTo(double x, double y) => p.moveTo(x, y);
  @override
  void lineTo(double x, double y) => p.lineTo(x, y);
  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3) => p.cubicTo(x1, y1, x2, y2, x3, y3);
  @override
  void close() => p.close();
}

void _replay(Float32List v, ui.Path p) {
  var i = 0;
  final n = v.length;
  while (i < n) {
    final op = v[i].toInt();
    if (op == PathOp.move) {
      p.moveTo(v[i + 1], v[i + 2]);
      i += 3;
    } else if (op == PathOp.line) {
      p.lineTo(v[i + 1], v[i + 2]);
      i += 3;
    } else if (op == PathOp.cubic) {
      p.cubicTo(v[i + 1], v[i + 2], v[i + 3], v[i + 4], v[i + 5], v[i + 6]);
      i += 7;
    } else {
      p.close();
      i += 1;
    }
  }
}

/// Whether a shape encloses no area: a line; a polyline or path whose points (curve control points too) all lie on one
/// straight line; a box or an ellipse with no width or no height. SVG fills nothing there and Chrome draws nothing, but
/// dart:ui does not promise the same: Flutter 3.44's renderer draws such a fill as a hairline along the line (in the
/// fill's colour, often SVG's default black under a coloured stroke). So the engine leaves the fill of these shapes
/// out (0.6.4), on every Flutter version. Their stroke is drawn as before.
bool geometryHasNoArea(Geometry g) {
  final v = g.v;
  switch (g.kind) {
    case 'line':
      return true;
    case 'rect':
    case 'ellipse':
      return v![2] <= 0 || v[3] <= 0;
    case 'poly':
      return _onOneLine(v!);
    case 'd':
      var cmds = g.commands;
      if (cmds == null) {
        try {
          cmds = PathCommands.parse(g.d!);
        } on FormatException {
          return false; // drawn as it is; the renderer reports malformed data
        }
      }
      final data = cmds.data, pts = <double>[];
      var i = 0;
      while (i < data.length) {
        final op = data[i].toInt();
        final n = op == PathOp.move || op == PathOp.line ? 2 : op == PathOp.cubic ? 6 : 0;
        for (var k = 1; k <= n; k++) {
          pts.add(data[i + k]);
        }
        i += n + 1;
      }
      return _onOneLine(pts);
  }
  return false;
}

/// Do the points [x0, y0, x1, y1, ...] all lie on one straight line (within a thousandth of a unit)?
bool _onOneLine(List<double> p) {
  if (p.length < 6) return true;
  final ax = p[0], ay = p[1];
  // the point farthest from the first gives the line's direction
  var bx = ax, by = ay, far = 0.0;
  for (var i = 2; i + 1 < p.length; i += 2) {
    final d = (p[i] - ax) * (p[i] - ax) + (p[i + 1] - ay) * (p[i + 1] - ay);
    if (d > far) {
      far = d;
      bx = p[i];
      by = p[i + 1];
    }
  }
  if (far <= 1e-12) return true;
  final len = math.sqrt(far), dx = bx - ax, dy = by - ay;
  for (var i = 2; i + 1 < p.length; i += 2) {
    if (((p[i] - ax) * dy - (p[i + 1] - ay) * dx).abs() / len > 1e-3) return false;
  }
  return true;
}

/// SVG geometry to a Path. Malformed path data throws [FormatException] (the loader reports it).
ui.Path pathOfGeometry(Geometry g) {
  final p = ui.Path();
  final v = g.v;
  switch (g.kind) {
    case 'd':
      final cmds = g.commands;
      if (cmds != null) {
        _replay(cmds.data, p);
      } else {
        writeSvgPathDataToPath(g.d, _PathProxy(p));
      }
    case 'rect':
      p.addRRect(ui.RRect.fromRectXY(ui.Rect.fromLTWH(v![0], v[1], v[2], v[3]), v[4], v[5]));
    case 'ellipse':
      p.addOval(ui.Rect.fromCenter(center: ui.Offset(v![0], v[1]), width: 2 * v[2], height: 2 * v[3]));
    case 'line':
      p
        ..moveTo(v![0], v[1])
        ..lineTo(v[2], v[3]);
    case 'poly':
      for (var i = 0; i + 1 < v!.length; i += 2) {
        if (i == 0) {
          p.moveTo(v[i], v[i + 1]);
        } else {
          p.lineTo(v[i], v[i + 1]);
        }
      }
      if (g.closed) p.close();
  }
  return p;
}

/// A rect or an ellipse as SVG draws its outline (where a dash pattern starts and which way it runs), or null for
/// other geometry (their path data already says it).
ui.Path? svgStartPath(Geometry g) {
  final v = g.v;
  if (g.kind == 'rect') {
    final x = v![0], y = v[1], w = v[2], h = v[3], rx = v[4], ry = v[5];
    final p = ui.Path()..moveTo(x + rx, y);
    final r = ui.Radius.elliptical(rx, ry);
    p.lineTo(x + w - rx, y);
    if (rx > 0 && ry > 0) p.arcToPoint(ui.Offset(x + w, y + ry), radius: r);
    p.lineTo(x + w, y + h - ry);
    if (rx > 0 && ry > 0) p.arcToPoint(ui.Offset(x + w - rx, y + h), radius: r);
    p.lineTo(x + rx, y + h);
    if (rx > 0 && ry > 0) p.arcToPoint(ui.Offset(x, y + h - ry), radius: r);
    p.lineTo(x, y + ry);
    if (rx > 0 && ry > 0) p.arcToPoint(ui.Offset(x + rx, y), radius: r);
    return p..close();
  }
  if (g.kind == 'ellipse') {
    final rect = ui.Rect.fromCenter(center: ui.Offset(v![0], v[1]), width: 2 * v[2], height: 2 * v[3]);
    return ui.Path()
      ..arcTo(rect, 0, math.pi, true)
      ..arcTo(rect, math.pi, math.pi, false)
      ..close();
  }
  return null;
}

Float64List _m4(Float64List m) => Float64List.fromList([m[0], m[1], 0, 0, m[2], m[3], 0, 0, 0, 0, 1, 0, m[4], m[5], 0, 1]);

Float64List _mul(Float64List m, Float64List n) => Float64List.fromList([
      m[0] * n[0] + m[2] * n[1],
      m[1] * n[0] + m[3] * n[1],
      m[0] * n[2] + m[2] * n[3],
      m[1] * n[2] + m[3] * n[3],
      m[0] * n[4] + m[2] * n[5] + m[4],
      m[1] * n[4] + m[3] * n[5] + m[5],
    ]);

ui.Color _colour(int argb, [double alpha = 1]) {
  final a = ((argb >> 24) & 0xFF) / 255 * alpha;
  return ui.Color.fromRGBO((argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF, a.clamp(0.0, 1.0));
}

/// A dashed copy of a path (SVG stroke-dasharray / stroke-dashoffset), in the path's own units.
ui.Path dashPath(ui.Path source, Float64List dashes, double offset) {
  if (dashes.isEmpty || dashes.every((d) => d <= 0)) return source;
  final out = ui.Path();
  final pattern = dashes.length.isOdd ? [...dashes, ...dashes] : dashes.toList();
  final total = pattern.fold<double>(0, (a, b) => a + b);
  for (final metric in source.computeMetrics()) {
    var dist = -(offset % total);
    var i = 0;
    while (dist < metric.length) {
      final len = pattern[i % pattern.length];
      if (i.isEven) {
        final a = math.max(0.0, dist), b = math.min(metric.length, dist + len);
        if (b > a) out.addPath(metric.extractPath(a, b), ui.Offset.zero);
      }
      dist += len;
      i++;
    }
  }
  return out;
}

class _Filter {
  _Filter(this.def);
  final FilterDef def;
  bool get active => def.blur > 0 || def.shadows.isNotEmpty;
}

sealed class _R {}

class _RPicture extends _R {
  _RPicture(this.picture);
  final ui.Picture picture;
}

class _RGroup extends _R {
  // only what drawing needs: holding the GroupNode would keep its static children (already in pictures) alive
  _RGroup(GroupNode node, this.tf, this.layer, this.clip, this.filter, this.kids)
      : opacity = node.opacity,
        px = node.px,
        py = node.py,
        cc = node.cc,
        box = node.box,
        clipBox = node.clipBox;
  final double opacity, px, py;
  final int cc;
  final BoxDef? box;
  final bool clipBox;

  /// Its layer trims the strokes under it.
  bool trims = false;
  final Float64List? tf;
  final int layer;
  final ui.Path? clip;
  final _Filter? filter;
  final List<_R> kids;
}

class _RText extends _R {
  _RText(this.node, this.tf, this.clip, this.filter);
  final TextNode node;
  final Float64List? tf;
  final ui.Path? clip;
  final _Filter? filter;
  int colour = 0; // the colour the cached picture was recorded with
  ui.Picture? picture;
}

class _RPlugin extends _R {
  _RPlugin(this.node, this.tf, this.clip, this.filter);
  final PluginNode node;
  final Float64List? tf;
  final ui.Path? clip;
  final _Filter? filter;
}

class _RPart extends _R {
  _RPart(this.node, this.tf, this.clip, this.filter);
  final PartNode node;
  final Float64List? tf;
  final ui.Path? clip;
  final _Filter? filter;
}

class _RShape extends _R {
  _RShape(this.node, this.tf, this.path, this.strokePath, this.clip, this.filter, this.fill, this.stroke, {this.trimSource});
  final ShapeNode node;
  final Float64List? tf;
  final ui.Path path;

  /// The path the stroke draws (the dashed one when the stroke is dashed; the fill always uses [path]).
  final ui.Path strokePath;
  final ui.Path? clip;
  final _Filter? filter;
  final ui.Paint? fill, stroke;

  /// Under a trimmed layer: the stroke's whole path as SVG runs it (where it starts, which way), to cut.
  final ui.Path? trimSource;
  List<ui.PathMetric>? _metrics;
  double _total = 0, _c0 = -1, _c1 = -1;
  ui.Path? _cut;

  /// The stroke from [t0] to [t1] of its length (0..1), over its contours in order; the last cut is kept.
  ui.Path cut(double t0, double t1) {
    if (t0 == _c0 && t1 == _c1 && _cut != null) return _cut!;
    final ms = _metrics ??= () {
      final list = trimSource!.computeMetrics().toList();
      _total = list.fold(0.0, (a, m) => a + m.length);
      return list;
    }();
    final a = t0.clamp(0.0, 1.0) * _total, b = t1.clamp(0.0, 1.0) * _total;
    var out = ui.Path();
    var at = 0.0;
    for (final m in ms) {
      final s0 = math.max(a, at), s1 = math.min(b, at + m.length);
      if (s1 > s0) out.addPath(m.extractPath(s0 - at, s1 - at), ui.Offset.zero);
      at += m.length;
    }
    final dash = node.dash;
    if (dash != null) out = dashPath(out, dash, node.dashOffset);
    _c0 = t0;
    _c1 = t1;
    return _cut = out;
  }
}

/// One art file, prepared for drawing: paths built, static parts recorded as pictures.
class CompiledArt {
  /// Prepare [def] for a scene whose layers are numbered by [layerIndex]. [recolour] swaps colours (0xRRGGBB to
  /// 0xRRGGBB, alpha kept) in fills, strokes, gradient stops and text: a kit part's tint.
  CompiledArt(ArtDef def, Map<String, int> layerIndex, {this.fonts = const AliveFonts(), this.recolour = const {}, Set<String> trimmed = const {}})
      : _def = def,
        _layerIndex = layerIndex,
        _trimmed = trimmed {
    for (final _ in _build()) {}
  }

  CompiledArt._(this._def, this._layerIndex, this.fonts, this.recolour, this._trimmed);

  /// Prepare [def] as the constructor does, in slices of about [slice]: after each, [pause] is asked for a future to
  /// wait on (the loader's waits for the next frame to be drawn while frames are coming, and gives null when none is
  /// due, so the work goes straight on). Without [pause] it is the constructor. The same result, drawn the same.
  static Future<CompiledArt> prepare(ArtDef def, Map<String, int> layerIndex,
      {AliveFonts fonts = const AliveFonts(),
      Map<int, int> recolour = const {},
      Set<String> trimmed = const {},
      Duration slice = const Duration(milliseconds: 4),
      Future<void>? Function()? pause}) async {
    final c = CompiledArt._(def, layerIndex, fonts, recolour, trimmed);
    final budget = slice.inMicroseconds;
    final sw = Stopwatch()..start();
    for (final _ in c._build()) {
      if (pause == null || sw.elapsedMicroseconds < budget) continue;
      final wait = pause();
      if (wait != null) await wait;
      sw.reset();
    }
    return c;
  }

  // One step per clip, per static node drawn and per animated node compiled.
  Iterable<void> _build() sync* {
    for (final e in def.clips.entries) {
      var out = ui.Path();
      if (e.value.any((s) => s.evenOdd)) {
        // each shape with its own clip rule, then their exact union (SVG); the old painter's plain concatenation below
        // is kept for clips without even-odd shapes, so their pixels do not move
        for (final s in e.value) {
          var p = pathOfGeometry(s.geometry);
          if (s.tf != null) p = p.transform(_m4(s.tf!));
          if (s.evenOdd) p.fillType = ui.PathFillType.evenOdd;
          out = ui.Path.combine(ui.PathOperation.union, out, p);
        }
      } else {
        for (final s in e.value) {
          final p = pathOfGeometry(s.geometry);
          out.addPath(s.tf == null ? p : p.transform(_m4(s.tf!)), ui.Offset.zero);
        }
      }
      _clips[e.key] = out;
      yield null;
    }
    for (final n in def.roots) {
      final plane = n is GroupNode ? n.plane : 'main';
      (_planes[plane] ??= <ArtNode>[]).add(n);
    }
    for (final e in _planes.entries) {
      final out = <_R>[];
      _roots[e.key] = out;
      yield* _compileList(e.value, out);
    }
    _planes.clear();
  }

  /// The art (after [releaseTree], its header only: id, size, offset, layers).
  ArtDef get def => _def;
  ArtDef _def;

  /// Let go of the parsed node tree: what is static is in the pictures, what moves is compiled. [def] keeps the
  /// art's header. The loader does it once a scene is prepared, so a scene on screen holds no path text.
  void releaseTree() => _def = _def.header();

  /// Fonts the text was laid out with.
  final AliveFonts fonts;

  /// Colour swaps applied when the art was prepared (a tint).
  final Map<int, int> recolour;

  int _rc(int argb) {
    if (recolour.isEmpty) return argb;
    final v = recolour[argb & 0xFFFFFF];
    return v == null ? argb : (argb & 0xFF000000) | (v & 0xFFFFFF);
  }

  final Map<String, int> _layerIndex;

  // layers whose strokes are trimmed (a scene keys their trimStart or trimEnd): strokes under them are drawn per frame
  final Set<String> _trimmed;
  final Map<String, ui.Path> _clips = {};
  final Set<String> _pluginKinds = {};

  /// The plugin node kinds this art draws.
  Set<String> get pluginKinds => _pluginKinds;
  final Map<String, List<ArtNode>> _planes = {};
  final Map<String, List<_R>> _roots = {};
  final List<ui.Picture> _pictures = [];
  final ui.Paint _layerPaint = ui.Paint();
  final Float64List _delta = Float64List(16);
  bool _disposed = false;

  /// The planes this art draws ('main' unless it splits itself).
  Iterable<String> get planes => _roots.keys;

  /// Pictures recorded (for tests and the benchmark).
  int get pictureCount => _pictures.length;

  /// Native memory the recorded pictures hold, approximately (Picture.approximateBytesUsed).
  int get pictureBytes => _pictures.fold(0, (n, p) => n + p.approximateBytesUsed);

  /// Release the recorded pictures. The art cannot be drawn afterwards.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final p in _pictures) {
      p.dispose();
    }
    _pictures.clear();
    void texts(List<_R> list) {
      for (final r in list) {
        if (r is _RText) r.picture?.dispose();
        if (r is _RGroup) texts(r.kids);
      }
    }

    _roots.values.forEach(texts);
    _roots.clear();
  }

  /// Has [dispose] run?
  bool get disposed => _disposed;

  // ---------- compile ----------

  // Is there a stroke in [n] (under a trimmed layer it cannot be recorded once)?
  static bool _stroked(ArtNode n) => switch (n) {
        ShapeNode() => n.stroke != null && n.strokeWidth > 0,
        GroupNode() => n.kids.any(_stroked),
        _ => false,
      };

  Iterable<void> _compileList(List<ArtNode> nodes, List<_R> out, [bool trim = false]) sync* {
    // a run of static siblings is recorded into one picture (the recorder stays open across steps)
    ui.PictureRecorder? rec;
    ui.Canvas? c;
    void flush() {
      final r = rec;
      if (r == null) return;
      final pic = r.endRecording();
      _pictures.add(pic);
      out.add(_RPicture(pic));
      rec = null;
      c = null;
    }

    for (final n in nodes) {
      if (!n.isDynamic && !(trim && _stroked(n))) {
        if (rec == null) {
          rec = ui.PictureRecorder();
          c = ui.Canvas(rec!);
        }
        yield* _drawStaticSteps(c!, n);
        continue;
      }
      flush();
      yield* _compileDynamic(n, out, trim);
    }
    flush();
  }

  Iterable<void> _compileDynamic(ArtNode n, List<_R> out, [bool trim = false]) sync* {
    final tf = n.tf == null ? null : _m4(n.tf!);
    final clip = n.clip == null ? null : _clips[n.clip];
    final f = n.filter == null ? null : _Filter(def.filters[n.filter]!);
    final filter = f != null && f.active ? f : null;
    if (n is GroupNode) {
      final kids = <_R>[];
      final trims = n.layer != null && _trimmed.contains(n.layer);
      out.add(_RGroup(n, tf, n.layer == null ? -1 : (_layerIndex[n.layer] ?? -1), clip, filter, kids)..trims = trims);
      yield* _compileList(n.kids, kids, trim || trims);
      return;
    }
    if (n is TextNode) {
      out.add(_RText(n, tf, clip, filter));
    } else if (n is PluginNode) {
      _pluginKinds.add(n.kind);
      out.add(_RPlugin(n, tf, clip, filter));
    } else if (n is PartNode) {
      out.add(_RPart(n, tf, clip, filter));
    } else {
      final s = n as ShapeNode;
      final path = _shapePath(s);
      final op = s.both ? 1.0 : s.opacity;
      final trimSource = trim && s.stroke != null ? (svgStartPath(s.geometry) ?? path) : null;
      final fill = geometryHasNoArea(s.geometry) ? null : _paintOf(s.fill, s.fillOpacity * op, path, null);
      out.add(_RShape(s, tf, path, _strokePath(s, path), clip, filter, fill, _strokeOf(s, op, path), trimSource: trimSource));
    }
    yield null;
  }

  // A static node drawn in steps: a plain group (no layer for opacity or a filter) one child at a time, anything else
  // in one go. The same drawing as _drawStatic.
  Iterable<void> _drawStaticSteps(ui.Canvas c, ArtNode n) sync* {
    if (n is GroupNode && n.opacity >= 0.999 && (n.filter == null || !_Filter(def.filters[n.filter]!).active)) {
      c.save();
      if (n.tf != null) c.transform(_m4(n.tf!));
      if (n.clip != null) c.clipPath(_clips[n.clip]!);
      for (final k in n.kids) {
        yield* _drawStaticSteps(c, k);
      }
      c.restore();
      return;
    }
    _drawStatic(c, n);
    yield null;
  }

  ui.Path _shapePath(ShapeNode s) {
    final p = pathOfGeometry(s.geometry);
    if (s.evenOdd) p.fillType = ui.PathFillType.evenOdd;
    return p;
  }

  // a dash pattern applies to the stroke only: the fill (and a gradient's box) use the whole shape, as SVG and the
  // old painter do; and it starts where SVG starts the shape (a rect at its top left, going right; an ellipse at its
  // right end, going down), not where dart:ui's addRRect and addOval start theirs
  ui.Path _strokePath(ShapeNode s, ui.Path path) {
    if (s.dash == null || s.stroke == null) return path;
    return dashPath(svgStartPath(s.geometry) ?? path, s.dash!, s.dashOffset);
  }

  ui.Paint? _strokeOf(ShapeNode s, double op, ui.Path path) {
    if (s.stroke == null || s.strokeWidth <= 0) return null;
    final p = _paintOf(s.stroke, s.strokeOpacity * op, path, null);
    if (p == null) return null;
    return p
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = s.strokeWidth
      ..strokeCap = s.cap == 'round' ? ui.StrokeCap.round : s.cap == 'square' ? ui.StrokeCap.square : ui.StrokeCap.butt
      ..strokeJoin = s.join == 'round' ? ui.StrokeJoin.round : s.join == 'bevel' ? ui.StrokeJoin.bevel : ui.StrokeJoin.miter
      ..strokeMiterLimit = s.miter;
  }

  /// A paint for a spec; currentColor uses [current] (black when unknown).
  ui.Paint? _paintOf(String? spec, double alpha, ui.Path shape, int? current) {
    if (spec == null) return null;
    if (spec.startsWith('url:')) {
      final g = def.paints[spec.substring(4)];
      if (g == null || g.colours.isEmpty) return null;
      final box = shape.getBounds();
      // a bounding-box gradient on a shape with no width or no height has no box to fill: SVG ignores the paint and
      // Chrome draws nothing (round 8: ending C's train trails, horizontal lines, were drawn black here)
      if (g.bbox && (box.width <= 1e-9 || box.height <= 1e-9)) return null;
      return ui.Paint()..shader = _shader(g, box, alpha);
    }
    if (spec == 'currentColor') return ui.Paint()..color = _colour(current ?? 0xFF000000, alpha);
    final hex = spec.length == 9 ? int.parse(spec.substring(7, 9), radix: 16) << 24 | int.parse(spec.substring(1, 7), radix: 16) : 0xFF000000 | int.parse(spec.substring(1, 7), radix: 16);
    return ui.Paint()..color = _colour(_rc(hex), alpha);
  }

  ui.Shader _shader(PaintDef g, ui.Rect box, double alpha) {
    var colors = [for (final c in g.colours) _colour(_rc(c), alpha)];
    var stops = g.stops;
    // one stop paints its colour everywhere (SVG); dart:ui needs two
    if (colors.length == 1) {
      colors = [colors[0], colors[0]];
      stops = const [0.0, 1.0];
    }
    var m = g.bbox ? Float64List.fromList([box.width, 0, 0, box.height, box.left, box.top]) : Float64List.fromList([1, 0, 0, 1, 0, 0]);
    if (g.tf != null) m = _mul(m, g.tf!);
    final mm = _m4(m), k = g.coords;
    final tile = g.spread == 'reflect' ? ui.TileMode.mirror : g.spread == 'repeat' ? ui.TileMode.repeated : ui.TileMode.clamp;
    if (g.radial) {
      final f = g.focal;
      if (f != null && (f[0] != k[0] || f[1] != k[1] || f[2] > 0)) {
        return ui.Gradient.radial(ui.Offset(k[0], k[1]), k[2], colors, stops, tile, mm, ui.Offset(f[0], f[1]), f[2]);
      }
      return ui.Gradient.radial(ui.Offset(k[0], k[1]), k[2], colors, stops, tile, mm);
    }
    return ui.Gradient.linear(ui.Offset(k[0], k[1]), ui.Offset(k[2], k[3]), colors, stops, tile, mm);
  }

  // ---------- drawing (static nodes are drawn once, into a picture) ----------

  void _drawStatic(ui.Canvas c, ArtNode n) {
    c.save();
    if (n.tf != null) c.transform(_m4(n.tf!));
    if (n.clip != null) c.clipPath(_clips[n.clip]!);
    final f = n.filter == null ? null : _Filter(def.filters[n.filter]!);
    final filter = f != null && f.active ? f : null;
    switch (n) {
      case GroupNode():
        if (n.opacity > .001) {
          _layer(c, n.opacity, filter, () {
            for (final k in n.kids) {
              _drawStatic(c, k);
            }
          });
        }
      case ShapeNode():
        final path = _shapePath(n), sp = _strokePath(n, path);
        final op = n.both ? 1.0 : n.opacity;
        // a shape with no area has nothing to fill (geometryHasNoArea)
        final fill = geometryHasNoArea(n.geometry) ? null : _paintOf(n.fill, n.fillOpacity * op, path, null), stroke = _strokeOf(n, op, path);
        _layer(c, n.both ? n.opacity : 1, filter, () {
          if (fill != null) c.drawPath(path, fill);
          if (stroke != null) c.drawPath(sp, stroke);
        });
      case TextNode():
        _layer(c, n.opacity, filter, () => _text(c, n, 0xFF000000));
      case PartNode():
      case PluginNode():
        break; // never static
    }
    c.restore();
  }

  void _text(ui.Canvas c, TextNode t, int current) {
    final spans = [
      for (final s in t.spans)
        TextSpan(
          text: s.text,
          style: TextStyle(
            fontFamily: fonts.family(s.font),
            fontSize: s.size,
            fontWeight: FontWeight.values[(s.weight ~/ 100 - 1).clamp(0, 8)],
            color: _colour(s.colour == -1 ? current : _rc(s.colour)),
            height: s.lineHeight,
            // a text box's line height is shared above and below the line, as Figma and CSS do (Flutter's default
            // splits it in proportion to the font's ascent and descent, which sits Rubik about 1.5 px lower at 16/24)
            leadingDistribution: ui.TextLeadingDistribution.even,
            letterSpacing: s.letterSpacing,
          ),
        ),
    ];
    if (t.baseline) {
      // an SVG text: one line, its baseline at y, anchored at x
      final tp = TextPainter(text: TextSpan(children: spans), textDirection: TextDirection.ltr)..layout();
      // dart:ui puts half of the letter spacing before the first letter; SVG (Chrome) puts all of it after each one
      final ls = t.spans.isEmpty ? 0.0 : (t.spans.first.letterSpacing ?? 0) / 2;
      final dx = (t.anchor == 'middle' ? -tp.width / 2 : t.anchor == 'end' ? -tp.width : 0.0) - ls;
      tp.paint(c, ui.Offset(t.x + dx, t.y - tp.computeDistanceToActualBaseline(TextBaseline.alphabetic)));
      tp.dispose();
      return;
    }
    final align = t.align == 'center' ? TextAlign.center : t.align == 'right' ? TextAlign.right : TextAlign.left;
    final tp = TextPainter(text: TextSpan(children: spans), textDirection: TextDirection.ltr, textAlign: align);
    if (t.nowrap) {
      tp.layout();
    } else {
      tp.layout(minWidth: t.w, maxWidth: math.max(t.w, 1));
    }
    var dx = 0.0;
    if (t.nowrap) dx = align == TextAlign.center ? (t.w - tp.width) / 2 : align == TextAlign.right ? t.w - tp.width : 0;
    tp.paint(c, ui.Offset(t.x + dx, t.y));
    tp.dispose();
  }

  /// A layer for opacity and a filter: drop shadows behind, a layer blur on the content (the old painter's rules).
  void _layer(ui.Canvas c, double o, _Filter? f, void Function() content) {
    if (o >= 0.999 && f == null) {
      content();
      return;
    }
    if (o < 0.999) c.saveLayer(null, ui.Paint()..color = ui.Color.fromRGBO(0, 0, 0, o));
    if (f != null) {
      for (final s in f.def.shadows) {
        ui.ImageFilter? img = s.std > 0 ? ui.ImageFilter.blur(sigmaX: s.std, sigmaY: s.std, tileMode: ui.TileMode.decal) : null;
        if (s.spread > 0) {
          final dil = ui.ImageFilter.dilate(radiusX: s.spread, radiusY: s.spread);
          img = img == null ? dil : ui.ImageFilter.compose(outer: img, inner: dil);
        }
        final p = ui.Paint()..colorFilter = ui.ColorFilter.mode(_colour(s.colour), ui.BlendMode.srcIn);
        if (img != null) p.imageFilter = img;
        c.saveLayer(null, p);
        c.translate(s.dx, s.dy);
        content();
        c.restore();
      }
    }
    if (f != null && f.def.blur > 0) {
      c.saveLayer(null, ui.Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: f.def.blur, sigmaY: f.def.blur, tileMode: ui.TileMode.decal));
      content();
      c.restore();
    } else {
      content();
    }
    if (o < 0.999) c.restore();
  }

  // ---------- per frame ----------

  /// Draw [plane] of this art with the frame's [values], in scene coordinates.
  void paint(ui.Canvas c, LayerState values, {String plane = 'main'}) {
    if (_disposed) throw StateError('art "${def.id}" was released');
    final roots = _roots[plane];
    if (roots == null) return;
    c.save();
    if (def.offsetX != 0 || def.offsetY != 0) c.translate(-def.offsetX, -def.offsetY);
    _drawList(c, roots, values, 0xFF000000, 0, 1);
    c.restore();
  }

  void _drawList(ui.Canvas c, List<_R> list, LayerState s, int colour, double t0, double t1) {
    for (final r in list) {
      switch (r) {
        case _RPicture():
          c.drawPicture(r.picture);
        case _RGroup():
          _drawGroup(c, r, s, colour, t0, t1);
        case _RShape():
          _drawShape(c, r, colour, t0, t1);
        case _RText():
          _drawText(c, r, colour);
        case _RPart():
          _drawPart(c, r, s);
        case _RPlugin():
          _drawPlugin(c, r, s);
      }
    }
  }

  /// A plugin node: the frame's host draws it with the app's painter (nothing when none is registered).
  void _drawPlugin(ui.Canvas c, _RPlugin r, LayerState s) {
    final h = s.plugins;
    if (h == null || r.node.opacity <= .001) return;
    c.save();
    if (r.tf != null) c.transform(r.tf!);
    if (r.clip != null) c.clipPath(r.clip!);
    _layer(c, r.node.opacity, r.filter, () => h.paintPlugin(c, r.node));
    c.restore();
  }

  /// A worn part: the frame's dressing draws whatever the look puts in that slot (nothing when no one dresses it).
  void _drawPart(ui.Canvas c, _RPart r, LayerState s) {
    final d = s.dressing;
    if (d == null || !(r.node.front ? d.wearsFront(r.node.slot) : d.wears(r.node.slot, r.node.alt))) return;
    c.save();
    if (r.tf != null) c.transform(r.tf!);
    if (r.clip != null) c.clipPath(r.clip!);
    _layer(c, r.node.opacity, r.filter, () => d.paintPart(c, r.node.slot, r.node.alt));
    c.restore();
  }

  void _drawGroup(ui.Canvas c, _RGroup g, LayerState s, int colourIn, double t0In, double t1In) {
    final n = g;
    var op = n.opacity, colour = colourIn, t0 = t0In, t1 = t1In;
    final li = g.layer;
    if (li >= 0) {
      if (s.hidden[li] != 0) return;
      final lo = s.get(li, LayerProp.opacity);
      op *= lo < 0 ? 0.0 : (lo > 1 ? 1.0 : lo);
      if (op <= .001) return;
    }
    c.save();
    if (g.tf != null) c.transform(g.tf!);
    if (li >= 0) {
      if (s.deltaInto(li, n.px, n.py, _delta)) c.transform(_delta);
      if (n.cc == 1 && s.fill[li] >= 0) colour = 0xFF000000 | (s.fill[li] & 0xFFFFFF);
      if (n.cc == 2 && s.stroke[li] >= 0) colour = 0xFF000000 | (s.stroke[li] & 0xFFFFFF);
      if (g.trims) {
        t0 = s.get(li, LayerProp.trimStart);
        t1 = s.get(li, LayerProp.trimEnd);
      }
    }
    if (g.clip != null) c.clipPath(g.clip!);
    if (op > .001) {
      final f = g.filter;
      if (f == null) {
        if (op < .999) c.saveLayer(null, _layerPaint..color = ui.Color.fromRGBO(0, 0, 0, op));
        _groupContent(c, g, s, colour, t0, t1);
        if (op < .999) c.restore();
      } else {
        _layer(c, op, f, () => _groupContent(c, g, s, colour, t0, t1));
      }
    }
    c.restore();
  }

  void _groupContent(ui.Canvas c, _RGroup g, LayerState s, int colour, double t0, double t1) {
    final box = g.box;
    if (box == null) {
      _drawList(c, g.kids, s, colour, t0, t1);
      return;
    }
    final li = g.layer;
    double val(LayerProp v, double def) {
      if (li < 0) return def;
      final x = s.get(li, v);
      return x.isNaN ? def : x;
    }

    final w = math.max(0.0, val(LayerProp.w, box.w)), h = math.max(0.0, val(LayerProp.h, box.h));
    final r = math.min(math.min(val(LayerProp.r, box.r), w / 2), h / 2);
    final rr = ui.RRect.fromRectAndRadius(ui.Rect.fromLTWH(box.x, box.y, w, h), ui.Radius.circular(r));
    final fill = li >= 0 && s.fill[li] >= 0 ? (0xFF000000 | (s.fill[li] & 0xFFFFFF)) : box.fill;
    final stroke = box.stroke == null ? null : (li >= 0 && s.stroke[li] >= 0 ? (0xFF000000 | (s.stroke[li] & 0xFFFFFF)) : box.stroke);
    void bg() {
      if (fill != null) c.drawRRect(rr, ui.Paint()..color = _colour(fill, box.fillOpacity));
      if (stroke != null) {
        c.drawRRect(
            rr,
            ui.Paint()
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = box.strokeWidth
              ..color = _colour(stroke));
      }
    }

    if (g.clipBox) {
      c.save();
      c.clipRRect(rr);
      bg();
      _drawList(c, g.kids, s, colour, t0, t1);
      c.restore();
    } else {
      bg();
      _drawList(c, g.kids, s, colour, t0, t1);
    }
  }

  /// A text whose colour follows a layer: laid out again only when the colour changes (recorded as a picture).
  void _drawText(ui.Canvas c, _RText r, int colour) {
    var pic = r.picture;
    if (pic == null || r.colour != colour) {
      pic?.dispose();
      final rec = ui.PictureRecorder();
      _text(ui.Canvas(rec), r.node, colour);
      pic = r.picture = rec.endRecording();
      r.colour = colour;
    }
    c.save();
    if (r.tf != null) c.transform(r.tf!);
    if (r.clip != null) c.clipPath(r.clip!);
    _layer(c, r.node.opacity, r.filter, () => c.drawPicture(pic!));
    c.restore();
  }

  void _drawShape(ui.Canvas c, _RShape r, int colour, double t0, double t1) {
    final n = r.node;
    c.save();
    if (r.tf != null) c.transform(r.tf!);
    if (r.clip != null) c.clipPath(r.clip!);
    final op = n.both ? 1.0 : n.opacity;
    final fill = r.fill, stroke = r.stroke;
    if (fill != null && n.fill == 'currentColor') fill.color = _colour(colour, n.fillOpacity * op);
    if (stroke != null && n.stroke == 'currentColor') stroke.color = _colour(colour, n.strokeOpacity * op);
    // under a trimmed layer the stroke is cut to its share of the length (nothing when the share is empty)
    final cut = r.trimSource != null && (t0 > 0 || t1 < 1);
    final strokePath = cut ? (t1 > t0 ? r.cut(t0, t1) : null) : r.strokePath;
    void draw() {
      if (fill != null) c.drawPath(r.path, fill);
      if (stroke != null && strokePath != null) c.drawPath(strokePath, stroke);
    }

    _layer(c, n.both ? n.opacity : 1, r.filter, draw);
    c.restore();
  }
}
